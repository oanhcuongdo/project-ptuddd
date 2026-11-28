import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/supabase_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebaseSafely();
  await SupabaseStorageService.initializeSafely();
  await LocalNotificationService.initializeSafely();
  runApp(
    const ProviderScope(
      child: TravelBuddyApp(),
    ),
  );
}

Future<void> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Allow app and widget tests to boot before FlutterFire/native configs are added.
    debugPrint('Firebase initialization skipped: $e');
  }
}

class TravelBuddyApp extends ConsumerWidget {
  const TravelBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Travel Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
