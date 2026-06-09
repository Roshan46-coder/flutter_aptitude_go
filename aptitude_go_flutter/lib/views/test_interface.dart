import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/hive_database.dart';
import 'test_result.dart';

class TestInterfaceScreen extends StatefulWidget {
  final String categorySlug;
  final bool isEvent;
  final int? eventId;

  const TestInterfaceScreen({
    super.key,
    required this.categorySlug,
    this.isEvent = false,
    this.eventId,
  });

  @override
  State<TestInterfaceScreen> createState() => _TestInterfaceScreenState();
}

class _TestInterfaceScreenState extends State<TestInterfaceScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _testData;
  List<dynamic> _questions = [];
  bool _isLoading = true;
  String? _error;
  bool _examStarted = false;

  int _currentQuestionIndex = 0;
  int _secondsLeft = 60;
  Timer? _timer;

  final Map<int, dynamic> _userAnswers = {};
  final _codeController = TextEditingController();

  int _cheatAttempts = 0;

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSub;
  double _currentNoise = 0;
  bool _noisePermissionGranted = false;
  bool _noiseMeterActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTestQuestions();
    _initNoiseMeter();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _codeController.dispose();
    _noiseSub?.cancel();
    super.dispose();
  }

  Future<void> _initNoiseMeter() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() => _noisePermissionGranted = true);
    }
  }

  void _startNoiseMonitoring() {
    if (!_noisePermissionGranted || _noiseMeterActive) return;
    try {
      _noiseMeterActive = true;
      _noiseMeter = NoiseMeter();
      _noiseSub = _noiseMeter!.noise.listen(
        (noise) {
          if (!mounted) return;
          double db = max(noise.maxDecibel, noise.meanDecibel);
          if (db.isFinite && db > 0) {
            setState(() => _currentNoise = db.clamp(0, 120));
            if (db > 78) {
              _handleMalpracticeDetected();
            }
          }
        },
        onError: (e) {
          debugPrint("NoiseMeter error: $e");
          _noiseMeterActive = false;
        },
        onDone: () {
          _noiseMeterActive = false;
        },
      );
    } catch (e) {
      debugPrint("Failed to start noise meter: $e");
      _noiseMeterActive = false;
    }
  }

  void _stopNoiseMonitoring() {
    _noiseSub?.cancel();
    _noiseMeterActive = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _handleMalpracticeDetected();
    }
  }

  void _handleMalpracticeDetected() {
    _cheatAttempts++;
    if (_cheatAttempts >= 2) {
      _timer?.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Malpractice Disqualification"),
          content: const Text("You have switched away from the testing window multiple times. This test is being automatically submitted."),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitQuiz(autoSubmit: true);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("WARNING: Switching apps or closing the window is prohibited! The test will auto-forfeit next time."),
          backgroundColor: AppTheme.livesRed,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadTestQuestions() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      if (widget.isEvent) {
        final response = await api.get('events/${widget.eventId}/');
        if (mounted) {
          final raw = response.data;
          final rawQuestions = raw['questions'] as List<dynamic>? ?? [];

          // Check if user is not registered (no questions and not registered)
          final registration = raw['registration'] as Map<String, dynamic>?;
          final isRegistered = registration?['is_registered'] as bool? ?? false;
          final isCompleted = registration?['is_completed'] as bool? ?? false;

          final List<dynamic> mappedQuestions = rawQuestions.map((q) {
            return {
              'id': q['id'],
              'text': q['text'],
              'time_limit': 60,
              'is_coding': false,
              'marks': q['marks'] ?? 1,
              'options': [
                {'id': 'A', 'text': q['option_a']},
                {'id': 'B', 'text': q['option_b']},
                {'id': 'C', 'text': q['option_c']},
                {'id': 'D', 'text': q['option_d']},
              ]
            };
          }).toList();
          final seenEvent = <int>{};
          mappedQuestions.retainWhere((q) => seenEvent.add(q['id'] as int));

          String? err;
          if (mappedQuestions.isEmpty) {
            if (!isRegistered) {
              err = "You are not registered for this exam. Please join with the correct code.";
            } else if (isCompleted) {
              err = "You have already completed this exam.";
            } else {
              err = "This exam has no questions yet.";
            }
          }

          setState(() {
            _testData = raw;
            _questions = mappedQuestions;
            _isLoading = false;
            _error = err;
          });

          if (_questions.isNotEmpty) {
            _precacheQuestionImages(api.baseUrl);
            _showStartDialog();
          }
        }
      } else {
        final response = await api.get('tests/practice/${widget.categorySlug}/');
        if (mounted) {
          List<dynamic> allQuestions = response.data['questions'] ?? [];
          allQuestions = List.from(allQuestions);
          final seenPractice = <int>{};
          allQuestions.retainWhere((q) => seenPractice.add(q['id'] as int));
          allQuestions.shuffle(Random());

          const int maxQuestions = 20;
          if (allQuestions.length > maxQuestions) {
            allQuestions = allQuestions.sublist(0, maxQuestions);
          }

          setState(() {
            _testData = response.data;
            _questions = allQuestions;
            _isLoading = false;
            _error = _questions.isEmpty ? "No questions found in this category." : null;
          });

          if (_questions.isNotEmpty) {
            _precacheQuestionImages(api.baseUrl);
            _showStartDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Could not start test. Check your internet connection.";
          _isLoading = false;
        });
      }
    }
  }

  void _precacheQuestionImages(String apiBaseUrl) {
    final imgRegex = RegExp(r"""<img\s+[^>]*src=["']([^"']+)["'][^>]*>""", caseSensitive: false);
    for (final q in _questions) {
      final text = q['text'] as String? ?? '';
      for (final match in imgRegex.allMatches(text)) {
        final src = match.group(1);
        if (src == null) continue;
        final url = () {
          if (src.startsWith('http://') || src.startsWith('https://')) return src;
          final idx = apiBaseUrl.indexOf('/api/');
          final djangoBase = idx != -1 ? apiBaseUrl.substring(0, idx) : apiBaseUrl;
          if (src.startsWith('/media/') || src.startsWith('media/')) {
            final cleanSrc = src.startsWith('/') ? src : '/$src';
            return '$djangoBase$cleanSrc';
          }
          var cleanSrc = src;
          if (cleanSrc.startsWith('/images/')) {
            cleanSrc = cleanSrc.replaceFirst('/images/', '');
          } else if (cleanSrc.startsWith('images/')) {
            cleanSrc = cleanSrc.replaceFirst('images/', '');
          } else if (cleanSrc.startsWith('/')) {
            cleanSrc = cleanSrc.substring(1);
          }
          return '$djangoBase/media/question_images/$cleanSrc';
        }();
        precacheImage(NetworkImage(url), context);
      }
    }
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.quiz_outlined, color: AppTheme.neonPurple, size: 28),
            const SizedBox(width: 10),
            const Text("Ready to Begin?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              widget.isEvent
                  ?               "Exam: ${_testData?['event']?['title'] ?? 'Private Exam'}"
                  : "Category: ${_testData?['category']?['name'] ?? widget.categorySlug}",
              style: TextStyle(fontSize: 14, color: context.onSurface.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 6),
            Text(
              "Questions: ${_questions.length}",
              style: TextStyle(fontSize: 14, color: context.onSurface.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 6),
            Text(
              "Time per question: 60 seconds",
              style: TextStyle(fontSize: 14, color: context.onSurface.withValues(alpha: 0.70)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.neonPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.neonPurple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Switching apps or loud noise will be flagged. Two violations will auto-submit your test.",
                      style: TextStyle(fontSize: 12, color: context.onSurface.withValues(alpha: 0.54)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Cancel", style: TextStyle(color: context.onSurface.withValues(alpha: 0.38))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startExam();
            },
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text("Start Exam"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonPurple,
              foregroundColor: context.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _startExam() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await HiveDatabase.instance.checkAndRestoreLives();
    final freshUser = HiveDatabase.instance.getCurrentUser();
    if (freshUser != null) {
      api.updateCurrentUser({'lives': freshUser['lives'], 'last_life_reset_date': freshUser['last_life_reset_date']});
      final lives = (freshUser['lives'] as num?)?.toInt() ?? 0;
      debugPrint("💙 Exam start: user has $lives lives");
    }
    setState(() => _examStarted = true);
    _startNoiseMonitoring();
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    final currentQ = _questions[_currentQuestionIndex];

    setState(() {
      _secondsLeft = currentQ['time_limit'] ?? 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
        } else {
          _saveCurrentAnswer();
          _nextQuestion();
        }
      });
    });
  }

  void _saveCurrentAnswer() {
    if (_questions.isEmpty) return;
    final currentQ = _questions[_currentQuestionIndex];
    final qId = currentQ['id'] as int;
    final isCoding = currentQ['is_coding'] as bool;

    if (isCoding) {
      _userAnswers[qId] = _codeController.text.trim();
    }
  }

  void _nextQuestion() {
    _saveCurrentAnswer();

    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    if (!isLastQuestion) {
      setState(() {
        _currentQuestionIndex++;
        _codeController.clear();
        final qId = _questions[_currentQuestionIndex]['id'] as int;
        if (_userAnswers.containsKey(qId) && _questions[_currentQuestionIndex]['is_coding']) {
          _codeController.text = _userAnswers[qId] ?? '';
        }
      });
      _startQuestionTimer();
    } else {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz({bool autoSubmit = false}) async {
    _timer?.cancel();
    _saveCurrentAnswer();
    _stopNoiseMonitoring();

    if (widget.isEvent) {
      setState(() => _isLoading = true);
      final api = Provider.of<ApiClient>(context, listen: false);
      try {
        // Convert int keys → string keys so backend's answers.get(str(q.id)) works reliably
        final Map<String, dynamic> stringKeyedAnswers = {
          for (final entry in _userAnswers.entries)
            entry.key.toString(): entry.value,
        };
        final res = await api.post('events/${widget.eventId}/submit/', data: {
          'answers': stringKeyedAnswers,
        });
        if (mounted) {
          final score = (res.data['score'] as num?)?.toInt() ?? 0;
          final totalMarks = _questions.fold<int>(0, (sum, q) => sum + ((q['marks'] as int?) ?? 1));

          final resultData = {
            'score': score.toString(),
            'correct': score,
            'total': totalMarks,
            'coins_earned': 0,
            'exp_earned': 0,
            'leveled_up': false,
            'new_level': 1,
            'category': widget.categorySlug,
            'message': 'Event exam completed successfully',
            'results': <Map<String, dynamic>>[],
          };
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TestResultScreen(resultData: resultData),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit event exam: ${e.toString()}'), backgroundColor: AppTheme.livesRed),
          );
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    int correct = 0;
    int total = 0;
    final List<Map<String, dynamic>> resultsList = [];

    for (final q in _questions) {
      final qId = q['id'] as int;
      final isCoding = q['is_coding'] == true;
      final questionText = q['text'] as String? ?? '';
      final explanation = q['explanation'] as String? ?? '';

      if (isCoding) {
        final userAnswer = _userAnswers[qId] as String?;
        resultsList.add({
          'is_coding': true,
          'is_correct': false,
          'question_text': questionText,
          'user_code': userAnswer ?? '',
          'explanation': explanation,
        });
      } else {
        total++;
        final correctIdx = q['correct_index'] as int? ?? -1;
        final options = q['options'] as List<dynamic>? ?? [];

        Map<String, dynamic>? correctOption;
        if (correctIdx >= 0 && correctIdx < options.length) {
          correctOption = Map<String, dynamic>.from(options[correctIdx] as Map);
        }

        final userAnswerId = _userAnswers[qId] as int?;
        Map<String, dynamic>? selectedOption;
        if (userAnswerId != null) {
          for (final opt in options) {
            if (opt['id'] == userAnswerId) {
              selectedOption = Map<String, dynamic>.from(opt as Map);
              break;
            }
          }
        }

        final isCorrect = selectedOption != null && correctOption != null && selectedOption['id'] == correctOption['id'];
        if (isCorrect) {
          correct++;
        }

        resultsList.add({
          'is_coding': false,
          'is_correct': isCorrect,
          'question_text': questionText,
          'selected_option': selectedOption,
          'correct_option': correctOption,
          'explanation': explanation,
        });
      }
    }

    final coinsEarned = correct * 10;
    final expEarned = correct * 20;
    final score = total > 0 ? (correct / total) : 0.0;

    final api = Provider.of<ApiClient>(context, listen: false);
    final currentExp = (api.currentUser?['exp'] as num?)?.toInt() ?? 0;
    final currentLevel = (api.currentUser?['level'] as num?)?.toInt() ?? 1;
    final currentCoins = (api.currentUser?['coins'] as num?)?.toInt() ?? 0;
    final currentLives = (api.currentUser?['lives'] as num?)?.toInt() ?? 5;

    final newExp = currentExp + expEarned;
    final newLevel = HiveDatabase.levelInfo(newExp)[0];
    final leveledUp = newLevel > currentLevel;
    final newCoins = currentCoins + coinsEarned;
    final newLives = currentLives > 0 ? currentLives - 1 : 0;

    api.updateUserStats(
      coins: newCoins,
      exp: newExp,
      level: newLevel,
      lives: newLives,
    );

    await _saveAttemptLocally(
      correct: correct,
      total: total,
      slug: widget.categorySlug,
    );

    final resultData = {
      'score': score.toStringAsFixed(2),
      'correct': correct,
      'total': total,
      'coins_earned': coinsEarned,
      'exp_earned': expEarned,
      'leveled_up': leveledUp,
      'new_level': newLevel,
      'category': widget.categorySlug,
      'message': 'Test submitted successfully',
      'results': resultsList,
    };

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultScreen(resultData: resultData),
        ),
      );
    }

    _submitResultToApi(
      autoSubmit,
      coinsEarned: coinsEarned,
      expEarned: expEarned,
      newLevel: newLevel,
      newLives: newLives,
      currentCoins: currentCoins,
      currentExp: currentExp,
    );
  }

  Future<void> _saveAttemptLocally({
    required int correct,
    required int total,
    required String slug,
  }) async {
    try {
      final catName = _testData?['category']?['name'] as String? ?? slug;
      final now = DateTime.now().toIso8601String();
      final percentage = total > 0 ? double.parse(((correct / total) * 100).toStringAsFixed(1)) : 0.0;
      await HiveDatabase.instance.addAttempt({
        'score': correct,
        'total_questions': total,
        'percentage': percentage,
        'category_name': catName,
        'completed_at': now,
      });
    } catch (e) {
      debugPrint("Failed to save attempt locally: $e");
    }
  }

  void _submitResultToApi(
    bool autoSubmit, {
    required int coinsEarned,
    required int expEarned,
    required int newLevel,
    required int newLives,
    required int currentCoins,
    required int currentExp,
  }) {
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      api.dio.post('tests/submit/', data: {
        'answers': autoSubmit ? {} : _userAnswers,
        'category_slug': widget.categorySlug,
        'question_ids': _questions.map((q) => q['id'] as int).toList(),
      }).then((response) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          final serverCoins = (data['coins_earned'] as num?)?.toInt() ?? coinsEarned;
          final serverExp = (data['exp_earned'] as num?)?.toInt() ?? expEarned;
          final serverLevel = (data['new_level'] as num?)?.toInt() ?? newLevel;
          final serverLives = (data['lives_remaining'] as num?)?.toInt() ?? newLives;
          final serverCoinsTotal = currentCoins + serverCoins;
          final serverExpTotal = currentExp + serverExp;
          api.updateUserStats(
            coins: serverCoinsTotal,
            exp: serverExpTotal,
            level: serverLevel,
            lives: serverLives,
          );
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  List<InlineSpan> _buildQuestionSpans(String text, String apiBaseUrl) {
    final spans = <InlineSpan>[];
    final cleanedText = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    final imgRegex = RegExp(r"""<img\s+[^>]*src=["']([^"']+)["'][^>]*>""", caseSensitive: false);
    int lastEnd = 0;

    for (final match in imgRegex.allMatches(cleanedText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: cleanedText.substring(lastEnd, match.start)));
      }
      final src = match.group(1);
      if (src != null) {
        final filename = () {
          var s = src;
          final lastSlash = s.lastIndexOf('/');
          if (lastSlash != -1) {
            s = s.substring(lastSlash + 1);
          }
          return s;
        }();

        final url = () {
          if (src.startsWith('http://') || src.startsWith('https://')) {
            return src;
          }
          final idx = apiBaseUrl.indexOf('/api/');
          final djangoBase = idx != -1 ? apiBaseUrl.substring(0, idx) : apiBaseUrl;

          if (src.startsWith('/media/') || src.startsWith('media/')) {
            final cleanSrc = src.startsWith('/') ? src : '/$src';
            return '$djangoBase$cleanSrc';
          }

          var cleanSrc = src;
          if (cleanSrc.startsWith('/images/')) {
            cleanSrc = cleanSrc.replaceFirst('/images/', '');
          } else if (cleanSrc.startsWith('images/')) {
            cleanSrc = cleanSrc.replaceFirst('images/', '');
          } else if (cleanSrc.startsWith('/')) {
            cleanSrc = cleanSrc.substring(1);
          }

          return '$djangoBase/media/question_images/$cleanSrc';
        }();

        final isSvg = filename.toLowerCase().endsWith('.svg');
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: isSvg
                ? _SvgImage(
                    assetPath: 'assets/images/$filename',
                    url: url,
                    height: 120,
                  )
                : Image.network(
                    url,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, e, st) => Image.asset(
                      'assets/images/$filename',
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx2, e2, st2) => Container(
                        height: 120,
                        alignment: Alignment.center,
                        child: Icon(Icons.image_outlined, color: context.onSurface.withValues(alpha: 0.24), size: 40),
                      ),
                    ),
                  ),
          ),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < cleanedText.length) {
      spans.add(TextSpan(text: cleanedText.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: cleanedText));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonPurple)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEvent
              ? (_testData?['event']?['title'] ?? 'Private Exam')
              : 'Practice Test'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPurple),
                  child: const Text("Go Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_examStarted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.neonPurple),
              const SizedBox(height: 16),
              Text(
                "Preparing ${_questions.length} questions...",
                style: TextStyle(color: context.onSurface.withValues(alpha: 0.54), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final currentQ = _questions[_currentQuestionIndex];
    final isCoding = currentQ['is_coding'] as bool;
    final int qId = currentQ['id'];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    final noiseLevel = _currentNoise.isFinite ? (_currentNoise / 100.0).clamp(0.0, 1.0) : 0.0;
    final isNoiseHigh = _currentNoise > 68;

    final apiBaseUrl = () {
      try {
        final api = Provider.of<ApiClient>(context, listen: false);
        return api.baseUrl;
      } catch (_) {}
      return 'http://localhost:8000/api/';
    }();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Quit Test?"),
            content: const Text("Exiting this test will lose your progress and cost you 1 life. Are you sure?"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Resume")),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Quit")),
            ],
          ),
        );
        if ((confirm ?? false) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEvent
                ? (_testData?['event']?['title'] ?? 'Exam')
                : (_testData?['category']?['name'] ?? 'Test'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_noisePermissionGranted)
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Center(
                  child: Tooltip(
                    message: "Noise level${isNoiseHigh ? ' - Too loud!' : ''}",
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNoiseHigh ? AppTheme.livesRed.withValues(alpha: 0.15) : Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isNoiseHigh ? AppTheme.livesRed : context.onSurface.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNoiseHigh ? Icons.mic_off : Icons.mic,
                            size: 14,
                            color: isNoiseHigh ? AppTheme.livesRed : context.onSurface.withValues(alpha: 0.54),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 36,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: noiseLevel,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isNoiseHigh ? AppTheme.livesRed : AppTheme.neonPurple,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _secondsLeft <= 10 ? AppTheme.livesRed.withValues(alpha: 0.15) : context.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _secondsLeft <= 10 ? AppTheme.livesRed : context.onSurface.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: _secondsLeft <= 10 ? AppTheme.livesRed : context.onSurface.withValues(alpha: 0.60)),
                      const SizedBox(width: 4),
                      Text(
                        "$_secondsLeft s",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _secondsLeft <= 10 ? AppTheme.livesRed : context.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonPurple),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
                  style: TextStyle(fontSize: 12, color: context.onSurface.withValues(alpha: 0.30)),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, color: context.onSurface),
                              children: _buildQuestionSpans(currentQ['text'] ?? '', apiBaseUrl),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (isCoding)
                        _buildCodingInputField()
                      else
                        _buildMCQOptions(currentQ['options'], qId),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLastQuestion ? AppTheme.emeraldGreen : AppTheme.neonPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLastQuestion ? "Submit" : "Next",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastQuestion ? Icons.check_circle_outline : Icons.arrow_forward_ios,
                              size: 18,
                              color: context.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMCQOptions(List<dynamic> options, int qId) {
    final selectedOptionId = _userAnswers[qId];

    return Column(
      children: options.map((opt) {
        final isSelected = selectedOptionId == opt['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonPurple.withValues(alpha: 0.08) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.neonPurple : Theme.of(context).dividerColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: RadioListTile<dynamic>(
            value: opt['id'],
            groupValue: selectedOptionId,
            onChanged: (val) {
              setState(() {
                _userAnswers[qId] = val;
              });
            },
            title: Text(
              opt['text'] ?? '',
              style: TextStyle(fontSize: 14, color: context.onSurface),
            ),
            activeColor: AppTheme.neonPurple,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCodingInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Type your code answer below:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.onSurface.withValues(alpha: 0.70)),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _codeController,
          maxLines: 8,
          style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: context.onSurface),
          decoration: InputDecoration(
            hintText: "def solve(n):\n    # Type code here...",
            fillColor: Theme.of(context).colorScheme.surface,
          ),
        ),
      ],
    );
  }
}

