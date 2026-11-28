# BÁO CÁO THỰC HÀNH 4 (TH4): XÂY DỰNG ĐỀ CƯƠNG PROJECT CUỐI KỲ

### Học phần: Phát Triển Ứng Dụng Di Động - Giảng viên hướng dẫn: ThS. Đỗ Cường Oanh

---

## THÔNG TIN CHUNG

- **Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD)
- **Lớp học phần / Lớp sinh hoạt:** 65KTPM
- **Nhóm thực hiện:** Nhóm 09
- **Giảng viên hướng dẫn:** ThS. Đỗ Cường Oanh
- **Tên đề tài Project cuối kỳ:** **ỨNG DỤNG KỶ LUẬT CÁ NHÂN CẢI THIỆN KỸ NĂNG GIAO TIẾP VÀ VƯỢT RÀO CẢN NGÔN NGỮ (BUDDYTALK)**

### Bảng Thông Tin Thành Viên Nhóm 09:

| STT | Họ và Tên | Mã Sinh Viên | Lớp Sinh Hoạt | Vai Trò | Nhiệm Vụ Phân Công | Đóng Góp (%) | Email |
| :-: | :--- | :---: | :---: | :---: | :--- | :---: | :--- |
| **1** | **Phạm Văn Hưng** | **2351170598** | 65KTPM | Trưởng nhóm | Quản lý dự án, Thiết kế CSDL, Đăng nhập / Đăng ký (Email & Google) & Thiết lập hồ sơ, Quản lý phòng học, Kiểm duyệt thành viên phòng học, Phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng), Bảng Thông tin phòng, Nhắn tin Realtime, Lên lịch học bằng Video Call, Điểm danh & Tính chuỗi ngày học (theo phòng và cá nhân), Thông báo Realtime | 100% | phamvanhung21122004@gmail.com |
| **2** | **Trịnh Trung Kiên** | **2251172396** | 65KTPM | Thành viên | Thiết kế UI/UX Material 3 toàn ứng dụng, Lập trình Phân hệ Quản lý Buổi luyện tập (Practice Sessions): Tạo lịch hẹn, Đồng hồ đếm giờ học (Session Timer 15-30p), Đánh giá buổi học và Thống kê tổng giờ luyện tập | 100% | trinhkien0103@gmail.com |
| **3** | **Đỗ Việt Tiến** | **2251243452** | 65KTPM | Thành viên | Lập trình Phân hệ Tìm kiếm & Ghép cặp bạn đồng hành (Buddy Matching) theo ngôn ngữ bù trừ và bộ lọc trình độ | 100% | tien.dv.65ktpm@gmail.com |
| **4** | **Cao Đức Đạo** | **2351170581** | 65KTPM | Thành viên | Lập trình Phân hệ Gợi ý chủ đề & Kịch bản hội thoại tình huống (Conversation Topics): Kịch bản mẫu theo cấp độ A1-B2, gợi ý câu mở đầu hội thoại | 100% | caoducdao17022005@gmail.com |
| **5** | **Trương Tuấn Hải** | **2351170590** | 65KTPM | Thành viên | Lập trình Phân hệ Trợ lý Dịch thuật tức thì (Translation Assistant) & Sổ tay từ vựng: Chuẩn hóa định danh đa ngôn ngữ (`TranslationLanguage` Trung - Việt - Anh), tích hợp API Dịch song ngữ, nút dịch nhanh trong chat, tra cứu và lưu từ mới | 100% | tuanhaiii2005@gmail.com |

---

## PHẦN 1: TỔNG HỢP CÁC ỨNG DỤNG ĐÃ PHÂN TÍCH, THIẾT KẾ TRONG HỌC KỲ (CHECKLIST 1)

Trong suốt quá trình học tập và thực hành học phần Phát Triển Ứng Dụng Di Động dưới sự hướng dẫn của giảng viên ThS. Đỗ Cường Oanh, sinh viên và nhóm đã nghiên cứu, phân tích kiến trúc mã nguồn và xây dựng nguyên mẫu cho **8 ứng dụng thực tế trong suốt học kỳ**:

