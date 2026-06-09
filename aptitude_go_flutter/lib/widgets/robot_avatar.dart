import 'package:flutter/material.dart';
import '../core/theme.dart';

class RobotAvatar extends StatefulWidget {
  final double size;
  final Color accentColor;
  final bool autoAnimate;

  const RobotAvatar({
    super.key,
    this.size = 48,
    this.accentColor = AppTheme.neonPurple,
    this.autoAnimate = true,
  });

  @override
  State<RobotAvatar> createState() => _RobotAvatarState();
}

class _RobotAvatarState extends State<RobotAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  bool _eyesOpen = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _floatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.autoAnimate) {
      _controller.repeat();
    }

    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() => _eyesOpen = false);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        setState(() => _eyesOpen = true);
        _startBlinking();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RobotPainter(
                accentColor: widget.accentColor,
                eyesOpen: _eyesOpen,
                isDark: isDark,
                pulseValue: _pulseAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RobotPainter extends CustomPainter {
  final Color accentColor;
  final bool eyesOpen;
  final bool isDark;
  final double pulseValue;

  _RobotPainter({
    required this.accentColor,
    required this.eyesOpen,
    required this.isDark,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final headRadius = radius * 0.75;
    final headCenter = Offset(center.dx, center.dy - radius * 0.05);

    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: FractionalOffset(0.4, 0.3),
        radius: 1.0,
        colors: [
          accentColor.withValues(alpha: 0.85),
          accentColor.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));

    final outlinePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(headCenter, headRadius, bgPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: FractionalOffset(0.5, 0.5),
        radius: 0.6,
        colors: [
          accentColor.withValues(alpha: 0.15 * (pulseValue - 0.9) * 10),
          accentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
          center: headCenter, radius: headRadius * 1.6));

    canvas.drawCircle(headCenter, headRadius * 1.6, glowPaint);

    final antennaY = headCenter.dy - headRadius - 4;
    final antennaPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(headCenter.dx, headCenter.dy - headRadius + 2),
      Offset(headCenter.dx, antennaY),
      antennaPaint,
    );

    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(headCenter.dx, antennaY), 3, ballPaint);

    final faceCenterY = headCenter.dy + headRadius * 0.08;
    final eyeRadius = radius * 0.1;
    final eyeSpacing = radius * 0.22;

    if (eyesOpen) {
      canvas.drawCircle(
        Offset(center.dx - eyeSpacing, faceCenterY),
        eyeRadius,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeSpacing, faceCenterY),
        eyeRadius,
        Paint()..color = Colors.white,
      );

      final pupilRadius = eyeRadius * 0.55;
      canvas.drawCircle(
        Offset(center.dx - eyeSpacing, faceCenterY),
        pupilRadius,
        Paint()..color = const Color(0xFF1A1A2E),
      );
      canvas.drawCircle(
        Offset(center.dx + eyeSpacing, faceCenterY),
        pupilRadius,
        Paint()..color = const Color(0xFF1A1A2E),
      );

      final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
      final hlRadius = pupilRadius * 0.35;
      canvas.drawCircle(
        Offset(center.dx - eyeSpacing - pupilRadius * 0.25, faceCenterY - pupilRadius * 0.25),
        hlRadius,
        highlightPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeSpacing - pupilRadius * 0.25, faceCenterY - pupilRadius * 0.25),
        hlRadius,
        highlightPaint,
      );
    } else {
      final closedEyePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - eyeSpacing - eyeRadius, faceCenterY),
        Offset(center.dx - eyeSpacing + eyeRadius, faceCenterY),
        closedEyePaint,
      );
      canvas.drawLine(
        Offset(center.dx + eyeSpacing - eyeRadius, faceCenterY),
        Offset(center.dx + eyeSpacing + eyeRadius, faceCenterY),
        closedEyePaint,
      );
    }

    final mouthY = faceCenterY + radius * 0.28;
    final mouthPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    final mouthWidth = radius * 0.25;
    mouthPath.moveTo(center.dx - mouthWidth, mouthY);
    mouthPath.quadraticBezierTo(
      center.dx,
      mouthY + mouthWidth * 0.5,
      center.dx + mouthWidth,
      mouthY,
    );
    canvas.drawPath(mouthPath, mouthPaint);

    final earPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final earRadius = radius * 0.08;
    canvas.drawCircle(
      Offset(headCenter.dx - headRadius + 2, headCenter.dy),
      earRadius,
      earPaint,
    );
    canvas.drawCircle(
      Offset(headCenter.dx + headRadius - 2, headCenter.dy),
      earRadius,
      earPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RobotPainter oldDelegate) =>
      oldDelegate.eyesOpen != eyesOpen ||
      oldDelegate.pulseValue != pulseValue ||
      oldDelegate.isDark != isDark;
}
