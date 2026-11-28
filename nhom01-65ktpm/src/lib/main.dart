import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

// Getter toàn cục giúp mọi màn hình trong app truy cập SupabaseClient dễ dàng và an toàn
SupabaseClient get supabase => Supabase.instance.client;

void main() async {
  // Đảm bảo Flutter framework đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Nạp biến môi trường từ file .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Lỗi khi nạp file .env: $e");
  }

  // 2. Đọc trực tiếp từ file .env (Tuyệt đối không lộ key trong code)
  final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Lỗi: Chưa cấu hình SUPABASE_URL hoặc SUPABASE_ANON_KEY trong file .env');
  }

  // 3. Khởi tạo kết nối Supabase Cloud
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Kiểm tra phiên đăng nhập đã lưu
  final bool hasSession = supabase.auth.currentUser != null;

  runApp(BallerDisciplineApp(hasSession: hasSession));
}

class BallerDisciplineApp extends StatelessWidget {
  final bool hasSession;
  const BallerDisciplineApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baller Discipline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1320),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: hasSession ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
