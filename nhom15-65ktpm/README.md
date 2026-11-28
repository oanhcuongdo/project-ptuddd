# Nhóm 15 - Lớp 65KTPM
## Ứng Dụng Học Toán Finger Math Tương Tác Hai Bàn Tay Kết Hợp AI Trợ Lý Giọng Nói Cho Trẻ 4–6 Tuổi (Finger Math Kids App)

---

### 1. Thông Tin Nhóm & Phân Công Nhiệm Vụ

**Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD)  
**Lớp:** 65KTPM  
**Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  
**Kho lưu trữ nguồn:** `nhom15-65ktpm/`  

| STT | Mã Sinh Viên (MSSV) | Họ và Tên | Vai Trò | Nhánh Git Cá Nhân | Trách Nhiệm Kỹ Thuật Chính |
| :---: | :---: | :--- | :--- | :--- | :--- |
| 1 | **2351170569** | **Dương Nguyên Anh** | **Nhóm trưởng / Tech Lead** | `feat/abacus-core`<br>`feature/nhom15/duong-nguyen-anh-2351170569` | Xây dựng Finger Math Engine hai bàn tay, xử lý Flashcard 1D RH/LH, quy ước toán học và bộ công thức |
| 2 | **2351060487** | **Phạm Duy Thái** | **Thành viên** | `feat/ui-gamification`<br>`feature/nhom15/pham-duy-thai-2351060487` | Thiết kế Zero-Text UI, Gamification chuỗi ngày học liên tiếp (Streak), Cổng khóa phụ huynh (Parental Gate) & biểu đồ |
| 3 | **2351170594** | **Nguyễn Thị Thu Hoài** | **Thành viên** | `feat/flash-anzan`<br>`feature/nhom15/nguyen-thi-thu-hoai-2351170594` | Xây dựng bộ sinh đề thông minh (chỉ cộng trừ không âm), màn hình bài học và chế độ tính nhẩm Flash Anzan |
| 4 | **2351170605** | **Nguyễn Thị Cẩm Ly** | **Thành viên** | `feat/ai-voice`<br>`feature/nhom15/nguyen-thi-cam-ly-2351170605` | Tích hợp AI Micro nhận diện giọng nói tiếng Việt (`speech_to_text`), bộ bóc tách số NLP và Gia sư thích ứng AI |

---

### 2. Định Hướng Sản Phẩm & Giới Hạn Nghiệp Vụ

1. **Phạm vi nghiệp vụ toán học:**
   - **Độc quyền chỉ phép Cộng và phép Trừ** trong phạm vi từ $0$ đến $99$.
   - Tuyệt đối không có phép nhân, phép chia, phân số hay kết quả âm ($0 \le \text{kết quả} \le 99$).
2. **Quy ước chuẩn Hai Bàn Tay Finger Math:**
   - **Tay Phải (Hàng đơn vị $0 \to 9$):** Ngón cái = $5$, bốn ngón dài = $1$ mỗi ngón ($6 = 5 + 1$, $7 = 5 + 2$, $8 = 5 + 3$, $9 = 5 + 4$).
   - **Tay Trái (Hàng chục $10 \to 90$):** Ngón cái = $50$, bốn ngón dài = $10$ mỗi ngón.
   - Kết hợp 2 bàn tay tính toán linh hoạt từ $00 \to 99$.
3. **Bộ công thức Toán tư duy:**
   - **Anh Bạn Nhỏ (cặp số có tổng = 5):** $(1-4), (2-3)$ trên cùng một bàn tay.
   - **Anh Bạn Lớn (cặp số có tổng = 10):** $(1-9), (2-8), (3-7), (4-6), (5-5)$ phối hợp Tay Trái và Tay Phải.
4. **Triết lý giao diện Không chữ (Zero-Text UI):**
   - Biểu tượng lớn, âm thanh vui nhộn, màu sắc rực rỡ chuẩn WCAG cho trẻ nhỏ.
   - Trợ lý giọng nói tiếng Việt đồng hành hướng dẫn mọi thao tác.

---

### 3. Cấu Trúc Mã Nguồn (Clean Architecture)

```
nhom15-65ktpm/
├── danhsachnhom.md               # Danh sách thành viên và phân công
├── README.md                     # Tài liệu tổng quan dự án
├── docs/                         # Hồ sơ tài liệu đồ án
│   ├── KIEN_TRUC_HE_THONG.md     # Kiến trúc kỹ thuật và hợp đồng dữ liệu
│   ├── KICH_BAN_TEST.md          # 21 ca kiểm thử tự động
│   ├── KICH_BAN_DEMO_VIDEO.md    # Kịch bản quay video demo 5 phút
│   ├── SLIDE_THUYET_TRINH.md     # 13 slide thuyết trình bảo vệ đồ án
│   ├── DE_CUONG_BAO_CAO.md       # Đề cương báo cáo 5 chương
│   └── BAO_CAO_DO_AN.md          # Báo cáo tổng kết đồ án hoàn chỉnh
└── src/                          # Mã nguồn ứng dụng Flutter
    ├── lib/
    │   ├── core/                 # Hạ tầng dùng chung (AudioService, Theme, Constants)
    │   ├── shared/               # Hợp đồng dữ liệu chung (ChildProfile, Question, Log)
    │   └── features/
    │       ├── 1_abacus_engine/  # Finger Math Engine 2 bàn tay (Flashcard 1D RH/LH)
    │       ├── 2_gamification/   # Zero-Text UI, Streak, Cổng phụ huynh & biểu đồ
    │       ├── 3_lessons/        # Bộ sinh đề cộng trừ & Flash Anzan siêu tốc
    │       └── 4_ai_voice/       # AI Speech-to-Text tiếng Việt & Gia sư thích ứng
    └── test/                     # 21 Unit Tests tự động đạt 100%
```

---

### 4. Hướng Dẫn Cài Đặt & Khởi Chạy

#### Yêu cầu môi trường:
- Flutter SDK $\ge 3.20.0$ (Dart $\ge 3.3.0$)
- Trình duyệt Chrome hoặc môi trường Windows Desktop (Visual Studio 2022 C++)

#### Lệnh thực thi:
```powershell
# Di chuyển vào thư mục mã nguồn của nhóm
cd nhom15-65ktpm\src

# Cài đặt các gói phụ thuộc
flutter pub get

# Chạy toàn bộ 21 ca kiểm thử tự động
flutter test

# Kiểm tra chất lượng mã nguồn
dart analyze lib test

# Khởi chạy trên Web Chrome
flutter run -d chrome

# Khởi chạy ứng dụng Windows Desktop Native
flutter run -d windows
```
