# Danh Sách Thành Viên - Nhóm 15

- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Tên đề tài / Ứng dụng:** Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói (Soroban Kids App)
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường

---

## 1. Bảng Thông Tin Thành Viên Và Phân Công Nhiệm Vụ

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Kỹ Thuật Cốt Lõi | Sản Phẩm Bàn Giao (Deliverables) | Đóng Góp (%) | Email |
| :-: | --------- | :----------: | :-----------: | :-----: | ------------------------- | -------------------------------- | :----------: | ----- |
| 1 | **Dương Nguyên Anh** | 2351170569 | 65KTPM | **Nhóm trưởng** (Tech Lead) | • Thiết kế kiến trúc tổng thể (Feature-First Clean Architecture) & quản trị Git repository.<br>• Khóa Data Contract (Entities & Interfaces chung giữa 4 thành viên).<br>• Lập trình Bàn tính ảo Soroban (CustomPainter), cơ chế tương tác cảm ứng vuốt trượt hạt & animation 60fps.<br>• Thiết lập Dependency Injection (GetIt/Riverpod), kết nối Backend/Local storage.<br>• Lập kế hoạch kiểm thử (Test Plan) & kiểm thử tích hợp toàn diện. | • Repo Git chuẩn nhánh (`main`, `nhom15-65ktpm`, `feature/*`).<br>• Core Soroban Virtual Engine mượt mà.<br>• Cấu trúc Data Contract & DI hoàn chỉnh.<br>• Tài liệu kiểm thử & Slide thuyết trình. | 100% | 2351170569@e.tlu.edu.vn |
| 2 | **Phạm Duy Thái** | 2351060487 | 65KTPM | **Thành viên** | • Thiết kế Wireframe & UI Không chữ (Zero-Text UI) thân thiện với trẻ 4–6 tuổi.<br>• Lập trình giao diện Flutter: Màn hình chính, Lựa chọn bài học, Linh vật Mascot hoạt hình & hiệu ứng khen thưởng.<br>• Xây dựng Module Kỷ luật (Gamified Discipline): Tính chuỗi Streak, hệ thống mở khóa huy hiệu (Badges).<br>• Lập lịch thông báo nhắc nhở luyện tập hàng ngày (19:00).<br>• Xây dựng Cổng phụ huynh (Parental Gate) & Biểu đồ tiến bộ (fl_chart). | • Bộ thiết kế UI/UX trên Figma.<br>• Hệ thống màn hình Home, Lesson Selection, Mascot.<br>• Module Streak, Badges & Parental Dashboard.<br>• Dịch vụ thông báo cục bộ hoạt động chính xác. | 100% | 2351060487@e.tlu.edu.vn |
| 3 | **Nguyễn Thị Thu Hoài** | 2351170594 | 65KTPM | **Thành viên** | • Xây dựng Bộ sinh đề toán tự động (Question Generator) cho 3 cấp độ: Nhận diện hạt $\rightarrow$ Anh bạn nhỏ / Anh bạn lớn $\rightarrow$ Tính nhẩm nhanh Flash Anzan.<br>• Xử lý bộ đếm thời gian chính xác (Timer/AnimationController) cho Flash Anzan (tùy chỉnh tốc độ hiển thị từ 0.5s - 2s).<br>• Tích hợp hệ thống Âm thanh đa giác quan (Audio & TTS): Đọc đề bài, âm gảy hạt "tách", âm vỗ tay và lời khen khích lệ.<br>• Quản lý lịch sử câu trả lời (learning_logs) và tiến trình học tập. | • Engine sinh bài tập Soroban thông minh không trùng lặp.<br>• Module tính nhẩm nhanh Flash Anzan mượt mà.<br>• Hệ thống âm thanh phản hồi đa giác quan hoàn chỉnh.<br>• Bộ câu hỏi mẫu và kho bài học cấp độ 1-3. | 100% | 2351170594@e.tlu.edu.vn |
| 4 | **Nguyễn Thị Cẩm Ly** | 2351170605 | 65KTPM | **Thành viên** | • Tích hợp Speech-to-Text tiếng Việt (`speech_to_text`) tối ưu nhận diện giọng nói âm vực cao của trẻ em.<br>• Lập trình bộ phân tích NLP (Vietnamese Number Extractor) bóc tách số đếm từ khẩu ngữ tự nhiên (ví dụ: "dạ bằng mười lăm ạ" $\rightarrow$ 15).<br>• Xây dựng Thuật toán Gia sư AI Thích ứng (Adaptive Learning): Phân tích tỷ lệ đúng/sai và thời gian phản hồi để tự động tăng/giảm độ khó hoặc hiển thị gợi ý từng bước.<br>• Thiết kế Widget Micro động với hoạt họa sóng âm. | • Module nhận diện giọng nói tiếng Việt ổn định.<br>• Bộ hàm NLP trích xuất số đếm có độ chính xác cao.<br>• Thuật toán gia sư thích ứng tự động căn chỉnh bài học.<br>• Bộ Unit Test cho trích xuất số và thuật toán AI. | 100% | 2351170605@e.tlu.edu.vn |

---

## 2. Hướng Dẫn Thiết Lập Môi Trường Và Khởi Chạy Ứng Dụng

### 2.1. Yêu cầu môi trường kỹ thuật
- **Flutter SDK:** >= 3.3.0 (khuyến nghị Flutter 3.24.x trở lên, Dart SDK 3.x)
- **Hệ điều hành:** Windows 10/11, macOS hoặc Linux
- **Thiết bị thử nghiệm:** Android Emulator / Android Device (Android 8.0 trở lên) hoặc Chrome / Windows Desktop

### 2.2. Các bước cài đặt và khởi chạy

1. **Di chuyển vào thư mục mã nguồn của nhóm:**
   ```bash
   cd nhom15-65ktpm/src
   ```

2. **Cài đặt các gói thư viện phụ thuộc:**
   ```bash
   flutter pub get
   ```

3. **Chạy kiểm thử tự động (Unit Test):**
   ```bash
   flutter test
   ```

4. **Khởi chạy ứng dụng:**
   - Trên thiết bị Android/Máy ảo:
     ```bash
     flutter run
     ```
   - Trên trình duyệt Web (Chrome):
     ```bash
     flutter run -d chrome
     ```
   - Trên Windows Desktop:
     ```bash
     flutter run -d windows
     ```
