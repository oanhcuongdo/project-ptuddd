import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/0_authentication/presentation/screens/auth_gate.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: const AuthGate(),
    );
  }
}
