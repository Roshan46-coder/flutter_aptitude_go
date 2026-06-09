import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_database.dart';

class LocalDataProvider {
  static final LocalDataProvider instance = LocalDataProvider._init();
  LocalDataProvider._init();

  late Box _dataBox;
  Map<String, dynamic> _questions = {};

  Future<void> init() async {
    _dataBox = await Hive.openBox('local_data_box');
    await _loadQuestions();
    await _dataBox.put('store_items', _storeItems());
    if (_dataBox.isEmpty) {
      await _seedAllData();
    } else {
      if (_dataBox.get('practice_pdfs', defaultValue: []).isEmpty) {
        await _dataBox.put('practice_pdfs', _practicePdfs());
      }
      // Migration: clear old seeded conversations (id 1 or 2) if they exist
      final inboxData = _dataBox.get('inbox');
      if (inboxData is Map && inboxData['conversations'] is List) {
        final conversations = inboxData['conversations'] as List;
        bool hasSeed = conversations.any((c) => c['conversation_id'] == 1 || c['conversation_id'] == 2);
        if (hasSeed) {
          await _dataBox.put('inbox', {'conversations': []});
          await _dataBox.put('chat_messages', {});
        }
      }
    }
  }

  Future<void> _loadQuestions() async {
    try {
      final cached = _dataBox.get('question_data');
      if (cached is Map) {
        _questions = Map<String, dynamic>.from(cached);
        debugPrint("LocalDataProvider: loaded ${_questions.length} categories from Hive cache");
      }
    } catch (_) {}
    if (_questions.isEmpty) {
      try {
        final jsonStr = await rootBundle.loadString('assets/question_bank.json');
        _questions = Map<String, dynamic>.from(json.decode(jsonStr));
        await _dataBox.put('question_data', _questions);
        debugPrint("LocalDataProvider: loaded ${_questions.length} categories from JSON asset");
      } catch (e) {
        debugPrint("LocalDataProvider: failed to load question bank: $e");
      }
    }
  }

  Future<void> _seedAllData() async {
    await _dataBox.put('practice_categories', _practiceCategories());
    await _dataBox.put('questions', {});
    await _dataBox.put('store_items', _storeItems());
    await _dataBox.put('leaderboard', _leaderboard());
    await _dataBox.put('events', _events());
    await _dataBox.put('inbox', _inbox());
    await _dataBox.put('chat_messages', _chatMessages());
    await _dataBox.put('profiles', _profiles());
    await _dataBox.put('practice_pdfs', _practicePdfs());
    debugPrint("LocalDataProvider: seeded all data");
  }

  // ── ROUTER: map endpoint paths to local data ───────────────────────────────

  dynamic get(String path, {Map<String, dynamic>? queryParameters}) {
    final parts = _normalizePath(path);
    return _routeGet(parts, queryParameters);
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final parts = _normalizePath(path);
    return await _routePost(parts, data);
  }

  List<String> _normalizePath(String path) {
    String p = path.toLowerCase();
    if (p.endsWith('/')) p = p.substring(0, p.length - 1);
    return p.split('/').where((s) => s.isNotEmpty).toList();
  }

  dynamic _routeGet(List<String> parts, Map<String, dynamic>? params) {
    if (parts.isNotEmpty && parts[0] == 'api') parts = parts.sublist(1);
    try {
      if (_matches(parts, ['tests', 'practice'])) {
        return _getPracticeCategories();
      }
      if (_matches(parts, ['tests', 'categories'])) {
        return {'categories': _getCategories()};
      }
      if (_matches(parts, ['tests', 'practice', '*'])) {
        final slug = parts[2];
        return _getQuestionsForCategory(slug);
      }
      if (_matches(parts, ['tests', 'attempt-history'])) {
        return _getAttemptHistory();
      }
      if (_matches(parts, ['tests', 'arena', 'practice'])) {
        return {'pdfs': _dataBox.get('practice_pdfs', defaultValue: [])};
      }
      if (_matches(parts, ['leaderboard'])) {
        return _getLeaderboard();
      }
      if (_matches(parts, ['leaderboard', 'category', '*'])) {
        final catId = int.tryParse(parts[2]) ?? 0;
        return _getCategoryLeaderboard(catId);
      }
      if (_matches(parts, ['events']) || _matches(parts, ['events', 'dashboard'])) {
        final events = _getEventsForDashboard();
        if (_matches(parts, ['events', 'dashboard'])) {
          // Return in Django /api/events/dashboard/ format
          return events;
        }
        return events;
      }
      if (_matches(parts, ['events', '*', 'results']) || _matches(parts, ['events', '*', 'leaderboard'])) {
        final eventId = int.tryParse(parts[1]) ?? 0;
        return _getEventLeaderboard(eventId);
      }
      if (_matches(parts, ['events', '*', 'generate-code'])) {
        return {'success': true, 'access_code': 'EXAM1234'};
      }
      if (_matches(parts, ['events', '*']) && parts.length == 2) {
        final eventId = int.tryParse(parts[1]) ?? 0;
        return _getEventDetail(eventId);
      }
      if (_matches(parts, ['inbox'])) {
        return _getInbox();
      }
      if (_matches(parts, ['chat', '*'])) {
        final convId = int.tryParse(parts[1]) ?? 0;
        return _getChatMessages(convId, otherUser: params?['other_user'] as String?);
      }
      if (_matches(parts, ['gamification', 'store'])) {
        return _getStore();
      }
      if (_matches(parts, ['gamification', 'reward-wheel', 'status'])) {
        return _getSpinStatus();
      }
      if (_matches(parts, ['profile'])) {
        return _getProfile(null);
      }
      if (_matches(parts, ['profile', 'certificates'])) {
        final user = HiveDatabase.instance.getCurrentUser();
        final username = (user?['username'] as String?) ?? '';
        return _listCertificates(username);
      }
      if (_matches(parts, ['profile', 'certificates', '*'])) {
        return _listCertificates(parts[2]);
      }
      if (_matches(parts, ['profile', '*'])) {
        return _getProfile(parts[1]);
      }
      if (_matches(parts, ['profile', 'recruiter', 'data'])) {
        return _getRecruiterProfileData(null);
      }
      if (_matches(parts, ['profile', 'recruiter', 'data', '*'])) {
        return _getRecruiterProfileData(parts[3]);
      }
      if (_matches(parts, ['auth-status'])) {
        return {'authenticated': true, 'message': 'Authenticated locally'};
      }
      if (_matches(parts, ['admin', 'dashboard']) || _matches(parts, ['admin', 'stats'])) {
        return _getAdminDashboard();
      }
      if (_matches(parts, ['recruiter', 'dashboard'])) {
        return _getRecruiterDashboard();
      }
      if (_matches(parts, ['recruiter', 'exam-results', '*'])) {
        final eventId = int.tryParse(parts[2]) ?? 0;
        return _getExamCandidates(eventId);
      }
      if (_matches(parts, ['recruiter', 'search'])) {
        return _searchTalent(params?['q'] as String?, role: params?['role'] as String?);
      }
      if (_matches(parts, ['recruiter', 'top-people'])) {
        return _getTopPeople();
      }
      if (_matches(parts, ['aptix'])) {
        return {'success': true, 'response': 'I am running in offline mode. Ask me anything about aptitude!'};
      }
    } catch (e) {
      debugPrint("LocalDataProvider get error for $parts: $e");
    }
    return null;
  }

