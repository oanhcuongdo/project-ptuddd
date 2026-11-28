import 'package:flutter/material.dart';
import 'habit_model.dart';

class HabitPreset {
  final String id;
  final String title;
  final String subtitle;
  final String roleTag; // Tiền đạo, Tiền vệ, Hậu vệ, Thủ môn, Toàn năng
  final IconData icon;
  final Color accentColor;
  final List<HabitModel> habits;

  const HabitPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.roleTag,
    required this.icon,
    required this.accentColor,
    required this.habits,
  });
}

class PresetRepository {
  static final List<HabitPreset> presets = [
    // 1. Thể lực Siêu Cầu Thủ
    HabitPreset(
      id: 'cr7_beast',
      title: 'Kỷ Luật Thể Lực CR7 (Quái Thú)',
      subtitle: 'Xây dựng nền tảng thể lực, tốc độ và sức bền không giới hạn',
      roleTag: 'Cường độ cao',
      icon: Icons.bolt,
      accentColor: const Color(0xFF10B981), // Neon Green
      habits: [
        HabitModel(
          id: '',
          title: 'Chạy biến tốc Interval Sprint',
          description: '10 đợt bứt tốc 100m nghỉ 30s giữa các hiệp',
          category: HabitCategory.fitness,
          type: HabitType.quantitative,
          targetValue: 5.0,
          currentValue: 0,
          unit: 'km',
        ),
        HabitModel(
          id: '',
          title: 'Plank & Siết cơ bụng Core',
          description: 'Củng cố trục thăng bằng và sức mạnh tranh chấp tì đè',
          category: HabitCategory.fitness,
          type: HabitType.quantitative,
          targetValue: 15,
          currentValue: 0,
          unit: 'phút',
        ),
        HabitModel(
          id: '',
          title: 'Chống đẩy Push-ups',
          description: 'Tăng cường sức mạnh thân trên và cơ vai',
          category: HabitCategory.fitness,
          type: HabitType.quantitative,
          targetValue: 100,
          currentValue: 0,
          unit: 'cái',
        ),
        HabitModel(
          id: '',
          title: 'Bù nước điện giải trong ngày',
          description: 'Uống từng ngụm nhỏ duy trì độ ẩm cho cơ bắp',
          category: HabitCategory.nutrition,
          type: HabitType.quantitative,
          targetValue: 3.0,
          currentValue: 0,
          unit: 'lít',
        ),
      ],
    ),

    // 2. Tiền vệ Nhạc Trưởng
    HabitPreset(
      id: 'maestro_midfield',
      title: 'Nhạc Trưởng Kiểm Soát Bóng (Modric / Iniesta)',
      subtitle: 'Rèn giũa cảm giác bóng ma thuật, nhãn quan và xử lý 1 chạm',
      roleTag: 'Tiền vệ',
      icon: Icons.all_inclusive,
      accentColor: const Color(0xFF38BDF8), // Sky Blue
      habits: [
        HabitModel(
          id: '',
          title: 'Tâng bóng cảm giác 2 chân',
          description: 'Cảm giác bóng mu bàn chân, má trong má ngoài xen kẽ',
          category: HabitCategory.technical,
          type: HabitType.quantitative,
          targetValue: 500,
          currentValue: 0,
          unit: 'cái',
        ),
        HabitModel(
          id: '',
          title: 'Chuyền bật tường 1 chạm',
          description: 'Khoảng cách 5m-10m, xoay trở quan sát trước khi nhận bóng',
          category: HabitCategory.technical,
          type: HabitType.qualitative,
          targetValue: 1,
          currentValue: 0,
          unit: 'phiên',
        ),
        HabitModel(
          id: '',
          title: 'Rê bóng qua cọc zíc-zắc (Dribble)',
          description: 'Đổi hướng bóng nhanh bằng cả 2 chân trong phạm vi hẹp',
          category: HabitCategory.technical,
          type: HabitType.quantitative,
          targetValue: 20,
          currentValue: 0,
          unit: 'lượt',
        ),
        HabitModel(
          id: '',
          title: 'Giãn cơ Foam Roller sau tập',
          description: 'Thả lỏng bắp chuối và gân kheo tránh co rút',
          category: HabitCategory.fitness,
          type: HabitType.qualitative,
          targetValue: 1,
          currentValue: 0,
          unit: 'phiên',
        ),
      ],
    ),

    // 3. Tiền đạo Sát Thủ
    HabitPreset(
      id: 'striker_instinct',
      title: 'Bản Năng Sát Thủ Vòng Cấm (Striker Instinct)',
      subtitle: 'Cải thiện độ chính xác dứt điểm và tốc độ bứt phá đoạn ngắn',
      roleTag: 'Tiền đạo',
      icon: Icons.adjust,
      accentColor: const Color(0xFFF59E0B), // Amber/Flame
      habits: [
        HabitModel(
          id: '',
          title: 'Sút góc chữ A & cứa lòng hiểm',
          description: '10 quả chân thuận và 10 quả chân không thuận',
          category: HabitCategory.technical,
          type: HabitType.quantitative,
          targetValue: 20,
          currentValue: 0,
          unit: 'quả',
        ),
        HabitModel(
          id: '',
          title: 'Bật nhảy đánh đầu (Jump Header)',
          description: 'Tập đà bật cao và điểm tiếp xúc trán chuẩn xác',
          category: HabitCategory.technical,
          type: HabitType.quantitative,
          targetValue: 30,
          currentValue: 0,
          unit: 'lần',
        ),
        HabitModel(
          id: '',
          title: 'Bứt tốc đoạn ngắn 20m',
          description: 'Phản xạ xuất phát nhanh chiếm lĩnh khoảng trống',
          category: HabitCategory.fitness,
          type: HabitType.quantitative,
          targetValue: 15,
          currentValue: 0,
          unit: 'lần',
        ),
        HabitModel(
          id: '',
          title: 'Bữa ăn giàu đạm Protein sau tập',
          description: 'Ức gà, trứng hoặc whey giúp phục hồi sợi cơ rách',
          category: HabitCategory.nutrition,
          type: HabitType.qualitative,
          targetValue: 1,
          currentValue: 0,
          unit: 'bữa',
        ),
      ],
    ),

    // 4. Bức Tường Thép (Hậu vệ / Thủ môn)
    HabitPreset(
      id: 'solid_defense',
      title: 'Bức Tường Thép (Thủ Môn & Hậu Vệ)',
      subtitle: 'Phản xạ cực nhạy, sức bật tranh chấp trên không và độ dẻo dai',
      roleTag: 'Phòng ngự',
      icon: Icons.shield,
      accentColor: const Color(0xFFA855F7), // Purple
      habits: [
        HabitModel(
          id: '',
          title: 'Phản xạ bóng bàn / tennis',
          description: 'Bắt bóng phản xạ nhanh với tường 15 phút',
          category: HabitCategory.technical,
          type: HabitType.quantitative,
          targetValue: 15,
          currentValue: 0,
          unit: 'phút',
        ),
        HabitModel(
          id: '',
          title: 'Bật nhảy chạm xà ngang',
          description: 'Rèn sức bật cổ chân và khớp gối',
          category: HabitCategory.fitness,
          type: HabitType.quantitative,
          targetValue: 25,
          currentValue: 0,
          unit: 'cái',
        ),
        HabitModel(
          id: '',
          title: 'Tập xoạc bóng & phá bóng an toàn',
          description: 'Phán đoán điểm rơi và căn thời gian chuẩn xác',
          category: HabitCategory.technical,
          type: HabitType.qualitative,
          targetValue: 1,
          currentValue: 0,
          unit: 'phiên',
        ),
        HabitModel(
          id: '',
          title: 'Ngủ sâu 8 tiếng phục hồi hệ thần kinh',
          description: 'Đi ngủ trước 23h để phản xạ mắt luôn ở mức tối đa',
          category: HabitCategory.nutrition,
          type: HabitType.quantitative,
          targetValue: 8,
          currentValue: 0,
          unit: 'tiếng',
        ),
      ],
    ),
  ];
}
