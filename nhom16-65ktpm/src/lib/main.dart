import 'package:flutter/material.dart';
import 'core/database/database_factory_setup.dart';
import 'core/constants/app_strings.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/main_navigation_screen.dart';
import 'features/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupDatabaseFactory();
  runApp(const GoodDeedsFundApp());
}

class GoodDeedsFundApp extends StatefulWidget {
  const GoodDeedsFundApp({super.key});

  @override
  State<GoodDeedsFundApp> createState() => _GoodDeedsFundAppState();
}

class _GoodDeedsFundAppState extends State<GoodDeedsFundApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final AuthService _authService = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _authService.isLoggedIn
          ? MainNavigationScreen(
              onToggleTheme: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
              onLogout: () => _authService.logout(),
            )
          : LoginScreen(
              onLoginSuccess: () => setState(() {}),
            ),
    );
  }
}