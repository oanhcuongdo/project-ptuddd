import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/contracts/contracts.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/glass_lens.dart';
import 'features/pronunciation/pronunciation_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlassLens.init();
  runApp(
    ProviderScope(
      overrides: [
        if (!AppConfig.fakeData) ...[
          pinyinServiceProvider.overrideWith((ref) => ref.watch(cedictPinyinServiceProvider)),
          voiceRecorderProvider.overrideWith((ref) => ref.watch(realVoiceRecorderProvider)),
          pronunciationScorerProvider.overrideWith((ref) => ref.watch(hybridPronunciationScorerProvider)),
        ],
      ],
      child: const ChaiLishApp(),
    ),
  );
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
      scrollBehavior: const AppScrollBehavior(),
    );
  }
}
