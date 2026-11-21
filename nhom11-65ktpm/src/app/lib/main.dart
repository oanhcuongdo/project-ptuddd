import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_lens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassLens.init();
  runApp(const ProviderScope(child: ChaiLishApp()));
}

class ChaiLishApp extends StatelessWidget {
  const ChaiLishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChaiLish',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