// ─── Reliable SVG image widget for Flutter Web ───────────────────────────────
// Uses rootBundle.loadString + SvgPicture.string so the SVG data is read
// directly from the bundled assets without any HTTP request, which avoids
// CORS issues entirely when the app runs in a browser.
class _SvgImage extends StatelessWidget {
  final String assetPath;
  final String url;
  final double height;

  const _SvgImage({
    required this.assetPath,
    required this.url,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // On web, <img> tag renders SVGs natively — bypasses Kaspersky fetch hook
    if (kIsWeb) {
      return Image.network(
        url,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (ctx, e, st) => Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (ctx2, e2, st2) => SizedBox(
            height: height,
            child: Center(
              child: Icon(Icons.image_outlined, color: context.onSurface.withValues(alpha: 0.24), size: 40),
            ),
          ),
        ),
      );
    }

    // Mobile: try bundled asset first, then network
    return _MobileSvgImage(assetPath: assetPath, url: url, height: height);
  }
}

class _MobileSvgImage extends StatefulWidget {
  final String assetPath;
  final String url;
  final double height;

  const _MobileSvgImage({
    required this.assetPath,
    required this.url,
    required this.height,
  });

  @override
  State<_MobileSvgImage> createState() => _MobileSvgImageState();
}

class _MobileSvgImageState extends State<_MobileSvgImage> {
  late Future<String?> _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadFromAssets();
  }

  Future<String?> _loadFromAssets() async {
    try {
      return await rootBundle.loadString(widget.assetPath);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _svgFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return SvgPicture.string(
            snapshot.data!,
            height: widget.height,
            fit: BoxFit.contain,
          );
        }

        return SvgPicture.network(
          widget.url,
          height: widget.height,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => SizedBox(
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.neonPurple),
            ),
          ),
        );
      },
    );
  }
}
