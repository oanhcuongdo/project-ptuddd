import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/supabase_config.dart';
import 'data/database/database_factory_initializer_stub.dart'
    if (dart.library.io)
      'data/database/database_factory_initializer_io.dart'
    as database_factory_initializer;
import 'data/services/notification_service.dart';
import 'data/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/sleep_provider.dart';
import 'providers/nap_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  database_factory_initializer.initializeDatabaseFactory();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermission();
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
    SupabaseService.instance.markInitialized();
  } catch (e) {
    debugPrint('[Supabase] Init fallback (offline mode): $e');
  }
  runApp(const DCSleepApp());
}

class DCSleepApp extends StatelessWidget {
  const DCSleepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SleepProvider()..loadData()),
        ChangeNotifierProvider(create: (_) => NapProvider()..loadHistory()),
        ChangeNotifierProvider(
          create: (_) => AIAssistantProvider()..loadMessages(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..loadSettings(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'DCSleep',
            debugShowCheckedModeBanner: false,
            theme: settings.isDarkMode ? AppTheme.darkTheme : ThemeData.light(useMaterial3: true),
            home: settings.isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
