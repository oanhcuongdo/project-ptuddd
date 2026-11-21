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
| **1** | **Phạm Văn Hưng** | **2351170598** | 65KTPM | Trưởng nhóm | Quản lý dự án, Thiết kế CSDL (Supabase + SQLite), Firebase Auth & Hồ sơ người dùng, Phân hệ Kỷ luật (Mục tiêu hàng ngày, Streak, Heatmap), Phân hệ Chat Realtime (Chat 1-1 & Chat Nhóm học tập) | 100% | phamvanhung21122004@gmail.com |
| **2** | **Trịnh Trung Kiên** | **2251172396** | 65KTPM | Thành viên | Thiết kế UI/UX Material 3 toàn ứng dụng, Lập trình Phân hệ Quản lý Buổi luyện tập (Practice Sessions): Tạo lịch hẹn, Đồng hồ đếm giờ học (Session Timer 15-30p), Đánh giá buổi học và Thống kê tổng giờ luyện tập | 100% | trinhkien0103@gmail.com |
| **3** | **Đỗ Việt Tiến** | **2251243452** | 65KTPM | Thành viên | Lập trình Phân hệ Tìm kiếm & Ghép cặp bạn đồng hành (Buddy Matching) theo ngôn ngữ bù trừ và bộ lọc trình độ | 100% | tien.dv.65ktpm@gmail.com |
| **4** | **Cao Đức Đạo** | **2351170581** | 65KTPM | Thành viên | Lập trình Phân hệ Gợi ý chủ đề & Kịch bản hội thoại tình huống (Conversation Topics): Kịch bản mẫu theo cấp độ A1-B2, gợi ý câu mở đầu hội thoại | 100% | caoducdao17022005@gmail.com |
| **5** | **Trương Tuấn Hải** | **2351170590** | 65KTPM | Thành viên | Lập trình Phân hệ Trợ lý Dịch thuật tức thì (Translation Assistant) & Sổ tay từ vựng: Tích hợp API Dịch song ngữ (Trung - Việt - Anh), nút dịch nhanh trong chat, tra cứu và lưu từ mới | 100% | tuanhaiii2005@gmail.com |

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
5. **Khối lượng công việc cân bằng cho nhóm 5 người:** Áp dụng kiến trúc Feature-First kết hợp Pragmatic Clean Architecture, tích hợp CSDL SQLite cục bộ (Offline-First), Supabase Realtime WebSocket, Firebase Auth và Translation API, đảm bảo cả 5 thành viên đều có phân hệ độc lập, rõ ràng và đóng góp 100% công sức.

---

## PHẦN 3: ĐỀ CƯƠNG CHI TIẾT PROJECT CUỐI KỲ (CHECKLIST 3)

### 3.1. Mục tiêu của Project