| STT | Tên Ứng Dụng Đã Phân Tích & Thiết Kế | Nghiệp Vụ & Chức Năng Cốt Lõi | Công Nghệ & Kiến Trúc Áp Dụng | Giá Trị Kế Thừa Cho Đồ Án Cuối Kỳ |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Ứng dụng Học Ngoại Ngữ Luyện Nói Phát Âm AI (Bài Thực Hành TH3)** | Luyện phát âm tiếng Anh, stream âm thanh thời gian thực (WebSocket), AI Faster-Whisper + CMUdict chấm điểm âm vị, tô màu từ sai, đếm giờ học và chuỗi ngày rèn luyện (Streak). | • Flutter Material 3, Waveform<br>• WebSocket Audio Streaming<br>• Faster-Whisper + Needleman-Wunsch<br>• Firebase Auth + Supabase (6 bảng) | **Kế thừa trực tiếp:** Mô hình luyện nói, nhận diện giọng nói và kiến trúc Backend Cloud. |
| **2** | **Ứng dụng Kỷ Luật Cá Nhân & Quản Lý Thói Quen (Habit Tracker)** | Quản lý thói quen hàng ngày, check-in tiến độ, tính chuỗi ngày kỷ luật (Streak), thanh trượt chọn ngày, biểu đồ cột tuần, ma trận Heatmap, đổi theme Sáng/Tối. | • Flutter SDK 3.x, Provider<br>• SQLite cục bộ (`sqflite`)<br>• SharedPreferences (Theme) | **Kế thừa trực tiếp:** Bộ khung quản lý thói quen, chuỗi Streak, ma trận Heatmap và CSDL SQLite cục bộ. |
| **3** | **Hệ Thống Quản Lý Tài Liệu Học Tập Đa Nền Tảng (Bài Thực Hành TH2)** | Hệ thống quản lý tài liệu học phần, xem trước file PDF/Docs, bảo mật phân quyền dữ liệu mức dòng Row Level Security (RLS). | • Flutter Responsive (Mobile/Web)<br>• Firebase Authentication (OAuth)<br>• Supabase PostgreSQL Cloud RLS | **Kế thừa:** Cơ chế xác thực tài khoản Google và phân quyền bảo mật dữ liệu người dùng. |
| **4** | **Ứng dụng Nhật Ký Đa Phương Tiện Bảo Mật (Daily You)** | Phân tích mã nguồn mở chuyên sâu: viết nhật ký hành trình, quản lý đa phương tiện (ảnh/video), bảo mật riêng tư tuyệt đối (Privacy by Design), Offline-First. | • Flutter SDK, Clean Architecture<br>• Offline-First (gỡ quyền Internet)<br>• Xử lý Media / Video Player | **Kế thừa:** Triết lý bảo vệ quyền riêng tư và tối ưu hóa trải nghiệm Offline-First. |
| **5** | **Ứng dụng Quản Lý Tài Chính Cá Nhân (Cashew)** | Phân tích mã nguồn mở: ghi chép thu chi, phân bổ hạn mức ngân sách, báo cáo biểu đồ trực quan, hỗ trợ đa tiền tệ. | • Flutter Native, Clean Architecture<br>• Local-First với Hive / SQLite<br>• Trực quan hóa dữ liệu biểu đồ | **Kế thừa:** Cấu trúc phân tầng Clean Architecture và kỹ thuật trực quan hóa dữ liệu biểu đồ. |
| **6** | **Ứng dụng Hồ Sơ Cá Nhân Android Native (Java & XML Layout)** | Lập trình Android gốc: Hồ sơ cá nhân (Business Card), bố cục co giãn ConstraintLayout, NestedScrollView, sự kiện Intent mở web/email/call. | • Android Native (Java + XML)<br>• MaterialCardView bo tròn 16dp<br>• Intent.ACTION_VIEW / SENDTO | **Kế thừa:** Tư duy lập trình di động tầng sâu trên hệ điều hành Android gốc. |
| **7** | **Ứng dụng Hồ Sơ Cá Nhân Đa Nền Tảng (Bài Thực Hành TH1 / Flutter)** | Business Card điện tử: giới thiệu kỹ năng, kinh nghiệm, dự án, liên hệ mạng xã hội, điều hướng NavigationBar 4 tabs, Box Model. | • Flutter SDK (Dart)<br>• Box Model & Composition Layout<br>• Responsive không lỗi tràn viền | **Kế thừa:** Kỹ năng bố cục giao diện responsive, chống lỗi tràn viền (RenderFlex overflow). |
| **8** | **Bộ Bài Tập Thực Hành Giao Diện Cơ Bản (Layout & Core Widgets)** | Làm quen vòng đời ứng dụng Flutter, làm chủ StatelessWidget, StatefulWidget và các widget hiển thị cơ bản. | • Flutter Core Widgets<br>• Bố cục Row, Column, Container | **Kế thừa:** Nền tảng lập trình Flutter sơ khởi ban đầu. |

