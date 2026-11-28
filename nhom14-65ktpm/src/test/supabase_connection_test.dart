// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nhom14_app/core/supabase_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // Cho phép thực hiện HTTP request thật khi có mạng

  test('Supabase Config and Initialization test', () async {
    SharedPreferences.setMockInitialValues({});

    if (SupabaseConfig.isConfigured) {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      expect(SupabaseConfig.supabaseUrl.endsWith('/rest/v1'), isFalse);
      expect(SupabaseConfig.supabaseUrl.endsWith('/'), isFalse);

      await SupabaseConfig.initialize();
      expect(SupabaseConfig.isInitialized, isTrue);

      final result = await SupabaseConfig.checkConnection();
      // ignore: avoid_print
      print('Supabase connection check result: $result');
      expect(result['connected'], isTrue);
    } else {
      // Khi chạy test không kèm --dart-define-from-file, đảm bảo app không bị crash
      expect(SupabaseConfig.isInitialized, isFalse);
      await SupabaseConfig.initialize();
      expect(SupabaseConfig.isInitialized, isFalse);

      final result = await SupabaseConfig.checkConnection();
      expect(result['connected'], isFalse);
    }
  });
}
