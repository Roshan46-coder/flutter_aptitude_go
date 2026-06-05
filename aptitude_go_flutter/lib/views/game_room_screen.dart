import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

enum GameState { countdown, question, result, finished }

class GameRoomScreen extends StatefulWidget {
  final String roomId;
  final String categoryName;
  final String opponentName;

  const GameRoomScreen({
    super.key,
    required this.roomId,
    required this.categoryName,
    required this.opponentName,
  });

  @override
  State<GameRoomScreen> createState() => _GameRoomScreenState();
}

class _GameRoomScreenState extends State<GameRoomScreen>
    with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  GameState _gameState = GameState.countdown;

  // Game data
  Map<String, dynamic>? _currentQuestion;
  int _questionIndex = 0;
  int _totalQuestions = 10;
  int _myScore = 0;
  int _opponentScore = 0;
  int? _selectedAnswer;
  int? _correctAnswer;
  bool _answered = false;
  String? _roundResult; // 'win', 'lose', 'tie'

  // Timer
  int _timeLeft = 15;
  Timer? _questionTimer;

  // Countdown
  int _countdown = 3;
  Timer? _countdownTimer;

  // Animations
  late AnimationController _scoreAnimController;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnim;

  // Players
  String _myUsername = '';

  @override
  void initState() {
    super.initState();
    _scoreAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _feedbackController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _feedbackAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );

    _connectWebSocket();
    _startCountdown();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    _scoreAnimController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _countdown--);
        if (_countdown <= 0) {
          t.cancel();
          setState(() => _gameState = GameState.question);
        }
      }
    });
  }

  void _connectWebSocket() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    _myUsername = api.currentUser?['username'] ?? '';
    final wsUrl = api.wsBaseUrl;
    final cookie = await api.getSessionCookie();

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/game/${widget.roomId}/'),
        protocols: cookie != null ? ['sessionid=$cookie'] : null,
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String);
          _handleWsMessage(data);
        },
        onError: (_) {},
        onDone: () {
          if (mounted && _gameState != GameState.finished) {
            _showDisconnectionDialog();
          }
        },
      );
    } catch (_) {}
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'new_question':
        _questionTimer?.cancel();
        if (mounted) {
          setState(() {
            _currentQuestion = data['question'];
            _questionIndex = (data['question_index'] as num?)?.toInt() ?? _questionIndex;
            _totalQuestions = (data['total_questions'] as num?)?.toInt() ?? _totalQuestions;
            _selectedAnswer = null;
            _correctAnswer = null;
            _answered = false;
            _timeLeft = 15;
            _gameState = GameState.question;
            _roundResult = null;
          });
          _startQuestionTimer();
        }
        break;

      case 'score_update':
        if (mounted) {
          final scores = data['scores'] as Map<String, dynamic>? ?? {};
          setState(() {
            _myScore = (scores[_myUsername] as num?)?.toInt() ?? _myScore;
            _opponentScore = (scores[widget.opponentName] as num?)?.toInt() ?? _opponentScore;
            _correctAnswer = (data['correct_answer'] as num?)?.toInt();
            _gameState = GameState.result;
          });
          if (data['winner_this_round'] != null) {
            final winner = data['winner_this_round'] as String;
            setState(() => _roundResult = winner == _myUsername ? 'win' : winner == 'tie' ? 'tie' : 'lose');
          }
          _feedbackController.forward(from: 0);
        }
        break;

      case 'game_over':
        _questionTimer?.cancel();
        if (mounted) {
          final finalScores = data['scores'] as Map<String, dynamic>? ?? {};
          final winner = data['winner'] as String?;
          setState(() {
            _myScore = (finalScores[_myUsername] as num?)?.toInt() ?? _myScore;
            _opponentScore = (finalScores[widget.opponentName] as num?)?.toInt() ?? _opponentScore;
            _gameState = GameState.finished;
          });
          _showGameOverDialog(winner);
        }
        break;

      case 'opponent_answered':
        // Optional: show indicator that opponent answered
        break;
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) {
          t.cancel();
          if (!_answered) _submitAnswer(-1); // timeout
        }
      }
    });
  }

  void _submitAnswer(int answerIndex) {
    if (_answered) return;
    setState(() { _selectedAnswer = answerIndex; _answered = true; });
    _questionTimer?.cancel();
    _channel?.sink.add(jsonEncode({
      'type': 'submit_answer',
      'answer': answerIndex,
      'time_taken': 15 - _timeLeft,
    }));
  }

  void _showDisconnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnected'),
        content: const Text('Your opponent disconnected. You win by default!'),
        actions: [
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('Back to Menu'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(String? winner) {
    final iWon = winner == _myUsername;
    final isTie = winner == 'tie' || winner == null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTie ? '🤝 Draw!' : iWon ? '🏆 You Win!' : '💀 You Lost!',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _finalScore('You', _myScore, iWon ? AppTheme.goldAccent : Colors.white54),
                const Text('VS', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                _finalScore(widget.opponentName, _opponentScore, !iWon && !isTie ? AppTheme.goldAccent : Colors.white54),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finalScore(String name, int score, Color color) {
    return Column(
      children: [
        Text('$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        Text(name, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: _gameState == GameState.countdown
              ? _buildCountdown()
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _gameState == GameState.question || _gameState == GameState.result
                          ? _buildQuestionView()
                          : const SizedBox(),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Get Ready!', style: TextStyle(fontSize: 24, color: Colors.white54)),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '$_countdown',
              key: ValueKey(_countdown),
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: AppTheme.neonPurple),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.categoryName, style: const TextStyle(color: Colors.white30)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final progress = _totalQuestions > 0 ? _questionIndex / _totalQuestions : 0.0;
    final timerFraction = _timeLeft / 15;
    final timerColor = _timeLeft > 8
        ? AppTheme.emeraldGreen
        : _timeLeft > 4 ? AppTheme.goldAccent : AppTheme.livesRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          // Score row
          Row(
            children: [
              Expanded(child: _playerScore('You', _myScore, true)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_timeLeft',
                      style: TextStyle(color: timerColor, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Text('sec', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
              Expanded(child: _playerScore(widget.opponentName, _opponentScore, false)),
            ],
          ),
          const SizedBox(height: 12),
          // Question progress
          Row(
            children: [
              Text('Q${_questionIndex + 1}/$_totalQuestions',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.divider,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.neonPurple),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              // Timer bar
              SizedBox(
                width: 60,
                child: LinearProgressIndicator(
                  value: timerFraction.clamp(0.0, 1.0),
                  backgroundColor: AppTheme.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playerScore(String name, int score, bool isMe) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          name,
          style: const TextStyle(color: Colors.white38, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$score',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.neonPurple),
        ),
      ],
    );
  }

  Widget _buildQuestionView() {
    final q = _currentQuestion;
    if (q == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.neonPurple));
    }
    final options = (q['options'] as List?)?.cast<String>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round result banner
          if (_gameState == GameState.result && _roundResult != null)
            FadeTransition(
              opacity: _feedbackAnim,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _roundResult == 'win'
                      ? AppTheme.emeraldGreen.withValues(alpha: 0.15)
                      : _roundResult == 'tie'
                          ? AppTheme.goldAccent.withValues(alpha: 0.15)
                          : AppTheme.livesRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _roundResult == 'win'
                        ? AppTheme.emeraldGreen.withValues(alpha: 0.3)
                        : _roundResult == 'tie'
                            ? AppTheme.goldAccent.withValues(alpha: 0.3)
                            : AppTheme.livesRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _roundResult == 'win' ? '✅ Correct! +1' : _roundResult == 'tie' ? '⚡ Tie!' : '❌ Wrong!',
                    style: TextStyle(
                      color: _roundResult == 'win'
                          ? AppTheme.emeraldGreen
                          : _roundResult == 'tie'
                              ? AppTheme.goldAccent
                              : AppTheme.livesRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),

          // Question text
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              q['text'] as String? ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...options.asMap().entries.map((entry) {
            final i = entry.key;
            final opt = entry.value;
            final isSelected = _selectedAnswer == i;
            final isCorrect = _correctAnswer == i;
            final isWrong = _answered && isSelected && _correctAnswer != null && !isCorrect;

            Color borderColor = AppTheme.divider;
            Color bgColor = AppTheme.cardBg;

            if (_answered && _correctAnswer != null) {
              if (isCorrect) { borderColor = AppTheme.emeraldGreen; bgColor = AppTheme.emeraldGreen.withValues(alpha: 0.12); }
              else if (isWrong) { borderColor = AppTheme.livesRed; bgColor = AppTheme.livesRed.withValues(alpha: 0.12); }
            } else if (isSelected) {
              borderColor = AppTheme.neonPurple;
              bgColor = AppTheme.neonPurple.withValues(alpha: 0.12);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _answered ? null : _submitAnswer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: borderColor.withValues(alpha: 0.15),
                          border: Border.all(color: borderColor.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(opt, style: const TextStyle(fontSize: 14, color: Colors.white70))),
                      if (_answered && isCorrect)
                        const Icon(Icons.check_circle, color: AppTheme.emeraldGreen, size: 20),
                      if (isWrong)
                        const Icon(Icons.cancel, color: AppTheme.livesRed, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