---

## PHẦN 2: LỰA CHỌN ỨNG DỤNG PHÙ HỢP LÀM PROJECT CUỐI KỲ (CHECKLIST 2)

### Đề tài được lựa chọn:

**ỨNG DỤNG KỶ LUẬT CÁ NHÂN CẢI THIỆN KỸ NĂNG GIAO TIẾP VÀ VƯỢT RÀO CẢN NGÔN NGỮ (BUDDYTALK)**

### 5 Luận điểm then chốt lựa chọn đề tài:

1. **Đúng chuẩn định hướng học phần:** Đề tài bám sát tài liệu chính thức của giảng viên trên hệ thống đào tạo MIS: *"Tài liệu: Xây dựng ứng dụng kỷ luật cá nhân với flutter"*, kết hợp chặt chẽ với giải bài toán thực tế của sinh viên.
2. **Khắc phục triệt để "nỗi đau" học giao tiếp:** Giải quyết vấn đề lớn nhất của người tự học ngoại ngữ (tiếng Anh, tiếng Trung...): Tìm bạn luyện nói nhưng nhanh chóng bỏ cuộc sau 2-3 ngày vì thiếu kỷ luật, không có chủ đề cụ thể và gặp rào cản bất đồng ngôn ngữ.
3. **Mô hình kiềng 3 chân đột phá:** Không đơn thuần là app học từ vựng hay mạng xã hội tìm bạn, BuddyTalk kết hợp chặt chẽ 3 yếu tố: **Kỷ luật cá nhân (Streak/Heatmap)** + **Kết nối bạn đồng hành bù trừ ngôn ngữ (Buddy Matching)** + **Thực hành giao tiếp thực tế qua Chat 1-1 & Chat Nhóm học tập đa người dùng**.
4. **Tập trung sâu vào giao tiếp trực tuyến linh hoạt:** Hỗ trợ song song cả **Chat 1-1** riêng tư và **Chat Nhóm học tập (Study Group Rooms)** cho phép nhiều người cùng vào phòng luyện giao tiếp theo chủ đề, kết hợp dịch tức thì và gợi ý kịch bản tình huống phong phú.
5. **Khối lượng công việc cân bằng cho nhóm 5 người:** Áp dụng kiến trúc Feature-First kết hợp Pragmatic Clean Architecture, tích hợp CSDL **Supabase Cloud PostgreSQL 100% trực tuyến**, Supabase Realtime WebSocket, Firebase Auth và Translation API, đảm bảo cả 5 thành viên đều có phân hệ độc lập, rõ ràng và đóng góp 100% công sức.

---

