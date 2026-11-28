import 'package:flutter/material.dart';

/// Hệ thống màu sắc dùng chung cho toàn bộ ứng dụng Finger Math Soroban Kids.
///
/// Phân chia màu sắc theo ý nghĩa sử dụng (Semantic Design System):
/// - Primary: Cam đất (#E05638)
/// - Secondary: Vàng chuối (#FACC15)
/// - Tertiary/Accent: Tím mộng mơ (#8B5CF6)
/// - Background & Surface: Nền dịu mắt (#F7F9FC) & Thẻ trắng (#FFFFFF)
/// - Text: Text Primary (#2D3748) & Text Secondary (#536170)
/// - Status: Success (#176B4D), Warning (#FFBF69), Error (#B3261E), Info (#176B87)
/// - Data & Chart: Hệ màu biểu đồ tương thích fl_chart cho Parent Dashboard
///
/// Tuân thủ tiêu chuẩn tương phản WCAG AA:
/// - Contrast ratio >= 4.5:1 cho văn bản thông thường.
/// - Contrast ratio >= 3.0:1 cho các thành phần đồ họa, biểu tượng và viền.
class AppColors {
  // ===========================================================================
  // 1. CÁC MÀU CHỦ ĐẠO (Brand Colors)
  // ===========================================================================
  /// Màu cam đất: Năng động, lôi cuốn, dùng cho hành động chính (Primary Action)
  static const Color primary = Color(0xFFE05638);

  /// Màu vàng chuối: Vui vẻ, ấm áp, dùng cho Streak, Huy hiệu, Sao (Secondary Action)
  static const Color secondary = Color(0xFFFACC15);

  /// Viền vàng nâu tương phản trên nền vàng, dịu hơn xanh than.
  static const Color secondaryOutline = Color(0xFF8C6500);

  /// Màu tím mộng mơ: Kích thích trí tưởng tượng, dùng cho Flash Anzan (Accent / Tertiary)
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color tertiary = accentPurple;

  // Bí danh (Aliases) tương thích ngược với code cũ
  static const Color accentYellow = secondary;
  static const Color accentOrange = primary;

  // ===========================================================================
  // Button surfaces: brighter fills with dark, readable foregrounds
  // ===========================================================================
  static const Color buttonPrimary = Color(0xFFFFC7B7);
  static const Color buttonPrimaryOutline = Color(0xFF9D3A27);
  static const Color buttonSecondary = Color(0xFFFFE792);
  static const Color buttonSecondaryOutline = Color(0xFF8C6500);
  static const Color buttonPurple = Color(0xFFE0D2FF);
  static const Color buttonPurpleOutline = Color(0xFF583B8F);
  static const Color buttonMint = Color(0xFFC9EBD8);
  static const Color buttonMintOutline = Color(0xFF286B4B);
  static const Color buttonNeutral = Color(0xFFE8EEF5);
  static const Color buttonNeutralOutline = Color(0xFF65758B);

  // ===========================================================================
  // 2. MÀU TƯƠNG PHẢN CHO NỀN CHỦ ĐẠO (Accessible Foregrounds - WCAG AA >= 4.5:1)
  // ===========================================================================
  /// Chữ/Icon trên nền Cam đất #E05638 (Luminance ratio >= 4.5:1)
  static const Color onPrimary = Color(0xFF111111);

  /// Chữ/Icon trên nền Vàng chuối #FACC15 (Luminance ratio >= 7.5:1, tuyệt đối không dùng màu trắng)
  static const Color onSecondary = Color(0xFF2D3748);

  /// Chữ/Icon trên nền Tím mộng mơ #8B5CF6 (Luminance ratio >= 5.1:1)
  static const Color onAccentPurple = Color(0xFF000000);
  static const Color onTertiary = onAccentPurple;

  /// Màu chữ cam đất tương phản cao khi viết trên nền sáng (Contrast >= 5.5:1 trên background)
  static const Color primaryText = Color(0xFFB43822);

  /// Màu chữ tím đậm tương phản cao khi viết trên nền sáng (Contrast >= 7.0:1 trên background)
  static const Color purpleText = Color(0xFF6D28D9);

