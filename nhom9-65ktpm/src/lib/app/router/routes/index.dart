import '../app_router.dart';
import 'auth_routes.dart';

/// Khởi tạo và đăng ký tất cả các router con của từng phân hệ.
/// Sau này phát triển thêm phân hệ nào chỉ cần đăng ký thêm 1 dòng tại đây.
void registerAllRoutes() {
  AppRouter.register(AuthRoutes.onGenerateRoute);
}
