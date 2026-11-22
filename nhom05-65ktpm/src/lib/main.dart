import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'app_state.dart';
import 'data/app_database.dart';
import 'services/firebase_backend.dart';
import 'services/notification_service.dart';
import 'ui/firebase_access_screen.dart';
import 'ui/home_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (FirebaseRuntime.enabled) {
    try {
      await FirebaseRuntime.initialize();
    } catch (_) {
      // The app shows a setup message below; local learner data is untouched.
    }
  }
  final db = await AppDatabase.open();
  if (!FirebaseRuntime.enabled) await db.seedDemoIfEmpty();
  await NotificationService.init();
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(db), child: const App()),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final hasUser = context.select<AppState, bool>((s) => s.user != null);
    return MaterialApp(
      title: 'Speak Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: FirebaseRuntime.enabled
          ? FirebaseRuntime.initializationError == null
                ? auth.FirebaseAuth.instance.currentUser != null && hasUser
                      ? const HomeScreen()
                      : const FirebaseAccessScreen()
                : const _FirebaseSetupError()
          : hasUser
          ? const HomeScreen()
          : const ProfileScreen(),
    );
  }
}

class _FirebaseSetupError extends StatelessWidget {
  const _FirebaseSetupError();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firebase setup required')),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Firebase is enabled but not configured for this app. Run '
          'flutterfire configure for the team Firebase project, then try again. '
          'Local profile data has not been changed.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