## PHẦN 3: ĐỀ CƯƠNG CHI TIẾT PROJECT CUỐI KỲ (CHECKLIST 3)

### 3.1. Mục tiêu của Project

- **Mục tiêu tổng quát:** Xây dựng ứng dụng di động hoàn chỉnh bằng Flutter, đóng vai trò là "Người quản trị kỷ luật và Cầu nối kèm cặp", giúp người dùng rèn luyện thói quen giao tiếp mỗi ngày thông qua mục tiêu cụ thể, chuỗi ngày kỷ luật (Streak), ma trận nhiệt (Heatmap Grid), ghép cặp bạn đồng hành bù trừ ngôn ngữ (Language Buddy) và phòng chat thực chiến thời gian thực (hỗ trợ cả Chat 1-1 và Chat Nhóm học tập, dịch tức thì và kho kịch bản tình huống).
- **Mục tiêu cụ thể:**
  - Hoàn thiện giao diện Material 3 đa nền tảng (Web Dashboard & Mobile).
  - Quản lý xác thực Firebase Auth (Email & Google), tự động khôi phục phiên và thiết lập hồ sơ ban đầu (Onboarding).
  - Hệ thống Quản lý phòng học, Chat & Video Call Realtime: Khám phá/tạo phòng học (ảnh bìa, định hướng kỹ năng, trình độ, sức chứa), kiểm duyệt thành viên, phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng), bảng Thông tin phòng, nhắn tin Realtime, lên lịch học bằng Video Call, điểm danh & tính chuỗi ngày học (chuỗi theo từng phòng và chuỗi mục tiêu ngày cá nhân) và Thông báo Realtime.
  - Xây dựng thuật toán ghép cặp bạn học bù trừ ngôn ngữ (Vietnamese ⇄ English/Chinese).
  - Tích hợp công cụ Dịch tức thì (Instant Translate) hiển thị song song câu gốc - câu dịch và Sổ tay lưu từ vựng (Vocabulary Notebook).
  - Kho kịch bản và chủ đề hội thoại tình huống theo cấp độ (A1, A2, B1...), giải quyết triệt để vấn đề "không biết nói gì".
  - Quản lý buổi luyện tập (Practice Sessions): bấm giờ thời lượng thực hành (Session Timer 15-30 phút), ghi chú từ vựng và đánh giá đối tác sau buổi học.

### 3.2. Phạm vi nghiên cứu (Scope)

- **Đối tượng người dùng:** Sinh viên, học sinh, người học ngoại ngữ muốn tìm bạn đồng hành luyện tập và rèn luyện thói quen giao tiếp kỷ luật mỗi ngày.
- **Nền tảng triển khai:** Ứng dụng di động đa nền tảng, tập trung tối ưu hóa cho hệ điều hành **Android** (hỗ trợ từ Android 8.0 trở lên).
- **Phạm vi dữ liệu:** Dữ liệu mục tiêu kỷ luật, chuỗi Streak, lịch sử hoàn thành nhiệm vụ, hồ sơ ngôn ngữ, danh sách ghép cặp bạn học, tin nhắn chat 1-1 và tin nhắn nhóm realtime kèm bản dịch, kho chủ đề hội thoại và nhật ký các buổi luyện tập.

### 3.3. Các phân hệ chức năng chính (Bản Vẽ Hệ Thống)

