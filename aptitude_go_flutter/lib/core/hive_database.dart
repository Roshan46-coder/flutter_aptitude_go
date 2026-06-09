import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveDatabase {
  static final HiveDatabase instance = HiveDatabase._init();

  HiveDatabase._init();

  late Box _categoriesBox;
  late Box _chatBox;
  late Box _authBox;
  late Box _profileBox;

  Future<void> init() async {
    await Hive.initFlutter();
    debugPrint("Hive: Initialized Flutter Hive");

    _categoriesBox = await Hive.openBox('categories_box');
    _chatBox = await Hive.openBox('chat_box');
    _authBox = await Hive.openBox('auth_box');
    _profileBox = await Hive.openBox('profile_box');
    debugPrint("Hive: All boxes opened successfully");

    final savedUser = _authBox.get('current_user');
    debugPrint("Hive: current_user exists in auth_box: ${savedUser != null}");

    final registeredUsers = _authBox.get('registered_users', defaultValue: []);
    if (registeredUsers is List) {
      debugPrint("Hive: registered_users count: ${registeredUsers.length}");
      for (int i = 0; i < registeredUsers.length; i++) {
        final u = registeredUsers[i];
        if (u is Map) {
          debugPrint("Hive:   user[$i]: username=${u['username']}, email=${u['email']}, is_company=${u['is_company']}, is_active=${u['is_active']}, has_password=${u['password'] != null && (u['password'] as String).isNotEmpty}");
        } else {
          debugPrint("Hive:   user[$i]: NOT A MAP — type=${u.runtimeType}");
        }
      }
    } else {
      debugPrint("Hive: registered_users is NOT a List — type=${registeredUsers.runtimeType}");
    }

    if (savedUser is Map && (registeredUsers is List ? registeredUsers.isEmpty : true)) {
      final restored = Map<String, dynamic>.from(savedUser);
      restored['password'] = _hashPassword('');
      await _authBox.put('registered_users', [restored]);
      debugPrint("Hive: Restored user '${restored['username']}' to registered_users (was missing)");
    }

    // Migrate old profile data from 'current_user' key to actual username key
    await _migrateOldProfileData();
  }

  /// Migrates old test attempt data stored under `profiles['current_user']`
  /// (pre-fix key) to the correct `profiles[actualUsername]` key.
  /// Runs once; subsequent runs are no-ops via a migration flag.
  Future<void> _migrateOldProfileData() async {
    try {
      final migrationDone = _authBox.get('_profile_migration_done', defaultValue: false);
      if (migrationDone == true) return;

      final profilesBox = await Hive.openBox('local_data_box');
      final raw = profilesBox.get('profiles', defaultValue: <String, dynamic>{});
      if (raw is! Map) return;
      final profiles = Map<String, dynamic>.from(raw);

      if (profiles.containsKey('current_user')) {
        final oldData = profiles['current_user'];
        if (oldData is Map) {
          final oldProfile = Map<String, dynamic>.from(oldData);
          final oldAttempts = (oldProfile['attempts'] as List?) ?? [];
          final oldCerts = (oldProfile['certificates'] as List?) ?? [];

          if (oldAttempts.isNotEmpty || oldCerts.isNotEmpty) {
            // Try to migrate to each registered user that doesn't already have data
            final users = getUsers();
            bool migrated = false;

            // First, try to migrate to the currently logged-in user
            final savedUser = _authBox.get('current_user');
            if (savedUser is Map) {
              final currentUsername = (savedUser['username'] as String? ?? '').toLowerCase();
              if (currentUsername.isNotEmpty) {
                final currentProfile = profiles[currentUsername] as Map? ?? <String, dynamic>{};
                final currentAttempts = (currentProfile['attempts'] as List?) ?? [];
                if (currentAttempts.isEmpty) {
                  profiles[currentUsername] = oldProfile;
                  profiles.remove('current_user');
                  migrated = true;
                  debugPrint("Hive: Migrated profile data from 'current_user' to '$currentUsername' (${oldAttempts.length} attempts)");
                }
              }
            }

            // If not migrated yet, try each user
            if (!migrated) {
              for (final u in users) {
                final uname = (u['username'] as String? ?? '').toLowerCase();
                if (uname.isEmpty) continue;
                final userProfile = profiles[uname] as Map? ?? <String, dynamic>{};
                final userAttempts = (userProfile['attempts'] as List?) ?? [];
                if (userAttempts.isEmpty) {
                  profiles[uname] = oldProfile;
                  profiles.remove('current_user');
                  migrated = true;
                  debugPrint("Hive: Migrated profile data from 'current_user' to '$uname' (${oldAttempts.length} attempts)");
                  break;
                }
              }
            }

            if (migrated) {
              await profilesBox.put('profiles', profiles);
            }
          } else {
            // No meaningful data; just clean up
            profiles.remove('current_user');
            await profilesBox.put('profiles', profiles);
          }
        } else {
          profiles.remove('current_user');
          await profilesBox.put('profiles', profiles);
        }
      }

      await _authBox.put('_profile_migration_done', true);
      debugPrint("Hive: Profile data migration completed");
    } catch (e) {
      debugPrint("Hive: Profile migration error: $e");
    }
  }

  // ── CATEGORIES DATA CACHING ────────────────────────────────────────────────

  Future<void> saveCategories({
    required List<dynamic> general,
    required List<dynamic> company,
  }) async {
    try {
      await _categoriesBox.put('general_categories', general);
      await _categoriesBox.put('company_categories', company);
    } catch (e) {
      debugPrint("Hive: Failed to save categories: $e");
    }
  }

  List<dynamic> getCachedGeneralCategories() {
    try {
      final data = _categoriesBox.get('general_categories');
      if (data is List) return data;
    } catch (_) {}
    return [];
  }

  List<dynamic> getCachedCompanyCategories() {
    try {
      final data = _categoriesBox.get('company_categories');
      if (data is List) return data;
    } catch (_) {}
    return [];
  }

  // ── AI CHATBOT PERSISTENCE ────────────────────────────────────────────────

  Future<void> saveChatMessage(Map<String, String> message, {required String username}) async {
    try {
      final key = 'message_history_$username';
      final List<dynamic> history = _chatBox.get(key, defaultValue: []);
      final List<Map<String, String>> updated = List<Map<String, String>>.from(
        history.map((e) => Map<String, String>.from(e)),
      );

      updated.add(message);
      await _chatBox.put(key, updated);
    } catch (e) {
      debugPrint("Hive: Failed to save chat message: $e");
    }
  }

  List<Map<String, String>> getCachedChatMessages({required String username}) {
    try {
      final key = 'message_history_$username';
      final data = _chatBox.get(key);
      if (data is List) {
        return List<Map<String, String>>.from(
          data.map((e) => Map<String, String>.from(e)),
        );
      }
    } catch (_) {}
    return [];
  }

  Future<void> clearChatHistory({String? username}) async {
    try {
      if (username != null) {
        final key = 'message_history_$username';
        await _chatBox.delete(key);
      } else {
        // Clear all chat history keys from all users
        final keys = _chatBox.keys.where((k) => k.toString().startsWith('message_history_')).toList();
        for (final k in keys) {
          await _chatBox.delete(k);
        }
      }
    } catch (_) {}
  }

  // ── LOCAL AUTH / USER MANAGEMENT ──────────────────────────────────────────

  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
    required bool isCompany,
    String? firstName,
    String? lastName,
    String? organization,
    String? currentStatus,
    String? interestedField,
    String? hiringFocus,
  }) async {
    try {
      final users = _getUsers();

      if (users.any((u) => u['username'] == username.toLowerCase())) {
        return {'success': false, 'error': 'Username already taken'};
      }
      if (users.any((u) => u['email'] == email.toLowerCase())) {
        return {'success': false, 'error': 'Email already registered'};
      }

      final verificationToken = _generateToken();

      final user = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'username': username.toLowerCase(),
        'email': email.toLowerCase(),
        'password': _hashPassword(password),
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'organization': organization ?? '',
        'is_company': isCompany,
        'is_active': false,
        'verification_token': verificationToken,
        'date_joined': DateTime.now().toIso8601String(),
        'level': 1,
        'exp': 0,
        'coins': 0,
        'lives': 5,
        'last_life_reset_date': DateTime.now().toIso8601String(),
        'current_status': currentStatus ?? '',
        'interested_field': interestedField ?? '',
        'hiring_focus': hiringFocus ?? '',
        'avatar': '',
        'company_name': '',
        'company_website': '',
        'company_description': '',
        'linkedin_url': '',
        'github_url': '',
        'leetcode_url': '',
      };

      users.add(user);
      await _authBox.put('registered_users', users);
      return {'success': true, 'message': 'Account created successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  Future<Map<String, dynamic>> loginUser(String usernameOrEmail, String password) async {
    try {
      final users = _getUsers();
      final input = usernameOrEmail.toLowerCase();

      debugPrint("🔐 LOGIN: Searching for '$input' among ${users.length} registered users");
      for (int i = 0; i < users.length; i++) {
        debugPrint("🔐 LOGIN:   user[$i]: username='${users[i]['username']}', email='${users[i]['email']}', is_company=${users[i]['is_company']}, is_active=${users[i]['is_active']}");
      }

      int foundIdx = -1;
      for (int i = 0; i < users.length; i++) {
        if (users[i]['username'] == input || users[i]['email'] == input) {
          foundIdx = i;
          break;
        }
      }

      if (foundIdx == -1) {
        debugPrint("🔐 LOGIN: No user found matching '$input'");
        return {'success': false, 'error': 'Invalid username or password'};
      }

      final user = users[foundIdx];
      debugPrint("🔐 LOGIN: Found user at index $foundIdx: username='${user['username']}', email='${user['email']}'");

      final inputHash = _hashPassword(password);
      final storedHash = user['password'] as String? ?? '';
      debugPrint("🔐 LOGIN: password check — stored='$storedHash', input_hash='$inputHash', match=${storedHash == inputHash}");

      if (storedHash != inputHash) {
        return {'success': false, 'error': 'Invalid username or password'};
      }

      if (user['is_active'] != true) {
        debugPrint("🔐 LOGIN: User is NOT active (is_active=${user['is_active']})");
        return {'success': false, 'error': 'Account is inactive. Please verify your email first.'};
      }

      final userData = Map<String, dynamic>.from(user);
      userData.remove('password');

      await _authBox.put('current_user', userData);
      return {'success': true, 'message': 'Logged in successfully', 'user': userData};
    } catch (e) {
      debugPrint("Hive login error: $e");
      return {'success': false, 'error': 'Login failed'};
    }
  }

  Map<String, dynamic>? getCurrentUser() {
    try {
      final data = _authBox.get('current_user');
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return null;
  }

  Future<void> saveCurrentUser(Map<String, dynamic> userData) async {
    try {
      await _authBox.put('current_user', userData);
      debugPrint("Hive: Saved current_user to auth_box");
    } catch (e) {
      debugPrint("Hive: Failed to save current_user: $e");
    }
  }

  Future<void> clearCurrentUser() async {
    try {
      await _authBox.delete('current_user');
      debugPrint("Hive: Deleted current_user from auth_box");
    } catch (e) {
      debugPrint("Hive: Failed to delete current_user: $e");
    }
  }

  Future<Map<String, dynamic>> verifyUser(String email) async {
    try {
      final users = _getUsers();
      final input = email.toLowerCase();
      int foundIndex = -1;

      for (int i = 0; i < users.length; i++) {
        if (users[i]['email'] == input) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex == -1) {
        return {'success': false, 'error': 'No account found with this email'};
      }

      users[foundIndex]['is_active'] = true;
      users[foundIndex]['verification_token'] = null;
      await _authBox.put('registered_users', users);
      return {'success': true, 'message': 'Email verified successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      final users = _getUsers();
      final input = email.toLowerCase();
      int foundIndex = -1;

      for (int i = 0; i < users.length; i++) {
        if (users[i]['email'] == input) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex == -1) {
        return {'success': false, 'error': 'No account found with this email'};
      }

      if (users[foundIndex]['is_active'] == true) {
        return {'success': false, 'error': 'Account is already verified'};
      }

      users[foundIndex]['verification_token'] = _generateToken();
      await _authBox.put('registered_users', users);
      return {'success': true, 'message': 'Verification email resent'};
    } catch (e) {
      return {'success': false, 'error': 'Failed to resend verification: $e'};
    }
  }

  Future<void> addUserReward(String rewardLabel) async {
    try {
      final current = _authBox.get('current_user');
      if (current is! Map) return;

      final user = Map<String, dynamic>.from(current);
      final username = user['username'] as String?;
      if (username == null) return;

      if (rewardLabel.contains('Coins')) {
        final amount = int.tryParse(rewardLabel.split(' ').first) ?? 0;
        user['coins'] = ((user['coins'] as num?)?.toInt() ?? 0) + amount;
      } else if (rewardLabel.contains('Life')) {
        final amount = int.tryParse(rewardLabel.split(' ').first.replaceAll('+', '')) ?? 1;
        user['lives'] = ((user['lives'] as num?)?.toInt() ?? 5) + amount;
      }

      await _authBox.put('current_user', user);

      final users = _getUsers();
      for (int i = 0; i < users.length; i++) {
        if (users[i]['username'] == username) {
          if (rewardLabel.contains('Coins')) {
            final amount = int.tryParse(rewardLabel.split(' ').first) ?? 0;
            users[i]['coins'] = ((users[i]['coins'] as num?)?.toInt() ?? 0) + amount;
          } else if (rewardLabel.contains('Life')) {
            final amount = int.tryParse(rewardLabel.split(' ').first.replaceAll('+', '')) ?? 1;
            users[i]['lives'] = ((users[i]['lives'] as num?)?.toInt() ?? 5) + amount;
          }
          break;
        }
      }
      await _authBox.put('registered_users', users);
    } catch (e) {
      debugPrint("Hive: Failed to add reward: $e");
    }
  }

  Future<void> addAttempt(Map<String, dynamic> attempt) async {
    try {
      final currentUser = getCurrentUser();
      if (currentUser == null) return;
      final username = currentUser['username'] as String? ?? '';
      if (username.isEmpty) return;

      final profilesBox = await Hive.openBox('local_data_box');
      final raw = profilesBox.get('profiles', defaultValue: <String, dynamic>{});
      final profiles = Map<String, dynamic>.from(raw as Map);
      final profileKey = username.toLowerCase();

      // Check both the current username key and legacy 'current_user' key
      final existingProfile = profiles[profileKey] ?? profiles['current_user'] ?? <String, dynamic>{};
      final profileData = existingProfile as Map? ?? <String, dynamic>{};
      final profile = Map<String, dynamic>.from(profileData);

      final attempts = List<Map<String, dynamic>>.from(
        (profile['attempts'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      attempts.add(attempt);
      profile['attempts'] = attempts;

      // Always write to the correct username key, never to 'current_user'
      if (profiles.containsKey('current_user') && profileKey != 'current_user') {
        profiles.remove('current_user');
      }
      profiles[profileKey] = profile;
      await profilesBox.put('profiles', profiles);
    } catch (e) {
      debugPrint("Hive: Failed to add attempt: $e");
    }
  }

  Future<void> updateCurrentUser(Map<String, dynamic> updates) async {
    try {
      final current = _authBox.get('current_user');
      if (current is! Map) return;
      final user = Map<String, dynamic>.from(current);
      final username = user['username'] as String?;
      user.addAll(updates);
      await _authBox.put('current_user', user);

      if (username != null) {
        final users = _getUsers();
        for (int i = 0; i < users.length; i++) {
          if (users[i]['username'] == username) {
            users[i].addAll(updates);
            break;
          }
        }
        await _authBox.put('registered_users', users);
      }
    } catch (e) {
      debugPrint("Hive: Failed to update user: $e");
    }
  }

  /// Checks if a new day has started and restores lives to max (5).
  /// Returns true if lives were restored.
  Future<bool> checkAndRestoreLives() async {
    try {
      final current = _authBox.get('current_user');
      if (current is! Map) return false;
      final user = Map<String, dynamic>.from(current);
      final username = user['username'] as String?;
      if (username == null) return false;

      final lastReset = user['last_life_reset_date'] as String?;
      final today = DateTime.now();

      if (lastReset != null) {
        final lastDate = DateTime.tryParse(lastReset);
        if (lastDate != null && _isSameDay(lastDate, today)) {
          return false; // already reset today
        }
      }

      user['lives'] = 5;
      user['last_life_reset_date'] = today.toIso8601String();
      await _authBox.put('current_user', user);

      final users = _getUsers();
      for (int i = 0; i < users.length; i++) {
        if (users[i]['username'] == username) {
          users[i]['lives'] = 5;
          users[i]['last_life_reset_date'] = today.toIso8601String();
          break;
        }
      }
      await _authBox.put('registered_users', users);

      debugPrint("❤️ Daily life reset: restored lives to 5 for '$username'");
      return true;
    } catch (e) {
      debugPrint("Hive: Failed to check/restore lives: $e");
      return false;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool isUsernameTaken(String username) {
    return _getUsers().any((u) => u['username'] == username.toLowerCase());
  }

  bool isEmailTaken(String email) {
    return _getUsers().any((u) => u['email'] == email.toLowerCase());
  }

  String? getVerificationToken(String email) {
    final users = _getUsers();
    final input = email.toLowerCase();
    for (final u in users) {
      if (u['email'] == input) {
        return u['verification_token'] as String?;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> getUsers() {
    final data = _authBox.get('registered_users', defaultValue: []);
    if (data is List) {
      final result = <Map<String, dynamic>>[];
      for (int i = 0; i < data.length; i++) {
        final e = data[i];
        if (e is Map) {
          try {
            result.add(Map<String, dynamic>.from(e));
          } catch (parseErr) {
            debugPrint("⚠️ getUsers: Failed to parse user[$i]: $parseErr");
          }
        } else {
          debugPrint("⚠️ getUsers: user[$i] is not a Map — type=${e.runtimeType}, value=$e");
        }
      }
      return result;
    }
    debugPrint("⚠️ getUsers: registered_users is not a List — type=${data.runtimeType}, value=$data");
    return [];
  }

  // ── CANDIDATE PROFILE DATA ─────────────────────────────────────────────────

  Map<String, dynamic> getCandidateProfile(String username) {
    final key = 'profile_$username';
    final data = _profileBox.get(key);
    if (data is Map) return Map<String, dynamic>.from(data);
    return _emptyProfile();
  }

  Future<void> saveCandidateProfile(String username, Map<String, dynamic> profile) async {
    await _profileBox.put('profile_$username', profile);
  }

  Map<String, dynamic> _emptyProfile() {
    return {
      'phone': '',
      'dob': '',
      'gender': '',
      'location': '',
      'headline': '',
      'bio': '',
      'education': <Map<String, dynamic>>[],
      'skills': <Map<String, dynamic>>[],
      'projects': <Map<String, dynamic>>[],
      'experience': <Map<String, dynamic>>[],
      'certifications': <Map<String, dynamic>>[],
      'resume_path': '',
      'portfolio_url': '',
      'github_url': '',
      'linkedin_url': '',
      'preferred_roles': <String>[],
      'preferred_location': '',
      'expected_salary': '',
      'employment_type': '',
      'availability': '',
      'achievements': <Map<String, dynamic>>[],
    };
  }

  // ── RECRUITER PROFILE DATA ─────────────────────────────────────────────────

  Map<String, dynamic> getRecruiterProfile(String username) {
    final key = 'recruiter_profile_$username';
    final data = _profileBox.get(key);
    if (data is Map) return Map<String, dynamic>.from(data);
    return _emptyRecruiterProfile();
  }

  Future<void> saveRecruiterProfile(String username, Map<String, dynamic> profile) async {
    await _profileBox.put('recruiter_profile_$username', profile);
    debugPrint("Hive: Saved recruiter profile for $username");
  }

  Map<String, dynamic> _emptyRecruiterProfile() {
    return {
      'phone': '',
      'designation': '',
      'location': '',
      'about': '',
      'company_name': '',
      'company_website': '',
      'company_description': '',
      'linkedin_url': '',
      'avatar_path': '',
    };
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  // ── LOCAL OTP (FALLBACK WHEN SERVER IS UNAVAILABLE) ───────────────────────

  Future<Map<String, dynamic>> generateLocalOtp({
    required String email,
    required String purpose,
  }) async {
    try {
      final otpCode = (Random().nextInt(900000) + 100000).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;

      final otpData = {
        'email': email.toLowerCase(),
        'otp': otpCode,
        'purpose': purpose,
        'expires_at': expiresAt,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'attempts': 0,
        'max_attempts': 5,
      };

      await _authBox.put('current_otp', otpData);
      debugPrint("Hive: Generated OTP for $email: $otpCode");
      return {'success': true, 'message': 'OTP sent to $email', 'otp_debug': otpCode};
    } catch (e) {
      return {'success': false, 'error': 'Failed to generate OTP: $e'};
    }
  }

  Future<void> clearOtp() async {
    try {
      await _authBox.delete('current_otp');
    } catch (_) {}
  }

  Future<Map<String, dynamic>> verifyLocalOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    try {
      final stored = _authBox.get('current_otp');
      if (stored == null) {
        return {'success': false, 'error': 'No OTP found. Request a new one.'};
      }

      final otpData = Map<String, dynamic>.from(stored);

      if (otpData['email'] != email.toLowerCase() || otpData['purpose'] != purpose) {
        return {'success': false, 'error': 'OTP mismatch. Request a new one.'};
      }

      if (DateTime.now().millisecondsSinceEpoch > (otpData['expires_at'] as int)) {
        await _authBox.delete('current_otp');
        return {'success': false, 'error': 'OTP has expired. Request a new one.'};
      }

      otpData['attempts'] = (otpData['attempts'] as int) + 1;
      if (otpData['attempts'] > otpData['max_attempts']) {
        await _authBox.delete('current_otp');
        return {'success': false, 'error': 'Too many failed attempts. Request a new OTP.'};
      }
      await _authBox.put('current_otp', otpData);

      if (otpData['otp'] != otp) {
        final remaining = (otpData['max_attempts'] as int) - (otpData['attempts'] as int);
        return {'success': false, 'error': 'Incorrect OTP. $remaining attempts remaining.'};
      }

      await _authBox.delete('current_otp');

      if (purpose == 'verify') {
        await verifyUser(email);
      }

      return {'success': true, 'message': 'OTP verified successfully'};
    } catch (e) {
      return {'success': false, 'error': 'Verification failed: $e'};
    }
  }

  Future<Map<String, dynamic>> resetLocalPassword({
    required String email,
    required String password,
  }) async {
    try {
      final users = _getUsers();
      final input = email.toLowerCase();

      debugPrint("🔑 PASSWORD RESET: Request for email='$input'");
      debugPrint("🔑 PASSWORD RESET: Total users stored BEFORE: ${users.length}");
      for (int i = 0; i < users.length; i++) {
        debugPrint("🔑 PASSWORD RESET:   user[$i]: username='${users[i]['username']}', email='${users[i]['email']}', is_company=${users[i]['is_company']}, is_active=${users[i]['is_active']}, has_password=${(users[i]['password'] as String?)?.isNotEmpty == true}");
      }

      int foundIndex = -1;
      for (int i = 0; i < users.length; i++) {
        if (users[i]['email'] == input) {
          foundIndex = i;
          break;
        }
      }

      if (foundIndex == -1) {
        debugPrint("🔑 PASSWORD RESET: No user found with email '$input'");
        return {'success': false, 'error': 'No account found with this email'};
      }

      debugPrint("🔑 PASSWORD RESET: Found user at index $foundIndex");
      debugPrint("🔑 PASSWORD RESET: User BEFORE update: username='${users[foundIndex]['username']}', email='${users[foundIndex]['email']}', password='${users[foundIndex]['password']}'");

      final newHash = _hashPassword(password);
      users[foundIndex]['password'] = newHash;

      debugPrint("🔑 PASSWORD RESET: User AFTER update: username='${users[foundIndex]['username']}', email='${users[foundIndex]['email']}', password='$newHash'");

      await _authBox.put('registered_users', users);

      final verifyUsers = _getUsers();
      debugPrint("🔑 PASSWORD RESET: Total users stored AFTER: ${verifyUsers.length}");
      for (int i = 0; i < verifyUsers.length; i++) {
        debugPrint("🔑 PASSWORD RESET:   user[$i]: username='${verifyUsers[i]['username']}', email='${verifyUsers[i]['email']}', password='${verifyUsers[i]['password']}'");
      }

      return {'success': true, 'message': 'Password reset successfully'};
    } catch (e) {
      debugPrint("🔑 PASSWORD RESET: EXCEPTION: $e");
      return {'success': false, 'error': 'Failed to reset password: $e'};
    }
  }

  List<Map<String, dynamic>> _getUsers() {
    return getUsers();
  }

  /// Given cumulative total XP, returns [level, xpIntoLevel, xpForNextLevel].
  static List<int> levelInfo(int totalExp) {
    int level = 1;
    int cumulative = 0;
    while (true) {
      final needed = level * 100;
      if (totalExp < cumulative + needed) {
        return [level, totalExp - cumulative, needed];
      }
      cumulative += needed;
      level++;
    }
  }

  /// Cumulative XP required to reach a given level (exclusive).
  static int cumulativeXpForLevel(int level) {
    if (level <= 1) return 0;
    return 50 * level * (level - 1);
  }

  /// XP needed to go from [level] to [level] + 1.
  static int xpForNextLevel(int level) => level * 100;

  String _hashPassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  String _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return base64Encode(utf8.encode('verify_$now$random'));
  }
}