  Future<dynamic> _routePost(List<String> parts, dynamic data) async {
    if (parts.isNotEmpty && parts[0] == 'api') parts = parts.sublist(1);
    try {
      if (_matches(parts, ['tests', 'submit'])) {
        return _submitTest(data);
      }
      if (_matches(parts, ['gamification', 'buy', '*'])) {
        final itemId = int.tryParse(parts[2]) ?? 0;
        return _buyItem(itemId, data);
      }
      if (_matches(parts, ['gamification', 'process-spin'])) {
        return _processSpin();
      }
      if (_matches(parts, ['events', 'join'])) {
        // Look up the event by access code – do NOT hardcode event_id!
        final code = (data is Map) ? (data['code'] as String? ?? '').toUpperCase() : '';
        final eventsBoxData = _dataBox.get('events', defaultValue: _events());
        final studentEvents = (eventsBoxData['student_events'] as List?) ?? [];
        for (final e in studentEvents) {
          if (e is Map) {
            final storedCode = (e['access_code'] as String? ?? '').toUpperCase();
            if (storedCode == code) {
              return {
                'success': true,
                'message': 'Joined exam successfully',
                'event_id': e['id'],
                'event_title': e['title'] ?? 'Private Exam',
              };
            }
          }
        }
        return {
          'success': false,
          'error': 'Invalid or expired exam code. Please check the code and try again.',
        };
      }
      if (_matches(parts, ['events', 'create'])) {
        return _createEvent(data);
      }
      if (_matches(parts, ['events', '*', 'register'])) {
        return {'message': 'Registered for event successfully'};
      }
      if (_matches(parts, ['events', '*', 'submit'])) {
        final eventId = int.tryParse(parts[1]) ?? 0;
        return _submitEventTest(eventId, data);
      }
      if (_matches(parts, ['chat', '*', 'send'])) {
        final convId = int.tryParse(parts[1]) ?? 0;
        return _sendMessage(convId, data);
      }
      if (_matches(parts, ['resend-verification'])) {
        return {'success': true, 'message': 'Verification email resent'};
      }
      if (_matches(parts, ['register'])) {
        return {'success': true, 'message': 'Registered successfully'};
      }
      if (_matches(parts, ['login'])) {
        return {'success': true, 'message': 'Logged in', 'user': {}};
      }
      if (_matches(parts, ['logout'])) {
        return {'success': true, 'message': 'Logged out'};
      }
      if (_matches(parts, ['profile', 'edit'])) {
        final updates = Map<String, dynamic>.from(data as Map);
        HiveDatabase.instance.updateCurrentUser(updates);
        final user = HiveDatabase.instance.getCurrentUser();
        final username = (user?['username'] as String?) ?? 'anon';
        final profiles = _dataBox.get('profiles', defaultValue: _profiles());
        final profileKey = username.toLowerCase();
        final live = Map<String, dynamic>.from(profiles[profileKey] ?? profiles['current_user'] ?? {});
        final userLive = Map<String, dynamic>.from(live['user'] ?? {});
        userLive.addAll(updates);
        live['user'] = userLive;
        // Always write to the correct username key
        if (profiles.containsKey('current_user') && profileKey != 'current_user') {
          profiles.remove('current_user');
        }
        profiles[profileKey] = live;
        _dataBox.put('profiles', profiles);
        return {'success': true, 'message': 'Profile updated locally'};
      }
      if (_matches(parts, ['profile', 'delete-account'])) {
        return {'success': true, 'message': 'Account deleted'};
      }
      if (_matches(parts, ['profile', 'recruiter', 'data', 'save'])) {
        return _saveRecruiterProfileData(data);
      }
      if (_matches(parts, ['profile', 'upload-certificate'])) {
        return _addCertificate(data);
      }
      if (_matches(parts, ['profile', 'delete-certificate', '*'])) {
        final certId = int.tryParse(parts[2]) ?? 0;
        return _deleteCertificate(certId);
      }

      if (_matches(parts, ['admin', 'approve-user', '*'])) {
        final userId = int.tryParse(parts[2]) ?? 0;
        final authBox = Hive.box('auth_box');
        final users = List<Map<String, dynamic>>.from(
          (authBox.get('registered_users', defaultValue: []) as List).map((e) => Map<String, dynamic>.from(e as Map))
        );
        final index = users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          users[index]['is_active'] = true;
          await authBox.put('registered_users', users);
        }
        return {'success': true, 'message': 'User approved'};
      }

      if (_matches(parts, ['admin', 'delete-user', '*'])) {
        final userId = int.tryParse(parts[2]) ?? 0;
        final authBox = Hive.box('auth_box');
        final users = List<Map<String, dynamic>>.from(
          (authBox.get('registered_users', defaultValue: []) as List).map((e) => Map<String, dynamic>.from(e as Map))
        );
        users.removeWhere((u) => u['id'] == userId);
        await authBox.put('registered_users', users);
        return {'success': true, 'message': 'User deleted'};
      }

      if (_matches(parts, ['admin', 'toggle-malpractice'])) {
        final current = _dataBox.get('anti_malpractice_enabled', defaultValue: false);
        final next = !current;
        await _dataBox.put('anti_malpractice_enabled', next);
        return {'success': true, 'message': 'Anti-malpractice toggled', 'anti_malpractice_enabled': next};
      }

      if (_matches(parts, ['admin', 'add-question'])) {
        final text = (data is Map) ? (data['text'] ?? '') : '';
        final optionsList = (data is Map) ? (data['options'] as List? ?? []) : [];
        final correctIdx = (data is Map) ? (data['correct_index'] ?? 0) : 0;
        final difficulty = (data is Map) ? (data['difficulty'] ?? 'Medium') : 'Medium';
        final categoryId = (data is Map) ? (data['category_id'] ?? 1) : 1;
        
        final categorySlug = _categories.firstWhere((c) => c['id'] == categoryId, orElse: () => _categories[0])['slug'] as String;
        
        final qData = Map<String, dynamic>.from(_dataBox.get('question_data', defaultValue: {}));
        final catQuestions = List<dynamic>.from(qData[categorySlug] ?? []);
        
        final newId = DateTime.now().millisecondsSinceEpoch;
        final formattedOptions = optionsList.asMap().entries.map((e) => {
          'id': e.key,
          'text': e.value.toString(),
        }).toList();
        
        final newQ = {
          'id': newId,
          'text': text,
          'options': formattedOptions,
          'correct_index': correctIdx,
          'difficulty': difficulty,
          'category_name': _categories.firstWhere((c) => c['id'] == categoryId, orElse: () => _categories[0])['name'] as String,
        };
        
        catQuestions.add(newQ);
        qData[categorySlug] = catQuestions;
        await _dataBox.put('question_data', qData);
        
        return {'success': true, 'message': 'Question added'};
      }

      if (_matches(parts, ['admin', 'delete-question', '*'])) {
        final qId = int.tryParse(parts[2]) ?? 0;
        final qData = Map<String, dynamic>.from(_dataBox.get('question_data', defaultValue: {}));
        
        bool deleted = false;
        qData.forEach((key, val) {
          if (val is List) {
            final list = List<dynamic>.from(val);
            final index = list.indexWhere((q) => (q is Map && q['id'] == qId));
            if (index != -1) {
              list.removeAt(index);
              qData[key] = list;
              deleted = true;
            }
          }
        });
        
        if (deleted) {
          await _dataBox.put('question_data', qData);
        }
        return {'success': true, 'message': 'Question deleted'};
      }

      if (_matches(parts, ['admin', 'create-event']) || _matches(parts, ['events', 'create'])) {
        return _createEvent(data);
      }

      if (_matches(parts, ['admin', 'delete-event', '*'])) {
        final eventId = int.tryParse(parts[2]) ?? 0;
        final eventsBoxData = _dataBox.get('events', defaultValue: _events());
        final studentEvents = List<dynamic>.from(eventsBoxData['student_events'] ?? []);
        
        studentEvents.removeWhere((e) => e is Map && e['id'] == eventId);
        eventsBoxData['student_events'] = studentEvents;
        await _dataBox.put('events', eventsBoxData);
        
        return {'success': true, 'message': 'Event deleted'};
      }

      if (_matches(parts, ['recruiter', 'message'])) {
        final toUser = (data is Map) ? (data['to'] ?? '') : '';
        final msgContent = (data is Map) ? (data['message'] ?? '') : '';
        if (toUser.isNotEmpty && msgContent.isNotEmpty) {
          final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
          final sender = currentUser['username'] ?? 'recruiter';

          // Find if there is an existing conversation with toUser in the inbox
          final inbox = Map<String, dynamic>.from(_dataBox.get('inbox', defaultValue: _inbox()));
          final conversations = List<Map<String, dynamic>>.from(
            (inbox['conversations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
          );

          int foundId = -1;
          for (final conv in conversations) {
            final participants = List<String>.from(conv['participants'] ?? []);
            if (participants.contains(sender) && participants.contains(toUser)) {
              foundId = conv['conversation_id'] as int;
              break;
            }
          }

          if (foundId == -1) {
            foundId = DateTime.now().millisecondsSinceEpoch;
          }

          _addMessageToConversation(
            conversationId: foundId,
            sender: sender,
            recipient: toUser,
            content: msgContent,
          );
        }
        return {'success': true, 'message': 'Message sent'};
      }
      if (_matches(parts, ['aptix'])) {
        final msg = (data is Map) ? (data['message'] ?? '') : '';
        return {'success': true, 'response': getAptixResponse(msg)};
      }
    } catch (e) {
      debugPrint("LocalDataProvider post error for $parts: $e");
    }
    return null;
  }

  bool _matches(List<String> parts, List<String> pattern) {
    if (parts.length != pattern.length) return false;
    for (int i = 0; i < parts.length; i++) {
      if (pattern[i] != '*' && parts[i] != pattern[i]) return false;
    }
    return true;
  }

  // ── DATA GENERATORS ────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> _categories = [
    {'id': 1, 'slug': 'quantitative-aptitude', 'name': 'Quantitative Aptitude'},
    {'id': 2, 'slug': 'logical-reasoning', 'name': 'Logical Reasoning'},
    {'id': 3, 'slug': 'verbal-ability', 'name': 'Verbal Ability'},
    {'id': 4, 'slug': 'computer-fundamentals', 'name': 'Computer Fundamentals'},
    {'id': 5, 'slug': 'programming-logic', 'name': 'Programming Logic'},
    {'id': 6, 'slug': 'general-aptitude', 'name': 'General Aptitude'},
  ];

  static const List<Map<String, dynamic>> _companyCategories = [
    {'slug': 'accenture', 'name': 'Accenture'},
    {'slug': 'cognizant', 'name': 'Cognizant'},
    {'slug': 'tcs', 'name': 'TCS'},
    {'slug': 'tcs-ninja', 'name': 'TCS - NINJA'},
    {'slug': 'wipro-elite-nlth', 'name': 'Wipro Elite NLTH'},
    {'slug': 'tata-elxsi', 'name': 'TATA ELXSI'},
  ];

  Map<String, dynamic> _practiceCategories() {
    final general = _categories.map((c) {
      final slug = c['slug'] as String;
      final qs = _questions[slug] as List<dynamic>?;
      return {
        'slug': slug,
        'name': c['name'],
        'q_count': qs?.length ?? 0,
      };
    }).toList();
    final company = _companyCategories.map((c) {
      final slug = c['slug'] as String;
      final qs = _questions[slug] as List<dynamic>?;
      return {
        'slug': slug,
        'name': c['name'],
        'q_count': qs?.length ?? 0,
      };
    }).toList();
    return {
      'general_categories': general,
      'company_categories': company,
    };
  }

  List<Map<String, dynamic>> _getCategories() {
    return _categories.map((c) => {'id': c['id'], 'name': c['name']}).toList();
  }

  Map<String, dynamic> _getPracticeCategories() {
    return _practiceCategories();
  }

  Map<String, dynamic> _getQuestionsForCategory(String slug) {
    final all = _questions;
    final raw = all[slug] as List<dynamic>? ?? [];
    final questions = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final seen = <int>{};
    questions.retainWhere((q) => seen.add(q['id'] as int));
    final name = _categories.firstWhere(
      (c) => c['slug'] == slug,
      orElse: () => _companyCategories.firstWhere(
        (c) => c['slug'] == slug,
        orElse: () => {'name': slug},
      ),
    )['name'] as String;
    return {
      'category': {'name': name},
      'questions': questions,
    };
  }

