/// Chuỗi của phân hệ Đăng nhập / Onboarding / Hồ sơ.
class AuthStrings {
  AuthStrings._();

  // Đăng nhập / đăng ký
  static const welcomeTitle = 'Chào mừng đến NutriTrack AI';
  static const welcomeSubtitle = 'Trợ lý nhỏ giúp bạn ăn uống lành mạnh hơn mỗi ngày';
  static const signInTab = 'Đăng nhập';
  static const registerTab = 'Đăng ký';
  static const email = 'Email';
  static const password = 'Mật khẩu';
  static const confirmPassword = 'Nhập lại mật khẩu';
  static const displayName = 'Tên hiển thị';
  static const signIn = 'Đăng nhập';
  static const register = 'Tạo tài khoản';
  static const signInWithGoogle = 'Tiếp tục với Google';
  static const forgotPassword = 'Quên mật khẩu?';
  static const or = 'hoặc';
  static const resetEmailSent = 'Đã gửi email đặt lại mật khẩu. Kiểm tra hộp thư nhé.';
  static const enterEmailFirst = 'Nhập email trước để đặt lại mật khẩu.';

  // Validate
  static const invalidEmail = 'Email chưa đúng định dạng';
  static const passwordTooShort = 'Mật khẩu cần ít nhất 6 ký tự';
  static const passwordMismatch = 'Mật khẩu nhập lại không khớp';
  static const nameRequired = 'Vui lòng nhập tên hiển thị';

  // Lỗi Firebase Auth
  static const errWrongCredential = 'Email hoặc mật khẩu chưa đúng.';
  static const errEmailInUse = 'Email này đã được đăng ký.';
  static const errWeakPassword = 'Mật khẩu quá yếu, thử mật khẩu dài hơn nhé.';
  static const errUserDisabled = 'Tài khoản đã bị vô hiệu hóa.';
  static const errTooManyRequests = 'Bạn thử quá nhiều lần, đợi một lát rồi thử lại nhé.';
  static const errGoogleUnavailable = 'Thiết bị chưa hỗ trợ đăng nhập Google.';
  static const errGoogleFailed =
      'Đăng nhập Google chưa thành công. Kiểm tra SHA-1/SHA-256 trong Firebase Console.';

  // Onboarding
  static const onboardingAgeTitle = 'Trước tiên, cho mình làm quen nhé';
  static const birthYear = 'Năm sinh';
  static const ageConfirm = 'Tôi xác nhận mình từ 18 tuổi trở lên';
  static const ageRestricted = 'NutriTrack AI chỉ dành cho người từ 18 tuổi trở lên.';
  static const birthYearInvalid = 'Năm sinh chưa hợp lệ';
  static const onboardingGoalTitle = 'Mục tiêu của bạn là gì?';
  static const onboardingGoalHint = 'Gợi ý trong app sẽ bám theo mục tiêu này. Bạn đổi được bất cứ lúc nào.';
  static const onboardingBaselineTitle = 'Thói quen hiện tại';
  static const onboardingBaselineHint = 'Ước lượng thôi, không cần chính xác.';
  static const sugaryDrinksPerWeek = 'Số ly đồ uống ngọt mỗi tuần';
  static const eatOutPerWeek = 'Số bữa ăn ngoài mỗi tuần';
  static const onboardingReminderTitle = 'Nhắc ghi bữa';
  static const onboardingReminderHint =
      'NutriTrack AI sẽ gửi thông báo nhẹ nhàng vào giờ bạn chọn để nhắc ghi lại bữa ăn. '
      'Ở bước tiếp theo, Android có thể hỏi quyền gửi thông báo – bạn có thể tắt bất cứ lúc nào.';
  static const finish = 'Bắt đầu';
}

class ProfileStrings {
  ProfileStrings._();

  static const title = 'Hồ sơ';
  static const goalSection = 'Mục tiêu';
  static const reminderSection = 'Nhắc ghi bữa';
  static const reminderEnabled = 'Bật nhắc ghi bữa';
  static const addTime = 'Thêm giờ';
  static const maxTimesReached = 'Tối đa 6 giờ nhắc';
  static const themeSection = 'Giao diện';
  static const baselineSection = 'Thói quen ban đầu';
  static String baselineSummary(int drinks, int eatOut) =>
      '$drinks ly đồ uống ngọt • $eatOut bữa ăn ngoài mỗi tuần';
  static const signOut = 'Đăng xuất';
  static const signOutConfirm = 'Bạn muốn đăng xuất khỏi NutriTrack AI?';
  static const chooseGoal = 'Chọn mục tiêu';
  static const saved = 'Đã lưu thay đổi';
}
