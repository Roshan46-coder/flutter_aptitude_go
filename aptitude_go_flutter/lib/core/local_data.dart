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
    await _dataBox.put('gamification_status', {'eligible': true, 'last_spin': null});
    await _dataBox.put('practice_pdfs', _practicePdfs());
    debugPrint("LocalDataProvider: seeded all data");
  }

  // ── ROUTER: map endpoint paths to local data ───────────────────────────────

  dynamic get(String path, {Map<String, dynamic>? queryParameters}) {
    final parts = _normalizePath(path);
    return _routeGet(parts, queryParameters);
  }

  dynamic post(String path, {dynamic data}) {
    final parts = _normalizePath(path);
    return _routePost(parts, data);
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
      if (_matches(parts, ['events', '*']) && parts.length == 2) {
        final eventId = int.tryParse(parts[1]) ?? 0;
        return _getEventDetail(eventId);
      }
      if (_matches(parts, ['inbox'])) {
        return _getInbox();
      }
      if (_matches(parts, ['chat', '*'])) {
        final convId = int.tryParse(parts[1]) ?? 0;
        return _getChatMessages(convId);
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
      if (_matches(parts, ['profile', '*'])) {
        return _getProfile(parts[1]);
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
      if (_matches(parts, ['recruiter', 'search'])) {
        return _searchTalent(params?['q'] as String?);
      }
      if (_matches(parts, ['aptix'])) {
        return {'success': true, 'response': 'I am running in offline mode. Ask me anything about aptitude!'};
      }
    } catch (e) {
      debugPrint("LocalDataProvider get error for $parts: $e");
    }
    return null;
  }

  dynamic _routePost(List<String> parts, dynamic data) {
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
      if (_matches(parts, ['events', '*', 'register'])) {
        return {'message': 'Registered for event successfully'};
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
        final profiles = _dataBox.get('profiles', defaultValue: _profiles());
        final live = Map<String, dynamic>.from(profiles['current_user'] ?? _profiles()['current_user']);
        final userLive = Map<String, dynamic>.from(live['user'] ?? {});
        userLive.addAll(updates);
        live['user'] = userLive;
        profiles['current_user'] = live;
        _dataBox.put('profiles', profiles);
        return {'success': true, 'message': 'Profile updated locally'};
      }
      if (_matches(parts, ['profile', 'delete-account'])) {
        return {'success': true, 'message': 'Account deleted'};
      }
      if (_matches(parts, ['profile', 'upload-certificate'])) {
        return _addCertificate(data);
      }
      if (_matches(parts, ['profile', 'delete-certificate', '*'])) {
        final certId = int.tryParse(parts[2]) ?? 0;
        return _deleteCertificate(certId);
      }
      if (_matches(parts, ['admin', 'approve-user', '*']) || _matches(parts, ['admin', 'delete-user', '*'])) {
        return {'success': true, 'message': 'User updated'};
      }
      if (_matches(parts, ['admin', 'toggle-malpractice'])) {
        return {'success': true, 'message': 'Anti-malpractice toggled', 'anti_malpractice_enabled': true};
      }
      if (_matches(parts, ['admin', 'add-question'])) {
        return {'success': true, 'message': 'Question added'};
      }
      if (_matches(parts, ['admin', 'delete-question', '*'])) {
        return {'success': true, 'message': 'Question deleted'};
      }
      if (_matches(parts, ['admin', 'create-event']) || _matches(parts, ['events', 'create'])) {
        return {'success': true, 'message': 'Event created', 'event_id': 1};
      }
      if (_matches(parts, ['admin', 'delete-event', '*'])) {
        return {'success': true, 'message': 'Event deleted'};
      }
      if (_matches(parts, ['recruiter', 'message'])) {
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
    final newLevel = 1 + (newExp ~/ 100);
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

    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    final profileKey = 'current_user';
    final profile = Map<String, dynamic>.from(profiles[profileKey] ?? _profiles()[profileKey]);
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
    profiles[profileKey] = profile;
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
    return _dataBox.get('gamification_status', defaultValue: {'eligible': true, 'last_spin': null});
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
    _dataBox.put('gamification_status', {'eligible': false, 'last_spin': DateTime.now().toIso8601String()});
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
    final now = DateTime.now();
    return {
      'upcoming': [
        {
          'id': 1,
          'title': 'Weekly Challenge',
          'description': 'Test your skills in this week\'s aptitude challenge.',
          'start_time': now.add(const Duration(days: 7)).toIso8601String(),
          'end_time': now.add(const Duration(days: 8)).toIso8601String(),
          'is_registered': false,
          'is_live': false,
          'has_completed': false,
          'my_score': null,
          'participant_count': 42,
          'category_slug': 'quantitative-aptitude',
        },
        {
          'id': 2,
          'title': 'Tech Titans Contest',
          'description': 'A contest for tech enthusiasts.',
          'start_time': now.add(const Duration(days: 14)).toIso8601String(),
          'end_time': now.add(const Duration(days: 15)).toIso8601String(),
          'is_registered': true,
          'is_live': false,
          'has_completed': false,
          'my_score': null,
          'participant_count': 128,
          'category_slug': 'programming-logic',
        },
      ],
      'active': [
        {
          'id': 3,
          'title': 'Live Speed Quiz',
          'description': 'Answer as fast as you can! Live event happening now.',
          'start_time': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
          'is_registered': false,
          'is_live': true,
          'has_completed': false,
          'my_score': null,
          'participant_count': 256,
          'category_slug': 'logical-reasoning',
        },
      ],
      'past': [
        {
          'id': 4,
          'title': 'Last Month Marathon',
          'description': 'The grand marathon from last month.',
          'start_time': now.subtract(const Duration(days: 30)).toIso8601String(),
          'end_time': now.subtract(const Duration(days: 29)).toIso8601String(),
          'is_registered': true,
          'is_live': false,
          'has_completed': true,
          'my_score': 85,
          'participant_count': 512,
          'category_slug': 'verbal-ability',
        },
      ],
    };
  }

  Map<String, dynamic> _getEventsForDashboard() {
    // Returns data in Django /api/events/dashboard/ format
    final now = DateTime.now();
    return {
      'student_events': [
        {
          'id': 1,
          'title': 'Weekly Challenge',
          'description': 'Test your skills in this week\'s aptitude challenge.',
          'category': 'Quantitative Aptitude',
          'start_time': now.add(const Duration(days: 7)).toIso8601String(),
          'end_time': now.add(const Duration(days: 8)).toIso8601String(),
          'total_questions': 10,
          'time_limit_seconds': 600,
          'threshold_type': null,
          'threshold_value': null,
          'is_registered': false,
          'is_completed': false,
          'status': 'UPCOMING',
        },
        {
          'id': 2,
          'title': 'Tech Titans Contest',
          'description': 'A contest for tech enthusiasts.',
          'category': 'Programming Logic',
          'start_time': now.add(const Duration(days: 14)).toIso8601String(),
          'end_time': now.add(const Duration(days: 15)).toIso8601String(),
          'total_questions': 10,
          'time_limit_seconds': 600,
          'threshold_type': 'LEVEL',
          'threshold_value': 3,
          'is_registered': true,
          'is_completed': false,
          'status': 'UPCOMING',
        },
        {
          'id': 3,
          'title': 'Live Speed Quiz',
          'description': 'Answer as fast as you can! Live event happening now.',
          'category': 'Logical Reasoning',
          'start_time': now.subtract(const Duration(hours: 1)).toIso8601String(),
          'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
          'total_questions': 10,
          'time_limit_seconds': 300,
          'threshold_type': null,
          'threshold_value': null,
          'is_registered': false,
          'is_completed': false,
          'status': 'LIVE',
        },
        {
          'id': 4,
          'title': 'Last Month Marathon',
          'description': 'The grand marathon from last month.',
          'category': 'Verbal Ability',
          'start_time': now.subtract(const Duration(days: 30)).toIso8601String(),
          'end_time': now.subtract(const Duration(days: 29)).toIso8601String(),
          'total_questions': 15,
          'time_limit_seconds': 900,
          'threshold_type': null,
          'threshold_value': null,
          'is_registered': true,
          'is_completed': true,
          'status': 'ENDED',
        },
      ],
    };
  }

  Map<String, dynamic> _getEventDetail(int eventId) {
    final now = DateTime.now();
    return {
      'event': {
        'id': eventId,
        'title': 'Event #$eventId',
        'description': 'Event description',
        'start_time': now.toIso8601String(),
        'end_time': now.add(const Duration(hours: 2)).toIso8601String(),
        'time_limit_seconds': 600,
        'is_live': true,
        'total_questions': 10,
      },
      'registration': {
        'is_registered': true,
        'is_completed': false,
        'score': null,
      },
      'questions': [
        {'id': 1, 'index': 1, 'text': 'Sample question?', 'option_a': 'A', 'option_b': 'B', 'option_c': 'C', 'option_d': 'D', 'marks': 1},
      ],
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
    final inbox = _dataBox.get('inbox', defaultValue: _inbox());
    return Map<String, dynamic>.from(inbox);
  }

  Map<String, dynamic> _inbox() {
    return {
      'conversations': [
        {
          'conversation_id': 1,
          'other_user': {'username': 'aptix_bot', 'avatar_url': null},
          'last_message': {'content': 'Hey! Ready for practice?', 'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
        },
        {
          'conversation_id': 2,
          'other_user': {'username': 'alice', 'avatar_url': null},
          'last_message': {'content': 'Great score on the last test!', 'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
        },
      ],
    };
  }

  Map<String, dynamic> _getChatMessages(int convId) {
    final all = _dataBox.get('chat_messages', defaultValue: _chatMessages());
    return all[convId.toString()] ?? {'messages': []};
  }

  Map<String, dynamic> _chatMessages() {
    return {
      '1': {
        'messages': [
          {'sender': 'aptix_bot', 'content': 'Hey! Ready for practice?', 'timestamp': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String()},
          {'sender': 'current_user', 'content': 'Yes, what should I study?', 'timestamp': DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String()},
          {'sender': 'aptix_bot', 'content': 'Try Quantitative Aptitude for starters!', 'timestamp': DateTime.now().subtract(const Duration(minutes: 3)).toIso8601String()},
        ],
      },
      '2': {
        'messages': [
          {'sender': 'alice', 'content': 'Great score on the last test!', 'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
          {'sender': 'current_user', 'content': 'Thanks! You too!', 'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 55)).toIso8601String()},
        ],
      },
    };
  }

  Map<String, dynamic> _sendMessage(int convId, dynamic data) {
    final content = (data is Map) ? (data['content'] ?? '') : '';
    final ts = DateTime.now().toIso8601String();
    final all = Map<String, dynamic>.from(_dataBox.get('chat_messages', defaultValue: _chatMessages()));
    final convKey = convId.toString();
    final conv = Map<String, dynamic>.from(all[convKey] ?? {'messages': []});
    final msgs = List<Map<String, dynamic>>.from(conv['messages'] as List);
    msgs.add({'sender': 'current_user', 'content': content, 'timestamp': ts});
    conv['messages'] = msgs;
    all[convKey] = conv;
    _dataBox.put('chat_messages', all);
    return {'success': true, 'message': {'sender': 'current_user', 'content': content, 'timestamp': ts}};
  }

  Map<String, dynamic> _addCertificate(dynamic data) {
    final title = (data is Map) ? (data['title'] ?? 'Certificate') : 'Certificate';
    final filename = (data is Map) ? (data['filename'] ?? '') : '';
    final localPath = (data is Map) ? (data['local_path'] ?? '') : '';
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
      'uploaded_at': DateTime.now().toIso8601String(),
    });
    _dataBox.put('user_certificates', certs);
    return {'success': true, 'message': 'Certificate uploaded locally', 'id': newId};
  }

  Map<String, dynamic> _deleteCertificate(int certId) {
    final certs = List<Map<String, dynamic>>.from(
      (_dataBox.get('user_certificates', defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map)),
    );
    certs.removeWhere((c) => c['id'] == certId);
    _dataBox.put('user_certificates', certs);
    return {'success': true, 'message': 'Certificate deleted'};
  }

  Map<String, dynamic> _getAttemptHistory() {
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    final profile = profiles['current_user'] ?? _profiles()['current_user'];
    final allAttempts = (profile['attempts'] as List?) ?? [];
    final realAttempts = allAttempts.where((a) {
      final m = a as Map?;
      return m != null && m.containsKey('total_questions');
    }).toList();
    return {'attempts': realAttempts};
  }

  Map<String, dynamic> _getProfile(String? username) {
    final profiles = _dataBox.get('profiles', defaultValue: _profiles());
    final key = username ?? 'current_user';
    final profile = Map<String, dynamic>.from(profiles[key] ?? profiles['current_user']);
    final userData = HiveDatabase.instance.getCurrentUser();
    if (userData != null && (username == null || username == userData['username'])) {
      profile['user'] = Map<String, dynamic>.from(profile['user'] ?? {})
        ..addAll(Map<String, dynamic>.from(userData));

      // Only keep real attempts (submitted by _submitTest) — filter seed/fake data
      final allAttempts = (profile['attempts'] as List?) ?? [];
      final realAttempts = allAttempts.where((a) {
        final m = a as Map?;
        return m != null && m.containsKey('total_questions');
      }).toList();
      profile['attempts'] = realAttempts;

      // Compute category_stats dynamically from real attempts
      final catMap = <String, List<int>>{};
      for (final a in realAttempts) {
        final m = a as Map;
        final catName = (m['category_name'] as String?) ?? 'General';
        final score = (m['score'] as num?)?.toInt() ?? 0;
        catMap.putIfAbsent(catName, () => []).add(score);
      }
      profile['category_stats'] = catMap.entries.map((e) {
        final scores = e.value;
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        return {
          'category_name': e.key,
          'avg_score': double.parse(avg.toStringAsFixed(1)),
        };
      }).toList();

      // Merge seed certificates with user-uploaded ones from Hive box
      final seedCerts = (profile['certificates'] as List?) ?? [];
      final boxCerts = (_dataBox.get('user_certificates', defaultValue: []) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final merged = <Map<String, dynamic>>[...seedCerts.cast(), ...boxCerts];
      profile['certificates'] = merged;
    }
    return profile;
  }

  Map<String, dynamic> _profiles() {
    return {
      'current_user': {
        'user': {
          'username': 'current_user',
          'first_name': '',
          'last_name': '',
          'avatar_url': null,
          'level': 1,
          'exp': 0,
          'coins': 0,
          'lives': 5,
          'is_company': false,
          'organization': '',
          'linkedin_url': '',
          'github_url': '',
        },
        'attempts': [],
        'category_stats': [],
        'certificates': [],
      },
      'alice': {
        'user': {
          'username': 'alice', 'first_name': 'Alice', 'last_name': 'W.', 'avatar_url': null,
          'level': 10, 'exp': 2000, 'coins': 1200, 'lives': 5, 'is_company': false,
          'organization': 'Tech University', 'linkedin_url': '', 'github_url': '',
        },
        'attempts': [],
        'category_stats': [],
        'certificates': [],
      },
    };
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

  Map<String, dynamic> _getAdminDashboard() {
    return {
      'anti_malpractice_enabled': false,
      'stats': {
        'total_users': 25,
        'total_candidates': 18,
        'total_recruiters': 4,
        'total_questions': 60,
        'total_attempts': 150,
        'active_events': 1,
      },
      'pending_approvals': [
        {'id': 1, 'username': 'newuser', 'email': 'newuser@test.com'},
      ],
      'users': [
        {'id': 1, 'username': 'admin', 'email': 'admin@test.com', 'is_company': false, 'is_staff': true, 'is_superuser': true, 'is_active': true},
        {'id': 2, 'username': 'alice', 'email': 'alice@test.com', 'is_company': false, 'is_staff': false, 'is_superuser': false, 'is_active': true},
        {'id': 3, 'username': 'recruiter1', 'email': 'recruiter@test.com', 'is_company': true, 'is_staff': false, 'is_superuser': false, 'is_active': true},
      ],
      'categories': _categories.map(_adminCategory).toList(),
      'events': [
        {'id': 3, 'title': 'Live Speed Quiz', 'start_time': DateTime.now().toIso8601String(), 'end_time': DateTime.now().add(const Duration(hours: 2)).toIso8601String(), 'is_live': true, 'participant_count': 256},
        {'id': 1, 'title': 'Weekly Challenge', 'start_time': DateTime.now().add(const Duration(days: 7)).toIso8601String(), 'end_time': DateTime.now().add(const Duration(days: 8)).toIso8601String(), 'is_live': false, 'participant_count': 42},
      ],
    };
  }

  Map<String, dynamic> _getRecruiterDashboard() {
    return {
      'stats': {
        'total_candidates': 18,
        'total_attempts': 150,
        'avg_score': 78.5,
        'total_certs': 5,
      },
      'top_talent': [
        {'username': 'alice', 'first_name': 'Alice', 'last_name': 'W.', 'avatar_url': null, 'avg_score': 92.0, 'certificate_count': 3, 'level': 10},
        {'username': 'bob', 'first_name': 'Bob', 'last_name': 'M.', 'avatar_url': null, 'avg_score': 88.0, 'certificate_count': 2, 'level': 9},
        {'username': 'charlie', 'first_name': 'Charlie', 'last_name': 'D.', 'avatar_url': null, 'avg_score': 82.0, 'certificate_count': 1, 'level': 8},
      ],
    };
  }

  Map<String, dynamic> _searchTalent(String? query) {
    if (query == null || query.isEmpty) {
      return {'results': ( _getRecruiterDashboard()['top_talent'] as List).take(2).toList()};
    }
    return {'results': []};
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
    if (msg.contains('hello') || msg.contains('hi') || msg.contains('hey'))
      return 'Hello! I\'m Aptix, your AI aptitude mentor on Aptitude GO. 🧠 I can help you understand concepts, guide you through the platform, and share study tips. What would you like to know?';

    // ── Platform navigation & features ──
    if (msg.contains('how to use') || msg.contains('how do i') || msg.contains('getting started') || msg.contains('guide') || msg.contains('tutorial'))
      return 'Here\'s how to use Aptitude GO:\n\n📚 **Practice Tab** — Take topic-wise aptitude tests (Quant, Logical, Verbal, etc.)\n📄 **Arena Tab** — Browse and view/download practice PDFs\n🛒 **Store Tab** — Spend coins on cosmetics like Golden Frame & Pro Avatar\n💬 **Chat Tab** — Message other users or chat with me (Aptix!)\n👤 **Profile Tab** — View your stats, level, certificates & achievements\n\nStart with Practice tests to build your skills!';

    if (msg.contains('feature') || msg.contains('what can') || msg.contains('what do you'))
      return 'This platform helps you prepare for aptitude tests and campus placements. Key features:\n\n✅ Topic-wise practice tests with instant scoring\n✅ Live & upcoming events and contests\n✅ Multiplayer mode to compete with others\n✅ Practice PDF library (Arena)\n✅ In-app store for cosmetics\n✅ Leaderboard to track rankings\n✅ Earn coins & level up as you improve!\n\nTry taking a test from the Practice tab to get started! 🚀';

    if (msg.contains('placement') || msg.contains('job') || msg.contains('campus') || msg.contains('recruit') || msg.contains('career') || msg.contains('hire') || msg.contains('get placed'))
      return 'Aptitude GO helps you prepare for campus placements and job recruitment tests! 🎯\n\n✅ Practice with topic-wise tests covering all major aptitude areas\n✅ Access HR interview PDF guides in the Arena\n✅ Compete in events to build confidence\n✅ Track your progress and improve weak areas\n\nConsistent practice here will boost your performance in real placement tests. Start with the **Practice** tab! 🚀';

    if (msg.contains('practice') || msg.contains('test') || msg.contains('quiz'))
      return 'To take a practice test:\n1. Go to the **Practice** tab from the bottom menu\n2. Pick a category (Quantitative, Logical, Verbal, etc.)\n3. Select the number of questions and time limit\n4. Answer & submit to see your score, coins earned & XP gained\n\nTip: Review your mistakes to improve faster! 📈';

    if (msg.contains('pdf') || msg.contains('arena') || msg.contains('study material'))
      return 'The **Arena** tab under Practice gives you access to detailed PDF study materials covering all aptitude topics — Quantitative, Logical, Verbal, Data Interpretation, Technical, and HR Interview guides. You can view them online or download for offline study. 📄';

    if (msg.contains('store') || msg.contains('coin') || msg.contains('buy') || msg.contains('purchase'))
      return 'You earn **coins** by completing tests and participating in events. Spend them in the **Store** tab to unlock:\n\n🪙 Golden Frame — a shiny border for your profile\n👤 Pro Avatar — premium avatar style\n❤️ Life Refill — restore your lives to 5\n\nKeep practicing to earn more coins!';

    if (msg.contains('event') || msg.contains('contest') || msg.contains('competition'))
      return 'Check the **Events** section for upcoming and live contests! Participating in events can earn you extra coins, certificates, and leaderboard recognition. Look for active events on the Events page and register to join. 🏆';

    if (msg.contains('leaderboard') || msg.contains('rank') || msg.contains('top'))
      return 'The **Leaderboard** shows top-performing users globally and weekly. Your rank improves as you score higher in tests and events. Compete, climb the ranks, and become the top performer! 🏅';

    if (msg.contains('multiplayer') || msg.contains('challenge') || msg.contains('1v1') || msg.contains('live opponent'))
      return 'The **Multiplayer** feature lets you challenge a live opponent in real-time! Go to the Multiplayer section, choose a topic, and compete head-to-head. Win to earn extra coins and bragging rights! 🎮';

    if (msg.contains('life') || msg.contains('heart') || msg.contains('live'))
      return 'You have **5 lives** that recharge when you take tests. If you run out, you can:\n- Wait for automatic refill over time\n- Purchase a **Life Refill** from the Store using coins\n\nLives are consumed when you start a test, so use them wisely! ❤️';

    if (msg.contains('profile') || msg.contains('avatar') || msg.contains('level') || msg.contains('xp'))
      return 'Your **Profile** shows your stats: Level, XP, Coins, Lives, and test history. You can also view your certificates and edit your personal info. As you take more tests, your level and XP increase! 📊';

    if (msg.contains('certificate') || msg.contains('cert'))
      return 'You can earn **certificates** by performing well in events and achieving high scores. View and download your certificates from your Profile page. Keep aiming higher! 🎓';

    if (msg.contains('message') || msg.contains('chat') || msg.contains('inbox') || msg.contains('talk'))
      return 'The **Chat** tab lets you message other users, and you\'re talking to me right now — Aptix! 🤖 I\'m here to help you with concepts, platform guidance, and study tips. Ask me anything about the platform!';

    // ── Concept help ──
    if (msg.contains('quantitative') || msg.contains('math') || msg.contains('numerical') || msg.contains('percentage') || msg.contains('ratio') || msg.contains('average'))
      return '**Quantitative Aptitude** covers percentages, ratios, averages, time-speed-distance, number systems, profit & loss, and more. Go to the Practice tab, select Quantitative Aptitude, and start solving! 📐';

    if (msg.contains('logical') || msg.contains('reasoning') || msg.contains('puzzle') || msg.contains('syllogism') || msg.contains('seating'))
      return '**Logical Reasoning** includes puzzles, seating arrangements, syllogisms, blood relations, coding-decoding, and more. Try practicing puzzle grids and take tests from the Logical Reasoning category. 🧩';

    if (msg.contains('verbal') || msg.contains('english') || msg.contains('grammar') || msg.contains('vocabulary'))
      return '**Verbal Ability** focuses on grammar, vocabulary, reading comprehension, sentence correction, and para jumbles. Practice regularly with English reading to improve! 📖';

    if (msg.contains('data interpretation') || msg.contains('data') && msg.contains('interpret'))
      return '**Data Interpretation & Analysis** covers tables, bar graphs, pie charts, line graphs, and caselet data. These are common in campus placements. Practice with the Data Interpretation category in Practice tab! 📊';

    if (msg.contains('technical') || msg.contains('programming') || msg.contains('coding') || msg.contains('computer') || msg.contains('aiml'))
      return '**Technical Aptitude** covers computer fundamentals, programming basics, and AI/ML concepts. Great for tech role placements! Practice under the Computer Fundamentals and Programming Logic categories. 💻';

    if (msg.contains('abstract') || msg.contains('non-verbal') || msg.contains('pattern'))
      return '**Abstract/Non-Verbal Reasoning** tests your ability to identify patterns, analogies, and sequences in shapes and figures. Practice these to improve your visual reasoning skills! 🔷';

    if (msg.contains('hr') || msg.contains('interview'))
      return 'HR Interview preparation is available in the **Arena** tab as PDF guides. These cover common HR questions, self-introduction tips, and interview strategies to help you succeed! 🎯';

    if (msg.contains('tip') || msg.contains('advice') || msg.contains('suggestion') || msg.contains('how to improve'))
      return 'Here are some tips to improve:\n\n✅ Practice daily — aim for at least 20 questions\n✅ Review your mistakes after every test\n✅ Focus on weaker topics first\n✅ Use the PDF study materials in Arena\n✅ Participate in events for extra practice\n✅ Track your progress on the Profile page\n\nConsistency is the key to success! 💪';

    if (msg.contains('thank') || msg.contains('thanks'))
      return 'You\'re welcome! Keep practicing and you\'ll see great results. If you ever need help, I\'m just a message away! 😊';

    if (msg.contains('who are you') || msg.contains('what are you') || msg.contains('who made'))
      return 'I\'m **Aptix** — your AI Aptitude Mentor on the **Aptitude GO** platform! 🧠 I\'m here to help you practice aptitude tests, learn concepts, and prepare for campus placements. Ask me anything about the platform or specific aptitude topics!';

    if (msg.contains('bye') || msg.contains('goodbye'))
      return 'Goodbye! Keep practicing and good luck with your placements! 🎯 Come back anytime you need help! 😊';

    // ── Off-topic check: refuse non-platform questions ──
    final offTopic = [
      'movie', 'song', 'music', 'dance', 'game', 'sports', 'cricket', 'football',
      'recipe', 'cook', 'food', 'weather', 'capital of', 'who is', 'history of',
      'joke', 'story', 'funny', 'horoscope', 'astrology', 'love', 'girlfriend',
      'boyfriend', 'relationship', 'politics', 'religion', 'god', 'party',
      'travel', 'tourism', 'fashion', 'shopping', 'price of', 'news',
      'what is the meaning of life', 'tell me a', 'make me', 'write a poem',
      'translate', 'how to hack', 'crack', 'cheat',
    ];
    for (final keyword in offTopic) {
      if (msg.contains(keyword)) {
        return 'I\'m designed only to assist you with the Aptitude GO platform and improving your aptitude skills. 🤖\n\nI can help you with:\n• Practice tests and study tips\n• Aptitude concepts (Quant, Logical, Verbal, etc.)\n• Campus placement preparation\n• How to use app features\n\nPlease ask me something related to the platform! 😊';
      }
    }

    // ── Default: guide the user ──
    return 'I\'m here to help you master aptitude skills on Aptitude GO! 🚀\n\nTry asking me about:\n• "Can I get placement from this app?"\n• "How to use this platform?"\n• "Tips to improve my score"\n• "What is Quantitative Aptitude?"\n• "How does the Store work?"\n• "Tell me about events and contests"\n\nWhat would you like to know? 😊';
  }
}
