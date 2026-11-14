import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/2_gamification_parent/presentation/screens/home_screen.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(
    const ProviderScope(
      child: SorobanKidsApp(),
    ),
  );
}

class SorobanKidsApp extends StatelessWidget {
  const SorobanKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soroban Kids - Toán Trí Tuệ Cho Bé',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.kidTheme,
      home: const HomeScreen(),
    );
  }
}
