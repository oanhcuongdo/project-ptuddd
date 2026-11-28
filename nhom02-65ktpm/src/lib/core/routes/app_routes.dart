import 'package:flutter/material.dart';
import '../../presentation/screens/shell/main_shell.dart';
import '../../presentation/screens/splash/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String foodDiary = '/food-diary';
  static const String mealScanner = '/meal-scanner';
  static const String analytics = '/analytics';
  static const String challenges = '/challenges';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Lỗi điều hướng')),
            body: Center(
              child: Text('Không tìm thấy màn hình: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
