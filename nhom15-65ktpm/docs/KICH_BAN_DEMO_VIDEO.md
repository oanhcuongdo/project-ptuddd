# Kịch Bản Quay Video Demo Đồ Án (Video Demonstration Script)

- **Đề tài:** Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói (Soroban Kids App)
- **Nhóm thực hiện:** Nhóm 15 - Lớp 65KTPM
- **Thời lượng khuyến nghị:** 3 - 5 phút
- **Độ phân giải:** 1080p (Full HD), 60fps

---

## Phân Cảnh Chi Tiết

### Phân cảnh 1: Giới thiệu tổng quan (0:00 - 0:45)
- **Hình ảnh:** Màn hình chính [`HomeScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/screens/home_screen.dart) rực rỡ sắc màu, linh vật gấu trúc Panda, chuỗi Streak ngọn lửa và 3 thẻ bài học.
- **Thuyết minh:** 
  > "Kính chào thầy và các bạn. Nhóm 15 xin trình bày sản phẩm đồ án: Soroban Kids App - Ứng dụng học toán Soroban tương tác và rèn luyện tư duy dành cho trẻ từ 4 đến 6 tuổi. Ứng dụng được thiết kế theo triết lý Không chữ (Zero-Text UI) kết hợp hướng dẫn giọng nói tiếng Việt đa giác quan."
- **Thao tác:** Bấm vào linh vật Panda để nghe giọng chào mừng vui nhộn.

---

### Phân cảnh 2: Bàn tính ảo Soroban tương tác thực tế (0:45 - 1:45)
- **Hình ảnh:** Mở chế độ **Bàn tính tự do** hoặc **Cấp độ 1: Hạt nhỏ nhận diện**.
- **Thuyết minh:** 
  > "Điểm nổi bật đầu tiên là Bàn tính ảo Soroban được vẽ hoàn toàn bằng CustomPainter 60fps. Khi trẻ chạm hoặc vuốt, các hạt hình quả trám sẽ trượt mượt mà kèm âm thanh gảy hạt chân thực và rung xúc giác. Hạt trên đại diện cho giá trị 5, bốn hạt dưới mỗi hạt đại diện cho giá trị 1. Hệ thống chỉ giới hạn ở phép cộng và phép trừ cơ bản, giúp trẻ dễ dàng làm quen với trực giác số học."
- **Thao tác:** 
  - Kéo hạt trên xuống sát xà ngang $\rightarrow$ hiển thị số 5.
  - Đẩy 2 hạt dưới lên sát xà ngang $\rightarrow$ tổng giá trị hiển thị thành 7.
  - Nhấn nút "Gạt số (0)" để reset bàn tính về trạng thái ban đầu.

---

### Phân cảnh 3: Tích hợp AI Trợ lý giọng nói tiếng Việt (1:45 - 2:45)
- **Hình ảnh:** Màn hình làm bài tập [`LessonPlayScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart).
- **Thuyết minh:** 
  > "Đối với trẻ 4-6 tuổi chưa biết gõ bàn phím, ứng dụng tích hợp Micro AI với Speech-to-Text tiếng Việt và bộ lọc NLP thông minh. Trẻ chỉ cần nhấn nút Micro và nói tự nhiên như khi thưa chuyện với cô giáo."
- **Thao tác:**
  - Trên màn hình hiện phép tính: `5 + 3 = ?`.
  - Nhấn Micro và nói: *"Dạ bằng tám ạ"*.
  - AI tự động lọc từ đệm, bóc tách ra số `8`, chấm điểm chính xác và phát lời khen động viên cùng hiệu ứng âm thanh chúc mừng.

---

### Phân cảnh 4: Tính nhẩm siêu tốc Flash Anzan & Gia sư thích ứng (2:45 - 3:45)
- **Hình ảnh:** Màn hình [`FlashAnzanScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart).
- **Thuyết minh:** 
  > "Module Flash Anzan giúp trẻ rèn luyện bán cầu não phải qua việc hình dung các con số xuất hiện chớp nhoáng từ 0.5s đến 1.5s. Đặc biệt, thuật toán Gia sư AI Thích ứng (Adaptive Learning) liên tục đánh giá độ chính xác và tốc độ phản xạ của bé để tự động tăng tốc độ thử thách hoặc giảm nhịp để hướng dẫn từng bước."
- **Thao tác:**
  - Nhấn "Bắt đầu chớp số" (3.. 2.. 1.. +2, +5, -1).
  - Trẻ gảy kết quả `6` lên bàn tính ảo và nhấn xác nhận.
  - Hiển thị thông báo điều chỉnh tốc độ tự động từ AI.

---

### Phân cảnh 5: Quản lý thói quen & Báo cáo phụ huynh (3:45 - 4:30)
- **Hình ảnh:** Cổng phụ huynh [`ParentalGateDialog`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart) và màn hình [`ParentDashboardScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/screens/parent_dashboard_screen.dart).
- **Thuyết minh:** 
  > "Để phụ huynh theo dõi tiến trình của con, ứng dụng có khu vực báo cáo chuyên biệt. Cổng được bảo vệ bằng phép tính cộng ngẫu nhiên để trẻ không tự ý vào thay đổi cài đặt. Phụ huynh có thể xem biểu đồ cột trực quan về số câu con đã làm trong tuần, tỷ lệ đúng và lịch nhắc học cố định lúc 19:00 hàng ngày."
- **Thao tác:** 
  - Giải phép tính mở khóa Cổng phụ huynh.
  - Xem biểu đồ cột trực quan và tỷ lệ chính xác.
