import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/di/app_dependencies.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/supabase_bootstrap.dart';
import 'features/auth/presentation/pages/firebase_config_error_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseBootstrap.initialize();
  } on FirebaseException catch (error) {
    runApp(FirebaseConfigErrorPage(detail: 'Mã lỗi: ${error.code}'));
    return;
  } catch (error) {
    runApp(FirebaseConfigErrorPage(detail: '$error'));
    return;
  }

  // Supabase là kho dữ liệu dùng chung (#21). Không cấu hình thì trả `null` và
  // app chạy ở chế độ chỉ lưu trên máy.
  SupabaseClient? supabase;
  if (SupabaseBootstrap.isConfigured) {
    supabase = await SupabaseBootstrap.initialize(
      accessToken: _firebaseIdToken,
    );
  }

  final dependencies = AppDependencies.create(supabaseClient: supabase);
  runApp(SmartNoteApp(dependencies: dependencies));
}

/// Supabase dùng JWT của Firebase (Third-party auth → Firebase), nên mỗi lần
/// Supabase cần token (REST, Realtime, refresh) ta trả ID token hiện tại.
Future<String?> _firebaseIdToken() async {
  final user = FirebaseAuth.instance.currentUser;
  return user?.getIdToken();
}
