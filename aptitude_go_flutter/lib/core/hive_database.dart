import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class HiveDatabase {
  static final HiveDatabase instance = HiveDatabase._init();

  HiveDatabase._init();

  late Box _categoriesBox;
  late Box _chatBox;
  late Box _authBox;

  Future<void> init() async {
    await Hive.initFlutter();

    _categoriesBox = await Hive.openBox('categories_box');
    _chatBox = await Hive.openBox('chat_box');
    _authBox = await Hive.openBox('auth_box');
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

  Future<void> saveChatMessage(Map<String, String> message) async {
    try {
      final List<dynamic> history = _chatBox.get('message_history', defaultValue: []);
      final List<Map<String, String>> updated = List<Map<String, String>>.from(
        history.map((e) => Map<String, String>.from(e)),
      );

      updated.add(message);
      await _chatBox.put('message_history', updated);
    } catch (e) {
      debugPrint("Hive: Failed to save chat message: $e");
    }
  }

  List<Map<String, String>> getCachedChatMessages() {
    try {
      final data = _chatBox.get('message_history');
      if (data is List) {
        return List<Map<String, String>>.from(
          data.map((e) => Map<String, String>.from(e)),
        );
      }
    } catch (_) {}
    return [];
  }

  Future<void> clearChatHistory() async {
    try {
      await _chatBox.delete('message_history');
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

      final user = users.cast<Map<String, dynamic>>().firstWhere(
        (u) =>
            u['username'] == input ||
            u['email'] == input,
        orElse: () => <String, dynamic>{},
      );

      if (user.isEmpty) {
        return {'success': false, 'error': 'Invalid username or password'};
      }

      if (user['password'] != _hashPassword(password)) {
        return {'success': false, 'error': 'Invalid username or password'};
      }

      if (user['is_active'] != true) {
        return {'success': false, 'error': 'Account is inactive'};
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

  Future<void> clearCurrentUser() async {
    await _authBox.delete('current_user');
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
      final profilesBox = await Hive.openBox('local_data_box');
      final raw = profilesBox.get('profiles', defaultValue: <String, dynamic>{});
      final profiles = Map<String, dynamic>.from(raw as Map);
      final profileKey = 'current_user';
      final profileData = profiles[profileKey] as Map? ?? <String, dynamic>{};
      final profile = Map<String, dynamic>.from(profileData);
      final attempts = List<Map<String, dynamic>>.from(
        (profile['attempts'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      attempts.add(attempt);
      profile['attempts'] = attempts;
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

  // ── HELPERS ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getUsers() {
    final data = _authBox.get('registered_users', defaultValue: []);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  String _hashPassword(String password) {
    return base64Encode(utf8.encode(password));
  }

  String _generateToken() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = now % 1000000;
    return base64Encode(utf8.encode('verify_$now$random'));
  }
}