```text
HỆ THỐNG KỶ LUẬT GIAO TIẾP & BẠN ĐỒNG HÀNH (BUDDYTALK)
├── 1. Phân hệ Xác Thực Tài Khoản & Thiết Lập Hồ Sơ Người Dùng (Auth & Onboarding)
│   ├── Đăng nhập / Đăng ký bằng Email & Google (Firebase Authentication), tự khôi phục phiên
│   ├── Luồng Thiết lập hồ sơ 2 bước (Onboarding): Ảnh đại diện, tên hiển thị, ngôn ngữ (từ bảng languages), trình độ & mục tiêu phút/ngày
│   └── Quản lý hồ sơ cá nhân & phân quyền người dùng trên Supabase Cloud
├── 2. Phân hệ Phòng Học, Chat Realtime, Phân Quyền & Lên Lịch Học Bằng Video Call
│   ├── Khám phá, tìm kiếm, lọc, phân trang phòng học & cột Cộng đồng (phòng sôi nổi, bạn bè đang online)
│   ├── Tạo phòng học nhóm (ảnh bìa, định hướng kỹ năng, trình độ, giới hạn thành viên, vào ngay / cần kiểm duyệt)
│   ├── Kiểm duyệt thành viên vào phòng (Xin tham gia -> Chờ duyệt -> Duyệt / Từ chối)
│   ├── Không gian học 2 cột & Nhắn tin Realtime (Supabase Realtime WebSocket)
│   ├── Bảng Thông tin phòng (thành viên, sửa nội quy, link đã chia sẻ, rời phòng) & Phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng)
│   ├── Lên lịch học bằng Video Call trực tiếp trong phòng học
│   └── Điểm danh tự động & Tính chuỗi ngày học (chuỗi lửa từng phòng và chuỗi mục tiêu ngày cá nhân)
├── 3. Phân hệ Thông Báo Thời Gian Thực (Realtime Notifications)
│   ├── Chuông thông báo trên Header cập nhật tức thì qua WebSocket (`public.notifications`)
│   ├── Dropdown kiểu Facebook (Tất cả / Chưa đọc / Đọc tất cả) & lịch sử duyệt/từ chối
│   └── Bấm thông báo xin tham gia mở trực tiếp hộp thoại duyệt thành viên & tự đồng bộ phòng
├── 4. Phân hệ Tìm Kiếm & Kết Nối Bạn Đồng Hành (Buddy Matching)
│   ├── Bộ lọc tìm kiếm theo ngôn ngữ học và ngôn ngữ có thể hỗ trợ
│   ├── Ghép cặp 2 chiều theo nhu cầu bù trừ (Việt học Ngoại ngữ ⇄ Nước ngoài học Tiếng Việt)
│   ├── Gửi, chấp nhận hoặc từ chối lời mời kèm cặp (Buddy Request)
│   └── Danh sách bạn học đang đồng hành (Active Buddies)
├── 5. Phân hệ Gợi Ý Chủ Đề & Kịch Bản Hội Thoại (Conversation Topics)
│   ├── Thư viện kịch bản hội thoại mẫu phân loại theo cấp độ (A1, A2, B1...)
│   ├── Chủ đề đa dạng: Giới thiệu bản thân, Du lịch, Công việc, Sở thích, Đời sống
│   ├── Bộ câu hỏi gợi ý mở đầu hội thoại (Conversation Starters) chống "bí từ"
│   └── Đánh dấu các chủ đề đã hoàn thành sau mỗi buổi luyện tập
├── 6. Phân hệ Trợ Lý Dịch Thuật Tức Thì & Sổ Tay Từ Vựng (Translation Assistant & Notebook)
│   ├── Chuẩn hóa định danh & bộ chuyển đổi mã đa ngôn ngữ (Trung - Việt - Anh, Tự động nhận diện)
│   ├── Nút dịch trực tiếp bên trong bong bóng tin nhắn chat 1-1 và chat nhóm
│   ├── Hiển thị song song câu gốc và câu dịch (Trung - Việt - Anh)
│   ├── Tra cứu nhanh nghĩa từ mới và lưu vào Sổ tay từ vựng cá nhân (Vocabulary Notebook)
│   └── Gợi ý cách diễn đạt tự nhiên hơn
└── 7. Phân hệ Quản Lý Buổi Luyện Tập & Thống Kê (Practice Sessions & Analytics)
    ├── Tạo lịch hẹn và thiết lập thời lượng buổi học (15p, 20p, 30p)
    ├── Đồng hồ đếm ngược thời gian thực hành tương tác (Session Timer)
    ├── Ghi chú từ vựng mới và điểm cần cải thiện trong buổi học
    └── Đánh giá, chấm sao đối tác và Biểu đồ thống kê tổng giờ luyện nói trong tuần
```

