# Soroban Kids App (Nhóm 15 - Lớp 65KTPM)

> **Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói.**

---

## 1. Giới Thiệu Dự Án

Trẻ em trong độ tuổi từ 4 đến 6 tuổi đang ở "giai đoạn vàng" phát triển não bộ và tư duy logic không gian. Phương pháp tính nhẩm Soroban (bàn tính gảy Nhật Bản) giúp trẻ kích thích sự phối hợp giữa hai bán cầu não thông qua việc hình dung các hạt bàn tính. Tuy nhiên, việc học toán theo cách truyền thống thường khô khan và gây quá tải đối với trẻ chưa biết đọc chữ.

**Soroban Kids App** giải quyết bài toán trên bằng cách:
1. **Phạm vi toán học tinh gọn (Chỉ giới hạn ở phép Cộng & Trừ):** Toàn bộ bài tập, công thức hạt (Anh bạn nhỏ/lớn) và tính nhẩm Flash Anzan đều được thiết kế độc quyền cho phép cộng và trừ (phạm vi từ 0 đến 99), phù hợp hoàn hảo với tư duy lứa tuổi mầm non (4–6 tuổi).
2. **Giao diện Không chữ (Zero-Text UI):** Tối ưu trải nghiệm cho trẻ 4–6 tuổi bằng biểu tượng trực quan, màu sắc thân thiện và giọng nói hướng dẫn thay thế hoàn toàn văn bản.
3. **Bàn tính ảo Soroban tương tác thực tế:** Vẽ bằng `CustomPainter` với hiệu ứng xúc giác và âm thanh chân thực khi hạt chạm thanh xà ngang.
4. **AI Trợ lý giọng nói tiếng Việt:** Ứng dụng công nghệ Speech-to-Text để trẻ đọc to kết quả bằng lời nói mà không cần gõ bàn phím.
5. **Gia sư thích ứng (Adaptive Learning):** Phân tích thời gian và độ chính xác để tự động điều chỉnh tốc độ Flash Anzan và độ khó phép tính.
6. **Gamified Discipline:** Xây dựng thói quen học tập bền vững qua hệ thống chuỗi Streak, huy hiệu và báo cáo phụ huynh minh bạch.

---

## 2. Kiến Trúc Mã Nguồn (Feature-First Clean Architecture)

Toàn bộ dự án được tổ chức theo mô hình **Feature-First Clean Architecture** kết hợp phân quyền rõ ràng giữa 4 thành viên:

