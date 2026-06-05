import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aptitude_go_flutter/core/api_client.dart';
import 'package:aptitude_go_flutter/main.dart';

void main() {
  testWidgets('App basic smoke test - loads LoginScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ApiClient(),
        child: const MyApp(),
      ),
    );

    // Verify that the login screen is loaded by verifying the login button text exists
    expect(find.text('Log In'), findsOneWidget);
  });
}
