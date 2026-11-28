# BẢNG PHÂN CÔNG NHIỆM VỤ CHI TIẾT THEO NỀN TẢNG VÀ CHỨC NĂNG

**Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD)  
**Lớp học phần / Lớp sinh hoạt:** 65KTPM  
**Đề tài:** Finger Math Kids App - Ứng dụng học toán ngón tay Finger Math tương tác hai bàn tay kết hợp AI trợ lý giọng nói cho trẻ 4–6 tuổi  
**Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  
**Nhóm sinh viên thực hiện:** Nhóm 15  

---

## 1. BẢNG TỔNG QUAN PHÂN CÔNG NỀN TẢNG & MODULE CHUYÊN MÔN

| STT | Họ và Tên | Mã Sinh Viên | Vai Trò | Nền Tảng Chịu Trách Nhiệm Chính | Module / Chức Năng Phụ Trách | Đóng Góp (%) |
| :-: | :--- | :---: | :--- | :--- | :--- | :---: |
| **1** | **Dương Nguyên Anh** | **2351170569** | **Trưởng nhóm<br>(Tech Lead)** | 🌐 **Web (Flutter Web)**<br>💻 **Windows Desktop Native** | **Module 1:** Finger Math Core Engine, Flashcard 1D & Hạ tầng Cloud Firebase | **100%** |
| **2** | **Nguyễn Thị Thu Hoài** | **2351170594** | **Thành viên** | 📱 **Android Native**<br>*(Gradle, APK Build & Device Test)* | **Module 3:** Bộ sinh đề toán học 4 cấp độ & Tính nhẩm siêu tốc Flash Anzan | **100%** |
| **3** | **Phạm Duy Thái** | **2351060487** | **Thành viên** | 🎨 **UI/UX Đa Nền Tảng**<br>*(Responsive Design, Theme & Mascot)* | **Module 2:** Zero-Text UI, Gamification Streak, Panda Mascot & Cổng phụ huynh | **100%** |
| **4** | **Nguyễn Thị Cẩm Ly** | **2351170605** | **Thành viên** | 🎙️ **Audio & Hardware Interop**<br>*(Microphone, Speech & Audio SFX)* | **Module 4:** AI Giọng nói tiếng Việt, Lọc ngôn ngữ tự nhiên NLP & Gia sư thích ứng | **100%** |

---

## 2. CHI TIẾT TRÁCH NHIỆM VÀ ĐẦU VIỆC CỤ THỂ CỦA TỪNG THÀNH VIÊN

### 👤 1. Dương Nguyên Anh (MSSV: 2351170569) - Trưởng nhóm / Tech Lead
* **Nền tảng chịu trách nhiệm:**
  - **Flutter Web Platform:** Đảm bảo ứng dụng chạy mượt mà trên trình duyệt Google Chrome, xử lý Responsive Web, Canvas rendering hiệu năng cao.
  - **Windows Desktop Native:** Tối ưu hóa build C++ Native trên hệ điều hành Windows.
* **Nhiệm vụ chuyên môn (Module 1 & Hạ tầng):**
  - Thiết kế kiến trúc tổng thể **Feature-First Clean Architecture** (`core/`, `shared/`, `features/`).
  - Xây dựng thuật toán cốt lõi **Finger Math Engine 2 bàn tay**:
    - Tay Phải: Biểu diễn hàng đơn vị ($0 \to 9$).
    - Tay Trái: Biểu diễn hàng chục ($10 \to 90$).
  - Hiện thực bộ thẻ bài **Flashcard 1D** hình ảnh ngón tay trực quan.
  - Xây dựng thuật toán công thức **Anh Bạn Nhỏ** ($\pm 5$) và **Anh Bạn Lớn** ($\pm 10$).
  - Thiết lập và quản trị hạ tầng Cloud **Firebase** (Firebase Core, Cloud Firestore, Firebase Auth, Google Services).
  - Quản trị kho mã nguồn Git, điều phối Pull Request nội bộ và đại diện nộp **Pull Request #4** cho Giảng viên.
  - Viết và đảm bảo **10 Unit Tests** cốt lõi của Module 1 passed 100%.

---

### 👤 2. Nguyễn Thị Thu Hoài (MSSV: 2351170594) - Thành viên
* **Nền tảng chịu trách nhiệm:**
  - **Android Native Platform:** Quản lý môi trường build Android, cấu hình `android/gradle.properties`, `build.gradle.kts`, giải quyết các lỗi phân quyền và tối ưu kích thước gói cài đặt APK.
  - Kiểm thử trực tiếp trên thiết bị di động Android thật và máy ảo Android Emulator.
* **Nhiệm vụ chuyên môn (Module 3):**
  - Xây dựng **Bộ sinh đề toán học tự động** (`AdaptiveTutorEngine`): Sinh đề ngẫu nhiên phép cộng và trừ đảm bảo kết quả không âm ($0 \le \text{kết quả} \le 99$).
  - Thiết kế màn hình luyện tập theo lộ trình **4 cấp độ bài học**:
    - Cấp độ 1: Nhận diện số lượng ngón tay.
    - Cấp độ 2: Cộng trừ không nhớ trong phạm vi 9.
    - Cấp độ 3: Anh Bạn Nhỏ (cộng trừ qua 5).
    - Cấp độ 4: Anh Bạn Lớn (cộng trừ hai bàn tay qua 10).
  - Hiện thực chế độ tính nhẩm siêu tốc **Flash Anzan**: Chớp số ngắt quãng 1.5s - 3s rèn luyện phản xạ ghi nhớ ngắn hạn.
  - Viết và hoàn thành Unit Test kiểm thử tương tác màn hình.

