import '../app_router.dart';
import '../guards/auth_guard.dart';
import '../../layouts/main_layout.dart';
import '../route_helper.dart';
import 'auth_routes.dart';

/// Khởi tạo và đăng ký tất cả các router con của từng phân hệ.
/// Sau này phát triển thêm phân hệ nào chỉ cần đăng ký thêm 1 dòng tại đây.
void registerAllRoutes() {
  AppRouter.register((settings) {
    if (settings.name == AppRouter.initialRoute) {
      return RouteHelper.buildPage(
        settings,
        const AuthGuard(child: MainLayout()),
      );
    }
    return null;
  });

  AppRouter.register(AuthRoutes.onGenerateRoute);
}
