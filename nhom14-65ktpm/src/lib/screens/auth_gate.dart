import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Cổng kiểm soát và điều hướng xác thực (AuthGate):
/// - Kiểm tra trạng thái xác thực khi ứng dụng khởi động.
/// - Nếu có phiên hợp lệ (Session != null), chuyển đến màn hình chính (MyHomePage).
/// - Nếu chưa đăng nhập hoặc phiên không hợp lệ/hết hạn, chuyển đến màn hình đăng nhập (LoginScreen).
/// - Theo dõi luồng sự kiện onAuthStateChange của Supabase Auth để phản hồi tức thì.
/// - Hiển thị màn hình chờ (SplashLoadingView) trong quá trình khôi phục phiên để tránh nháy màn hình.
/// - Tận dụng cơ chế lưu trữ phiên tự động trong SharedPreferences của supabase_flutter.
/// - Hủy subscription thích hợp trong dispose() để tránh rò rỉ bộ nhớ.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isLoading = true;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    // Đảm bảo hiển thị SplashLoadingView trong khung hình đầu tiên, tránh nhấp nháy giao diện
    await Future.microtask(() {});

    if (!mounted) return;

    // Xử lý an toàn nếu Supabase chưa được cấu hình (ví dụ: môi trường test không có env.json)
    if (!SupabaseConfig.isInitialized) {
      if (mounted) {
        setState(() {
          _session = null;
          _isLoading = false;
        });
      }
      return;
    }

    // Đăng ký listener duy nhất theo dõi thay đổi phiên (đăng nhập, đăng xuất, token refresh)
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _session = data.session;
        _isLoading = false;
      });

      // Nếu đang có route phụ/dialog được push phía trên, đóng lại để về root
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    // Đọc phiên đăng nhập hiện tại từ bộ nhớ đệm của Supabase Client
    Session? currentSession = supabase.auth.currentSession;

    // Nếu phiên đã hết hạn, cố gắng làm mới phiên
    if (currentSession != null && currentSession.isExpired) {
      try {
        final res = await supabase.auth.refreshSession();
        currentSession = res.session;
      } catch (_) {
        currentSession = null;
      }
    }

    if (mounted) {
      setState(() {
        _session = currentSession;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Hủy subscription khi widget bị hủy để tránh rò rỉ tài nguyên
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashLoadingView();
    }

    if (_session != null) {
      return const HomeScreen(
        title: 'HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN',
      );
    }

    return const LoginScreen();
  }
}

/// Màn hình chờ hiển thị trong khi kiểm tra phiên đăng nhập ban đầu.
/// Tuân thủ hệ thống màu chuẩn hóa:
/// - Primary background: #EBEAFF
/// - Secondary: #9694FF
/// - Primary action: #3D3BF3
class SplashLoadingView extends StatelessWidget {
  const SplashLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 34,
                color: AppColors.primaryAction,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'HỆ THỐNG HỖ TRỢ ĐỒ ÁN TỐT NGHIỆP CHO SINH VIÊN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang kiểm tra phiên đăng nhập...',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
