import '../../../models/trip_model.dart';
import '../models/checklist_item.dart';

extension TripTypeX on TripType {
  String get label => switch (this) {
        TripType.beach => 'Du lịch biển',
        TripType.trekking => 'Leo núi / Cắm trại',
        TripType.motorbike => 'Phượt xe máy',
        TripType.backpacking => 'Du lịch tự túc dài ngày',
        TripType.other => 'Tự chọn sau (Khác)',
      };
}

/// Built-in Smart Templates matching Section 7.1 of De_cuong_Travel_Buddy_Nhom8_v3.
abstract final class SmartChecklistTemplates {
  static ChecklistTemplate? forTripType(TripType tripType) {
    if (tripType == TripType.other) return null;
    for (final template in all) {
      if (template.tripType == tripType.name) return template;
    }
    return null;
  }

  static const List<ChecklistTemplate> all = [
    ChecklistTemplate(
      id: 'tpl_beach',
      tripType: 'beach',
      name: 'Du lịch biển (Phú Quốc, Nha Trang)',
      subtitle: 'Vé máy bay/xe, kem chống nắng, đồ bơi, túi chống nước...',
      items: [
        ChecklistTemplateItem(
          title: 'Đặt vé máy bay / xe khứ hồi cho cả nhóm',
          phase: ChecklistPhase.before30d,
          daysBeforeDeparture: 30,
        ),
        ChecklistTemplateItem(
          title: 'Đặt cọc homestay / resort gần biển',
          phase: ChecklistPhase.before30d,
          daysBeforeDeparture: 25,
        ),
        ChecklistTemplateItem(
          title: 'Đặt tour cano / lặn ngắm san hô',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 10,
        ),
        ChecklistTemplateItem(
          title: 'Mua kem chống nắng SPF 50+ & thuốc say tàu xe',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 7,
        ),
        ChecklistTemplateItem(
          title: 'Check-in vé online & kiểm tra CCCD',
          phase: ChecklistPhase.before3d,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Đồ bơi, kính râm & dép đi biển',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Túi chống nước điện thoại & sạc dự phòng',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          daysBeforeDeparture: 1,
        ),
      ],
    ),
    ChecklistTemplate(
      id: 'tpl_trekking',
      tripType: 'trekking',
      name: 'Leo núi / Cắm trại (Đà Lạt, Sa Pa)',
      subtitle: 'Áo giữ nhiệt, giày bám, đèn pin, bộ sơ cứu y tế...',
      items: [
        ChecklistTemplateItem(
          title: 'Đặt vé xe giường nằm & homestay / lều trại',
          phase: ChecklistPhase.before30d,
          daysBeforeDeparture: 25,
        ),
        ChecklistTemplateItem(
          title: 'Liên hệ porter / kiểm tra thời tiết cung đường',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 10,
        ),
        ChecklistTemplateItem(
          title: 'Chuẩn bị bộ sơ cứu y tế & xịt chống côn trùng',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 7,
        ),
        ChecklistTemplateItem(
          title: 'Sạc đầy pin dự phòng & đèn pin đội đầu',
          phase: ChecklistPhase.before3d,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Giày leo núi chống trượt & áo khoác giữ nhiệt',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Lều bạt, túi ngủ & bếp ga mini dùng chung',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          daysBeforeDeparture: 1,
        ),
      ],
    ),
    ChecklistTemplate(
      id: 'tpl_motorbike',
      tripType: 'motorbike',
      name: 'Phượt xe máy',
      subtitle: 'Bảo dưỡng xe, mũ 3/4, áo mưa bộ, bộ vá xe...',
      items: [
        ChecklistTemplateItem(
          title: 'Chốt lộ trình cung đường & điểm nghỉ qua đêm',
          phase: ChecklistPhase.before30d,
          daysBeforeDeparture: 20,
        ),
        ChecklistTemplateItem(
          title: 'Bảo dưỡng xe, thay nhớt & kiểm tra phanh/lốp',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 7,
        ),
        ChecklistTemplateItem(
          title: 'Kiểm tra GPLX, đăng ký xe & bảo hiểm xe máy',
          phase: ChecklistPhase.before3d,
          daysBeforeDeparture: 2,
        ),
        ChecklistTemplateItem(
          title: 'Mũ bảo hiểm 3/4, găng tay & áo mưa bộ',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Bộ dụng cụ vá xe khẩn cấp & dây chằng đồ',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          daysBeforeDeparture: 1,
        ),
      ],
    ),
    ChecklistTemplate(
      id: 'tpl_backpacking',
      tripType: 'backpacking',
      name: 'Du lịch tự túc dài ngày',
      subtitle: 'Vé tàu/xe, giấy tờ tùy thân, ổ cắm đa năng, thuốc men...',
      items: [
        ChecklistTemplateItem(
          title: 'Đặt vé di chuyển chặng chính & chỗ ở các đêm đầu',
          phase: ChecklistPhase.before30d,
          daysBeforeDeparture: 28,
        ),
        ChecklistTemplateItem(
          title: 'Mua thuốc cá nhân (cảm, tiêu hóa, urgo) & bảo hiểm',
          phase: ChecklistPhase.before14d,
          daysBeforeDeparture: 10,
        ),
        ChecklistTemplateItem(
          title: 'Tải bản đồ offline & lưu mã đặt chỗ trên điện thoại',
          phase: ChecklistPhase.before3d,
          daysBeforeDeparture: 2,
        ),
        ChecklistTemplateItem(
          title: 'CCCD/Hộ chiếu, thẻ ngân hàng & tiền mặt lẻ',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.personal,
          daysBeforeDeparture: 1,
        ),
        ChecklistTemplateItem(
          title: 'Ổ cắm nối dài đa năng dùng chung cho phòng nhóm',
          phase: ChecklistPhase.packing,
          scope: ChecklistScope.group,
          daysBeforeDeparture: 1,
        ),
      ],
    ),
  ];
}