### 3.4. Kiến trúc hệ thống & Cơ sở dữ liệu sử dụng

#### a) Kiến trúc mã nguồn: Feature-First kết hợp Pragmatic Clean Architecture

Nhằm phục vụ quá trình làm việc nhóm 5 thành viên hiệu quả, tránh xung đột mã nguồn (Zero Git Merge Conflicts), nhóm áp dụng mô hình **Feature-First kết hợp Clean Architecture thực dụng**:

- **Tầng Core (`lib/core/`):** Chứa các thành phần dùng chung: constants, theme Material 3, utils, network, widgets chung.
- **Tầng Features (`lib/features/`):** Phân chia thành các phân hệ độc lập tương ứng với 5 thành viên:
  - `auth_profile/`, `chat/`, `notifications/`: Đăng nhập / Đăng ký & Thiết lập hồ sơ (Onboarding), Quản lý phòng học, Kiểm duyệt thành viên, Phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng), Bảng Thông tin phòng, Nhắn tin Realtime, Lên lịch học bằng Video Call, Điểm danh & Tính chuỗi ngày học (theo phòng và cá nhân) & Thông báo Realtime (Thành viên 1 - Phạm Văn Hưng).
  - `session_management/`: Quản lý buổi học, Session Timer, Đánh giá đối tác & Bộ Theme UI Material 3 toàn app (Thành viên 2 - Trịnh Trung Kiên).
  - `buddy_matching/`: Tìm kiếm & Ghép cặp bạn đồng hành bù trừ ngôn ngữ (Thành viên 3 - Đỗ Việt Tiến).
  - `conversation_topics/`: Kho kịch bản chủ đề hội thoại tình huống A1-B2 & Starters (Thành viên 4 - Cao Đức Đạo).
  - `vocab_notebook/` & `chat_online/`: Trợ lý dịch tức thì (`TranslationLanguage`, `TranslationResult`, `TranslationService` hỗ trợ Trung - Việt - Anh đa nền tảng Web/Android & Cache), tầng dữ liệu & quản lý trạng thái Sổ tay từ vựng (`VocabEntryModel`, `VocabFilter`, `VocabRepository`, `VocabProvider` kết nối bảng `vocab_notebook` Supabase) và bộ `VocabStyles` Material 3 (Thành viên 5 - Trương Tuấn Hải).
- Mỗi thư mục tính năng gồm 2 tầng rõ ràng:
  - `data/`: Models, Repositories kết nối trực tuyến tới Supabase Cloud / Firebase.
  - `presentation/`: Màn hình giao diện (Screens/Components/Styles), Quản lý trạng thái bằng **Provider / ChangeNotifier** ($UI = f(State)$).

#### b) Kiến trúc Cơ sở dữ liệu: Firebase Authentication + Supabase Cloud PostgreSQL & Realtime (100% Online)

1. **Xác thực tài khoản (Firebase Authentication):**
   - Đăng nhập bằng Email/Mật khẩu và Google Sign-In an toàn, tự động khôi phục phiên làm việc (Session Persistence).
