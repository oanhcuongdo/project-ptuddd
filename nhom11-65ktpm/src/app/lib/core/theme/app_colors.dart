import 'package:flutter/material.dart';

/// Bảng màu lấy cảm hứng từ phong cách Anthropic: nền giấy ngà ấm,
/// chữ than chì, điểm nhấn cam đất sét (clay) và các màu phụ trầm dịu.
class AppColors {
  // ── Bảng màu gốc ──────────────────────────────────────────────
  static const Color clay = Color(0xFFD97757); // cam đất sét – điểm nhấn chính
  static const Color clayDeep = Color(0xFFC15F3C); // clay đậm – nút, chữ trên nền sáng
  static const Color clayLight = Color(0xFFE8A487);
  static const Color kraft = Color(0xFFD4A27F); // nâu giấy kraft
  static const Color manilla = Color(0xFFEBDBBC); // vàng giấy manila
  static const Color olive = Color(0xFF788C5D); // xanh ô-liu
  static const Color sky = Color(0xFF6A9BCC); // xanh trời
  static const Color heather = Color(0xFF8B7FB8); // tím thạch nam
  static const Color fig = Color(0xFFC46686); // hồng sung
  static const Color cactus = Color(0xFF5E8C7E); // xanh xương rồng

  static const Color ivory = Color(0xFFFAF9F5); // nền giấy ngà
  static const Color pampas = Color(0xFFF0EEE6); // nền ngà đậm hơn
  static const Color oat = Color(0xFFE3DACC); // viền, ngăn cách
  static const Color cloud = Color(0xFF87867F); // chữ phụ
  static const Color slate = Color(0xFF141413); // chữ chính / nền tối
  static const Color slateMid = Color(0xFF262624); // bề mặt tối
  static const Color slateLight = Color(0xFF3D3D3A);

  // ── Vai trò (giữ tên cũ để các màn hình khác không phải sửa) ──
  static const Color primary = clayDeep;
  static const Color primaryDark = Color(0xFF9C4526);
  static const Color primaryLight = clay;

  static const Color secondary = kraft;
  static const Color secondaryDark = Color(0xFFA9754F);
  static const Color secondaryLight = manilla;

  static const Color jadeGreen = olive; // thành công
  static const Color warningOrange = Color(0xFFCC8A2E);
  static const Color errorRed = Color(0xFFBF4D43);
  static const Color infoBlue = sky;

  // Background & Surface
  static const Color backgroundLight = ivory;
  static const Color surfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF1F1E1D);
  static const Color surfaceDark = slateMid;

  // Text colors
  static const Color textPrimaryLight = slate;
  static const Color textSecondaryLight = Color(0xFF5E5D59);
  static const Color textPrimaryDark = ivory;
  static const Color textSecondaryDark = Color(0xFFB7B5A9);

  // Divider & Border
  static const Color dividerLight = oat;
  static const Color dividerDark = slateLight;

  /// Gradient cho thẻ nổi bật / bong bóng người dùng.
  static const List<Color> clayGradient = [Color(0xFFDE8463), Color(0xFFB8552F)];
}
