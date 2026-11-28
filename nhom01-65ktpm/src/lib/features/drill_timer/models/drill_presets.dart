import 'drill_item.dart';

class DrillPresets {
  static const List<String> categories = [
    'Tất cả',
    'Khởi động',
    'Kỹ thuật',
    'Thể lực',
    'Phục hồi',
  ];

  static const List<DrillItem> defaultDrills = [
    DrillItem(
      id: 'drill_01',
      title: 'Khởi động khớp & Giãn cơ động',
      category: 'Khởi động',
      durationSeconds: 300,
      restSeconds: 30,
      sets: 1,
      description:
          'Xoay kỹ các khớp cổ chân, đầu gối, hông và thực hiện chạy bước nhỏ tại chỗ để làm nóng cơ thể trước khi vào bài tập chính.',
      iconName: 'directions_run',
    ),
    DrillItem(
      id: 'drill_02',
      title: 'Tâng bóng cảm giác 2 chân',
      category: 'Kỹ thuật',
      durationSeconds: 600,
      restSeconds: 60,
      sets: 3,
      description:
          'Tâng bóng liên tục luân phiên bằng mu chính diện cả chân trái và chân phải, giữ bóng không chạm đất và kiểm soát nhịp độ ổn định.',
      iconName: 'sports_soccer',
    ),
    DrillItem(
      id: 'drill_03',
      title: 'Rê bóng dích dắc qua cọc mốc',
      category: 'Kỹ thuật',
      durationSeconds: 900,
      restSeconds: 90,
      sets: 3,
      description:
          'Dẫn bóng tốc độ cao luồn lách qua các cọc mốc bằng má trong và má ngoài bàn chân, kết hợp động tác giả đổi hướng đột ngột.',
      iconName: 'timeline',
    ),
    DrillItem(
      id: 'drill_04',
      title: 'Chạy bứt tốc con thoi biến tốc',
      category: 'Thể lực',
      durationSeconds: 1200,
      restSeconds: 120,
      sets: 4,
      description:
          'Chạy nước rút cường độ tối đa 20m-40m rồi đi bộ/chạy chậm hồi phục, giúp tăng sức bền tốc độ và khả năng tranh chấp trên sân.',
      iconName: 'flash_on',
    ),
    DrillItem(
      id: 'drill_05',
      title: 'Sút bóng điểm chết & Dứt điểm',
      category: 'Kỹ thuật',
      durationSeconds: 900,
      restSeconds: 60,
      sets: 3,
      description:
          'Thực hiện các pha đặt lòng vào góc xa và sút mu chính diện từ rìa vòng cấm 16m50, rèn lực chân trụ và độ chính xác khi dứt điểm.',
      iconName: 'gps_fixed',
    ),
    DrillItem(
      id: 'drill_06',
      title: 'Chuyền bóng 1 chạm & Đỡ bước 1',
      category: 'Kỹ thuật',
      durationSeconds: 900,
      restSeconds: 60,
      sets: 3,
      description:
          'Tập chuyền bóng vào tường bật lại 1 chạm và đỡ bóng bước 1 mở hướng di chuyển thoát pressing.',
      iconName: 'swap_horiz',
    ),
    DrillItem(
      id: 'drill_07',
      title: 'Thả lỏng & Giãn cơ sau tập',
      category: 'Phục hồi',
      durationSeconds: 300,
      restSeconds: 0,
      sets: 1,
      description:
          'Giãn cơ đùi trước, đùi sau, bắp chân và điều hòa nhịp thở để giảm căng cơ và hạn chế chấn thương sau buổi tập.',
      iconName: 'self_improvement',
    ),
  ];

  static List<DrillItem> getByCategory(String category) {
    if (category == 'Tất cả') {
      return defaultDrills;
    }
    return defaultDrills.where((d) => d.category == category).toList();
  }
}
