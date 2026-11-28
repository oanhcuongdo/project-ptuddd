import 'package:flutter/material.dart';

import '../../domain/entities/summary_mode.dart';

/// Nhãn tiếng Việt cho ba kiểu tóm tắt — chỉ dùng ở tầng presentation.
extension SummaryModePresentation on SummaryMode {
  String get label {
    return switch (this) {
      SummaryMode.short => 'Ngắn',
      SummaryMode.long => 'Dài',
      SummaryMode.bullets => 'Gạch ý chính',
    };
  }

  IconData get icon {
    return switch (this) {
      SummaryMode.short => Icons.short_text_rounded,
      SummaryMode.long => Icons.notes_rounded,
      SummaryMode.bullets => Icons.format_list_bulleted_rounded,
    };
  }

  String get hint {
    return switch (this) {
      SummaryMode.short => 'Vài câu cốt lõi để nhớ nhanh.',
      SummaryMode.long => 'Giữ nhiều ý hơn, dùng khi cần ôn kỹ.',
      SummaryMode.bullets => 'Gạch đầu dòng từng ý chính.',
    };
  }
}
