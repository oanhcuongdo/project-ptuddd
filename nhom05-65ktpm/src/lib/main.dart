import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'data/app_database.dart';
import 'services/notification_service.dart';
import 'ui/home_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();
  await db.seedDemoIfEmpty();
  await NotificationService.init();
  runApp(ChangeNotifierProvider(create: (_) => AppState(db), child: const App()));
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
          colorSchemeSeed: Colors.indigo, brightness: Brightness.dark, useMaterial3: true),
      home: hasUser ? const HomeScreen() : const ProfileScreen(),
    );
  }
}
