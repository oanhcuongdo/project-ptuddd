import 'package:flutter/material.dart';

import '../../../features/auth_profile/presentation/screens/login_screen.dart';
import '../../../features/auth_profile/presentation/screens/register_screen.dart';
import '../route_helper.dart';

/// Đường dẫn phân hệ Xác thực & Hồ sơ người dùng (Phạm Văn Hưng)
class AuthRoutes {
  AuthRoutes._();

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';

  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case login:
        return RouteHelper.buildPage(routeSettings, const LoginScreen());
      case register:
        return RouteHelper.buildPage(routeSettings, const RegisterScreen());
      case profile:
        return RouteHelper.pendingPage(routeSettings, 'Hồ sơ cá nhân');
      case editProfile:
        return RouteHelper.pendingPage(routeSettings, 'Chỉnh sửa hồ sơ');
      case settings:
        return RouteHelper.pendingPage(routeSettings, 'Cài đặt ứng dụng');
      default:
        return null;
    }
  }
}
