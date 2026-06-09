import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/local_data.dart';
import '../core/email_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _progressBarController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowFade;
  late Animation<double> _progressBarVal;

  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Logo entrance animation (Scale & Fade)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Subtle breathing glow animation
    _glowFade = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Particle animation controller
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Progress bar animation controller
    _progressBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressBarVal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressBarController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Generate floating particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateParticles();
      _startAnimations();
    });
  }

  void _generateParticles() {
    final size = MediaQuery.of(context).size;
    for (int i = 0; i < 25; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble() * size.width,
          y: _random.nextDouble() * size.height,
          size: _random.nextDouble() * 4 + 2,
          speed: _random.nextDouble() * 0.8 + 0.3,
          angle: _random.nextDouble() * 2 * math.pi,
          opacity: _random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  Future<void> _startAnimations() async {
    // Start auth check and background service init in parallel
    final api = Provider.of<ApiClient>(context, listen: false);
    final authFuture = api.initialize();
    final localDataFuture = LocalDataProvider.instance.init();
    final emailFuture = EmailService.instance.init();

    // Start UI animations
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    await _progressBarController.forward();
    
    // Ensure all background tasks are completed before routing
    await Future.wait([authFuture, localDataFuture, emailFuture]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              api.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _progressBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF160A3D), // Extra Dark Purple
                  Color(0xFF2E1065), // Rich Royal Dark Purple
                  Color(0xFF4C1D95), // Deep Amethyst Purple
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Particle Layer
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(particles: _particles, controller: _particleController),
                size: Size.infinite,
              );
            },
          ),

          // Core Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Animated Logo Wrapper
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Neon Soft Glow
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C3BFF).withOpacity(_glowFade.value * 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            // Logo Image
                            Image.asset(
                              'assets/images/app_logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C3BFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.offline_bolt_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                
                // Animated Title & Tagline
                FadeTransition(
                  opacity: _logoFade,
                  child: Column(
                    children: [
                      const Text(
                        "APTITUDE",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Level Up Your Skills",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),

                // XP Style Progress Indicator
                AnimatedBuilder(
                  animation: _progressBarController,
                  builder: (context, child) {
                    return SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressBarVal.value,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA07DFF)),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "XP",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFA07DFF).withOpacity(0.8),
                                ),
                              ),
                              Text(
                                "${(_progressBarVal.value * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
  });

  void update(Size bounds) {
    x += math.cos(angle) * speed;
    y += math.sin(angle) * speed;

    if (x < 0 || x > bounds.width) {
      angle = math.pi - angle;
    }
    if (y < 0 || y > bounds.height) {
      angle = -angle;
    }
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final AnimationController controller;

  _ParticlePainter({required this.particles, required this.controller});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      particle.update(size);
      paint.color = Colors.white.withOpacity(particle.opacity);
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