2. **CSDL Đám mây & Realtime (Supabase Cloud PostgreSQL & Realtime Channels):**
   - Quản lý dữ liệu trung tâm 100% trực tuyến với các bảng quan hệ chuẩn hóa:
     - `users`, `user_accounts`, `profiles`, `languages`: Tài khoản đa phương thức, hồ sơ người dùng, danh mục ngôn ngữ cấp phép và trạng thái Onboarding.
     - `conversations`, `conversation_members`: Phòng học nhóm & Chat 1-1 (ảnh bìa `cover_url`, định hướng `room_focus`, kiểm duyệt `require_approval`, phân quyền `owner` / `co_owner` / `member`, chuỗi lửa phòng `streak_count`, `best_streak`, `last_chat_date`).
     - `messages`: Lịch sử tin nhắn hội thoại Realtime.
     - `room_meet_sessions`, `room_meet_attendance`, `user_quest_logs`: Lịch học bằng Video Call, điểm danh thời lượng học thực tế và tích lũy phút mục tiêu ngày cá nhân.
     - `notifications`: Thông báo Realtime dùng chung toàn ứng dụng (xin vào phòng, duyệt/từ chối, bổ nhiệm Trợ giảng, hẹn lịch Meet).
     - `buddy_matches`: Danh sách và trạng thái kết nối giữa các cặp bạn học (`pending`, `accepted`, `rejected`, `blocked`).
     - `conversation_topics`, `user_topic_progress`: Kho danh mục chủ đề và kịch bản hội thoại mẫu theo cấp độ.
     - `practice_sessions`, `vocab_notebook`: Lịch sử buổi luyện tập và sổ tay từ vựng cá nhân.
   - **Kênh WebSocket Realtime:** Khai thác **Supabase Realtime Channel** cho `messages`, `notifications`, `conversations`, `conversation_members`, `room_meet_sessions` giúp cập nhật tức thì không cần tải lại trang.

#### c) Danh mục thư viện & công nghệ cốt lõi

- **Nền tảng:** Flutter SDK (3.x trở lên), Dart SDK.
- **Xác thực tài khoản:** `firebase_core`, `firebase_auth`, `google_sign_in`.
- **CSDL Đám mây & Realtime:** `supabase_flutter` (PostgreSQL + Realtime WebSocket).
- **Video Call trực tuyến:** Jitsi Meet nhúng trực tiếp.
- **Dịch thuật tức thì:** Package `translator` (`GoogleTranslator`, hỗ trợ đa nền tảng Web/Android cho Trung - Việt - Anh).
- **Quản lý trạng thái:** `provider`.

---

### 3.5. Kế hoạch thực hiện & Phân công chi tiết (2 tuần)

