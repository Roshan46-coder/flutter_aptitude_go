import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/hive_database.dart';
import 'core/local_data.dart';
import 'core/theme.dart';
import 'views/home_screen.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDatabase.instance.init();
  await LocalDataProvider.instance.init();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ApiClient(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aptitude GO',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Consumer<ApiClient>(
        builder: (context, api, _) {
          if (api.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
