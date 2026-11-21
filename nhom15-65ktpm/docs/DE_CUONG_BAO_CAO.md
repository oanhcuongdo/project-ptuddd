# Đề Cương Báo Cáo Đồ Án (Project Report Outline)

**Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD) - Lớp 65KTPM  
**Đề tài:** Finger Math Kids App - Ứng dụng học toán ngón tay Finger Math tương tác hai bàn tay kết hợp AI trợ lý giọng nói cho trẻ 4–6 tuổi  
**Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  
**Nhóm sinh viên thực hiện:** Nhóm 15  
- **Dương Nguyên Anh (2351170569)** - Trưởng nhóm / Tech Lead
- **Phạm Duy Thái (2351060487)** - Thành viên
- **Nguyễn Thị Thu Hoài (2351170594)** - Thành viên
- **Nguyễn Thị Cẩm Ly (2351170605)** - Thành viên  

---

## MỤC LỤC CHI TIẾT BÁO CÁO

### CHƯƠNG 1: TỔNG QUAN VÀ TÍNH CẤP THIẾT CỦA ĐỀ TÀI
- 1.1. Bối cảnh chuyển đổi số trong giáo dục mầm non và phương pháp toán ngón tay Finger Math Nhật Bản/Hàn Quốc.
- 1.2. Thách thức đặc thù của đối tượng trẻ 4–6 tuổi: Chưa thành thạo đọc/viết chữ, khả năng tập trung ngắn hạn, cần phương pháp tiếp cận trực quan đa giác quan thông qua vận động đôi bàn tay.
- 1.3. Mục tiêu nghiên cứu và sản phẩm kỳ vọng của đồ án:
  - Giới hạn phạm vi toán học: **Độc quyền phép Cộng và Trừ** (phạm vi kết quả không âm từ 0 đến 99).
  - Triết lý thiết kế giao diện Không chữ (Zero-Text UI) chuẩn lứa tuổi mầm non.
  - Hệ thống tương tác đôi bàn tay Finger Math chuẩn hóa:
    - **Tay Phải:** Đại diện hàng đơn vị ($0 \to 9$), ngón cái mang giá trị 5, 4 ngón dài mang giá trị 1.
    - **Tay Trái:** Đại diện hàng chục ($10 \to 90$), ngón cái mang giá trị 50, 4 ngón dài mang giá trị 10.
  - Hiện thực hóa 2 bộ công thức kinh điển:
    - **Anh Bạn Nhỏ (tổng = 5):** Phép cộng và trừ 1, 2, 3, 4 thông qua mượn/trả 5.
    - **Anh Bạn Lớn (tổng = 10):** Phép cộng và trừ phối hợp hai bàn tay thông qua mượn/trả 10.
  - Tích hợp AI giọng nói tiếng Việt nhận diện câu trả lời và thuật toán gia sư thích ứng (Adaptive Learning).
- 1.4. Đối tượng thụ hưởng và phạm vi triển khai của ứng dụng.

---

### CHƯƠNG 2: CƠ SỞ KỸ THUẬT VÀ CÔNG NGHỆ ÁP DỤNG
- 2.1. Nền tảng phát triển ứng dụng di động đa nền tảng Flutter & Dart SDK:
  - Khả năng kết xuất đồ họa hiệu năng cao và cử động ngón tay mượt mà.
  - Quản lý trạng thái ứng dụng theo kiến trúc Clean Architecture.
- 2.2. Xử lý âm thanh và công nghệ nhận dạng giọng nói:
  - Thư viện `speech_to_text` tiếng Việt và `flutter_tts` tổng hợp giọng nói tự nhiên cho trẻ em.
  - Xử lý ngôn ngữ tự nhiên (NLP) mức từ vựng bóc tách số và lọc các từ đệm dạ thưa của trẻ.
- 2.3. Trực quan hóa dữ liệu tiến độ với thư viện `fl_chart`.
- 2.4. Lưu trữ dữ liệu cục bộ tốc độ cao với `shared_preferences`.

---

### CHƯƠNG 3: PHÂN TÍCH VÀ THIẾT KẾ HỆ THỐNG
- 3.1. Phân tích yêu cầu chức năng (Use Case Diagram):
  - Phân hệ Bé học tập (Làm quen số đếm ngón tay, Luyện tập 4 cấp độ, Flash Anzan chớp số, Trả lời bằng giọng nói).
  - Phân hệ Gamification (Duy trì chuỗi ngày học Streak, Điểm thưởng, Xem lại chi tiết từng bước).
  - Phân hệ Phụ huynh (Parental Gate, Báo cáo thời lượng học tập trong tuần).
- 3.2. Kiến trúc mã nguồn Feature-First Clean Architecture:
  - Tầng `core/`: Hạ tầng dùng chung (Theme, AudioService, Text-to-Speech).
  - Tầng `shared/`: Giao ước dữ liệu Data Contract (`ChildProfile`, `SorobanQuestion`, `AttemptLog`).
  - Tầng `features/`: 4 module phát triển độc lập theo ma trận phân công 4 thành viên.
- 3.3. Thiết kế chi tiết các thuật toán cốt lõi:
  - Thuật toán mô phỏng trạng thái 2 bàn tay Finger Math (`FingerHandState`).
  - Thuật toán sinh đề toán ngẫu nhiên thích ứng không âm từ 0 đến 99 (`AdaptiveTutorEngine`).
  - Thuật toán bóc tách số tiếng Việt (`VietnameseNumberExtractor`).
  - Thuật toán gia sư thích ứng điều chỉnh thời gian chớp số theo phong độ bé.

---

### CHƯƠNG 4: HIỆN THỰC VÀ KẾT QUẢ ĐẠT ĐƯỢC
- 4.1. Hiện thực Module 1 (Dương Nguyên Anh): Finger Math Engine 2 bàn tay, Flashcard 1D & Bộ 10 Unit Tests.
- 4.2. Hiện thực Module 2 (Phạm Duy Thái): Giao diện Zero-Text UI, Gamification Streak, Cổng phụ huynh & 3 Unit Tests.
- 4.3. Hiện thực Module 3 (Nguyễn Thị Thu Hoài): Bộ sinh đề tự động 4 cấp độ, Chế độ Flash Anzan chớp số & 1 Unit Test.
- 4.4. Hiện thực Module 4 (Nguyễn Thị Cẩm Ly): AI nhận dạng giọng nói tiếng Việt, Gia sư thích ứng & 7 Unit Tests.
- 4.5. Kết quả kiểm thử tự động (Unit Test): Tỷ lệ vượt qua **21/21 ca kiểm thử tự động (100%)**.

---

### CHƯƠNG 5: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN
- 5.1. Đánh giá mức độ hoàn thành so với mục tiêu đề ra: Đạt 100% tiến độ và yêu cầu kỹ thuật.
- 5.2. Đóng góp cụ thể của từng thành viên trong nhóm (Bảng ma trận đóng góp 4 thành viên 100%).
- 5.3. Hướng phát triển trong tương lai:
  - Bổ sung nhận diện cử chỉ bàn tay qua camera (Vision AI) để nhận dạng động tác ngón tay ngoài đời thực.
  - Mở rộng đấu trường thi đấu tính nhẩm Flash Anzan trực tuyến giữa các bạn nhỏ.
