import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'game_room_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String difficulty;

  const MatchmakingScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.difficulty,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with TickerProviderStateMixin {
  WebSocketChannel? _channel;
  String _status = 'searching';
  int _searchTime = 0;
  Timer? _searchTimer;

  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startSearchTimer();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _searchTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _startSearchTimer() {
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => _searchTime++);
    });
  }

  void _connectWebSocket() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    final wsUrl = api.wsBaseUrl;
    final cookie = await api.getSessionCookie();

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/matchmaking/?category=${widget.categoryId}&difficulty=${widget.difficulty}'),
        protocols: cookie != null ? ['sessionid=$cookie'] : null,
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message as String);
          _handleWsMessage(data);
        },
        onError: (err) {
          if (mounted) setState(() => _status = 'error');
        },
        onDone: () {
          if (mounted && _status == 'searching') setState(() => _status = 'error');
        },
      );
    } catch (e) {
      if (mounted) setState(() => _status = 'error');
    }
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'match_found':
        _searchTimer?.cancel();
        _pulseController.stop();
        _rotateController.stop();
        final roomId = data['room_id'] as String?;
        if (mounted && roomId != null) {
          setState(() => _status = 'matched');
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => GameRoomScreen(
                    roomId: roomId,
                    categoryName: widget.categoryName,
                    opponentName: data['opponent'] as String? ?? 'Opponent',
                  ),
                ),
              );
            }
          });
        }
        break;
      case 'waiting':
        if (mounted) setState(() => _status = 'searching');
        break;
      case 'error':
        if (mounted) setState(() => _status = 'error');
        break;
    }
  }

  void _cancelSearch() {
    _channel?.sink.close();
    _searchTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding Match'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelSearch,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Topic badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${widget.categoryName} · ${widget.difficulty}',
                  style: const TextStyle(color: AppTheme.neonPurple, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 48),

              // Animated radar
              if (_status == 'searching') _buildSearchingAnimation(),
              if (_status == 'matched') _buildMatchedAnimation(),
              if (_status == 'error') _buildErrorState(),

              const SizedBox(height: 40),

              // Status text
              if (_status == 'searching') ...[
                const Text(
                  'Searching for an opponent...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatSearchTime(_searchTime),
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: _cancelSearch,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
              ],

              if (_status == 'matched')
                const Text(
                  'Opponent Found! Starting...',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                ),

              if (_status == 'error') ...[
                const Text(
                  'Connection Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.livesRed),
                ),
                const SizedBox(height: 8),
                const Text('Could not connect to matchmaking.', style: TextStyle(color: Colors.white38)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() { _status = 'searching'; _searchTime = 0; });
                    _startSearchTimer();
                    _connectWebSocket();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingAnimation() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating ring 1
          RotationTransition(
            turns: _rotateController,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.15), width: 2),
              ),
            ),
          ),
          // Rotating ring 2 (opposite)
          RotationTransition(
            turns: Tween<double>(begin: 1, end: 0).animate(_rotateController),
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.neonBlue.withValues(alpha: 0.2), width: 1.5),
              ),
            ),
          ),
          // Center pulsing icon
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonPurple.withValues(alpha: 0.1),
                border: Border.all(color: AppTheme.neonPurple.withValues(alpha: 0.4), width: 2),
                boxShadow: [BoxShadow(color: AppTheme.neonPurple.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 4)],
              ),
              child: const Icon(Icons.search_rounded, color: AppTheme.neonPurple, size: 40),
            ),
          ),
          // Radar dot
          RotationTransition(
            turns: _rotateController,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonPurple,
                  boxShadow: [BoxShadow(color: AppTheme.neonPurple, blurRadius: 8, spreadRadius: 2)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.emeraldGreen.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.emeraldGreen, width: 2),
        boxShadow: [BoxShadow(color: AppTheme.emeraldGreen.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 6)],
      ),
      child: const Icon(Icons.check_rounded, color: AppTheme.emeraldGreen, size: 60),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.livesRed.withValues(alpha: 0.1),
        border: Border.all(color: AppTheme.livesRed.withValues(alpha: 0.4), width: 2),
      ),
      child: const Icon(Icons.wifi_off_rounded, color: AppTheme.livesRed, size: 50),
    );
  }

  String _formatSearchTime(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s elapsed';
  }
}