| Tuần | Nội dung công việc cụ thể | Phân công chi tiết cả 5 thành viên | Sản phẩm bàn giao (Deliverables) |
| :---: | :--- | :--- | :--- |
| **Tuần 1**<br>*(Thiết kế, CSDL & Phân hệ nền tảng)* | • Khảo sát yêu cầu (SRS), thiết kế giao diện Material 3 và khởi tạo khung dự án Flutter theo kiến trúc Feature-First.<br>• Cấu hình Firebase Auth (Email & Google) và thiết kế CSDL trực tuyến 100% trên Supabase Cloud (PostgreSQL + Realtime).<br>• Lập trình Đăng nhập / Đăng ký, Thiết lập hồ sơ (Onboarding), Quản lý phòng học, Kiểm duyệt thành viên, Nhắn tin Realtime & Thông báo Realtime.<br>• Thiết kế dữ liệu và giao diện cơ bản cho Ghép cặp bạn học, Kho chủ đề hội thoại, Dịch tức thì & Quản lý buổi luyện tập. | • **Phạm Văn Hưng (Trưởng nhóm):** Khởi tạo dự án Flutter, thiết kế CSDL Supabase Cloud, lập trình Đăng nhập / Đăng ký & Onboarding, Quản lý phòng học, Kiểm duyệt thành viên, Nhắn tin Realtime & Thông báo Realtime.<br>• **Trịnh Trung Kiên:** Thiết kế UI/UX Material 3 toàn ứng dụng và khung màn hình Quản lý buổi luyện tập.<br>• **Đỗ Việt Tiến:** Thiết kế bảng `buddy_matches` và giao diện Tìm kiếm / Ghép cặp bạn đồng hành.<br>• **Cao Đức Đạo:** Biên soạn kho chủ đề & kịch bản hội thoại A1–B2, thiết kế bảng `conversation_topics`.<br>• **Trương Tuấn Hải:** Tích hợp API Dịch tức thì đa nền tảng (Trung - Việt - Anh, tự động nhận diện ngôn ngữ trong phòng chat), cấu trúc Sổ tay từ vựng và chuẩn hóa Unit Test (`flutter_test`) cho dịch thuật đa chiều. | Đề cương SRS, khung dự án Flutter chạy ổn định, CSDL Supabase Cloud, các phân hệ Auth, Phòng học, Chat & Thông báo Realtime và API Dịch thuật. |
| **Tuần 2**<br>*(Tính năng nâng cao, Kiểm thử & Đóng gói)* | • Hoàn thiện Phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng), Bảng Thông tin phòng, Lên lịch học bằng Video Call, Điểm danh & Tính chuỗi ngày học (theo phòng và cá nhân).<br>• Hoàn thiện Ghép cặp bạn đồng hành, Thư viện chủ đề hội thoại, Tích hợp nút Dịch tức thì + Sổ tay từ vựng và Quản lý buổi luyện tập.<br>• Viết Unit/Widget Test, kiểm thử toàn diện (`flutter analyze` 0 cảnh báo) và đóng gói `app-release.apk`.<br>• Hoàn thiện báo cáo đồ án, slide bảo vệ, video demo và nộp bài đúng chuẩn Git/GitHub. | • **Phạm Văn Hưng (Trưởng nhóm):** Hoàn thiện Phân quyền thành viên trong phòng học (Chủ phòng, Trợ giảng, Người dùng), Bảng Thông tin phòng, Lên lịch học bằng Video Call, Điểm danh & Tính chuỗi ngày học, kiểm duyệt PR và đóng gói tài liệu nộp bài.<br>• **Trịnh Trung Kiên:** Hoàn thiện Quản lý buổi luyện tập (Session Timer, đánh giá đối tác) & phối hợp đóng gói `app-release.apk`.<br>• **Đỗ Việt Tiến:** Hoàn thiện ghép cặp bạn học bù trừ ngôn ngữ, gửi/nhận lời mời và danh sách bạn đồng hành.<br>• **Cao Đức Đạo:** Hoàn thiện thư viện chủ đề A1–B2, bộ lọc cấp độ và gợi ý câu mở đầu hội thoại.<br>• **Trương Tuấn Hải:** Hoàn thiện dịch tức thì trong chat, tra cứu & lưu Sổ tay từ vựng.<br>• **Cả nhóm 09:** Kiểm thử chéo, hoàn thiện Báo cáo, Slide thuyết trình và Video demo. | Ứng dụng BuddyTalk hoàn chỉnh, `app-release.apk`, Báo cáo đồ án, Slide thuyết trình & Video demo. |

---

## PHẦN 4: KẾT LUẬN & CAM KẾT CỦA NHÓM

Đề cương Project cuối kỳ của Nhóm 09 được xây dựng chặt chẽ, thực tiễn và giải quyết trực diện bài toán rèn luyện kỹ năng giao tiếp của sinh viên. Bằng việc kết hợp hài hòa giữa **Kỷ luật cá nhân (Streak/Heatmap)**, **Kết nối bạn đồng hành bù trừ ngôn ngữ (Buddy Matching)**, **Kho chủ đề hội thoại tình huống phong phú** và **Phòng Chat Realtime (hỗ trợ cả Chat 1-1 và Chat Nhóm học tập đa người dùng cùng học)**, ứng dụng đảm bảo tính khả thi kỹ thuật cao, loại bỏ hoàn toàn các rủi ro phức tạp về phần cứng định vị ngoài đời và tập trung tối đa vào trải nghiệm người dùng. Toàn thể 5 thành viên Nhóm 09 cam kết phối hợp kỷ luật, nộp bài đúng chuẩn Git/GitHub và hoàn thành đúng tiến độ.