  Map<String, dynamic> _submitTest(dynamic data) {
    if (data is! Map) {
      return {'score': '0.00', 'correct': 0, 'total': 0, 'message': 'Invalid submission'};
    }

    final answers = data['answers'] as Map<dynamic, dynamic>? ?? {};
    final slug = data['category_slug'] as String? ?? '';
    final questionIds = data['question_ids'] as List<dynamic>?;

    List<Map<String, dynamic>> questions;
    if (questionIds != null && questionIds.isNotEmpty) {
      final idSet = questionIds.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toSet();
      final raw = _questions[slug] as List<dynamic>? ?? [];
      questions = raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((q) => idSet.contains(q['id'] as int))
          .toList();
    } else {
      final raw = _questions[slug] as List<dynamic>? ?? [];
      questions = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    int correct = 0;
    final total = questions.length;

    for (final q in questions) {
      final qId = q['id'] as int;
      if (q['is_coding'] == true) continue;
      final correctIdx = q['correct_index'] as int? ?? -1;
      final options = q['options'] as List<dynamic>? ?? [];
      int correctOptionId = -1;
      if (correctIdx >= 0 && correctIdx < options.length) {
        correctOptionId = (options[correctIdx] as Map<String, dynamic>)['id'] as int;
      }
      final userAnswer = answers[qId.toString()] ?? answers[qId];
      if (userAnswer != null && userAnswer == correctOptionId) {
        correct++;
      }
    }

    final coinsEarned = correct * 10;
    final expEarned = correct * 20;
    final score = total > 0 ? (correct / total) : 0.0;

    final userData = HiveDatabase.instance.getCurrentUser();
    int currentExp = 0;
    int currentLevel = 1;
    int currentCoins = 0;
    int currentLives = 5;
    if (userData != null) {
      currentExp = (userData['exp'] as num?)?.toInt() ?? 0;
      currentLevel = (userData['level'] as num?)?.toInt() ?? 1;
      currentCoins = (userData['coins'] as num?)?.toInt() ?? 0;
      currentLives = (userData['lives'] as num?)?.toInt() ?? 5;
    }

    final newExp = currentExp + expEarned;
    final newLevel = HiveDatabase.levelInfo(newExp)[0];
    final leveledUp = newLevel > currentLevel;
    final newCoins = currentCoins + coinsEarned;
    final newLives = currentLives > 0 ? currentLives - 1 : 0;

    HiveDatabase.instance.updateCurrentUser({
      'coins': newCoins,
      'exp': newExp,
      'level': newLevel,
      'lives': newLives,
    });

    final catName = () {
      final cats = _questions[slug] as List<dynamic>?;
      if (cats != null && cats.isNotEmpty) {
        final first = cats.first as Map<String, dynamic>?;
        if (first != null && first['category_name'] != null) {
          return first['category_name'] as String;
        }
      }
      return slug;
    }();

    final currentUsername = (userData?['username'] as String?) ?? 'anon';
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    // Check both the current username key and the legacy 'current_user' key
    final profile = Map<String, dynamic>.from(profiles[currentUsername] ?? profiles['current_user'] ?? {'attempts': [], 'certificates': []});
    final attempts = List<Map<String, dynamic>>.from(
      (profile['attempts'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
    );
    attempts.add({
      'score': correct,
      'total_questions': total,
      'percentage': total > 0 ? double.parse(((correct / total) * 100).toStringAsFixed(1)) : 0.0,
      'category_name': catName,
      'completed_at': DateTime.now().toIso8601String(),
    });
    profile['attempts'] = attempts;
    profiles[currentUsername] = profile;
    _dataBox.put('profiles', profiles);

    return {
      'success': true,
      'score': score.toStringAsFixed(2),
      'correct': correct,
      'total': total,
      'coins_earned': coinsEarned,
      'exp_earned': expEarned,
      'leveled_up': leveledUp,
      'new_level': newLevel,
      'lives_remaining': newLives,
      'category': slug,
      'message': 'Test submitted successfully',
    };
  }

  List<Map<String, dynamic>> _storeItems() {
    return [
      {'id': 1, 'name': 'Life Refill', 'item_type': 'LIFE', 'cost': 100, 'is_purchased': false, 'is_equipped': false, 'min_level_required': 1, 'image_url': null, 'description': 'Instantly restores your heart lives back to 5 so you can practice tests.'},
      {'id': 2, 'name': 'Golden Frame', 'item_type': 'FRAME', 'cost': 500, 'is_purchased': false, 'is_equipped': false, 'min_level_required': 1, 'image_url': null, 'description': 'Apply a shining golden border around your profile avatar.'},
      {'id': 3, 'name': 'Pro Avatar', 'item_type': 'AVATAR', 'cost': 1000, 'is_purchased': false, 'is_equipped': false, 'min_level_required': 1, 'image_url': null, 'description': 'Unlock a premium purple-shadowed avatar for your profile.'},
    ];
  }

  Map<String, dynamic> _getStore() {
    final items = _dataBox.get('store_items', defaultValue: _storeItems());
    final userData = HiveDatabase.instance.getCurrentUser();
    final coins = userData != null ? ((userData['coins'] as num?)?.toInt() ?? 0) : 0;
    return {
      'items': (items as List).map((e) => Map<String, dynamic>.from(e)).toList(),
      'coins': coins,
    };
  }

  Map<String, dynamic> _buyItem(int itemId, dynamic data) {
    final userData = HiveDatabase.instance.getCurrentUser();
    if (userData == null) {
      return {'success': false, 'error': 'User not authenticated'};
    }

    int userCoins = (userData['coins'] as num?)?.toInt() ?? 0;
    int userLives = (userData['lives'] as num?)?.toInt() ?? 5;

    final items = _dataBox.get('store_items', defaultValue: _storeItems());
    Map<String, dynamic>? targetItem;
    
    for (final it in items) {
      if (it['id'] == itemId) {
        targetItem = Map<String, dynamic>.from(it);
        break;
      }
    }

    if (targetItem == null) {
      return {'success': false, 'error': 'Item not found'};
    }

    final cost = targetItem['cost'] as int;
    final name = targetItem['name'] as String;
    final isPurchased = targetItem['is_purchased'] as bool;

    if (isPurchased && name != 'Life Refill') {
      // Toggle equip status
      bool newEquip = false;
      final updated = (items as List).map((e) {
        final item = Map<String, dynamic>.from(e);
        if (item['id'] == itemId) {
          item['is_equipped'] = !(item['is_equipped'] ?? false);
          newEquip = item['is_equipped'];
        }
        return item;
      }).toList();
      _dataBox.put('store_items', updated);
      return {
        'success': true,
        'message': newEquip ? 'Item equipped!' : 'Item unequipped!',
        'is_equipped': newEquip
      };
    }

    if (userCoins < cost) {
      return {'success': false, 'error': 'Insufficient coins.'};
    }

    // Deduct coins and apply reward
    userCoins -= cost;
    if (name == 'Life Refill') {
      userLives = 5;
    }

    // Save user state
    HiveDatabase.instance.updateCurrentUser({
      'coins': userCoins,
      'lives': userLives,
    });

    // Update store item purchase state
    final updated = (items as List).map((e) {
      final item = Map<String, dynamic>.from(e);
      if (item['id'] == itemId) {
        if (name != 'Life Refill') {
          item['is_purchased'] = true;
          item['is_equipped'] = true;
        }
      }
      return item;
    }).toList();
    _dataBox.put('store_items', updated);

    return {
      'success': true,
      'message': name == 'Life Refill' ? 'Lives refilled successfully!' : 'Item purchased successfully!',
      'is_equipped': name != 'Life Refill',
      'coins': userCoins,
      'lives': userLives
    };
  }

  Map<String, dynamic> _getSpinStatus() {
    final user = HiveDatabase.instance.getCurrentUser();
    final username = user?['username'] as String?;

    if (username == null || user?['is_company'] == true || user?['is_superuser'] == true) {
      return {'eligible': false, 'last_spin': null};
    }

    final key = 'spin_status_$username';
    final raw = _dataBox.get(key, defaultValue: <String, dynamic>{'last_spin': null});
    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{'last_spin': null};
    final lastSpin = data['last_spin'] as String?;

    if (lastSpin == null || lastSpin.isEmpty) {
      return {'eligible': true, 'last_spin': null};
    }

    final lastDate = DateTime.tryParse(lastSpin);
    if (lastDate == null) {
      return {'eligible': true, 'last_spin': null};
    }

    final eligible = DateTime.now().difference(lastDate).inDays >= 7;
    return {'eligible': eligible, 'last_spin': lastSpin};
  }

  Map<String, dynamic> _processSpin() {
    final rewards = [
      {'index': 0, 'label': '+2 Life'},
      {'index': 1, 'label': '20 Coins'},
      {'index': 2, 'label': '30 Coins'},
      {'index': 3, 'label': '50 Coins'},
      {'index': 4, 'label': 'Golden Frame'},
      {'index': 5, 'label': '+1 Life'},
    ];
    final idx = DateTime.now().millisecondsSinceEpoch % 6;
    final user = HiveDatabase.instance.getCurrentUser();
    final username = user?['username'] as String?;
    if (username != null && username.isNotEmpty) {
      _dataBox.put('spin_status_$username', {'last_spin': DateTime.now().toIso8601String()});
    }
    return {
      'success': true,
      'reward_index': idx,
      'reward_label': rewards[idx]['label'],
    };
  }

  Map<String, dynamic> _getLeaderboard() {
    final board = _dataBox.get('leaderboard', defaultValue: _leaderboard());
    return Map<String, dynamic>.from(board);
  }

  Map<String, dynamic> _leaderboard() {
    final users = ['alice', 'bob', 'charlie', 'diana', 'eve', 'frank', 'grace', 'henry', 'iris', 'jack'];
    final global = <Map<String, dynamic>>[];
    for (int i = 0; i < users.length; i++) {
      global.add({
        'username': users[i],
        'avatar_url': null,
        'level': 10 - i,
        'attempts': (20 - i * 2),
        'avg_score': ((90 - i * 8) / 100).toStringAsFixed(2),
        'score': (1000 - i * 90),
      });
    }
    return {
      'global': global,
      'weekly': global.map((e) => Map<String, dynamic>.from(e)..['score'] = (e['score'] as int) ~/ 10).toList(),
      'categories': _categories.map((c) => {'id': c['id'], 'name': c['name']}).toList(),
    };
  }

  Map<String, dynamic> _getCategoryLeaderboard(int catId) {
    final lb = _getLeaderboard();
    return {
      'board': (lb['global'] as List).take(5).toList(),
    };
  }



  Map<String, dynamic> _events() {
    // No hardcoded mock events. Real events are synced via API or created via _createEvent.
    return {
      'student_events': [],
    };
  }

  Map<String, dynamic> _getEventsForDashboard() {
    // Returns events stored in Hive box. No hardcoded mock events.
    final eventsBoxData = _dataBox.get('events');
    if (eventsBoxData == null) {
      return {'student_events': []};
    }
    final eventsMap = Map<String, dynamic>.from(eventsBoxData);
    final studentEvents = (eventsMap['student_events'] as List?) ?? [];
    return {'student_events': studentEvents};
  }

  Map<String, dynamic> _getEventDetail(int eventId) {
    // Look up from Hive-stored events (only includes API-created or locally-created exams)
    final eventsBoxData = _dataBox.get('events');
    if (eventsBoxData == null) {
      final now = DateTime.now();
      return {
        'event': {
          'id': eventId,
          'title': 'Event #$eventId',
          'description': 'No exams available offline. Connect to the server.',
          'start_time': now.toIso8601String(),
          'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
          'time_limit_seconds': 600,
          'is_live': false,
          'total_questions': 0,
        },
        'registration': {
          'is_registered': false,
          'is_completed': false,
          'score': null,
        },
        'questions': [],
      };
    }

    final eventsMap = Map<String, dynamic>.from(eventsBoxData);
    final studentEvents = (eventsMap['student_events'] as List?) ?? [];

    for (final e in studentEvents) {
      if (e is Map && e['id'] == eventId) {
        final event = Map<String, dynamic>.from(e);
        final rawQuestions = event['questions'] as List? ?? [];

        // Map stored questions to the expected API format
        final mappedQuestions = rawQuestions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          if (q is Map) {
            return <String, dynamic>{
              'id': q['id'] ?? (eventId * 1000 + idx + 1),
              'index': idx,
              'text': q['text'] ?? '',
              'option_a': q['option_a'] ?? '',
              'option_b': q['option_b'] ?? '',
              'option_c': q['option_c'] ?? '',
              'option_d': q['option_d'] ?? '',
              'marks': q['marks'] ?? 1,
            };
          }
          return <String, dynamic>{};
        }).where((q) => q.isNotEmpty).toList();
        final seenEvent = <int>{};
        mappedQuestions.retainWhere((q) => seenEvent.add(q['id'] as int));

        return {
          'event': {
            'id': eventId,
            'title': event['title'] ?? 'Event #$eventId',
            'description': event['description'] ?? '',
            'start_time': event['start_time'] ?? DateTime.now().toIso8601String(),
            'end_time': event['end_time'] ?? DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
            'time_limit_seconds': event['time_limit_seconds'] ?? 600,
            'is_live': event['is_live'] ?? true,
            'total_questions': mappedQuestions.length,
          },
          'registration': {
            'is_registered': true,
            'is_completed': false,
            'score': null,
          },
          'questions': mappedQuestions,
        };
      }
    }

    // Event not found – return empty questions so candidate sees a helpful error
    final now = DateTime.now();
    return {
      'event': {
        'id': eventId,
        'title': 'Event #$eventId',
        'description': 'Exam not found in local storage.',
        'start_time': now.toIso8601String(),
        'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
        'time_limit_seconds': 600,
        'is_live': false,
        'total_questions': 0,
      },
      'registration': {
        'is_registered': false,
        'is_completed': false,
        'score': null,
      },
      'questions': [],
    };
  }

  Map<String, dynamic> _getEventLeaderboard(int eventId) {
    return {
      'event_title': 'Event #$eventId',
      'leaderboard': [
        {'username': 'alice', 'score': 95},
        {'username': 'bob', 'score': 88},
        {'username': 'charlie', 'score': 82},
        {'username': 'diana', 'score': 76},
        {'username': 'eve', 'score': 71},
      ],
    };
  }

  Map<String, dynamic> _getInbox() {
    final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
    final currentUsername = currentUser['username'] ?? '';
    
    final inbox = Map<String, dynamic>.from(_dataBox.get('inbox', defaultValue: _inbox()));
    final conversations = List<Map<String, dynamic>>.from(
      (inbox['conversations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    // Filter conversations to only those involving currentUsername
    final userConversations = conversations.where((conv) {
      final participants = List<String>.from(conv['participants'] ?? []);
      return participants.contains(currentUsername);
    }).map((conv) {
      final newConv = Map<String, dynamic>.from(conv);
      final participants = List<String>.from(conv['participants'] ?? []);
      
      // Determine other user
      String otherUsername = '';
      if (participants.length == 2) {
        otherUsername = participants.firstWhere((p) => p != currentUsername, orElse: () => '');
      } else if (participants.isNotEmpty) {
        otherUsername = participants.firstWhere((p) => p != currentUsername, orElse: () => participants.first);
      }
      
      newConv['other_user'] = {
        'username': otherUsername,
        'avatar_url': null,
      };
      
      return newConv;
    }).toList();

    return {'conversations': userConversations};
  }

  Map<String, dynamic> _inbox() {
    return {'conversations': []};
  }

  Map<String, dynamic> _getChatMessages(int convId, {String? otherUser}) {
    final chatMessages = Map<String, dynamic>.from(_dataBox.get('chat_messages', defaultValue: _chatMessages()));
    
    // Check if there is an existing conversation with otherUser in the inbox
    if (otherUser != null && otherUser.isNotEmpty) {
      final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
      final currentUsername = currentUser['username'] ?? '';
      
      final inbox = Map<String, dynamic>.from(_dataBox.get('inbox', defaultValue: _inbox()));
      final conversations = List<Map<String, dynamic>>.from(
        (inbox['conversations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
      );
      
      for (final conv in conversations) {
        final participants = List<String>.from(conv['participants'] ?? []);
        if (participants.contains(currentUsername) && participants.contains(otherUser)) {
          final existingConvId = conv['conversation_id'] as int;
          final convKey = existingConvId.toString();
          if (chatMessages.containsKey(convKey)) {
            return Map<String, dynamic>.from(chatMessages[convKey]);
          }
        }
      }
    }

    final convKey = convId.toString();
    return Map<String, dynamic>.from(chatMessages[convKey] ?? {
      'messages': [],
      'participants': otherUser != null ? [otherUser] : []
    });
  }

  Map<String, dynamic> _chatMessages() {
    return {};
  }

  Map<String, dynamic> _addMessageToConversation({
    required int conversationId,
    required String sender,
    required String recipient,
    required String content,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    
    // 1. Update inbox conversations list
    final inbox = Map<String, dynamic>.from(_dataBox.get('inbox', defaultValue: _inbox()));
    final conversations = List<Map<String, dynamic>>.from(
      (inbox['conversations'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    int foundIndex = -1;
    for (int i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      final participants = List<String>.from(conv['participants'] ?? []);
      // Match by exact conversation ID first
      if (conv['conversation_id'] == conversationId) {
        foundIndex = i;
        break;
      }
      // If we don't have the same conversation ID, check if participants match
      if (participants.contains(sender) && participants.contains(recipient)) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex == -1) {
      conversations.add({
        'conversation_id': conversationId,
        'participants': [sender, recipient],
        'last_message': {
          'content': content,
          'timestamp': timestamp,
          'sender': sender,
        },
      });
    } else {
      // Use the existing conversation ID if we matched on participants but ID was different
      final matchedId = conversations[foundIndex]['conversation_id'] as int;
      conversations[foundIndex]['last_message'] = {
        'content': content,
        'timestamp': timestamp,
        'sender': sender,
      };
      // Keep using the matchedId for chatMessages key update
      conversationId = matchedId;
    }

    inbox['conversations'] = conversations;
    _dataBox.put('inbox', inbox);

    // 2. Update chat messages
    final chatMessages = Map<String, dynamic>.from(_dataBox.get('chat_messages', defaultValue: _chatMessages()));
    final convKey = conversationId.toString();
    final convMessages = Map<String, dynamic>.from(chatMessages[convKey] ?? {'messages': [], 'participants': [sender, recipient]});
    
    final msgsList = List<Map<String, dynamic>>.from(
      (convMessages['messages'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final newMsg = {
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
    };
    msgsList.add(newMsg);

    convMessages['messages'] = msgsList;
    convMessages['participants'] = [sender, recipient];
    chatMessages[convKey] = convMessages;
    _dataBox.put('chat_messages', chatMessages);

    return newMsg;
  }

  Map<String, dynamic> _sendMessage(int convId, dynamic data) {
    final content = (data is Map) ? (data['content'] ?? data['message'] ?? '') : '';
    final otherUser = (data is Map) ? (data['other_user'] ?? '') : '';
    final sender = HiveDatabase.instance.getCurrentUser()?['username'] ?? 'user';
    
    final newMsg = _addMessageToConversation(
      conversationId: convId,
      sender: sender,
      recipient: otherUser,
      content: content,
    );
    
    return {'success': true, 'message': newMsg};
  }

  Map<String, dynamic> _addCertificate(dynamic data) {
    final title = (data is Map) ? (data['title'] ?? 'Certificate') : 'Certificate';
    final filename = (data is Map) ? (data['filename'] ?? '') : '';
    final localPath = (data is Map) ? (data['local_path'] ?? '') : '';
    final username = (data is Map && (data['username'] ?? '') != '')
        ? (data['username'] as String)
        : (HiveDatabase.instance.getCurrentUser()?['username'] as String? ?? '');
    final isImage = filename.toLowerCase().endsWith('.jpg') ||
        filename.toLowerCase().endsWith('.jpeg') ||
        filename.toLowerCase().endsWith('.png');
    final certs = List<Map<String, dynamic>>.from(
      (_dataBox.get('user_certificates', defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    final newId = certs.isEmpty ? 1 : ((certs.last['id'] as int? ?? 0) + 1);
    certs.add({
      'id': newId,
      'title': title,
      'filename': filename,
      'local_path': localPath,
      'is_image': isImage,
      'username': username.toLowerCase(),
      'uploaded_at': DateTime.now().toIso8601String(),
    });
    _dataBox.put('user_certificates', certs);
    return {'success': true, 'message': 'Certificate uploaded locally', 'id': newId};
  }

  Map<String, dynamic> _deleteCertificate(int certId) {
    final user = HiveDatabase.instance.getCurrentUser();
    final currentUsername = (user?['username'] as String?)?.toLowerCase() ?? '';
    final certs = List<Map<String, dynamic>>.from(
      (_dataBox.get('user_certificates', defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    certs.removeWhere((c) => c['id'] == certId && (c['username'] as String?)?.toLowerCase() == currentUsername);
    _dataBox.put('user_certificates', certs);
    return {'success': true, 'message': 'Certificate deleted'};
  }

  List<Map<String, dynamic>> _getAllCertificates() {
    final raw = _dataBox.get('user_certificates', defaultValue: []) as List;
    return raw.map((e) {
      final c = Map<String, dynamic>.from(e);
      final fileName = c['filename'] as String? ?? '';
      final fileType = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : '';
      return {
        'id': c['id'],
        'title': c['title'],
        'file_url': c['local_path'] ?? c['filename'] ?? '',
        'file_type': fileType,
        'file_size': 0,
        'uploaded_at': c['uploaded_at'] ?? '',
        'is_image': c['is_image'] == true,
      };
    }).toList();
  }

  Map<String, dynamic> _listCertificates(String username) {
    final all = _getAllCertificates();
    if (username.isNotEmpty) {
      final filtered = all.where((c) =>
        (c['username'] as String? ?? '').toLowerCase() == username.toLowerCase()
      ).toList();
      return {'certificates': filtered};
    }
    return {'certificates': all};
  }

  Map<String, dynamic> _getAttemptHistory() {
    final user = HiveDatabase.instance.getCurrentUser();
    final currentUsername = (user?['username'] as String?) ?? 'anon';
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    // Check both the current username key and the legacy 'current_user' key
    final profile = profiles[currentUsername] ?? profiles['current_user'] ?? {'attempts': []};
    final allAttempts = (profile['attempts'] as List?) ?? [];
    final realAttempts = allAttempts.where((a) {
      final m = a as Map?;
      return m != null && m.containsKey('total_questions');
    }).toList();
    return {'attempts': realAttempts};
  }

  Map<String, dynamic> _getProfile(String? username) {
    // 1. Determine target username
    String targetUsername = '';
    if (username == null) {
      final curUser = HiveDatabase.instance.getCurrentUser();
      if (curUser != null) {
        targetUsername = curUser['username'] ?? '';
      }
    } else {
      targetUsername = username;
    }

    // 2. Look up in registered users
    final users = HiveDatabase.instance.getUsers();
    Map<String, dynamic>? matchUser;
    for (final u in users) {
      if (u['username']?.toString().toLowerCase() == targetUsername.toLowerCase()) {
        matchUser = Map<String, dynamic>.from(u);
        break;
      }
    }

    // If not found in registered users, fall back to current session or default
    if (matchUser == null) {
      final curUser = HiveDatabase.instance.getCurrentUser();
      if (curUser != null && (username == null || curUser['username']?.toString().toLowerCase() == username.toLowerCase())) {
        matchUser = Map<String, dynamic>.from(curUser);
      } else {
        // Mock fallback if user doesn't exist
        matchUser = {
          'username': targetUsername.isNotEmpty ? targetUsername : 'unknown',
          'email': '',
          'first_name': targetUsername.isNotEmpty ? targetUsername : 'Unknown',
          'last_name': '',
          'is_company': false,
          'organization': '',
          'level': 1,
          'exp': 0,
          'coins': 0,
          'lives': 5,
        };
      }
    }

    // Ensure we don't return the password
    matchUser.remove('password');

    // 3. Load user's profile details from Hive box keyed by actual username
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    final profileKey = targetUsername.toLowerCase();
        
    // Check both the current username key and the legacy 'current_user' key
    final userProfile = Map<String, dynamic>.from(profiles[profileKey] ?? profiles['current_user'] ?? {
      'attempts': [],
      'category_stats': [],
      'certificates': [],
    });

    final realAttempts = (userProfile['attempts'] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .where((a) => a.containsKey('total_questions'))
        .toList() ?? [];

    // Compute category_stats dynamically from real attempts
    final catMap = <String, List<int>>{};
    for (final a in realAttempts) {
      final catName = (a['category_name'] as String?) ?? 'General';
      final score = (a['score'] as num?)?.toInt() ?? 0;
      catMap.putIfAbsent(catName, () => []).add(score);
    }
    final categoryStats = catMap.entries.map((e) {
      final scores = e.value;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return {
        'category_name': e.key,
        'avg_score': double.parse(avg.toStringAsFixed(1)),
      };
    }).toList();

    // Merge seed certificates with user-uploaded ones from Hive box
    List<Map<String, dynamic>> mergedCerts = [];
    final seedCerts = (userProfile['certificates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final boxCerts = (_dataBox.get('user_certificates', defaultValue: []) as List)
        .map((e) {
          final c = Map<String, dynamic>.from(e);
          final fileName = c['filename'] as String? ?? '';
          final fileType = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : '';
          return {
            'id': c['id'],
            'title': c['title'],
            'file_url': c['local_path'] ?? c['filename'] ?? '',
            'file_type': fileType,
            'file_size': 0,
            'uploaded_at': c['uploaded_at'] ?? '',
            'is_image': c['is_image'] == true,
            'username': c['username'] ?? '',
          };
        })
        .where((c) => (c['username'] as String).toLowerCase() == targetUsername.toLowerCase())
        .toList();
    mergedCerts = [...seedCerts, ...boxCerts];

    return {
      'user': matchUser,
      'attempts': realAttempts,
      'category_stats': categoryStats,
      'certificates': mergedCerts,
    };
  }

  Map<String, dynamic> _profiles() {
    return {};
  }

  Map<String, dynamic> _adminCategory(Map<String, dynamic> c) {
    final slug = c['slug'] as String;
    final rawQs = _questions[slug] as List<dynamic>? ?? [];
    final qs = rawQs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return {
      'id': c['id'],
      'name': c['name'],
      'question_count': qs.length,
      'questions': qs.map((q) => {
        'id': q['id'],
        'text': q['text'],
        'difficulty': ['Easy', 'Medium', 'Hard'][q['id'] % 3],
      }).toList(),
    };
  }

  List<double> _getUserGrowthData(List<dynamic> users) {
    final counts = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    int total = users.length;
    for (int i = 0; i < 7; i++) {
      counts[i] = (total * (i + 1) / 7).roundToDouble();
    }
    return counts;
  }

  List<double> _getExamActivityData(Map<dynamic, dynamic> profiles) {
    int count = 0;
    profiles.forEach((key, val) {
      if (val is Map && val['attempts'] is List) {
        count += (val['attempts'] as List).length;
      }
    });
    final counts = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    for (int i = 0; i < 7; i++) {
      counts[i] = (count * (i + 1) / 7).roundToDouble();
    }
    return counts;
  }

  List<double> _getRecruiterActivityData(List<dynamic> users) {
    final recruiters = users.where((u) => u['is_company'] == true).length;
    final counts = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    for (int i = 0; i < 7; i++) {
      counts[i] = (recruiters * (i + 1) / 7).roundToDouble();
    }
    return counts;
  }

  List<double> _getQuestionGrowthData(Map<dynamic, dynamic>? qData) {
    int count = 0;
    if (qData is Map) {
      qData.forEach((key, val) {
        if (val is List) count += val.length;
      });
    }
    final counts = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    for (int i = 0; i < 7; i++) {
      counts[i] = (count * (i + 1) / 7).roundToDouble();
    }
    return counts;
  }

  Map<String, dynamic> _getAdminDashboard() {
    final users = HiveDatabase.instance.getUsers();
    final candidatesCount = users.where((u) => u['is_company'] != true).length;
    final recruitersCount = users.where((u) => u['is_company'] == true).length;

    int questionsCount = 0;
    final qData = _dataBox.get('question_data');
    if (qData is Map) {
      qData.forEach((key, val) {
        if (val is List) questionsCount += val.length;
      });
    }

    int attemptsCount = 0;
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    if (profiles is Map) {
      profiles.forEach((key, val) {
        if (val is Map && val['attempts'] is List) {
          attemptsCount += (val['attempts'] as List).length;
        }
      });
    }

    int certsCount = 0;
    if (profiles is Map) {
      profiles.forEach((key, val) {
        if (val is Map && val['certificates'] is List) {
          certsCount += (val['certificates'] as List).length;
        }
      });
    }
    final userCerts = _dataBox.get('user_certificates', defaultValue: []);
    if (userCerts is List) {
      certsCount += userCerts.length;
    }

    final eventsBoxData = _dataBox.get('events', defaultValue: _events());
    final studentEvents = eventsBoxData['student_events'] as List? ?? [];

    final dynamicCategories = _categories.map((c) {
      final slug = c['slug'] as String;
      final rawQs = qData is Map ? (qData[slug] as List? ?? []) : [];
      return {
        'id': c['id'],
        'name': c['name'],
        'question_count': rawQs.length,
        'questions': rawQs.map((q) => {
          'id': q['id'],
          'text': q['text'],
          'difficulty': q['difficulty'] ?? 'Medium',
        }).toList(),
      };
    }).toList();

    final allAttempts = <Map<String, dynamic>>[];
    if (profiles is Map) {
      profiles.forEach((username, profile) {
        if (profile is Map && profile['attempts'] is List) {
          for (final att in profile['attempts']) {
            if (att is Map) {
              allAttempts.add({
                'username': username == 'current_user' ? (HiveDatabase.instance.getCurrentUser()?['username'] ?? 'candidate') : username,
                'category_name': att['category_name'] ?? 'General',
                'score': att['score'] ?? 0,
                'total_questions': att['total_questions'] ?? 10,
                'percentage': att['percentage'] ?? 0.0,
                'completed_at': att['completed_at'] ?? '',
                'has_certificate': (att['percentage'] ?? 0.0) >= 70.0,
              });
            }
          }
        }
      });
    }

    final allCertificates = <Map<String, dynamic>>[];
    for (final att in allAttempts) {
      if (att['has_certificate'] == true) {
        allCertificates.add({
          'username': att['username'],
          'exam_name': att['category_name'],
          'score': '${att['score']}/${att['total_questions']}',
          'date': att['completed_at'],
          'verified': true,
        });
      }
    }
    if (userCerts is List) {
      for (final c in userCerts) {
        if (c is Map) {
          allCertificates.add({
            'username': 'current_user',
            'exam_name': c['title'] ?? 'Certificate',
            'score': 'N/A',
            'date': c['uploaded_at'] ?? '',
            'verified': false,
          });
        }
      }
    }

    return {
      'anti_malpractice_enabled': _dataBox.get('anti_malpractice_enabled', defaultValue: false),
      'stats': {
        'total_users': users.length,
        'total_candidates': candidatesCount,
        'total_recruiters': recruitersCount,
        'total_questions': questionsCount,
        'total_attempts': attemptsCount,
        'total_certificates': certsCount,
        'active_events': studentEvents.where((e) => e is Map && e['is_live'] == true).length,
      },
      'pending_approvals': users.where((u) => u['is_company'] == true && u['is_active'] != true).map((u) => {
        'id': u['id'], 'username': u['username'], 'email': u['email']
      }).toList(),
      'users': users.map((u) => {
        'id': u['id'],
        'username': u['username'],
        'email': u['email'],
        'is_company': u['is_company'] ?? false,
        'is_staff': u['is_staff'] ?? false,
        'is_superuser': u['is_superuser'] ?? false,
        'is_active': u['is_active'] ?? false,
        'date_joined': u['date_joined'] ?? DateTime.now().toIso8601String(),
        'interested_field': u['interested_field'] ?? '',
        'current_status': u['current_status'] ?? '',
        'level': u['level'] ?? 1,
        'coins': u['coins'] ?? 0,
      }).toList(),
      'categories': dynamicCategories,
      'events': studentEvents,
      'attempts': allAttempts,
      'certificates': allCertificates,
      'analytics': {
        'user_growth': _getUserGrowthData(users),
        'exam_activity': _getExamActivityData(profiles),
        'recruiter_activity': _getRecruiterActivityData(users),
        'question_growth': _getQuestionGrowthData(qData),
      }
    };
  }

  Future<Map<String, dynamic>> _createEvent(dynamic data) async {
    final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
    final username = currentUser['username'] as String? ?? 'admin';
    final title = (data is Map) ? (data['title'] ?? 'Private Exam') : 'Private Exam';
    final desc = (data is Map) ? (data['description'] ?? '') : '';
    final startTime = (data is Map) ? (data['start_time'] ?? DateTime.now().toIso8601String()) : DateTime.now().toIso8601String();
    final endTime = (data is Map) ? (data['end_time'] ?? DateTime.now().add(const Duration(hours: 2)).toIso8601String()) : DateTime.now().add(const Duration(hours: 2)).toIso8601String();
    final duration = (data is Map) ? (data['time_limit_seconds'] ?? 600) : 600;
    final rawQuestions = (data is Map) ? (data['questions'] as List? ?? []) : [];
    final thresholdType = (data is Map) ? (data['threshold_type'] ?? 'TIME') : 'TIME';
    final thresholdValue = (data is Map) ? (data['threshold_value'] ?? 0) : 0;

    final eventsBoxData = Map<String, dynamic>.from(_dataBox.get('events', defaultValue: _events()));
    final studentEvents = List<Map<String, dynamic>>.from(
      (eventsBoxData['student_events'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final newId = studentEvents.isEmpty ? 1 : (studentEvents.map((e) => e['id'] as int).reduce((a, b) => a > b ? a : b) + 1);
    final accessCode = 'EXAM${1000 + newId}';

    // Assign a unique numeric ID and positional index to every question
    final questions = rawQuestions.asMap().entries.map((entry) {
      final idx = entry.key;
      final q = Map<String, dynamic>.from(entry.value is Map ? entry.value as Map : {});
      q['id'] = q['id'] ?? (newId * 1000 + idx + 1); // stable unique ID
      q['index'] = idx;
      return q;
    }).toList();
    final seenCreate = <int>{};
    questions.retainWhere((q) => seenCreate.add(q['id'] as int));

    final categoryName = () {
      final catId = (data is Map) ? data['category_id'] : null;
      if (catId != null) {
        for (final c in _categories) {
          if (c['id'] == catId) return c['name'] as String;
        }
      }
      return 'General';
    }();

    final newEvent = <String, dynamic>{
      'id': newId,
      'title': title,
      'description': desc,
      'category': categoryName,
      'start_time': startTime,
      'end_time': endTime,
      'total_questions': questions.length,
      'time_limit_seconds': duration,
      'threshold_type': thresholdType,
      'threshold_value': thresholdValue,
      'is_registered': false,
      'is_completed': false,
      'status': 'UPCOMING',
      'is_live': true,
      'participant_count': 0,
      'questions': questions,
      'access_code': accessCode,
      'created_by': username,
    };

    studentEvents.add(newEvent);
    eventsBoxData['student_events'] = studentEvents;
    await _dataBox.put('events', eventsBoxData);

    return {
      'success': true,
      'message': 'Event created successfully',
      'event_id': newId,
      'access_code': accessCode,
    };
  }

  Map<String, dynamic> _submitEventTest(int eventId, dynamic data) {
    final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
    final username = currentUser['username'] as String? ?? 'unknown';
    final firstName = currentUser['first_name'] as String? ?? '';
    final lastName = currentUser['last_name'] as String? ?? '';
    final email = currentUser['email'] as String? ?? '';

    final answers = (data is Map) ? (data['answers'] as Map<dynamic, dynamic>? ?? {}) : {};
    final eventsBoxData = Map<String, dynamic>.from(_dataBox.get('events', defaultValue: _events()));
    final studentEvents = List<Map<String, dynamic>>.from(
      (eventsBoxData['student_events'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final eventIndex = studentEvents.indexWhere((e) => e['id'] == eventId);
    if (eventIndex == -1) {
      return {'success': false, 'message': 'Event not found'};
    }

    final event = studentEvents[eventIndex];
    final questions = event['questions'] as List? ?? [];

    int correct = 0;
    int totalMarks = 0;
    for (final q in questions) {
      if (q is! Map) continue;
      // Use question ID as key (matches what TestInterfaceScreen sends)
      final qId = q['id'];
      final qMarks = (q['marks'] as int?) ?? 1;
      totalMarks += qMarks;
      final correctOption = (q['correct_option'] as String? ?? 'A').toUpperCase();
      // Answers are keyed by question ID (string) and valued as 'A'/'B'/'C'/'D'
      final userAnswer = (answers[qId?.toString()] ?? answers[qId])?.toString().toUpperCase();
      if (userAnswer != null && userAnswer == correctOption) {
        correct += qMarks;
      }
    }

    final total = totalMarks;
    final percentage = total > 0 ? (correct / total) * 100 : 0.0;
    final passed = percentage >= 40.0;
    final now = DateTime.now().toIso8601String();

    final examResults = Map<String, dynamic>.from(_dataBox.get('exam_results', defaultValue: {}));
    final examKey = 'exam_$eventId';
    final participants = List<Map<String, dynamic>>.from(
      (examResults[examKey] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final existingIdx = participants.indexWhere((p) => p['username'] == username);
    final result = <String, dynamic>{
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'score': correct,
      'total_questions': total,
      'percentage': double.parse(percentage.toStringAsFixed(1)),
      'passed': passed,
      'completed_at': now,
    };

    if (existingIdx >= 0) {
      participants[existingIdx] = result;
    } else {
      participants.add(result);
    }

    examResults[examKey] = participants;
    _dataBox.put('exam_results', examResults);

    event['participant_count'] = participants.length;
    studentEvents[eventIndex] = event;
    eventsBoxData['student_events'] = studentEvents;
    _dataBox.put('events', eventsBoxData);

    final coinsEarned = correct * 10;
    final expEarned = correct * 20;
    HiveDatabase.instance.updateCurrentUser({
      'coins': ((currentUser['coins'] as num?)?.toInt() ?? 0) + coinsEarned,
      'exp': ((currentUser['exp'] as num?)?.toInt() ?? 0) + expEarned,
    });

    return {
      'success': true,
      'message': 'Event test submitted successfully',
      'score': correct,
      'total': total,
      'percentage': double.parse(percentage.toStringAsFixed(1)),
      'passed': passed,
      'coins_earned': coinsEarned,
      'exp_earned': expEarned,
    };
  }

  Map<String, dynamic> _getExamCandidates(int eventId) {
    final eventsBoxData = Map<String, dynamic>.from(_dataBox.get('events', defaultValue: _events()));
    final studentEvents = List<Map<String, dynamic>>.from(
      (eventsBoxData['student_events'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final eventIndex = studentEvents.indexWhere((e) => e['id'] == eventId);
    if (eventIndex == -1) {
      return {'success': false, 'candidates': [], 'event': null};
    }

    final event = studentEvents[eventIndex];
    final examKey = 'exam_$eventId';
    final examResults = Map<String, dynamic>.from(_dataBox.get('exam_results', defaultValue: {}));
    final participants = List<Map<String, dynamic>>.from(
      (examResults[examKey] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );

    final users = HiveDatabase.instance.getUsers();
    final enriched = participants.map((p) {
      final user = users.cast<Map<String, dynamic>?>().firstWhere(
        (u) => u?['username'] == p['username'],
        orElse: () => null,
      );
      return <String, dynamic>{
        ...p,
        'avatar_url': user?['avatar_url'],
        'level': user?['level'] ?? 1,
        'has_certificate': ((p['percentage'] as num?)?.toDouble() ?? 0.0) >= 70.0,
      };
    }).toList();

    enriched.sort((a, b) => (b['score'] as num).compareTo(a['score'] as num));
    for (int i = 0; i < enriched.length; i++) {
      enriched[i]['rank'] = i + 1;
    }

    final scores = enriched.map((e) => (e['score'] as num).toDouble()).toList();
    final percentages = enriched.map((e) => (e['percentage'] as num).toDouble()).toList();
    final totalCandidates = enriched.length;
    final passedCount = enriched.where((e) => e['passed'] == true).length;

    return {
      'success': true,
      'event': {
        'id': event['id'],
        'title': event['title'],
        'total_questions': event['total_questions'],
        'time_limit_seconds': event['time_limit_seconds'],
      },
      'candidates': enriched,
      'analytics': {
        'total_candidates': totalCandidates,
        'average_score': totalCandidates > 0
            ? double.parse((scores.reduce((a, b) => a + b) / totalCandidates).toStringAsFixed(1))
            : 0.0,
        'highest_score': scores.isEmpty ? 0.0 : scores.reduce((a, b) => a > b ? a : b),
        'lowest_score': scores.isEmpty ? 0.0 : scores.reduce((a, b) => a < b ? a : b),
        'average_percentage': totalCandidates > 0
            ? double.parse((percentages.reduce((a, b) => a + b) / totalCandidates).toStringAsFixed(1))
            : 0.0,
        'pass_percentage': totalCandidates > 0
            ? double.parse(((passedCount / totalCandidates) * 100).toStringAsFixed(1))
            : 0.0,
        'completion_percentage': totalCandidates > 0 ? 100.0 : 0.0,
      },
    };
  }

  Map<String, dynamic> _getRecruiterDashboard() {
    final currentUser = HiveDatabase.instance.getCurrentUser() ?? {};
    final currentUsername = currentUser['username'] as String? ?? '';

    final users = HiveDatabase.instance.getUsers();
    final candidates = users.where((u) =>
      u['is_company'] != true &&
      u['is_active'] == true
    ).toList();

    final profiles = Map<String, dynamic>.from(
      _dataBox.get('profiles', defaultValue: _profiles()),
    );

    final topTalent = candidates.map((u) {
      final username = u['username'] ?? '';
      final profileKey = username is String ? username.toLowerCase() : '';

      Map<String, dynamic>? userProfile;
      final raw = profiles[profileKey] ?? null;
      if (raw is Map) {
        userProfile = Map<String, dynamic>.from(raw);
      }

      final attempts = (userProfile?['attempts'] as List?) ?? [];
      final totalScore = attempts.fold<num>(0, (s, a) => s + ((a as Map?)?['score'] as num? ?? 0));
      final avgScore = attempts.isNotEmpty ? (totalScore / attempts.length) : 0.0;
      return {
        'username': username,
        'first_name': u['first_name'] ?? '',
        'last_name': u['last_name'] ?? '',
        'avatar_url': u['avatar_url'],
        'avg_score': double.parse(avgScore.toStringAsFixed(1)),
        'certificate_count': (userProfile?['certificates'] as List?)?.length ?? 0,
        'level': u['level'] ?? 1,
      };
    }).toList();

    topTalent.sort((a, b) => (b['avg_score'] as double).compareTo(a['avg_score'] as double));

    final eventsBoxData = Map<String, dynamic>.from(_dataBox.get('events', defaultValue: _events()));
    final allEvents = List<Map<String, dynamic>>.from(
      (eventsBoxData['student_events'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? []
    );
    final myExams = allEvents.where((e) => e['created_by'] == currentUsername).toList();

    final examResults = Map<String, dynamic>.from(_dataBox.get('exam_results', defaultValue: {}));
    int totalAttempts = 0;
    double scoreSum = 0;
    for (final e in myExams) {
      final key = 'exam_${e['id']}';
      final participants = (examResults[key] as List?) ?? [];
      totalAttempts += participants.length;
      for (final p in participants) {
        if (p is Map) {
          scoreSum += (p['score'] as num?)?.toDouble() ?? 0;
        }
      }
    }

    int totalCerts = 0;
    for (final p in candidates) {
      final username = p['username'] ?? '';
      final profileKey = username is String ? username.toLowerCase() : '';
      final raw = profiles[profileKey] ?? null;
      if (raw is Map) {
        final userProfile = Map<String, dynamic>.from(raw);
        totalCerts += (userProfile['certificates'] as List?)?.length ?? 0;
      }
    }

    return {
      'stats': {
        'total_candidates': candidates.length,
        'total_attempts': totalAttempts > 0 ? totalAttempts : candidates.length,
        'avg_score': totalAttempts > 0 ? double.parse((scoreSum / totalAttempts).toStringAsFixed(1)) : 0.0,
        'total_certs': totalCerts,
        'total_exams_created': myExams.length,
      },
      'top_talent': topTalent,
      'exams': myExams.map((e) {
        final key = 'exam_${e['id']}';
        final participants = (examResults[key] as List?) ?? [];
        return {
          'id': e['id'],
          'title': e['title'],
          'total_questions': e['total_questions'],
          'participant_count': participants.length,
          'status': e['status'],
          'access_code': e['access_code'],
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _searchTalent(String? query, {String? role}) {
    final users = HiveDatabase.instance.getUsers();
    var matches = users.where((u) =>
      u['is_company'] != true &&
      u['is_active'] == true
    );

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      matches = matches.where((u) =>
        (u['username'] as String? ?? '').toLowerCase().contains(q) ||
        (u['first_name'] as String? ?? '').toLowerCase().contains(q) ||
        (u['last_name'] as String? ?? '').toLowerCase().contains(q)
      );
    }

    if (role != null && role != 'All') {
      matches = matches.where((u) =>
        (u['interested_field'] as String? ?? '').toLowerCase() == role.toLowerCase()
      );
    }

    // Sort by level descending
    final sorted = matches.toList()
      ..sort((a, b) => ((b['level'] as num?)?.toInt() ?? 0).compareTo((a['level'] as num?)?.toInt() ?? 0));

    final resultList = sorted.take(100).map((u) {
      final username = u['username'] ?? '';
      final profiles = Map<String, dynamic>.from(
        _dataBox.get('profiles', defaultValue: _profiles()),
      );
      final profileKey = username is String ? username.toLowerCase() : '';

      Map<String, dynamic>? userProfile;
      final raw = profiles[profileKey] ?? null;
      if (raw is Map) {
        userProfile = Map<String, dynamic>.from(raw);
      }

      return {
        'username': username,
        'first_name': u['first_name'] ?? '',
        'last_name': u['last_name'] ?? '',
        'avatar_url': u['avatar'],
        'avg_score': 0.0,
        'certificate_count': (userProfile?['certificates'] as List?)?.length ?? 0,
        'level': u['level'] ?? 1,
        'interested_field': u['interested_field'] ?? '',
        'exp': u['exp'] ?? 0,
        'coins': u['coins'] ?? 0,
        'email': u['email'] ?? '',
      };
    }).toList();
    return {'results': resultList};
  }

  Map<String, dynamic> _getTopPeople() {
    final users = HiveDatabase.instance.getUsers();
    final candidates = users.where((u) =>
      u['is_company'] != true &&
      u['is_active'] == true
    ).toList();

    final profiles = Map<String, dynamic>.from(
      _dataBox.get('profiles', defaultValue: _profiles()),
    );

    final enriched = candidates.map((u) {
      final username = u['username'] ?? '';
      final profileKey = username is String ? username.toLowerCase() : '';

      Map<String, dynamic>? userProfile;
      final raw = profiles[profileKey] ?? null;
      if (raw is Map) {
        userProfile = Map<String, dynamic>.from(raw);
      }

      final attempts = (userProfile?['attempts'] as List?) ?? [];
      final totalScore = attempts.fold<num>(0, (s, a) => s + ((a as Map?)?['score'] as num? ?? 0));
      final avgScore = attempts.isNotEmpty ? (totalScore / attempts.length) : 0.0;
      final examsCompleted = attempts.length;
      final certificatesCount = (userProfile?['certificates'] as List?)?.length ?? 0;

      final candidateProfile = HiveDatabase.instance.getCandidateProfile(username);
      final achievementsCount = (candidateProfile['achievements'] as List?)?.length ?? 0;

      return {
        'username': username,
        'first_name': u['first_name'] ?? '',
        'last_name': u['last_name'] ?? '',
        'avatar_url': u['avatar'],
        'level': u['level'] ?? 1,
        'exp': u['exp'] ?? 0,
        'coins': u['coins'] ?? 0,
        'interested_field': u['interested_field'] ?? '',
        'avg_score': double.parse(avgScore.toStringAsFixed(1)),
        'total_score': totalScore.toInt(),
        'exams_completed': examsCompleted,
        'certificate_count': certificatesCount,
        'achievements_count': achievementsCount,
        'email': u['email'] ?? '',
      };
    }).toList();

    enriched.sort((a, b) {
      int cmp = (b['level'] as int).compareTo(a['level'] as int);
      if (cmp != 0) return cmp;
      cmp = (b['total_score'] as int).compareTo(a['total_score'] as int);
      if (cmp != 0) return cmp;
      cmp = (b['certificate_count'] as int).compareTo(a['certificate_count'] as int);
      if (cmp != 0) return cmp;
      cmp = (b['exams_completed'] as int).compareTo(a['exams_completed'] as int);
      if (cmp != 0) return cmp;
      cmp = (b['achievements_count'] as int).compareTo(a['achievements_count'] as int);
      return cmp;
    });

    for (int i = 0; i < enriched.length; i++) {
      enriched[i]['rank'] = i + 1;
    }

    return {'results': enriched};
  }

  List<Map<String, String>> _practicePdfs() {
    return [
      {'name': '01_Quantitative_Aptitude_Numerical_Ability_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': '02_Logical_Reasoning_Analytical_Ability_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': '03_Verbal_Ability_English_Comprehension_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': '04_Data_Interpretation_and_Analysis_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': '05_Abstract_Reasoning_Non-Verbal_Reasoning_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': '06_Technical_Aptitude_Basic_Programming_and_AIML_Concepts_Full_Content.pdf', 'size': '0.1 MB'},
      {'name': 'core_aptitudelevel_questions.pdf', 'size': '0.2 MB'},
      {'name': 'hr_interview_part1.pdf', 'size': '21.6 MB'},
      {'name': 'hr_interview_part2.pdf', 'size': '21.6 MB'},
      {'name': 'hr_interview_part3.pdf', 'size': '21.6 MB'},
      {'name': 'hr_interview_part4.pdf', 'size': '21.6 MB'},
    ];
  }

  String getAptixResponse(String message) {
    final msg = message.toLowerCase();

    // ── Greetings ──
    if (msg.contains('hello') || msg.contains('hi') || msg.contains('hey'))
      return 'Hello! I\'m Aptix, your AI Platform Guide for Aptitude GO. 🤖 I can help you with registration, exams, levels, certificates, recruiter features, and everything about the platform. What would you like to know?';

    if (msg.contains('who are you') || msg.contains('what are you') || msg.contains('who made'))
      return 'I\'m **Aptix** — your AI Platform Guide on the **Aptitude GO** platform! 🤖 I\'m here to help you navigate the app, understand features, and get the most out of your aptitude preparation. Ask me anything about the platform!';

    if (msg.contains('bye') || msg.contains('goodbye') || msg.contains('see you'))
      return 'Goodbye! Keep practicing and good luck with your preparation! 🎯 Come back anytime you need help! 😊';

    if (msg.contains('thank') || msg.contains('thanks'))
      return 'You\'re welcome! If you ever have more questions about Aptitude GO, I\'m just a message away! 😊';

    // ── Registration & Login ──
    if (msg.contains('register') || msg.contains('sign up') || msg.contains('create account') || msg.contains('new account'))
      return 'To create an account on Aptitude GO:\n\n1. Open the app and tap **Register** on the login screen\n2. Choose your role: **Candidate** (student) or **Recruiter** (company)\n3. Fill in your details: username, email, password\n4. Complete email verification if prompted\n5. Log in and start using the platform!\n\nIf you\'re a recruiter, you\'ll need to provide your organization name during registration.';

    if (msg.contains('login') || msg.contains('sign in') || msg.contains('log in'))
      return 'To log in:\n\n1. Open the Aptitude GO app\n2. Enter your **username** and **password**\n3. Tap the **Login** button\n\nThe app will remember your session, so you won\'t need to log in every time. If you forgot your password, use the **Forgot Password** option on the login screen.';

    if (msg.contains('password reset') || msg.contains('forgot password') || msg.contains('reset password') || msg.contains('change password'))
      return 'To reset your password:\n\n1. On the login screen, tap **Forgot Password**\n2. Enter your registered email address\n3. Check your email for a password reset link\n4. Click the link and follow the instructions to create a new password\n5. Return to the app and log in with your new password\n\nMake sure your new password is at least 8 characters long and includes a mix of letters and numbers.';

    if (msg.contains('email verify') || msg.contains('verify email') || msg.contains('email verification') || msg.contains('confirm email'))
      return 'Email verification helps secure your account. After registration:\n\n1. Check your email inbox (and spam folder) for a verification message\n2. Click the verification link in the email\n3. Once verified, you\'ll have full access to all features\n\nIf you didn\'t receive the email, you can request a new verification link from your Profile settings.';

    // ── Candidate Features ──
    if (msg.contains('candidate feature') || msg.contains('candidate can') || msg.contains('student feature') || msg.contains('what can i do as a'))
      return 'As a **Candidate** on Aptitude GO, you can:\n\n📝 **Practice Tests** — Take topic-wise aptitude tests with instant scoring\n📄 **Study Materials** — Browse PDF guides in the Arena\n🏆 **Events & Contests** — Participate in live and upcoming events\n📊 **Leaderboard** — Compete for top rankings\n🎡 **Weekly Spin** — Spin the wheel for rewards\n🎓 **Certificates** — Earn certificates for high scores\n👤 **Profile** — Track your level, XP, coins, and progress\n\nStart by taking a practice test from the Practice tab!';

    // ── Recruiter Features ──
    if (msg.contains('recruiter feature') || msg.contains('recruiter can') || msg.contains('company feature') || msg.contains('recruiter create'))
      return 'As a **Recruiter** on Aptitude GO, you can:\n\n📝 **Create Exams** — Design custom aptitude tests for candidates\n🔍 **Search Candidates** — Find candidates by skills and performance\n📊 **View Analytics** — Track candidate performance on your exams\n👥 **Manage Listings** — Post and manage job openings\n📈 **Monitor Progress** — See how candidates perform over time\n\nTo create an exam, go to your Recruiter Dashboard and tap **Create Exam**.';

    if (msg.contains('recruiter create exam') || msg.contains('create exam as recruiter') || msg.contains('how to create exam') || msg.contains('make exam'))
      return 'To create an exam as a Recruiter:\n\n1. Go to your **Recruiter Dashboard**\n2. Tap **Create Exam** or the **+** button\n3. Enter the exam title, description, and category\n4. Select questions from the question bank or add new ones\n5. Set the time limit and passing threshold\n6. Choose whether to make it **Public** or **Private** (with access code)\n7. Tap **Create** to publish the exam\n\nCandidates can then find and take your exam. You can view their results in the Analytics section.';

    if (msg.contains('search candidate') || msg.contains('find candidate') || msg.contains('candidate search') || msg.contains('hire candidate'))
      return 'To search for candidates:\n\n1. Go to your **Recruiter Dashboard**\n2. Use the **Search Candidates** section\n3. Filter by skills, experience level, or test performance\n4. View candidate profiles including their scores and certificates\n5. Contact promising candidates through the platform\n\nThis helps you find the right talent for your organization!';

    // ── Admin Features ──
    if (msg.contains('admin feature') || msg.contains('admin can') || msg.contains('staff feature') || msg.contains('administrator'))
      return 'As an **Admin**, you have full control over the platform:\n\n📊 **Overview Dashboard** — View platform stats (users, questions, exams)\n👥 **User Management** — View, manage, and delete users\n❓ **Question Management** — Add, edit, and delete questions by category\n📋 **Events** — Manage platform events and contests\n📈 **Analytics** — View user growth, exam activity, recruiter activity, and question growth trends\n\nAdmins are responsible for maintaining the platform and ensuring smooth operation.';

    // ── Exams & Assessments ──
    if ((msg.contains('exam') || msg.contains('test') || msg.contains('assessment')) && !msg.contains('create exam'))
      return 'On Aptitude GO, you can take various types of exams:\n\n📝 **Practice Tests** — Choose a topic, number of questions, and time limit\n🏆 **Live Events** — Timed contests with other participants\n📋 **Recruiter Exams** — Tests created by recruiters for hiring\n🔑 **Private Exams** — Access with a unique exam code\n\nTo start: go to the **Practice** tab, pick a category, configure your test, and begin! Each test costs 1 life (heart).';

    // ── Levels & XP System ──
    if (msg.contains('level') || msg.contains('xp') || msg.contains('experience') || msg.contains('level up'))
      return 'The **Level & XP** system tracks your progress:\n\n⭐ **XP (Experience Points)** — Earned by completing tests. More questions = more XP.\n📈 **Levels** — Your level increases as you accumulate XP. Higher levels unlock recognition on the leaderboard.\n📊 **Progress** — View your current level and XP progress on your Profile page.\n\nThe more you practice, the higher your level! Keep taking tests to level up. 🚀';

    // ── Weekly Spin Wheel ──
    if (msg.contains('spin') || msg.contains('wheel') || msg.contains('spin wheel') || msg.contains('weekly spin') || msg.contains('reward wheel'))
      return 'The **Weekly Spin Wheel** lets you win rewards! 🎡\n\n- You can spin **once every 7 days**\n- Rewards include coins, bonus XP, and other prizes\n- Your spin status shows on the home dashboard\n- The wheel resets weekly, so come back to claim your reward\n\nCheck your dashboard for the spin wheel card and tap **Spin Now** when it\'s available!';

    // ── Certificates ──
    if (msg.contains('certificate') || msg.contains('cert') || msg.contains('certification'))
      return 'You can earn **certificates** on Aptitude GO! 🎓\n\n- **Event Certificates** — Awarded for participating in and completing events\n- **Achievement Certificates** — Earned by scoring 70% or higher on exams\n- View all your certificates on your **Profile** page\n- Certificates are stored and can be accessed anytime\n\nKeep aiming for high scores to earn more certificates!';

    // ── Leaderboard ──
    if (msg.contains('leaderboard') || msg.contains('rank') || msg.contains('top') || msg.contains('ranking'))
      return 'The **Leaderboard** shows top-performing users on the platform 🏅\n\n- **Global Ranking** — See how you compare against all users\n- **Weekly Ranking** — Track your performance this week\n- Rankings are based on scores, levels, and overall activity\n- Climb the ranks by taking more tests and scoring higher\n\nCheck the Leaderboard tab to see where you stand!';

    // ── Profile Management ──
    if (msg.contains('profile') || msg.contains('avatar') || msg.contains('edit profile') || msg.contains('my profile'))
      return 'Your **Profile** page is your personal hub on Aptitude GO:\n\n👤 **User Info** — View and edit your name, email, and other details\n🖼️ **Avatar** — Customize your profile with avatars from the Store\n📊 **Stats** — Track your level, XP, coins, and test history\n🎓 **Certificates** — View all certificates you\'ve earned\n⚙️ **Settings** — Manage account preferences\n\nTap the **Profile** tab at the bottom to access your profile!';

    // ── Exam Attempts & Lives ──
    if (msg.contains('life') || msg.contains('heart') || msg.contains('lives') || msg.contains('attempt'))
      return 'The **Lives** system manages your exam attempts ❤️\n\n- You start with **5 lives**\n- Each practice test consumes **1 life**\n- Lives **restore automatically** at the start of each new day\n- If you run out, you can purchase a **Life Refill** from the Store using coins\n- Recruiter exams and events may have separate rules\n\nUse your lives wisely and practice daily to improve!';

    // ── Platform navigation ──
    if (msg.contains('how to use') || msg.contains('how do i') || msg.contains('getting started') || msg.contains('guide') || msg.contains('tutorial'))
      return 'Here\'s how to get started with Aptitude GO:\n\n1. **Register** or **Log in** to your account\n2. Choose your role: **Candidate** or **Recruiter**\n3. **Candidates**: Start with practice tests, join events, earn certificates\n4. **Recruiters**: Create exams, search candidates, view analytics\n5. Explore tabs: Home, Practice, Events, Leaderboard, Profile\n\nNeed help with something specific? Just ask!';

    // ── Store & Coins ──
    if (msg.contains('store') || msg.contains('coin') || msg.contains('coins') || msg.contains('buy') || msg.contains('purchase') || msg.contains('spend'))
      return 'The **Store** lets you spend coins earned from tests and events 🛒\n\n🪙 **Golden Frame** — A shiny border for your profile avatar\n👤 **Pro Avatar** — Premium avatar style\n❤️ **Life Refill** — Restore your lives back to 5\n\nYou earn coins by:\n- Completing practice tests\n- Participating in events\n- Performing well on exams\n\nKeep practicing to build your coin balance!';

    // ── Events ──
    if (msg.contains('event') || msg.contains('contest') || msg.contains('competition') || msg.contains('live event'))
      return '**Events** are timed contests on Aptitude GO 🏆\n\n- **Upcoming Events** — Register in advance for future contests\n- **Live Events** — Currently active events you can join immediately\n- Events have specific categories and time limits\n- Top performers earn coins, certificates, and leaderboard recognition\n\nCheck the **Events** tab to see what\'s coming up!';

    // ── Dashboard & Analytics ──
    if (msg.contains('dashboard') || msg.contains('analytics') || msg.contains('stats') || msg.contains('performance'))
      return 'Your **Dashboard** provides a complete view of your activity:\n\n📊 **Score History** — Chart showing your performance over time\n📈 **Progress** — Track your improvement across different topics\n🏆 **Achievements** — View certificates and accomplishments\n📉 **Weak Areas** — Identify topics that need more practice\n\nRecruiters and Admins have their own dashboards with additional analytics features.';

    // ── General features overview ──
    if (msg.contains('feature') || msg.contains('what can') || msg.contains('capabilities') || msg.contains('what do you do'))
      return 'Aptitude GO is a comprehensive aptitude preparation platform:\n\n**For Candidates:**\n- Topic-wise practice tests (Quant, Logical, Verbal, etc.)\n- Live events and contests\n- PDF study materials\n- Spin wheel for rewards\n- Certificates and leaderboards\n- Level & XP progression system\n\n**For Recruiters:**\n- Create custom exams\n- Search and evaluate candidates\n- View detailed analytics\n- Manage hiring assessments\n\n**For Admins:**\n- Platform-wide analytics\n- User and question management\n- System oversight\n\nWhat specific feature would you like to know more about?';

    // ── Placement & Career ──
    if (msg.contains('placement') || msg.contains('job') || msg.contains('campus') || msg.contains('career') || msg.contains('hire') || msg.contains('recruit'))
      return 'Aptitude GO helps you prepare for campus placements and recruitment! 🎯\n\n✅ Practice with topic-wise tests that match placement exam patterns\n✅ Access HR interview PDF guides\n✅ Build your profile to get noticed by recruiters\n✅ Track improvement across all aptitude areas\n✅ Earn certificates to showcase your skills\n\nConsistent practice is the key to success in campus placements. Start today!';

    // ── Study Tips ──
    if (msg.contains('tip') || msg.contains('advice') || msg.contains('suggestion') || msg.contains('how to improve') || msg.contains('study'))
      return 'Here are some tips to get the most out of Aptitude GO:\n\n✅ Practice **daily** — even 20 questions help\n✅ Review **mistakes** after every test\n✅ Focus on **weak areas** first\n✅ Use **PDF study materials** in the Arena\n✅ Participate in **events** for extra practice\n✅ Track your **progress** on your Profile\n✅ Earn and save **coins** for useful items\n✅ Aim for **certificates** to validate your skills\n\nConsistency is the key to success! 💪';

    // ── Subject-specific (kept minimal, platform-focused) ──
    if (msg.contains('quantitative') || msg.contains('math') || msg.contains('numerical'))
      return '**Quantitative Aptitude** covers percentages, ratios, averages, time-speed-distance, number systems, profit & loss, and more. You can practice these in the **Practice** tab under the Quantitative Aptitude category. 📐';

    if (msg.contains('logical') || msg.contains('reasoning') || msg.contains('puzzle'))
      return '**Logical Reasoning** includes puzzles, seating arrangements, syllogisms, blood relations, coding-decoding, and more. Practice these under the Logical Reasoning category in the **Practice** tab. 🧩';

    if (msg.contains('verbal') || msg.contains('english') || msg.contains('grammar') || msg.contains('vocabulary'))
      return '**Verbal Ability** focuses on grammar, vocabulary, reading comprehension, and sentence correction. Practice under the Verbal Ability category in the **Practice** tab. 📖';

    if (msg.contains('hr') || msg.contains('interview'))
      return 'HR Interview preparation guides are available as PDFs in the **Arena** section. These cover common questions, self-introduction tips, and interview strategies. 🎯';

    // ── Off-topic check: refuse non-platform questions ──
    final offTopic = [
      'movie', 'song', 'music', 'dance', 'sports', 'cricket', 'football', 'basketball',
      'recipe', 'cook', 'food', 'weather', 'capital of', 'who is', 'history of',
      'joke', 'story', 'funny', 'horoscope', 'astrology', 'love', 'girlfriend',
      'boyfriend', 'relationship', 'politics', 'religion', 'god', 'party',
      'travel', 'tourism', 'fashion', 'news', 'celebrity', 'actor', 'actress',
      'what is the meaning of life', 'tell me a', 'make me', 'write a poem',
      'translate', 'how to hack', 'crack', 'cheat', 'python', 'javascript', 'java',
      'programming language', 'what is programming', 'define', 'explain quantum',
      'football match', 'cricket match', 'who won', 'score', 'match today',
      'stock market', 'bitcoin', 'crypto', 'investment',
    ];
    for (final keyword in offTopic) {
      if (msg.contains(keyword)) {
        return 'Sorry, I can only assist with questions related to the Aptitude GO platform and its features. 🤖\n\nI can help you with:\n• How to register and log in\n• Candidate and recruiter features\n• Exams, levels, XP, and certificates\n• Spin wheel, store, and coins\n• Leaderboards and profile management\n\nPlease ask me something about the platform!';
      }
    }

    // ── Default: guide the user ──
    return 'I\'m here to help you with Aptitude GO! 🤖\n\nTry asking me about:\n• "How do I register?"\n• "How to create an exam as a recruiter?"\n• "What are certificates?"\n• "How does the level system work?"\n• "Tell me about the spin wheel"\n• "How do I reset my password?"\n\nWhat would you like to know?';
  }

  Map<String, dynamic> _getRecruiterProfileData(String? username) {
    final curUser = HiveDatabase.instance.getCurrentUser();
    String targetUsername = username ?? curUser?['username'] ?? '';
    
    // Find user details
    final users = HiveDatabase.instance.getUsers();
    Map<String, dynamic>? matchUser;
    for (final u in users) {
      if (u['username']?.toString().toLowerCase() == targetUsername.toLowerCase()) {
        matchUser = Map<String, dynamic>.from(u);
        break;
      }
    }
    
    if (matchUser == null && curUser != null && curUser['username']?.toString().toLowerCase() == targetUsername.toLowerCase()) {
      matchUser = Map<String, dynamic>.from(curUser);
    }
    
    if (matchUser == null) {
      matchUser = {
        'username': targetUsername,
        'email': '',
        'first_name': targetUsername,
        'last_name': '',
        'is_company': true,
        'organization': '',
      };
    }
    
    matchUser.remove('password');
    
    final profile = HiveDatabase.instance.getRecruiterProfile(targetUsername);
    
    return {
      'user': matchUser,
      'recruiter_profile_data': profile,
      'stats': {
        'total_exams_created': 0,
      }
    };
  }

  Map<String, dynamic> _saveRecruiterProfileData(dynamic data) {
    final curUser = HiveDatabase.instance.getCurrentUser();
    if (curUser == null) return {'success': false, 'error': 'Not authenticated'};
    
    final username = curUser['username'] as String? ?? '';
    final profileData = Map<String, dynamic>.from(
      (data is Map && data['recruiter_profile_data'] is Map) 
          ? data['recruiter_profile_data'] 
          : (data is Map ? data : {})
    );
    
    HiveDatabase.instance.saveRecruiterProfile(username, profileData);
    
    return {'success': true, 'message': 'Recruiter profile saved successfully'};
  }
}
