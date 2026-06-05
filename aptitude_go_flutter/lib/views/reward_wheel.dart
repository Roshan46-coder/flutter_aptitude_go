import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../core/api_client.dart';
import '../core/hive_database.dart';
import '../core/theme.dart';

class RewardWheelScreen extends StatefulWidget {
  const RewardWheelScreen({super.key});

  @override
  State<RewardWheelScreen> createState() => _RewardWheelScreenState();
}

class _RewardWheelScreenState extends State<RewardWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late Animation<double> _animation;
  
  bool _isSpinning = false;
  bool _hasSpun = false;
  String _statusText = "Tap Spin to try your luck! 🍀";
  
  // List of reward slices (matches Django reward segment index exactly)
  // 0: +2 Life, 1: 20 Coins, 2: 30 Coins, 3: 50 Coins, 4: Golden Frame, 5: +1 Life
  final List<Map<String, dynamic>> _rewards = [
    {'name': '+2 Life', 'color': const Color(0xFFFFF9DB), 'icon_str': '❤️'},
    {'name': '20 Coins', 'color': const Color(0xFFFFFDE7), 'icon_str': '💰'},
    {'name': '30 Coins', 'color': const Color(0xFFFFF9DB), 'icon_str': '💰'},
    {'name': '50 Coins', 'color': const Color(0xFFFFFDE7), 'icon_str': '💰'},
    {'name': 'Golden Frame', 'color': const Color(0xFFFFF9DB), 'icon_str': '🖼️'},
    {'name': '+1 Life', 'color': const Color(0xFFFFFDE7), 'icon_str': '❤️'},
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    
    _animation = CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _startSpin() async {
    if (_isSpinning || _hasSpun) return;

    setState(() {
      _isSpinning = true;
      _statusText = "Spinning... 🌀";
    });

    final api = Provider.of<ApiClient>(context, listen: false);
    try {
      final response = await api.post('gamification/process-spin/');
      
      if (response.data['success'] == true) {
        final int rewardIndex = response.data['reward_index'] ?? 0;
        final String rewardLabel = response.data['reward_label'] ?? '';
        
        // Calculate rotation angle. Slices are 60 degrees (pi/3 radians).
        // 5-9 full rotations + index target offset.
        final double baseRotations = (5 + Random().nextInt(5)) * 2 * pi;
        final double sliceAngle = 2 * pi / _rewards.length;
        
        // Counted clockwise, so we subtract and subtract half slice to land in center
        final double targetAngle = baseRotations + (2 * pi - (rewardIndex * sliceAngle + sliceAngle / 2));

        _animation = Tween<double>(begin: 0.0, end: targetAngle).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeOutCubic),
        );

        _rotationController.reset();
        await _rotationController.forward();

        if (mounted) {
          setState(() {
            _isSpinning = false;
            _hasSpun = true;
            _statusText = "Congratulations! 🎉";
          });

          // Apply reward to user profile
          await HiveDatabase.instance.addUserReward(rewardLabel);

          // Sync user stats
          await api.checkAuthStatus();

          // Show reward popup
          _showRewardDialog(rewardLabel);
        }
      } else {
        setState(() {
          _isSpinning = false;
          _statusText = response.data['error'] ?? "Failed to spin.";
        });
      }
    } catch (_) {
      setState(() {
        _isSpinning = false;
        _statusText = "Connection error. Try again.";
      });
    }
  }

  void _showRewardDialog(String rewardLabel) {
    String type = 'COINS';
    if (rewardLabel.contains('Life')) {
      type = 'LIVES';
    } else if (rewardLabel.contains('Frame')) {
      type = 'FRAME';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Congratulations! 🎉",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating animation style reward display
            Text(
              type == 'LIVES' ? '❤️' : (type == 'FRAME' ? '🖼️' : '💰'),
              style: const TextStyle(fontSize: 70),
            ),
            const SizedBox(height: 16),
            Text(
              "You won $rewardLabel!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              "This reward has been successfully added to your profile.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // return true to refresh parent dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Awesome!", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Lucky Spin"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Gold Gradient Header like Web App
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ).createShader(bounds),
                child: const Text(
                  "Monthly Reward Spin",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 40),
              
              // Spinning wheel visual container
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Rotation animated wheel body
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: SizedBox(
                          width: 320,
                          height: 320,
                          child: CustomPaint(
                            painter: _WheelPainter(slices: _rewards),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Central SPIN button / core pin (Web style)
                  GestureDetector(
                    onTap: (_isSpinning || _hasSpun) ? null : _startSpin,
                    child: Container(
                      width: 85,
                      height: 85,
                      decoration: BoxDecoration(
                        color: _hasSpun ? const Color(0xFFF1F5F9) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                        border: Border.all(
                          color: _hasSpun ? const Color(0xFFE2E8F0) : const Color(0xFFFBBF24),
                          width: 6,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _hasSpun ? "DONE" : "SPIN",
                          style: TextStyle(
                            color: _hasSpun ? const Color(0xFF94A3B8) : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top stopper pin pointer (Web style)
                  Positioned(
                    top: -24,
                    child: SizedBox(
                      width: 40,
                      height: 45,
                      child: CustomPaint(
                        painter: _PointerPainter(),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 50),
              if (_hasSpun)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cardBg,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.divider),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text("Go Back", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw the pointer triangle
class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    
    canvas.drawPath(path.shift(const Offset(0, 4)), Paint()..color = Colors.black38..style = PaintingStyle.fill);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter to draw the reward wheel slices with text and icons
class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;
  _WheelPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sliceAngle = 2 * pi / slices.length;

    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Draw slices
    for (int i = 0; i < slices.length; i++) {
      paint.color = slices[i]['color'] as Color;
      
      // Draw slice arc
      // Slices start from top, shifting by sliceAngle/2 to center the 0th segment
      canvas.drawArc(
        rect,
        i * sliceAngle - pi / 2 - sliceAngle / 2,
        sliceAngle,
        true,
        paint,
      );

      // Draw border lines
      final borderPaint = Paint()
        ..color = const Color(0xFFFBBF24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        rect,
        i * sliceAngle - pi / 2 - sliceAngle / 2,
        sliceAngle,
        true,
        borderPaint,
      );
    }

    // 2. Draw outer golden border
    final outerBorderPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius - 6, outerBorderPaint);

    // 3. Draw text and icons inside slices
    for (int i = 0; i < slices.length; i++) {
      canvas.save();
      
      // Calculate center angle of the slice
      double angle = i * sliceAngle - pi / 2;
      
      // Translate to the middle of the slice's outer part
      double textRadius = radius * 0.65;
      double x = center.dx + textRadius * cos(angle);
      double y = center.dy + textRadius * sin(angle);
      
      canvas.translate(x, y);
      canvas.rotate(angle + pi / 2);
      
      final String iconStr = slices[i]['icon_str'];
      final String textStr = slices[i]['name'];
      
      // Draw emoji icon
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: iconStr,
          style: const TextStyle(fontSize: 22),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconPainter.paint(canvas, Offset(-iconPainter.width / 2, -32));
      
      // Draw text
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: textStr,
          style: const TextStyle(
            color: Color(0xFF92400E), // premium dark amber text
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, 2));
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