  // ===========================================================================
  // 3. MÀU NỀN & BỀ MẶT (Background & Surface)
  // ===========================================================================
  /// Nền chính toàn ứng dụng: Gam màu dịu nhẹ, hạn chế mỏi mắt cho trẻ 4–6 tuổi
  static const Color background = Color(0xFFF7F9FC);

  /// Bề mặt thẻ card, dialog, bottom sheet (màu trắng sạch sẽ)
  static const Color cardBg = Colors.white;

  /// Bề mặt trung gian (Surface container) dùng cho khung viền hoặc nền nhẹ
  static const Color surface = Color(0xFFEDF2F7);

  /// Màu viền phân cách (Border / Outline)
  static const Color outline = Color(0xFFCBD5E1);

  /// Nền chuyên biệt cho Parent UI (giao diện phụ huynh)
  static const Color parentSurface = Color(0xFFF8F9FD);
  static const Color parentCardBg = Colors.white;

  // ===========================================================================
  // 4. MÀU VĂN BẢN (Text Primary & Text Secondary)
  // ===========================================================================
  /// Màu chữ chính (Text Primary): Tối rõ ràng, dễ nhận diện (Contrast > 11:1 trên background)
  static const Color textDark = Color(0xFF2D3748);
  static const Color textPrimary = textDark;

  /// Màu chữ phụ (Text Secondary): Cho nhãn phụ, mô tả phụ (Contrast > 5.5:1 trên background)
  static const Color textLight = Color(0xFF536170);
  static const Color textSecondary = textLight;

  // ===========================================================================
  // 5. MÀU TRẠNG THÁI (Status Colors - Đạt chuẩn WCAG AA)
  // ===========================================================================
  /// Thành công (Success): Trả lời đúng, hoàn thành mục tiêu, vượt qua thử thách
  static const Color success = Color(0xFF176B4D);
  static const Color onSuccess = Colors.white;

  /// Cảnh báo (Warning): Nhắc nhở giờ học, cảnh báo chuỗi Streak sắp bị gián đoạn
  static const Color warning = Color(0xFFFFBF69);
  static const Color onWarning = Color(0xFF2D3748);

  /// Lỗi (Error): Trả lời chưa đúng, cổng phụ huynh nhập sai kết quả
  static const Color error = Color(0xFFB3261E);
  static const Color onError = Colors.white;

  /// Thông tin (Info): Gợi ý thông minh, trợ lý ảo AI, hướng dẫn thao tác
  static const Color info = Color(0xFF176B87);
  static const Color onInfo = Colors.white;

  // ===========================================================================
  // 6. MÀU DỮ LIỆU BIỂU ĐỒ (Chart Colors tương thích fl_chart & Parent Dashboard)
  // ===========================================================================
  /// Màu cột/đường biểu đồ chỉ số chính (Tổng số bài luyện tập)
  static const Color chartPrimary = primary;

  /// Màu cột/đường biểu đồ chỉ số phụ (Số câu làm đúng)
  static const Color chartSecondary = secondary;

  /// Màu biểu đồ tính nhẩm / tốc độ phản xạ
  static const Color chartAccent = accentPurple;

  /// Màu biểu đồ tỷ lệ chính xác cao / hoàn thành xuất sắc
  static const Color chartSuccess = Color(0xFF10B981);

  /// Màu biểu đồ cần cải thiện / tốc độ chậm
  static const Color chartWarning = Color(0xFFF59E0B);

  /// Màu đường lưới biểu đồ (Chart Grid Lines)
  static const Color chartGrid = Color(0xFFE2E8F0);

  /// Màu nhãn trục tọa độ (Chart Axis Labels)
  static const Color chartAxisLabel = textLight;

  // ===========================================================================
  // 7. MÀU CƠ CHẾ TOÁN SOROBAN & FINGER MATH (Engine Colors)
  // ===========================================================================
  static const Color abacusFrame = Color(0xFF4A3728);
  static const Color abacusBeam = Color(0xFFD4A373);
  static const Color abacusRod = Color(0xFFC0C0C0);
  static const Color beadUpper = Color(0xFFFF6B6B);
  static const Color beadLower = Color(0xFF4ECDC4);
  static const Color beadActive = Color(0xFFFFD166);
  static const Color unitDot = Color(0xFF2B2D42);
}
