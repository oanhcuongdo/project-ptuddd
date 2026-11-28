# TÀI LIỆU ĐẶC TẢ KỸ THUẬT PHÂN HỆ 5: THỐNG KÊ PHONG ĐỘ & NHẮC LỊCH RA SÂN

> **Dự án:** Baller Discipline – Sổ Tay Kỷ Luật & Huấn Luyện Bóng Đá Cá Nhân  
> **Học phần:** Phát triển ứng dụng trên thiết bị di động (PTUDDD - Flutter)  
> **Lớp:** 65KTPM - Nhóm 01  
> **Sinh viên phụ trách:** Nguyễn Hồng Thái  
> **Phân hệ:** Thống kê Phong độ Cầu thủ & Nhắc lịch ra sân (Analytics & Reminders)  

---

## 1. Tổng Quan Phân Hệ

Phân hệ **Thống kê Phong độ Cầu thủ & Nhắc lịch ra sân** đóng vai trò tổng hợp, phân tích toàn bộ dữ liệu tập luyện và thi đấu của cầu thủ từ các phân hệ khác (Kỷ luật bài tập, Bấm giờ Drill, Nhật ký trận đấu), đồng thời cung cấp hệ thống cảnh báo và lập lịch rèn luyện tự động giúp cầu thủ duy trì kỷ luật cá nhân cao nhất.

### Các tính năng cốt lõi:
1. **Biểu đồ Cột Thể Lực 7 Ngày Qua (Weekly Fitness Bar Chart):** Trực quan hóa số phút tập luyện và số bài drill rèn luyện mỗi ngày từ Thứ 2 đến Chủ nhật.
2. **Lưới Lịch Nhiệt Kỷ Luật Tháng (Monthly Discipline Heatmap Grid):** Hiển thị trực quan mức độ tuân thủ kỷ luật hàng ngày tương tự GitHub Contribution Graph với 5 cấp độ màu.
3. **Báo Cáo Tổng Hợp Phong Độ (KPIs Dashboard):** Tổng số phút tập luyện tuần/tháng, số trận ra sân, số bàn thắng, kiến tạo, điểm phong độ trung bình (1-5 ⭐) và chuỗi kỷ luật liên tục (Streak 🔥).
4. **Hệ Thống Lập Lịch Nhắc Nhở Ra Sân (Smart Training Reminders):** Hẹn giờ tập luyện sân cỏ cố định, thông báo giãn cơ, phục hồi, bổ sung nước với chức năng Thử chuông, Bật/Tắt, Thêm/Sửa/Xóa linh hoạt.

---

## 2. Kiến Trúc Mã Nguồn (Clean Architecture)

Tuân thủ kiến trúc phân tầng chuẩn của dự án:
```text
nhom01-65ktpm/src/
├── lib/
│   ├── models/
│   │   ├── analytics_model.dart       # Thực thể DailyDisciplineStat, WeeklyFitnessStat, HeatmapDayData, OverallSummaryReport
│   │   └── reminder_model.dart        # Thực thể TrainingReminder, ReminderCategory
│   ├── services/
│   │   ├── analytics_service.dart     # Tổng hợp dữ liệu từ Supabase (training_drills_sessions, match_journals, habit_logs)
│   │   └── reminder_service.dart      # Quản lý danh sách lịch nhắc và mô phỏng In-App notification banner
│   └── screens/
│       ├── analytics_screen.dart      # Giao diện biểu đồ cột, heatmap tháng, thẻ KPIs phong độ
│       └── reminder_screen.dart       # Giao diện quản lý lịch nhắc nhở, chọn giờ, lặp lại ngày
└── test/
    └── analytics_reminder_test.dart   # Bộ kiểm thử đơn vị tự động (Unit Tests)
```

---

## 3. Đặc Tả Dữ Liệu & Thuật Toán Tính Toán

### 3.1. Thuật toán phân cấp Lưới nhiệt Heatmap (`HeatmapDayData`)
Mức độ nhiệt ($I$) của từng ngày trong tháng được xác định dựa trên tỷ lệ bài tập hoàn thành:
$$Rate = \frac{CompletedHabits}{TotalHabits}$$
* $I = 0$: $Rate = 0$ (Nghỉ tập - Màu xám `#1F2937`)
* $I = 1$: $0 < Rate \le 0.25$ (Mức nhẹ - `#064E3B`)
* $I = 2$: $0.25 < Rate \le 0.50$ (Mức vừa - `#047857`)
* $I = 3$: $0.50 < Rate \le 0.75$ (Mức tốt - `#059669`)
* $I = 4$: $0.75 < Rate \le 1.00$ (Xuất sắc, 100% kỷ luật - `#10B981`)

### 3.2. Báo cáo KPIs tổng hợp
* **Tổng phút tập tuần/tháng:** Tổng hợp `duration_minutes` từ bảng `training_drills_sessions` theo mốc thời gian tuần và tháng hiện tại.
* **Chỉ số thi đấu:** Đếm số bản ghi trong bảng `match_journals`, cộng dồn `goals`, `assists`, và tính điểm phong độ trung bình:
  $$Rating_{avg} = \frac{\sum Rating_i}{TotalMatches}$$

---

## 4. Hệ Thống Lập Lịch Nhắc Nhở Ra Sân (`ReminderService`)

* **Hạng mục nhắc nhở:**
  * ⚽ Tập luyện sân cỏ (`ReminderCategory.training`)
  * 🏋️ Thể lực & Gym (`ReminderCategory.fitness`)
  * 🧘 Giãn cơ & Phục hồi (`ReminderCategory.stretching`)
  * 💧 Bổ sung nước & Dinh dưỡng (`ReminderCategory.hydration`)
  * 🏆 Trận đấu cuối tuần (`ReminderCategory.match`)
* **Lặp lại ngày linh hoạt:** Cầu thủ có thể chọn bất kỳ các ngày trong tuần (T2, T3, T4, T5, T6, T7, CN).
* **Trực quan hóa:** Hỗ trợ thông báo thử nghiệm trực tiếp trên app với âm thanh, rung và SnackBar nổi bật.

---

## 5. Kết Quả Kiểm Thử Đơn Vị (Unit Test Summary)

Bộ kiểm thử tại `test/analytics_reminder_test.dart` bao gồm 5 nhóm bài test:
1. `DailyDisciplineStat`: Kiểm tra tính toán tỷ lệ % hoàn thành (0%, 75%, 100%).
2. Chuyển đổi JSON: `fromJson` và `toJson` của các model thống kê.
3. Thuật toán `HeatmapDayData.calculateIntensity`: Đảm bảo 5 phân cấp nhiệt hoạt động chính xác.
4. Tính bất biến (Immutability) với `copyWith` của `OverallSummaryReport`.
5. Định dạng thời gian và nhãn ngày lặp lại của `TrainingReminder`.
