import '../../domain/enums.dart';

/// Chuỗi hiển thị dùng chung (tiếng Việt).
///
/// Mỗi phân hệ có file chuỗi riêng trong thư mục `core/strings/`
/// (auth_strings.dart, diary_strings.dart, ...) để tránh xung đột khi
/// nhiều thành viên cùng sửa. File này chứa phần dùng chung và nhãn của enum.
class AppStrings {
  AppStrings._();

  static const appName = 'NutriTrack AI';

  // Nút / hành động chung
  static const ok = 'Đồng ý';
  static const cancel = 'Hủy';
  static const save = 'Lưu';
  static const close = 'Đóng';
  static const retry = 'Thử lại';
  static const delete = 'Xóa';
  static const undo = 'Hoàn tác';
  static const edit = 'Sửa';
  static const next = 'Tiếp tục';
  static const back = 'Quay lại';
  static const loading = 'Đang tải...';

  // Tab điều hướng
  static const tabHome = 'Trang chủ';
  static const tabDiary = 'Nhật ký';
  static const tabReport = 'Báo cáo';
  static const tabProfile = 'Hồ sơ';
  static const scanFab = 'Quét';
  static const comingSoon = 'Tính năng đang được phát triển';

  // An toàn & miễn trừ trách nhiệm (bắt buộc hiển thị)
  static const disclaimerShort = 'Gợi ý mang tính tham khảo';
  static const disclaimerFull =
      'Gợi ý mang tính tham khảo, không thay thế tư vấn của chuyên gia dinh dưỡng.';

  // Lỗi chung
  static const genericError = 'Có lỗi xảy ra, bạn thử lại sau nhé.';
  static const networkError = 'Không có kết nối mạng. Kiểm tra Internet rồi thử lại nhé.';
  static const permissionError = 'Bạn không có quyền thực hiện thao tác này.';

  // ---------------------------------------------------------------------------
  // Nhãn enum
  // ---------------------------------------------------------------------------

  static String goal(Goal goal) => switch (goal) {
        Goal.weightLoss => 'Giảm cân',
        Goal.balanced => 'Ăn uống cân bằng',
        Goal.lessSugar => 'Giảm đường',
      };

  static String goalDescription(Goal goal) => switch (goal) {
        Goal.weightLoss => 'Ưu tiên món nhẹ, ít đường, ít dầu mỡ',
        Goal.balanced => 'Đủ rau, đủ đạm, đa dạng món',
        Goal.lessSugar => 'Hạn chế đồ uống và món tráng miệng nhiều đường',
      };

  static String mealType(MealType type) => switch (type) {
        MealType.breakfast => 'Bữa sáng',
        MealType.lunch => 'Bữa trưa',
        MealType.dinner => 'Bữa tối',
        MealType.snack => 'Bữa phụ',
      };

  static String category(FoodCategory category) => switch (category) {
        FoodCategory.drink => 'Đồ uống',
        FoodCategory.mainDish => 'Món chính',
        FoodCategory.snack => 'Ăn vặt',
        FoodCategory.dessert => 'Tráng miệng',
      };

  static String attribute(LevelAttribute attribute) => switch (attribute) {
        LevelAttribute.sugar => 'Độ ngọt',
        LevelAttribute.fat => 'Dầu mỡ',
        LevelAttribute.carb => 'Tinh bột',
        LevelAttribute.veg => 'Rau xanh',
        LevelAttribute.protein => 'Đạm',
        LevelAttribute.energy => 'Năng lượng',
      };

  /// Nhãn mức độ, phụ thuộc thuộc tính:
  /// - đường/mỡ/tinh bột: thấp / vừa / cao
  /// - rau/đạm: ít / vừa / nhiều
  /// - năng lượng: nhẹ / vừa / nhiều
  static String level(LevelAttribute attribute, Level level) {
    switch (attribute) {
      case LevelAttribute.veg:
      case LevelAttribute.protein:
        return switch (level) {
          Level.low => 'ít',
          Level.medium => 'vừa',
          Level.high => 'nhiều',
        };
      case LevelAttribute.energy:
        return switch (level) {
          Level.low => 'nhẹ',
          Level.medium => 'vừa',
          Level.high => 'nhiều',
        };
      case LevelAttribute.sugar:
      case LevelAttribute.fat:
      case LevelAttribute.carb:
        return switch (level) {
          Level.low => 'thấp',
          Level.medium => 'vừa',
          Level.high => 'cao',
        };
    }
  }

  static String themeMode(AppThemeMode mode) => switch (mode) {
        AppThemeMode.system => 'Theo hệ thống',
        AppThemeMode.light => 'Sáng',
        AppThemeMode.dark => 'Tối',
      };
}
