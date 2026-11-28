import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/constants/app_colors.dart';
import 'package:soroban_kids_app/core/constants/app_dimensions.dart';
import 'package:soroban_kids_app/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('brand and text color pairs meet WCAG AA contrast', () {
    expect(_contrastRatio(AppColors.primary, AppColors.onPrimary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.secondary, AppColors.onSecondary),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.accentPurple, AppColors.onAccentPurple),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.textDark),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.textLight),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.primaryText),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.background, AppColors.purpleText),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.success, AppColors.onSuccess),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.warning, AppColors.onWarning),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.error, AppColors.onError),
        greaterThanOrEqualTo(4.5));
    expect(_contrastRatio(AppColors.info, AppColors.onInfo),
        greaterThanOrEqualTo(4.5));
  });

  test('dedicated button fills keep readable dark text', () {
    for (final fill in [
      AppColors.buttonPrimary,
      AppColors.buttonSecondary,
      AppColors.buttonPurple,
      AppColors.buttonMint,
      AppColors.buttonNeutral,
    ]) {
      expect(
        _contrastRatio(fill, AppColors.textDark),
        greaterThanOrEqualTo(4.5),
        reason: 'Button fill $fill must keep text readable',
      );
    }
  });

  test('progress and status graphics meet WCAG non-text contrast', () {
    final progressTrack = Color.alphaBlend(
      AppColors.surface.withValues(alpha: 0.9),
      Colors.white,
    );
    expect(_contrastRatio(AppColors.primary, progressTrack),
        greaterThanOrEqualTo(3));

    final statusPairs = [
      (AppColors.success, AppColors.success),
      (AppColors.onWarning, AppColors.warning),
      (AppColors.error, AppColors.error),
      (AppColors.info, AppColors.info),
    ];
    for (final (foreground, background) in statusPairs) {
      final tintedBackground = Color.alphaBlend(
        background.withValues(alpha: 0.16),
        Colors.white,
      );
      expect(
        _contrastRatio(foreground, tintedBackground),
        greaterThanOrEqualTo(3),
      );
    }
  });

  test('Semantic color definitions match Zero-Text UI specifications', () {
    // 3 màu chủ đạo bắt buộc
    expect(AppColors.primary, const Color(0xFFE05638)); // Cam đất
    expect(AppColors.secondary, const Color(0xFFFACC15)); // Vàng chuối
    expect(AppColors.accentPurple, const Color(0xFF8B5CF6)); // Tím mộng mơ
    expect(AppColors.tertiary, AppColors.accentPurple);

    // Bề mặt & Màu nền
    expect(AppColors.background, const Color(0xFFF7F9FC));
    expect(AppColors.cardBg, Colors.white);
    expect(AppColors.surface, const Color(0xFFEDF2F7));
    expect(AppColors.outline, const Color(0xFFCBD5E1));

    // Văn bản
    expect(AppColors.textPrimary, AppColors.textDark);
    expect(AppColors.textSecondary, AppColors.textLight);

    // Trạng thái
    expect(AppColors.success, const Color(0xFF176B4D));
    expect(AppColors.warning, const Color(0xFFFFBF69));
    expect(AppColors.error, const Color(0xFFB3261E));
    expect(AppColors.info, const Color(0xFF176B87));

    // Dữ liệu biểu đồ fl_chart cho Parent Dashboard
    expect(AppColors.chartPrimary, AppColors.primary);
    expect(AppColors.chartSecondary, AppColors.secondary);
    expect(AppColors.chartAccent, AppColors.accentPurple);
    expect(AppColors.chartSuccess, const Color(0xFF10B981));
    expect(AppColors.chartWarning, const Color(0xFFF59E0B));
    expect(AppColors.chartGrid, const Color(0xFFE2E8F0));
  });

  test('ThemeData integrates Zero-Text UI color scheme and components', () {
    final theme = AppTheme.kidTheme;
    expect(theme.useMaterial3, isTrue);

    // ColorScheme
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.onPrimary, AppColors.onPrimary);
    expect(theme.colorScheme.secondary, AppColors.secondary);
    expect(theme.colorScheme.onSecondary, AppColors.onSecondary);
    expect(theme.colorScheme.tertiary, AppColors.accentPurple);
    expect(theme.colorScheme.error, AppColors.error);
    expect(theme.colorScheme.onError, AppColors.onError);
    expect(theme.colorScheme.surface, AppColors.background);

    // Scaffold & Background
    expect(theme.scaffoldBackgroundColor, AppColors.background);

    // Nút bấm & Touch target chuẩn WCAG (minTouchSize >= 48)
    expect(AppDimensions.minTouchSize, greaterThanOrEqualTo(48.0));
    final elevatedStyle = theme.elevatedButtonTheme.style;
    expect(elevatedStyle, isNotNull);
    expect(
      elevatedStyle!.backgroundColor!.resolve({}),
      AppColors.buttonPrimary,
    );
    expect(
      elevatedStyle.foregroundColor!.resolve({}),
      AppColors.textDark,
    );
    expect(
      _contrastRatio(AppColors.buttonPrimary, AppColors.textDark),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
      AppColors.buttonPrimary,
    );

    // Card, Dialog & BottomSheet themes
    expect(theme.cardTheme.color, AppColors.cardBg);
    expect(theme.dialogTheme.backgroundColor, AppColors.cardBg);
    expect(theme.bottomSheetTheme.backgroundColor, AppColors.cardBg);

    // Parent theme
    final parentTheme = AppTheme.parentTheme;
    expect(parentTheme.scaffoldBackgroundColor, AppColors.parentSurface);
  });
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;

  return (lighter + 0.05) / (darker + 0.05);
}
