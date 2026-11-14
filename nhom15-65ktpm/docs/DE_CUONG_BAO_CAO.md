# Đề Cương Báo Cáo Đồ Án (Project Report Outline)

**Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD)  
**Lớp:** 65KTPM  
**Nhóm:** Nhóm 15  
**Đề tài:** Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói (Soroban Kids App)  
**Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  

---

## MỤC LỤC CHI TIẾT BÁO CÁO

### CHƯƠNG 1: TỔNG QUAN VÀ TÍNH CẤP THIẾT CỦA ĐỀ TÀI
- 1.1. Bối cảnh chuyển đổi số trong giáo dục mầm non và phương pháp toán tư duy Soroban.
- 1.2. Thách thức đặc thù của đối tượng trẻ 4–6 tuổi: Chưa thành thạo đọc/viết chữ, khả năng tập trung có hạn, cần phương pháp tiếp cận trực giác đa giác quan.
- 1.3. Mục tiêu nghiên cứu và sản phẩm kỳ vọng của đồ án:
  - Giới hạn phạm vi toán học: **Độc quyền phép Cộng và Trừ** (phạm vi 0–99).
  - Triết lý giao diện Không chữ (Zero-Text UI).
  - Bàn tính ảo Soroban tương tác xúc giác và chuyển động 60fps.
  - Tích hợp AI giọng nói tiếng Việt và thuật toán thích ứng (Adaptive Learning).
- 1.4. Đối tượng và phạm vi ứng dụng.

---

### CHƯƠNG 2: CƠ SỞ KỸ THUẬT VÀ CÔNG NGHỆ ÁP DỤNG
- 2.1. Nền tảng phát triển đa nền tảng Flutter & Dart SDK:
  - Khả năng kết xuất đồ họa hiệu năng cao với `CustomPainter`.
  - Cơ chế quản lý trạng thái mượt mà với StateNotifier & Riverpod.
- 2.2. Xử lý âm thanh và công nghệ nhận dạng giọng nói:
  - Thư viện `speech_to_text` tiếng Việt và `flutter_tts` tổng hợp giọng nói tự nhiên.
  - Xử lý ngôn ngữ tự nhiên (NLP) mức từ vựng cho phát ngôn trẻ em.
- 2.3. Trực quan hóa dữ liệu với thư viện `fl_chart`.
- 2.4. Lưu trữ dữ liệu cục bộ tốc độ cao với `shared_preferences`.

---

### CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG
- 3.1. Phân tích yêu cầu chức năng (Use Case Diagram):
  - Phân hệ Bé học tập (Làm quen bàn tính, Học công thức Anh bạn nhỏ, Flash Anzan, Trả lời bằng giọng nói).
  - Phân hệ Gamification (Duy trì Streak, Nhận huy hiệu, Thông báo nhắc học 19:00).
  - Phân hệ Phụ huynh (Parental Gate, Báo cáo thống kê, Biểu đồ học tập).
- 3.2. Kiến trúc mã nguồn Feature-First Clean Architecture:
  - Tầng `core/`: Hạ tầng dùng chung (Theme, AudioService, StorageService).
  - Tầng `shared/`: Giao ước dữ liệu Data Contract (`ChildProfile`, `SorobanQuestion`, `AttemptLog`).
  - Tầng `features/`: 4 module phát triển độc lập theo ma trận phân công 4 thành viên.
- 3.3. Thiết kế chi tiết các thuật toán cốt lõi:
  - Thuật toán mô phỏng hạt Soroban trên hệ trục tọa độ 2D.
  - Thuật toán bóc tách số tiếng Việt (Vietnamese Number Extractor).
  - Thuật toán gia sư thích ứng (Adaptive Tutor Engine).

---

### CHƯƠNG 4: HIỆN THỰC VÀ KẾT QUẢ ĐẠT ĐƯỢC
- 4.1. Hiện thực Module 1: Bàn tính ảo Soroban tương tác cảm ứng.
- 4.2. Hiện thực Module 2: Giao diện Zero-Text UI, Gamification và Cổng phụ huynh.
- 4.3. Hiện thực Module 3: Bộ sinh đề tự động và Chế độ tính nhẩm nhanh Flash Anzan.
- 4.4. Hiện thực Module 4: Nút Micro AI nhận dạng giọng nói và tự động điều chỉnh tốc độ.
- 4.5. Kết quả kiểm thử tự động (Unit Test): Tỷ lệ vượt qua 17/17 ca kiểm thử (100%).

---

### CHƯƠNG 5: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN
- 5.1. Đánh giá mức độ hoàn thành so với mục tiêu đề ra.
- 5.2. Đóng góp cụ thể của từng thành viên trong nhóm.
- 5.3. Hướng phát triển trong tương lai:
  - Bổ sung nhận diện cử chỉ bàn tay qua camera (Vision AI) để nhận dạng động tác gảy hạt ngoài đời thực.
  - Mở rộng đấu trường thi đấu tính nhẩm Flash Anzan trực tuyến giữa các bạn nhỏ.
