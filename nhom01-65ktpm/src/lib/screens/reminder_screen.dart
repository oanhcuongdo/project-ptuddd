import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/reminder_service.dart';

/// Màn hình Quản lý Lập lịch thông báo & Nhắc lịch ra sân
/// Tác giả: Nguyễn Hồng Thái (Phân hệ 5 - Thống kê & Nhắc lịch ra sân)
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final ReminderService _reminderService = ReminderService();
  late List<TrainingReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    setState(() {
      _reminders = _reminderService.getReminders();
    });
  }

  void _toggleReminder(String id) {
    setState(() {
      _reminderService.toggleReminder(id);
      _reminders = _reminderService.getReminders();
    });
  }

  void _deleteReminder(String id) {
    setState(() {
      _reminderService.deleteReminder(id);
      _reminders = _reminderService.getReminders();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa lịch nhắc nhở thành công'),
        backgroundColor: Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddEditReminderDialog({TrainingReminder? existing}) {
    final isEditing = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final noteController = TextEditingController(text: existing?.note ?? '');
    TimeOfDay selectedTime = isEditing
        ? TimeOfDay(hour: existing.hour, minute: existing.minute)
        : const TimeOfDay(hour: 17, minute: 30);
    ReminderCategory selectedCategory = existing?.category ?? ReminderCategory.training;
    List<int> selectedDays = List<int>.from(existing?.repeatDays ?? [1, 3, 5]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Chỉnh Sửa Lịch Hẹn' : 'Thêm Lịch Nhắc Nhở Ra Sân',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 1. Chọn thời gian nhắc nhở
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF10B981),
                                  surface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.access_time_filled, color: Color(0xFF10B981)),
                                const SizedBox(width: 12),
                                Text(
                                  'Giờ nhắc hẹn: ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Text('Thay đổi', style: TextStyle(color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Tiêu đề lịch nhắc
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tên hoạt động rèn luyện',
                        labelStyle: const TextStyle(color: Colors.white60),
                        hintText: 'VD: Rèn luyện sút bóng, Chạy thể lực...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Chọn nhóm loại hoạt động
                    const Text('Phân loại hoạt động:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReminderCategory.values.map((cat) {
                        final isCatSelected = cat == selectedCategory;
                        return ChoiceChip(
                          avatar: Icon(cat.icon, size: 16, color: isCatSelected ? Colors.white : cat.color),
                          label: Text(cat.label),
                          selected: isCatSelected,
                          selectedColor: cat.color.withValues(alpha: 0.8),
                          backgroundColor: const Color(0xFF0F172A),
                          labelStyle: TextStyle(
                            color: isCatSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedCategory = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 4. Chọn các thứ trong tuần lặp lại
                    const Text('Lặp lại vào các ngày:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDayToggle(1, 'T2', selectedDays, setModalState),
                        _buildDayToggle(2, 'T3', selectedDays, setModalState),
                        _buildDayToggle(3, 'T4', selectedDays, setModalState),
                        _buildDayToggle(4, 'T5', selectedDays, setModalState),
                        _buildDayToggle(5, 'T6', selectedDays, setModalState),
                        _buildDayToggle(6, 'T7', selectedDays, setModalState),
                        _buildDayToggle(7, 'CN', selectedDays, setModalState),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 5. Ghi chú thêm
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ghi chú chuẩn bị (tùy chọn)',
                        labelStyle: const TextStyle(color: Colors.white60),
                        hintText: 'VD: Mang giày đinh, tất chống trơn, bình nước...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút xác nhận lưu
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final reminder = TrainingReminder(
                            id: isEditing ? existing.id : 'rem_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            category: selectedCategory,
                            hour: selectedTime.hour,
                            minute: selectedTime.minute,
                            repeatDays: selectedDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : selectedDays,
                            note: noteController.text.trim(),
                            isEnabled: isEditing ? existing.isEnabled : true,
                          );

                          if (isEditing) {
                            _reminderService.updateReminder(reminder);
                          } else {
                            _reminderService.addReminder(reminder);
                          }

                          Navigator.pop(context);
                          _loadReminders();
                        },
                        child: Text(
                          isEditing ? 'Lưu Thay Đổi' : 'Thêm Lịch Nhắc',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayToggle(int day, String label, List<int> selectedDays, StateSetter setModalState) {
    final isSelected = selectedDays.contains(day);
    return GestureDetector(
      onTap: () {
        setModalState(() {
          if (isSelected) {
            selectedDays.remove(day);
          } else {
            selectedDays.add(day);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF34D399) : Colors.white12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Lập Lịch Nhắc Nhở Ra Sân',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(Icons.alarm_add, color: Colors.white),
        label: const Text('Thêm Lịch Nhắc', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () => _showAddEditReminderDialog(),
      ),
      body: _reminders.isEmpty
          ? const Center(
              child: Text(
                'Chưa có lịch nhắc nhở nào.\nBấm + Thêm Lịch Nhắc để thiết lập!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                return _buildReminderCard(reminder);
              },
            ),
    );
  }

  Widget _buildReminderCard(TrainingReminder reminder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: reminder.isEnabled ? reminder.category.color.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon loại nhắc nhở
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: reminder.category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reminder.category.icon, color: reminder.category.color, size: 26),
              ),
              const SizedBox(width: 14),

              // Thời gian & Tiêu đề
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.formattedTime,
                      style: TextStyle(
                        color: reminder.isEnabled ? Colors.white : Colors.white38,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.title,
                      style: TextStyle(
                        color: reminder.isEnabled ? Colors.white : Colors.white38,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lặp lại: ${reminder.repeatDaysText}',
                      style: TextStyle(color: reminder.category.color.withValues(alpha: 0.9), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Switch Bật / Tắt
              Switch(
                value: reminder.isEnabled,
                activeThumbColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF064E3B),
                onChanged: (_) => _toggleReminder(reminder.id),
              ),
            ],
          ),

          if (reminder.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white54, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reminder.note,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Colors.white10),

          // Nút thao tác nhanh: Thử chuông, Sửa, Xóa
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.notifications_active, size: 16, color: Color(0xFF10B981)),
                label: const Text('Thử chuông', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                onPressed: () {
                  _reminderService.triggerNotificationBanner(context, reminder);
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.white60),
                tooltip: 'Sửa',
                onPressed: () => _showAddEditReminderDialog(existing: reminder),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                tooltip: 'Xóa',
                onPressed: () => _deleteReminder(reminder.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