- **Mục tiêu tổng quát:** Xây dựng ứng dụng di động hoàn chỉnh bằng Flutter, đóng vai trò là "Người quản trị kỷ luật và Cầu nối kèm cặp", giúp người dùng rèn luyện thói quen giao tiếp mỗi ngày thông qua mục tiêu cụ thể, chuỗi ngày kỷ luật (Streak), ma trận nhiệt (Heatmap Grid), ghép cặp bạn đồng hành bù trừ ngôn ngữ (Language Buddy) và phòng chat thực chiến thời gian thực (hỗ trợ cả Chat 1-1 và Chat Nhóm học tập, dịch tức thì và kho kịch bản tình huống).
- **Mục tiêu cụ thể:**
  - Hoàn thiện giao diện Material 3 (hỗ trợ trọn vẹn Dark/Light mode).
  - Quản lý mục tiêu kỷ luật hàng ngày, tính chuỗi Streak và ma trận nhiệt Heatmap chuyên cần trên CSDL SQLite cục bộ (Offline-First).
  - Hệ thống phòng Chat Realtime: Trò chuyện 1-1 ghép đôi và Phòng Chat Nhóm học tập đa người dùng (Group Chat) theo chủ đề.
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
├── 1. Phân hệ Xác Thực Tài Khoản & Quản Lý Hồ Sơ Người Dùng (Auth & Profile)
│   ├── Đăng nhập một chạm qua Google (Firebase Authentication)
│   ├── Quản lý hồ sơ cá nhân: Ảnh đại diện, ngôn ngữ mẹ đẻ, ngôn ngữ học, trình độ
│   ├── Cấu hình giao diện Sáng / Tối (SharedPreferences)
│   └── Báo cáo người dùng vi phạm và chặn đối tác không mong muốn
├── 2. Phân hệ Quản Lý Kỷ Luật Cá Nhân (Personal Discipline)
│   ├── Thiết lập mục tiêu luyện giao tiếp hằng ngày (15 - 30 phút/ngày)
│   ├── Thanh trượt chọn ngày linh hoạt & Check-in nhiệm vụ
│   ├── Tính chuỗi ngày liên tiếp (Streak) & Ma trận nhiệt (Heatmap Calendar Grid)
│   └── Thống kê tiến độ chuyên cần theo ngày, tuần, tháng (CSDL SQLite Offline-First)
├── 3. Phân hệ Chat Trực Tuyến Thời Gian Thực: 1-1 & Nhóm Học Tập (Realtime Chat & Group Rooms)
│   ├── Phòng Chat 1-1 ghép đôi thời gian thực qua WebSocket (Supabase Realtime)
│   ├── Phòng Chat Nhóm học tập (Study Group Rooms) cho phép nhiều thành viên cùng vào luyện nói theo chủ đề
│   ├── Trạng thái trực tuyến / ngoại tuyến (Online/Offline Status)
│   └── Lưu trữ, đồng bộ lịch sử hội thoại đám mây & gửi hình ảnh
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
  - `auth_discipline_chat/`: Xác thực Firebase Auth, Hồ sơ người dùng, Kỷ luật cá nhân (Streak/Heatmap/SQLite), Phòng Chat 1-1 & Chat Nhóm học tập (Thành viên 1 - Phạm Văn Hưng).
  - `session_management/`: Quản lý buổi học, Session Timer, Đánh giá đối tác & Bộ Theme UI Material 3 toàn app (Thành viên 2 - Trịnh Trung Kiên).
  - `buddy_matching/`: Tìm kiếm & Ghép cặp bạn đồng hành bù trừ ngôn ngữ (Thành viên 3 - Đỗ Việt Tiến).
  - `conversation_topics/`: Kho kịch bản chủ đề hội thoại tình huống A1-B2 & Starters (Thành viên 4 - Cao Đức Đạo).
  - `translation_notebook/`: Trợ lý dịch tức thì, Hiển thị song ngữ & Sổ tay từ vựng ôn tập (Thành viên 5 - Trương Tuấn Hải).
- Mỗi thư mục tính năng gồm 2 tầng rõ ràng:
  - `data/`: Models, Data Sources (SQLite / Supabase), Repositories.
  - `presentation/`: Màn hình giao diện (Screens/Widgets), Quản lý trạng thái bằng **Provider / ChangeNotifier** ($UI = f(State)$).

#### b) Kiến trúc Cơ sở dữ liệu: Bộ đôi Firebase Auth + Supabase Realtime + SQLite Cục bộ

1. **Xác thực tài khoản (Firebase Authentication):**
   - Đăng nhập Google (Google Sign-In) một chạm an toàn, tự động quản lý phiên làm việc (Session).
2. **CSDL Đám mây & Realtime (Supabase Cloud Database & Realtime Channels):**
   - Quản lý dữ liệu trung tâm với các bảng quan hệ chuẩn hóa:
     - `profiles`: Thông tin cá nhân, ngôn ngữ mẹ đẻ (`native_lang`), ngôn ngữ học (`target_lang`), trình độ, chuỗi Streak.
     - `buddy_matches`: Danh sách và trạng thái kết nối giữa các cặp bạn học (Pending, Accepted, Blocked).
     - `messages`: Lưu trữ tin nhắn hội thoại (tin nhắn 1-1 và tin nhắn trong phòng nhóm, bao gồm bản dịch).
     - `study_groups`: Quản lý danh sách các phòng học nhóm đa người dùng theo chủ đề.
     - `group_members`: Quản lý danh sách thành viên tham gia từng phòng học nhóm.
     - `conversation_topics`: Kho danh mục chủ đề và kịch bản hội thoại mẫu theo cấp độ.
     - `practice_sessions`: Lưu lịch sử các buổi học, thời lượng thực hành, ghi chú và điểm đánh giá.
     - `user_quest_logs`: Lịch sử check-in kỷ luật và ma trận nhiệt hàng ngày.
   - **Kênh Chat Realtime:** Khai thác **Supabase Realtime Channel (WebSocket)** giúp tin nhắn chat hiển thị tức thì với độ trễ < 100ms.
