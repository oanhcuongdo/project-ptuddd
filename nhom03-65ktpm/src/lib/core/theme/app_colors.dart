import 'package:flutter/material.dart';

/// Màu ngữ nghĩa dùng ngoài bảng role của Material 3 (thành công, cảnh báo).
///
/// M3 không có role `success`/`warning`, nên nhóm khai báo tại đây — **không**
/// dùng mã màu trực tiếp trong widget. Đọc bằng `AppSemanticColors.of(context)`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
  });

  /// Bảng màu sáng: xanh lá dịu + hổ phách đủ tương phản với chữ trắng.
  static const AppSemanticColors light = AppSemanticColors(
    success: Color(0xFF12855F),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCF6EC),
    warning: Color(0xFF9A5B00),
    onWarning: Color(0xFFFFFFFF),
    warningContainer: Color(0xFFFFF1D6),
  );

  /// Bảng màu tối: sáng hơn để đạt tương phản trên nền tối.
  static const AppSemanticColors dark = AppSemanticColors(
    success: Color(0xFF4FD1B0),
    onSuccess: Color(0xFF04291F),
    successContainer: Color(0xFF123B2F),
    warning: Color(0xFFFFC94D),
    onWarning: Color(0xFF3A2500),
    warningContainer: Color(0xFF3B3213),
  );

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;

  static AppSemanticColors of(BuildContext context) {
    return Theme.of(context).extension<AppSemanticColors>() ?? light;
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) {
      return this;
    }
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
    );
  }
}

/// Một tông màu pastel dùng cho thẻ ghi chú / nhãn môn học.
///
/// Tham chiếu mockup `02_notes_google_keep_inspired.png`: thẻ nền pastel,
/// tiêu đề đậm, nhãn môn học cùng tông nhưng đậm hơn.
@immutable
class AppNoteTone {
  const AppNoteTone({
    required this.container,
    required this.onContainer,
    required this.accent,
  });

  /// Nền thẻ.
  final Color container;

  /// Chữ trên nền thẻ.
  final Color onContainer;

  /// Nhãn/điểm nhấn (đậm hơn [container]).
  final Color accent;
}

/// Bộ 5 tông pastel của design system (mint, sky, lilac, peach, lemon).
///
/// Widget không tự chọn mã màu: lấy theo chỉ số ổn định của ghi chú qua
/// `AppNoteTones.of(context).toneAt(index)`.
@immutable
class AppNoteTones extends ThemeExtension<AppNoteTones> {
  const AppNoteTones({required this.tones});

  static const AppNoteTones light = AppNoteTones(
    tones: <AppNoteTone>[
      AppNoteTone(
        container: Color(0xFFE3F8EE),
        onContainer: Color(0xFF0B4A37),
        accent: Color(0xFF12855F),
      ),
      AppNoteTone(
        container: Color(0xFFE6EFFF),
        onContainer: Color(0xFF173A7A),
        accent: Color(0xFF2F6BFF),
      ),
      AppNoteTone(
        container: Color(0xFFEFE9FF),
        onContainer: Color(0xFF3B2670),
        accent: Color(0xFF7C5CFF),
      ),
      AppNoteTone(
        container: Color(0xFFFFEDE6),
        onContainer: Color(0xFF7A2E12),
        accent: Color(0xFFF2764A),
      ),
      AppNoteTone(
        container: Color(0xFFFFF6DB),
        onContainer: Color(0xFF6B4E00),
        accent: Color(0xFFC99700),
      ),
    ],
  );

  static const AppNoteTones dark = AppNoteTones(
    tones: <AppNoteTone>[
      AppNoteTone(
        container: Color(0xFF123B2F),
        onContainer: Color(0xFFA8EFD4),
        accent: Color(0xFF4FD1B0),
      ),
      AppNoteTone(
        container: Color(0xFF16294D),
        onContainer: Color(0xFFC7DBFF),
        accent: Color(0xFF7FA5FF),
      ),
      AppNoteTone(
        container: Color(0xFF26204A),
        onContainer: Color(0xFFDCD2FF),
        accent: Color(0xFFB39CFF),
      ),
      AppNoteTone(
        container: Color(0xFF3E2419),
        onContainer: Color(0xFFFFD6C4),
        accent: Color(0xFFFF9C73),
      ),
      AppNoteTone(
        container: Color(0xFF3B3213),
        onContainer: Color(0xFFFFE9A8),
        accent: Color(0xFFFFC94D),
      ),
    ],
  );

  final List<AppNoteTone> tones;

  static AppNoteTones of(BuildContext context) {
    return Theme.of(context).extension<AppNoteTones>() ?? light;
  }

  /// Chọn tông ổn định theo [index] (không đổi giữa các lần build).
  AppNoteTone toneAt(int index) => tones[index.abs() % tones.length];

  @override
  AppNoteTones copyWith({List<AppNoteTone>? tones}) {
    return AppNoteTones(tones: tones ?? this.tones);
  }

  @override
  AppNoteTones lerp(ThemeExtension<AppNoteTones>? other, double t) {
    if (other is! AppNoteTones || other.tones.length != tones.length) {
      return this;
    }
    return AppNoteTones(
      tones: <AppNoteTone>[
        for (int i = 0; i < tones.length; i++)
          AppNoteTone(
            container: Color.lerp(
              tones[i].container,
              other.tones[i].container,
              t,
            )!,
            onContainer: Color.lerp(
              tones[i].onContainer,
              other.tones[i].onContainer,
              t,
            )!,
            accent: Color.lerp(tones[i].accent, other.tones[i].accent, t)!,
          ),
      ],
    );
  }
}

/// Sáu tông chủ đề trong mẫu Ghi chú. Các nền sáng dùng cùng mực tím,
/// riêng thẻ tím đậm dùng chữ trắng để giữ tương phản.
abstract final class NotesTopicColors {
  static const _ink = Color(0xFF21154B);
  static const light = <Color>[
    Color(0xFF502BE0),
    Color(0xFFFFC2A2),
    Color(0xFFE5DBFF),
    Color(0xFFD8EDAC),
    Color(0xFFFFE5A1),
    Color(0xFFE0E9FF),
  ];
  static const dark = <Color>[
    Color(0xFF502BE0),
    Color(0xFF523223),
    Color(0xFF392866),
    Color(0xFF2F4527),
    Color(0xFF49391C),
    Color(0xFF29375D),
  ];
  static const darkInk = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFFD6C0),
    Color(0xFFEDE0FF),
    Color(0xFFE7F6CF),
    Color(0xFFFFE9B0),
    Color(0xFFE0E9FF),
  ];

  static Color foreground(int index, Brightness brightness) =>
      brightness == Brightness.dark
      ? darkInk[index]
      : (index == 0 ? darkInk[0] : _ink);
}
