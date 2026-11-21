import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/2_gamification_parent/presentation/screens/home_screen.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const FingerMathKidsApp());
}

class FingerMathKidsApp extends StatelessWidget {
  const FingerMathKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finger Math Kids - Toán Ngón Tay Cho Bé',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.kidTheme,
      home: const HomeScreen(),
    );
  }
}
