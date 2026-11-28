import 'package:flutter/material.dart';

/// Bảng màu gợi ý khi tạo môn học (`#RRGGBB`).
const List<String> subjectColorPalette = <String>[
  '#2F6BFF',
  '#E53935',
  '#43A047',
  '#FB8C00',
  '#8E24AA',
  '#00897B',
  '#6D4C41',
  '#546E7A',
];

/// Đổi chuỗi `#RRGGBB` thành [Color]; chuỗi lỗi thì dùng màu mặc định.
Color subjectColor(String? hex) {
  final value = int.tryParse((hex ?? '').replaceFirst('#', ''), radix: 16);
  if (value == null || (hex ?? '').length != 7) {
    return const Color(0xFF9E9E9E);
  }
  return Color(0xFF000000 | value);
}

/// Chấm tròn màu của môn học.
class SubjectColorDot extends StatelessWidget {
  const SubjectColorDot({required this.color, this.size = 12, super.key});

  final String? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: subjectColor(color),
        shape: BoxShape.circle,
      ),
    );
  }
}
