import 'package:flutter/material.dart';
import '../models/reminder_model.dart';

/// Dịch vụ quản lý Lập lịch thông báo & Nhắc lịch ra sân
/// Tác giả: Nguyễn Hồng Thái (Phân hệ 5 - Thống kê & Nhắc lịch ra sân)
class ReminderService {
  // Bộ nhớ tạm thời lưu danh sách nhắc nhở (In-memory storage)
  static final List<TrainingReminder> _reminders = [
    const TrainingReminder(
      id: 'rem_1',
      title: 'Xách giày ra sân tập kỹ thuật',
      category: ReminderCategory.training,
      hour: 17,
      minute: 30,
      repeatDays: [1, 3, 5], // T2, T4, T6
      isEnabled: true,
      note: 'Mang giày đinh AG, bóng tập và 1 bình nước điện giải.',
    ),
    const TrainingReminder(
      id: 'rem_2',
      title: 'Tập bứt tốc & Thể lực sức bền',
      category: ReminderCategory.fitness,
      hour: 6,
      minute: 30,
      repeatDays: [2, 4], // T3, T5
      isEnabled: true,
      note: 'Khởi động kỹ cổ chân, chạy cự ly ngắn ngắt quãng (HIIT).',
    ),
    const TrainingReminder(
      id: 'rem_3',
      title: 'Giãn cơ & Ngâm chân nước đá phục hồi',
      category: ReminderCategory.stretching,
      hour: 21,
      minute: 0,
      repeatDays: [1, 2, 3, 4, 5, 6, 7], // Hàng ngày
      isEnabled: true,
      note: 'Dành 15 phút giãn cơ đùi sau, bắp chân để phòng tránh chuột rút.',
    ),
    const TrainingReminder(
      id: 'rem_4',
      title: 'Uống đủ 2.5 lít nước trong ngày',
      category: ReminderCategory.hydration,
      hour: 14,
      minute: 0,
      repeatDays: [1, 2, 3, 4, 5, 6, 7], // Hàng ngày
      isEnabled: false,
      note: 'Bổ sung nước trước giờ thi đấu ít nhất 2 tiếng.',
    ),
    const TrainingReminder(
      id: 'rem_5',
      title: 'Trận đấu giao hữu bóng đá cuối tuần',
      category: ReminderCategory.match,
      hour: 16,
      minute: 0,
      repeatDays: [6, 7], // T7, CN
      isEnabled: true,
      note: 'Có mặt tại sân trước 30 phút để khởi động và họp chiến thuật.',
    ),
  ];

  /// 1. Lấy danh sách toàn bộ nhắc nhở
  List<TrainingReminder> getReminders() {
    return List.unmodifiable(_reminders);
  }

  /// 2. Bật / Tắt trạng thái nhắc nhở
  void toggleReminder(String id) {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final item = _reminders[index];
      _reminders[index] = item.copyWith(isEnabled: !item.isEnabled);
    }
  }

  /// 3. Thêm nhắc nhở mới
  void addReminder(TrainingReminder reminder) {
    _reminders.insert(0, reminder);
  }

  /// 4. Cập nhật nhắc nhở
  void updateReminder(TrainingReminder reminder) {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
    }
  }

  /// 5. Xóa nhắc nhở
  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
  }

  /// 6. Kích hoạt thông báo thử nghiệm trực tiếp trên giao diện ứng dụng (In-App Notification)
  void triggerNotificationBanner(BuildContext context, TrainingReminder reminder) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: reminder.category.color.withValues(alpha: 0.5), width: 1.5),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: reminder.category.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(reminder.category.icon, color: reminder.category.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '⚽ Nhắc lịch: ${reminder.formattedTime}',
                        style: TextStyle(
                          color: reminder.category.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Vừa xong',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (reminder.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      reminder.note,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