---

### 👤 3. Phạm Duy Thái (MSSV: 2351060487) - Thành viên
* **Nền tảng chịu trách nhiệm:**
  - **UI/UX Đa Nền Tảng (Cross-Platform UI):** Đảm bảo giao diện hiển thị đồng nhất, co giãn tự nhiên (Responsive) trên mọi kích thước màn hình từ điện thoại, máy tính bảng đến Desktop.
* **Nhiệm vụ chuyên môn (Module 2):**
  - Hiện thực triết lý **Zero-Text UI (Giao diện không chữ)**: Thiết kế toàn bộ nút bấm, điều hướng bằng hình ảnh biểu tượng và màu sắc sinh động chuẩn tâm lý thị giác trẻ 4–6 tuổi.
  - Xây dựng bộ thư viện Widget dùng chung: `KidButton`, `KidCard`, `KidBadgeCard`, `KidProgressBar`, `KidStatusBanner`.
  - Thiết kế và tích hợp linh vật tương tác **Panda Mascot** sống động tại màn hình chính.
  - Xây dựng thuật toán tính chuỗi ngày học liên tiếp (**Streak**) và hệ thống Gamification mở khóa huy hiệu.
  - Hiện thực **Cổng phụ huynh (Parental Gate)** và biểu đồ học tập tuần `fl_chart`.
  - Viết và hoàn thành **3 Unit Tests** quản lý thói quen và streak.

---

### 👤 4. Nguyễn Thị Cẩm Ly (MSSV: 2351170605) - Thành viên
* **Nền tảng chịu trách nhiệm:**
  - **Audio & Hardware Interop:** Xử lý cấp quyền Micro (Audio Recording Permissions), tương thích phần cứng thu âm và phát âm thanh trên cả Android, Web và Windows.
* **Nhiệm vụ chuyên môn (Module 4):**
  - Tích hợp công nghệ nhận diện giọng nói tiếng Việt trẻ em (`speech_to_text`), cho phép bé trả lời phép tính bằng giọng nói.
  - Xây dựng bộ xử lý ngôn ngữ tự nhiên (**NLP** - `VietnameseNumberExtractor`): Bóc tách số và lọc bỏ hoàn toàn các từ đệm dạ thưa của trẻ mầm non ("dạ", "thưa cô", "con nghĩ là", "bằng", ...).
  - Tích hợp giọng đọc trợ lý tiếng Việt tự nhiên (`flutter_tts`) đọc to đề bài và phát âm hướng dẫn từng bước.
  - Hiện thực hóa thuật toán **Gia sư thích ứng (Adaptive Learning)**: Tự động điều chỉnh thời gian chớp số và mức độ gợi ý dựa trên tốc độ phản xạ của bé.
  - Viết và hoàn thành **7 Unit Tests** kiểm thử NLP và AI giọng nói.

---

## 3. MA TRẬN TRÁCH NHIỆM RACI (RACI MATRIX)

*Ký hiệu:*
- **R (Responsible):** Người trực tiếp thực hiện chính.
- **A (Accountable):** Người chịu trách nhiệm phê duyệt cuối cùng (Trưởng nhóm).
- **C (Consulted):** Người được tham vấn chuyên môn.
- **I (Informed):** Người được thông báo kết quả.

| Hạng mục công việc | Dương Nguyên Anh | Nguyễn Thị Thu Hoài | Phạm Duy Thái | Nguyễn Thị Cẩm Ly |
| :--- | :---: | :---: | :---: | :---: |
| **Kiến trúc hệ thống & Git** | **R / A** | I | I | I |
| **Nền tảng Web & Windows** | **R / A** | I | C | I |
| **Nền tảng Android (APK/Gradle)** | A | **R** | C | C |
| **Thiết kế UI/UX & Panda Mascot** | A | C | **R** | I |
| **Finger Math Engine (0-99)** | **R / A** | C | I | I |
| **Bộ sinh đề & Flash Anzan** | A | **R** | I | C |
| **AI Giọng nói & Xử lý NLP** | A | I | I | **R** |
| **Tích hợp Cloud Firebase** | **R / A** | I | I | I |
| **Bộ 21 Unit Tests tự động** | **R / A** | **R** | **R** | **R** |
| **Nộp bài PR #4 cho Giảng viên** | **R / A** | I | I | I |

---

## 4. CAM KẾT ĐỒNG BỘ
Toàn bộ 4 thành viên cam kết:
1. Hoàn thành 100% khối lượng công việc được phân công đúng hạn.
2. Kiểm thử độc lập trên nền tảng mình phụ trách trước khi mở Pull Request.
3. Tham gia đầy đủ vào quy trình Review chéo mã nguồn nội bộ trên GitHub.