```text
nhom15-65ktpm/
├── danhsachnhom.md                  # Thông tin thành viên, phân công nhiệm vụ và hướng dẫn
├── README.md                        # Tài liệu tổng quan đề tài và kỹ thuật
├── docs/                            # Tài liệu đặc tả và kịch bản kiểm thử
│   ├── KIEN_TRUC_HE_THONG.md
│   └── KICH_BAN_TEST.md
└── src/                             # Mã nguồn chính dự án Flutter
    ├── pubspec.yaml                 # Khai báo thư viện chuẩn của nhóm
    ├── analysis_options.yaml        # Bộ quy tắc lint code
    ├── assets/                      # Tài nguyên tĩnh
    │   ├── audio/sfx/               # Tiếng gảy hạt (bead_click), âm thanh chúc mừng
    │   ├── audio/voice_prompts/     # Giọng nói hướng dẫn cho trẻ
    │   ├── images/mascot/           # Linh vật dẫn dắt
    │   └── images/badges/           # Bộ sưu tập huy hiệu khen thưởng
    │
    ├── lib/
    │   ├── main.dart                # Điểm khởi chạy ứng dụng
    │   ├── injection_container.dart # Đăng ký Dependency Injection (GetIt)
    │   │
    │   ├── core/                    # [Hạ tầng cốt lõi]
    │   │   ├── constants/           # AppColors, AppDimensions, DatabaseKeys
    │   │   ├── error/               # Failures, Exceptions
    │   │   ├── services/            # AudioService, NotificationService, StorageService
    │   │   ├── theme/               # Theme vui nhộn, font chữ bo tròn
    │   │   └── utils/               # Tiện ích tính toán, format
    │   │
    │   ├── shared/                  # [Data Contract giữa 4 thành viên]
    │   │   ├── entities/            # ChildProfile, SorobanQuestion, AttemptLog
    │   │   └── widgets/             # Nút bấm to (KidButton), MasotBubbleWidget
    │   │
    │   └── features/                # 4 Module phát triển độc lập:
    │       │
    │       ├── 1_abacus_engine/     # [Nguyên Anh] Bàn tính ảo Soroban CustomPainter
    │       │   ├── domain/entities/ # SorobanColumn, BeadState
    │       │   └── presentation/    # SorobanBoardWidget, SorobanPainter, AbacusController
    │       │
    │       ├── 2_gamification_parent/ # [Thái] UI chính, Streak, Nhắc nhở, Parental Gate
    │       │   ├── data/            # Local storage cho Streak, Badges
    │       │   ├── domain/          # StreakCalculator, BadgeUnlocker
    │       │   └── presentation/    # HomeScreen, LessonSelectScreen, ParentalGateDialog
    │       │
    │       ├── 3_lessons_flash_anzan/ # [Hoài] Sinh đề bài & Tính nhẩm nhanh Flash Anzan
    │       │   ├── data/            # QuestionRepository
    │       │   ├── domain/          # QuestionGenerator (Anh bạn nhỏ/lớn), FlashAnzanTimer
    │       │   └── presentation/    # LessonPlayScreen, FlashAnzanScreen
    │       │
    │       └── 4_ai_voice_tutor/    # [Ly] AI Giọng nói tiếng Việt & Học thích ứng
    │           ├── data/            # SpeechRecognitionRepository
    │           ├── domain/          # VietnameseNumberExtractor, AdaptiveTutorEngine
    │           └── presentation/    # VoiceAnswerMicButton, VoiceWaveformAnimation
    │
    └── test/                        # Bộ kiểm thử Unit & Widget Test
        ├── abacus_engine_test.dart
        ├── number_extractor_test.dart
        └── adaptive_tutor_test.dart
```

---

## 3. Quy Tắc Phối Hợp Kỹ Thuật (Nhóm 15)

1. **Khóa Data Contract (Giao ước dữ liệu):**
   - Các Entity tại `lib/shared/entities/` (`ChildProfile`, `SorobanQuestion`, `AttemptLog`) được định nghĩa chuẩn ngay từ đầu.
   - Nhờ đó, các thành viên phát triển logic bài học, AI giọng nói và giao diện có thể hoạt động song song bằng dữ liệu mẫu (mock data) mà không bị phụ thuộc chéo.
2. **Quy tắc phân quyền nhánh Git:**
   - Nhánh chính của nhóm: `nhom15-65ktpm`.
   - Các nhánh tính năng con: `feat/abacus-core`, `feat/ui-gamification`, `feat/flash-anzan`, `feat/ai-voice`.
   - Mọi Pull Request nội bộ được nhóm trưởng rà soát để đảm bảo không vi phạm quy chuẩn thư mục và lint code.
3. **Màn hình tích hợp trung tâm (LessonPlayScreen):**
   - Ghép nối 4 thành phần độc lập:
     - Header: Linh vật Mascot cổ vũ (Module 2).
     - Trung tâm: Hiển thị số chớp nhoáng Flash Anzan hoặc phép tính (Module 3).
     - Tương tác: Bàn tính ảo Soroban gảy hạt 60fps (Module 1).
     - Điều khiển giọng nói: Nút Micro AI tự động chấm đáp án (Module 4).

---

## 4. Hướng Dẫn Chạy & Kiểm Thử

```bash
# 1. Truy cập vào thư mục mã nguồn
cd nhom15-65ktpm/src

# 2. Cài đặt thư viện
flutter pub get

# 3. Chạy toàn bộ Unit Tests
flutter test

# 4. Chạy ứng dụng trên máy ảo hoặc thiết bị thực
flutter run
```