3. **Lưu trữ Cục bộ & Triết lý Offline-First (SQLite):**
   - Sử dụng `sqflite` lưu bộ nhớ đệm (Cache) danh sách nhiệm vụ kỷ luật và chủ đề hội thoại. Người dùng có thể check-in và ôn lại bài ngay cả khi không có kết nối mạng.

#### c) Danh mục thư viện & công nghệ cốt lõi

- **Nền tảng:** Flutter SDK (3.x trở lên), Dart SDK.
- **Xác thực tài khoản:** `firebase_core`, `firebase_auth`, `google_sign_in`.
- **CSDL Đám mây & Realtime:** `supabase_flutter`.
- **CSDL Cục bộ (Offline-First):** `sqflite`, `path_provider`.
- **Dịch thuật tức thì:** `translator` (hỗ trợ Trung - Việt - Anh).
- **Quản lý trạng thái:** `provider`.
- **Thông báo & Cấu hình:** `flutter_local_notifications`, `shared_preferences`.

---

### 3.5. Kế hoạch thực hiện & Phân công chi tiết (3 tuần)

| Tuần | Nội dung công việc cụ thể | Phân công chi tiết cả 5 thành viên | Sản phẩm bàn giao (Deliverables) |
| :---: | :--- | :--- | :--- |
| **Tuần 1**<br>*(Khởi động, Thiết kế & CSDL)* | • Khảo sát yêu cầu chi tiết (SRS), vẽ sơ đồ Use Case, Activity Diagram.<br>• Thiết kế Prototype Figma hoàn chỉnh cho các màn hình ứng dụng.<br>• Khởi tạo dự án Flutter theo kiến trúc Feature-First, cấu hình Theme Material 3 (Dark/Light).<br>• Tích hợp Firebase Auth (Google Sign-In), thiết kế các bảng CSDL trên Supabase & SQLite cục bộ (`sqflite`).<br>• Xây dựng bộ dữ liệu mẫu cho Kho chủ đề hội thoại và cấu hình API Dịch thuật. | • **Phạm Văn Hưng (Trưởng nhóm):** Phân tích SRS, khởi tạo khung dự án Flutter, cấu hình Firebase Auth & CSDL Supabase, thiết kế kiến trúc Chat Realtime & SQLite kỷ luật.<br>• **Trịnh Trung Kiên:** Thiết kế UI/UX Prototype Figma, xây dựng Theme Material 3 toàn hệ thống và thiết kế luồng quản lý buổi học.<br>• **Đỗ Việt Tiến:** Thiết kế luồng Use Case Ghép cặp bạn học, thiết kế bảng `buddy_matches` và UI tìm kiếm bạn.<br>• **Cao Đức Đạo:** Thu thập và biên soạn danh mục kịch bản chủ đề giao tiếp (A1-B2), thiết kế bảng `conversation_topics`.<br>• **Trương Tuấn Hải:** Nghiên cứu API Dịch thuật, thiết kế cấu trúc dữ liệu Sổ tay từ vựng và giao diện dịch trong chat. | Bản đặc tả SRS, Figma Prototype, Khung dự án Flutter chạy được, CSDL Supabase & SQLite sẵn sàng. |
| **Tuần 2**<br>*(Lập trình các Phân hệ cốt lõi)* | • Lập trình xác thực Đăng nhập Google, quản lý hồ sơ và CSDL SQLite Offline-First.<br>• Xây dựng Màn hình Kỷ luật hàng ngày, tính Streak và ma trận Heatmap.<br>• Lập trình Phòng Chat Realtime 1-1 và Phòng Chat Nhóm học tập đa người dùng.<br>• Lập trình thuật toán ghép cặp bạn học bù trừ ngôn ngữ và danh sách bạn đồng hành.<br>• Lập trình Màn hình Thư viện chủ đề hội thoại tình huống và bộ gợi ý mở đầu (Starters).<br>• Lập trình công cụ Dịch tức thì (song song câu gốc - câu dịch) và Đồng hồ bấm giờ buổi học. | • **Phạm Văn Hưng (Chủ trì):** Lập trình Đăng nhập Google, Hồ sơ người dùng, Màn hình Kỷ luật (Streak/Heatmap/SQLite), Phòng Chat 1-1 & Phòng Chat Nhóm học tập (Supabase Realtime).<br>• **Trịnh Trung Kiên (Chủ trì):** Lập trình Phân hệ Quản lý Buổi luyện tập: tạo lịch hẹn, Đồng hồ bấm giờ (Session Timer 15-30p) và hoàn thiện các UI Widgets chung.<br>• **Đỗ Việt Tiến (Chủ trì):** Lập trình logic ghép cặp bạn học bù trừ ngôn ngữ, gửi/nhận lời mời kèm cặp và quản lý danh sách bạn.<br>• **Cao Đức Đạo (Chủ trì):** Lập trình màn hình Thư viện chủ đề, bộ lọc cấp độ A1-B2, gợi ý mẫu câu hội thoại và đánh dấu hoàn thành.<br>• **Trương Tuấn Hải (Chủ trì):** Tích hợp nút Dịch tức thì trong tin nhắn chat, tính năng tra cứu từ mới và Sổ tay lưu từ vựng (Vocabulary Notebook). | Hoàn thành toàn bộ các phân hệ cốt lõi: Đăng nhập, Kỷ luật Streak/Heatmap, Chat 1-1 & Nhóm học tập, Ghép cặp bạn học, Kho chủ đề & Dịch tức thì. |
| **Tuần 3**<br>*(Thống Kê, Test, Đóng Gói & Báo Cáo)* | • Hoàn thiện màn hình Tổng kết buổi học, ghi chú từ vựng và chấm sao đánh giá bạn đồng hành.<br>• Viết Unit Test, Widget Test và kiểm thử chức năng toàn diện trên thiết bị thật Android.<br>• Rà soát và tối ưu mã nguồn (đạt 0 cảnh báo `flutter analyze`), xuất bản file cài đặt `app-release.apk`.<br>• Hoàn thiện toàn bộ Báo cáo đồ án chi tiết (Word/PDF), Slide bảo vệ và kịch bản video demo sản phẩm. | • **Trịnh Trung Kiên & Phạm Văn Hưng:** Hoàn thiện màn hình đánh giá buổi học, tối ưu hiệu năng và đóng gói `app-release.apk`.<br>• **Cả nhóm (Kiên, Tiến, Đạo, Hải):** Kiểm thử toàn diện chức năng trên nhiều thiết bị Android, rà soát giao diện và vá lỗi phát sinh.<br>• **Phạm Văn Hưng (Trưởng nhóm):** Kiểm duyệt kỹ thuật mã nguồn, đóng gói tài liệu nộp bài trên GitHub.<br>• **Cả nhóm 09:** Hoàn thiện Báo cáo đồ án chi tiết (DOCX/PDF), Slide thuyết trình và chuẩn bị video demo sản phẩm. | File cài đặt `app-release.apk`, Báo cáo đồ án chi tiết (DOCX/PDF), Slide thuyết trình và Video demo. |

---

## PHẦN 4: KẾT LUẬN & CAM KẾT CỦA NHÓM

Đề cương Project cuối kỳ của Nhóm 09 được xây dựng chặt chẽ, thực tiễn và giải quyết trực diện bài toán rèn luyện kỹ năng giao tiếp của sinh viên. Bằng việc kết hợp hài hòa giữa **Kỷ luật cá nhân (Streak/Heatmap)**, **Kết nối bạn đồng hành bù trừ ngôn ngữ (Buddy Matching)**, **Kho chủ đề hội thoại tình huống phong phú** và **Phòng Chat Realtime (hỗ trợ cả Chat 1-1 và Chat Nhóm học tập đa người dùng cùng học)**, ứng dụng đảm bảo tính khả thi kỹ thuật cao, loại bỏ hoàn toàn các rủi ro phức tạp về phần cứng định vị ngoài đời và tập trung tối đa vào trải nghiệm người dùng. Toàn thể 5 thành viên Nhóm 09 cam kết phối hợp kỷ luật, nộp bài đúng chuẩn Git/GitHub và hoàn thành đúng tiến độ.
