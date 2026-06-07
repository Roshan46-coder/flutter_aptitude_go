import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final api = Provider.of<ApiClient>(context, listen: false);
    await api.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ApiClient>(
      builder: (context, api, _) {
        if (!api.authInitialized) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.offline_bolt_rounded, size: 80, color: AppTheme.neonPurple),
                  const SizedBox(height: 24),
                  Text("Aptitude GO", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28)),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: AppTheme.neonPurple),
                ],
              ),
            ),
          );
        }

        if (api.isAuthenticated) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
