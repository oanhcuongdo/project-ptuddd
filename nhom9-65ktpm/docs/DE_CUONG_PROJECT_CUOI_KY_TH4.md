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

|     STT     | Họ và Tên                  |    Mã Sinh Viên    | Lớp Sinh Hoạt |    Vai Trò    | Nhiệm Vụ Phân Công                                                                                                                         | Đóng Góp (%) | Email                         |
| :---------: | :---------------------------- | :------------------: | :-------------: | :------------: | :--------------------------------------------------------------------------------------------------------------------------------------------- | :-------------: | :---------------------------- |
| **1** | **Phạm Văn Hưng**    | **2351170598** |     65KTPM     | Trưởng nhóm | Quản lý dự án, thiết kế kiến trúc hệ thống Feature-First, CSDL SQLite cục bộ kết hợp Firebase Auth và Supabase Realtime         |      100%      | phamvanhung21122004@gmail.com |
| **2** | **Trịnh Trung Kiên**  | **2251172396** |     65KTPM     |  Thành viên  | Thiết kế UI/UX Material 3, lập trình Phân hệ Thử thách Kỷ luật Giao tiếp hàng ngày & Thanh trượt chọn ngày linh hoạt         |      100%      | trinhkien0103@gmail.com       |
| **3** | **Đỗ Việt Tiến**    | **2251243452** |     65KTPM     |  Thành viên  | Lập trình Phân hệ Kèm Online: Chat Thực chiến 1-1, tích hợp API Dịch tức thì (Translate) và gợi ý mẫu câu thông minh         |      100%      | tien.dv.65ktpm@gmail.com      |
| **4** | **Cao Đức Đạo**     | **2351170581** |     65KTPM     |  Thành viên  | Lập trình Phân hệ Kèm Ngoài đời (Offline Meetup): Tích hợp Google Maps SDK, gợi ý điểm hẹn an toàn và Check-in GPS xác thực |      100%      | caoducdao17022005@gmail.com   |
| **5** | **Trương Tuấn Hải** | **2351170590** |     65KTPM     |  Thành viên  | Lập trình thuật toán ghép đôi (Buddy Matching), Bảng xếp hạng cặp đôi, Dashboard Thống kê Chỉ số Tự tin & Kiểm thử         |      100%      | tuanhaiii2005@gmail.com       |

---

## PHẦN 1: TỔNG HỢP CÁC ỨNG DỤNG ĐÃ PHÂN TÍCH, THIẾT KẾ TRONG HỌC KỲ (CHECKLIST 1)

Trong suốt quá trình học tập và thực hành học phần Phát Triển Ứng Dụng Di Động dưới sự hướng dẫn của giảng viên ThS. Đỗ Cường Oanh, sinh viên và nhóm đã nghiên cứu, phân tích kiến trúc mã nguồn và xây dựng nguyên mẫu cho **8 ứng dụng thực tế trong suốt học kỳ**:

|     STT     | Tên Ứng Dụng Đã Phân Tích & Thiết Kế                                             | Nghiệp Vụ & Chức Năng Cốt Lõi                                                                                                                                                                    | Công Nghệ & Kiến Trúc Áp Dụng                                                                                                  | Giá Trị Kế Thừa Cho Đồ Án Cuối Kỳ                                                                                 |
| :---------: | :---------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **1** | **Ứng dụng Học Ngoại Ngữ Luyện Nói Phát Âm AI (Bài Thực Hành TH3)**     | Luyện phát âm tiếng Anh, stream âm thanh thời gian thực (WebSocket), AI Faster-Whisper + CMUdict chấm điểm âm vị, tô màu từ sai, đếm giờ học và chuỗi ngày rèn luyện (Streak). | • Flutter Material 3, Waveform• WebSocket Audio Streaming• Faster-Whisper + Needleman-Wunsch• Firebase Auth + Supabase (6 bảng) | **Kế thừa trực tiếp:** Mô hình luyện nói, nhận diện giọng nói và kiến trúc Backend Cloud.             |
| **2** | **Ứng dụng Kỷ Luật Cá Nhân & Quản Lý Thói Quen (Habit Tracker)**           | Quản lý thói quen hàng ngày, check-in tiến độ, tính chuỗi ngày kỷ luật (Streak), thanh trượt chọn ngày, biểu đồ cột tuần, ma trận Heatmap, đổi theme Sáng/Tối.              | • Flutter SDK 3.x, Provider• SQLite cục bộ (`sqflite`)• SharedPreferences (Theme)                                             | **Kế thừa trực tiếp:** Bộ khung quản lý thói quen, chuỗi Streak, ma trận Heatmap và CSDL SQLite cục bộ. |
| **3** | **Hệ Thống Quản Lý Tài Liệu Học Tập Đa Nền Tảng (Bài Thực Hành TH2)** | Hệ thống quản lý tài liệu học phần, xem trước file PDF/Docs, bảo mật phân quyền dữ liệu mức dòng Row Level Security (RLS).                                                           | • Flutter Responsive (Mobile/Web)• Firebase Authentication (OAuth)• Supabase PostgreSQL Cloud RLS                                 | **Kế thừa:** Cơ chế xác thực tài khoản Google và phân quyền bảo mật dữ liệu người dùng.            |
| **4** | **Ứng dụng Nhật Ký Đa Phương Tiện Bảo Mật (Daily You)**                   | Phân tích mã nguồn mở chuyên sâu: viết nhật ký hành trình, quản lý đa phương tiện (ảnh/video), bảo mật riêng tư tuyệt đối (Privacy by Design), Offline-First.                | • Flutter SDK, Clean Architecture• Offline-First (gỡ quyền Internet)• Xử lý Media / Video Player                              | **Kế thừa:** Triết lý bảo vệ quyền riêng tư và tối ưu hóa trải nghiệm Offline-First.                  |
| **5** | **Ứng dụng Quản Lý Tài Chính Cá Nhân (Cashew)**                             | Phân tích mã nguồn mở: ghi chép thu chi, phân bổ hạn mức ngân sách, báo cáo biểu đồ trực quan, hỗ trợ đa tiền tệ.                                                               | • Flutter Native, Clean Architecture• Local-First với Hive / SQLite• Trực quan hóa dữ liệu biểu đồ                        | **Kế thừa:** Cấu trúc phân tầng Clean Architecture và kỹ thuật trực quan hóa dữ liệu biểu đồ.        |
| **6** | **Ứng dụng Hồ Sơ Cá Nhân Android Native (Java & XML Layout)**                 | Lập trình Android gốc: Hồ sơ cá nhân (Business Card), bố cục co giãn ConstraintLayout, NestedScrollView, sự kiện Intent mở web/email/call.                                                | • Android Native (Java + XML)• MaterialCardView bo tròn 16dp• Intent.ACTION_VIEW / SENDTO                                        | **Kế thừa:** Tư duy lập trình di động tầng sâu trên hệ điều hành Android gốc.                         |
| **7** | **Ứng dụng Hồ Sơ Cá Nhân Đa Nền Tảng (Bài Thực Hành TH1 / Flutter)**    | Business Card điện tử: giới thiệu kỹ năng, kinh nghiệm, dự án, liên hệ mạng xã hội, điều hướng NavigationBar 4 tabs, Box Model.                                                     | • Flutter SDK (Dart)• Box Model & Composition Layout• Responsive không lỗi tràn viền                                          | **Kế thừa:** Kỹ năng bố cục giao diện responsive, chống lỗi tràn viền (RenderFlex overflow).              |
| **8** | **Bộ Bài Tập Thực Hành Giao Diện Cơ Bản (Layout & Core Widgets)**           | Làm quen vòng đời ứng dụng Flutter, làm chủ StatelessWidget, StatefulWidget và các widget hiển thị cơ bản.                                                                               | • Flutter Core Widgets• Bố cục Row, Column, Container                                                                            | **Kế thừa:** Nền tảng lập trình Flutter sơ khởi ban đầu.                                                   |

---

## PHẦN 2: LỰA CHỌN ỨNG DỤNG PHÙ HỢP LÀM PROJECT CUỐI KỲ (CHECKLIST 2)

### Đề tài được lựa chọn:

**ỨNG DỤNG KỶ LUẬT CÁ NHÂN CẢI THIỆN KỸ NĂNG GIAO TIẾP VÀ VƯỢT RÀO CẢN NGÔN NGỮ (BUDDYTALK)**

### 5 Luận điểm then chốt lựa chọn đề tài:

1. **Đúng chuẩn định hướng học phần:** Đề tài bám sát tài liệu chính thức của giảng viên trên hệ thống đào tạo MIS: *"Tài liệu: Xây dựng ứng dụng kỷ luật cá nhân với flutter"*.
2. **Giải quyết đúng bài toán thực tế sâu sắc:** Khắc phục "nỗi đau" trên các hội nhóm mạng xã hội (học tiếng Trung, tiếng Việt, tiếng Anh...): Người học tìm bạn kèm cặp nhưng 99% đều bỏ cuộc sau 2-3 ngày vì thiếu kỷ luật, không có chủ đề cụ thể và gặp rào cản bất đồng ngôn ngữ.
3. **Kế thừa mã nguồn nền tảng vững chắc:** Tận dụng trực tiếp bộ khung nguyên mẫu từ Ứng dụng Kỷ luật cá nhân (CSDL SQLite, Provider, chuỗi ngày kỷ luật (Streak), ma trận Heatmap) và module phân tích giao tiếp từ bài thực hành TH3, giúp nhóm có bàn đạp công nghệ vững chắc.
4. **Đột phá với mô hình Kèm Cặp Linh Hoạt (Online & Offline):** Kết hợp cả Kèm Online (Chat 1-1 + Dịch tức thì + Gợi ý mẫu câu) và Kèm Ngoài đời (Google Maps + Điểm hẹn an toàn + Check-in GPS thực chiến), giúp người học từng bước vượt qua tâm lý e ngại để giao tiếp tự tin.
5. **Khối lượng công việc cân bằng cho nhóm 5 người:** Kết hợp phong phú các công nghệ di động tiêu chuẩn: Cơ sở dữ liệu SQLite, Cloud Realtime, Google Maps SDK, Định vị GPS và API Dịch thuật, đảm bảo cả 5 thành viên đều có phần việc chuyên sâu và đóng góp 100% công sức.

---

## PHẦN 3: ĐỀ CƯƠNG CHI TIẾT PROJECT CUỐI KỲ (CHECKLIST 3)

### 3.1. Mục tiêu của Project

- **Mục tiêu tổng quát:** Xây dựng ứng dụng di động đa nền tảng hoàn chỉnh bằng Flutter, đóng vai trò là "Người quản trị kỷ luật và Cầu nối kèm cặp", giúp người dùng rèn luyện thói quen giao tiếp mỗi ngày thông qua nhiệm vụ cụ thể, ghép cặp bạn đồng hành bù trừ ngôn ngữ (Language Buddy) và hỗ trợ kèm cặp linh hoạt cả Online (Chat dịch tức thì) lẫn Ngoài đời (Gặp mặt qua Google Maps).
- **Mục tiêu cụ thể:**
  - Hoàn thiện giao diện Material 3 (hỗ trợ trọn vẹn Dark/Light mode).
  - Quản lý chuỗi ngày kỷ luật (Streak) và nhiệm vụ giao tiếp mỗi ngày.
  - Hệ thống ghép cặp bạn học 1-1 theo chủ đề hội thoại.
  - Phòng Chat thực chiến tích hợp nút Dịch tức thì (Instant Translate) và Gợi ý mẫu câu thông minh.
  - Tích hợp Google Maps gợi ý điểm hẹn an toàn và Check-in GPS xác thực gặp mặt ngoài đời.
  - Dashboard đo lường Chỉ số Tự tin (Confidence Index) và Ma trận nhiệt Heatmap cả tháng.

### 3.2. Phạm vi nghiên cứu (Scope)

- **Đối tượng người dùng:** Sinh viên, học sinh, người học ngoại ngữ (tiếng Trung, tiếng Anh, tiếng Việt cho người nước ngoài) hoặc cá nhân muốn rèn luyện kỹ năng mềm và vượt qua sự nhút nhát trong giao tiếp.
- **Nền tảng triển khai:** Ứng dụng di động trên nền tảng **Android** (hỗ trợ từ Android 8.0 trở lên).
- **Phạm vi dữ liệu:** Nhiệm vụ kỷ luật giao tiếp, dữ liệu ghép cặp bạn học, tin nhắn chat kèm bản dịch, tọa độ điểm hẹn Google Maps, lịch sử check-in GPS và điểm số kỷ luật.

### 3.3. Các phân hệ chức năng chính (Bản Vẽ Hệ Thống)

```text
HỆ THỐNG KỶ LUẬT GIAO TIẾP & BẠN ĐỒNG HÀNH (BUDDYTALK)
├── 1. Phân hệ Thử Thách Kỷ Luật Giao Tiếp Hàng Ngày
│   ├── Nhận thử thách giao tiếp 3 cấp độ (Bắt chuyện / Trình bày / Nói lưu loát)
│   ├── Thanh trượt chọn ngày linh hoạt (DateSelectorBar)
│   ├── Điểm danh Check-in & Chuỗi ngày kỷ luật (Streak)
│   └── Nhật ký cảm xúc & bài học sau buổi giao tiếp
├── 2. Phân hệ Ghép Cặp Bạn Đồng Hành & Kèm Cặp (Tandem Buddy)
│   ├── Ghép đôi theo nhu cầu bù trừ (Người Việt học tiếng Trung ⇄ Người Trung học tiếng Việt)
│   ├── Cơ chế Kèm cặp 2 chiều (Accountability Partner)
│   └── Nhận xét, duyệt bài và đánh giá chéo giữa 2 bạn học
├── 3. Phân hệ Kèm Online: Chat Thực Chiến Tình Huống & Dịch Tức Thì
│   ├── Chat 1-1 theo kịch bản chủ đề hôm nay (tối thiểu 10 câu/người)
│   ├── Nút "Dịch tức thì" (Instant Translate) giải quyết bất đồng ngôn ngữ
│   ├── "Gợi ý mẫu câu" (Smart Prompts) khi bị bí từ
│   └── "Sửa lỗi trực tiếp" (Inline Correction) giúp đối tác chữa câu sai
├── 4. Phân hệ Kèm Ngoài Đời: Bản Đồ Điểm Hẹn & Check-in GPS (Google Maps)
│   ├── Lựa chọn chế độ: Kèm Online HOẶC Gặp mặt Ngoài đời (Offline Meetup)
│   ├── Tích hợp Google Maps SDK hiển thị vị trí và gợi ý "Điểm hẹn an toàn" (Quán cafe, thư viện)
│   ├── Thuật toán Check-in GPS thực chiến (<50m tại quán)
│   └── Thưởng nhân đôi điểm Kỷ luật (x2 XP) & Huy hiệu giao tiếp ngoài đời
├── 5. Phân hệ Thống Kê Dashboard & Đo Lường "Chỉ Số Tự Tin"
│   ├── Thẻ tóm tắt tiến độ ngày & châm ngôn tạo động lực
│   ├── Biểu đồ cột theo dõi số phút luyện nói / tin nhắn trong tuần
│   ├── Ma trận nhiệt (Heatmap Calendar Grid) đo lường độ chuyên cần cả tháng
│   └── Bảng xếp hạng các cặp đôi kiên trì nhất (Buddy Leaderboard)
└── 6. Phân hệ Cơ Sở Dữ Liệu & Đồng Bộ Đám Mây
    ├── Lưu trữ cục bộ SQLite (AppDatabase) đảm bảo 100% Offline-First
    ├── Xác thực tài khoản Google qua Firebase Authentication
    ├── CSDL đám mây & Động cơ Chat Realtime 1-1 trên Supabase
    └── Cấu hình giao diện Sáng / Tối (SharedPreferences)
```

### 3.4. Kiến trúc hệ thống & Cơ sở dữ liệu sử dụng

#### a) Kiến trúc mã nguồn: Feature-First kết hợp Pragmatic Clean Architecture

Nhằm phục vụ quá trình làm việc nhóm 5 thành viên hiệu quả, tránh xung đột mã nguồn (Zero Git Merge Conflicts), nhóm áp dụng mô hình **Feature-First kết hợp Clean Architecture thực dụng**:

- **Tầng Core (`lib/core/`):** Chứa các thành phần dùng chung toàn hệ thống: hằng số (`constants`), cấu hình theme Sáng/Tối (`theme`), cấu hình kết nối mạng (`network`), và hàm tiện ích (`utils`).
- **Tầng Features (`lib/features/`):** Phân chia độc lập theo 5 phân hệ tương ứng với 5 thành viên phụ trách:
  - `auth/`: Đăng nhập Google & Hồ sơ cá nhân (Thành viên 1).
  - `daily_quests/`: Thử thách kỷ luật hàng ngày & Thanh trượt chọn ngày (Thành viên 2).
  - `chat_online/`: Phòng chat thực chiến 1-1 & API Dịch tức thì (Thành viên 3).
  - `offline_meetup/`: Bản đồ Google Maps & Check-in GPS (Thành viên 4).
  - `buddy_matching/`: Ghép đôi bù trừ ngôn ngữ & Dashboard Tự tin (Thành viên 5).
- Mỗi thư mục tính năng được tổ chức gọn gàng gồm 2 tầng:
  - `data/`: Định nghĩa Models, Data Sources (giao tiếp CSDL SQLite/Supabase) và Repositories.
  - `presentation/`: Các màn hình UI (Widgets) và Quản lý trạng thái bằng **Provider / ChangeNotifier** theo mô hình phản ứng dữ liệu hai chiều ($UI = f(State)$).

#### b) Kiến trúc Cơ sở dữ liệu & Xác thực (Bộ đôi Firebase Auth + Supabase Realtime + SQLite Cục bộ)

Hệ thống kế thừa kiến trúc thực chiến đã triển khai thành công từ các bài thực hành trong học kỳ (TH2, TH3), kết hợp sức mạnh tối ưu của 3 nền tảng:

1. **Xác thực người dùng (Authentication - Firebase Auth):**
   - Sử dụng **Firebase Authentication** để xử lý tính năng **Đăng nhập Google (Google Sign-In)** một chạm.
   - Cơ chế bảo mật cao, tự động quản lý phiên làm việc (Session), đồng bộ tài khoản Google của người dùng trên thiết bị Android nhanh chóng và ổn định.
2. **Cơ sở dữ liệu Đám mây & Chat thời gian thực (Supabase Cloud Database & Realtime):**
   - Sử dụng **Supabase** làm hệ quản trị cơ sở dữ liệu đám mây trung tâm (quản lý trực quan trên giao diện Dashboard, không cần cài đặt máy chủ cục bộ).
   - Thiết kế 5 bảng dữ liệu quan hệ chuẩn hóa:
     - `profiles`: Lưu thông tin cá nhân, ngôn ngữ mẹ đẻ (`native_lang`), ngôn ngữ mục tiêu (`target_lang`), điểm chuỗi kỷ luật (Streak) và chỉ số tự tin.
     - `daily_quests`: Danh mục thử thách kỷ luật theo 3 cấp độ giao tiếp.
     - `user_quest_logs`: Lịch sử hoàn thành nhiệm vụ và nhật ký cảm xúc check-in hàng ngày.
     - `buddy_matches`: Quản lý danh sách các cặp đôi bạn học ghép cặp 2 chiều.
     - `messages`: Lưu trữ tin nhắn hội thoại 1-1 (bao gồm nội dung gốc và nội dung đã dịch).
   - **Kênh Chat Realtime:** Khai thác tính năng **Supabase Realtime Channel** (truyền nhận sự kiện qua WebSocket), giúp tin nhắn chat 1-1 hiển thị tức thì giữa 2 người học với độ trễ < 100ms.
3. **Lưu trữ Cục bộ & Triết lý Offline-First (SQLite):**
   - Sử dụng thư viện `sqflite` để quản lý CSDL SQLite ngay trong bộ nhớ thiết bị.
   - Lưu trữ bộ đệm (Cache) lịch sử nhiệm vụ, thông tin người dùng và tin nhắn ngoại tuyến. Khi thiết bị mất kết nối mạng, người dùng vẫn có thể xem lại bài học và check-in bình thường; dữ liệu sẽ tự động đồng bộ lên Supabase Cloud khi có mạng trở lại.

#### c) Danh mục thư viện & công nghệ cốt lõi

- **Nền tảng:** Flutter SDK (3.x trở lên), Dart SDK.
- **Xác thực tài khoản:** `firebase_core`, `firebase_auth`, `google_sign_in`.
- **CSDL Đám mây & Realtime:** `supabase_flutter`.
- **CSDL Cục bộ (Offline-First):** `sqflite`, `path_provider`.
- **Bản đồ & Định vị:** `google_maps_flutter`, `geolocator`.
- **Dịch thuật đa ngôn ngữ:** `translator` (Trung - Việt - Anh).
- **Quản lý trạng thái:** `provider`.
- **Thông báo & Cấu hình:** `flutter_local_notifications`, `shared_preferences`.

---

### 3.5. Kế hoạch thực hiện & Phân công chi tiết (3 tuần)

| Tuần | Nội dung công việc cụ thể | Phân công chi tiết cả 5 thành viên | Sản phẩm bàn giao (Deliverables) |
| :---: | :--- | :--- | :--- |
| **Tuần 1**<br>*(Khởi động, Thiết kế & CSDL)* | • Khảo sát yêu cầu chi tiết (SRS), vẽ sơ đồ Use Case, Activity Diagram.<br>• Thiết kế Prototype Figma hoàn chỉnh cho cả 5 phân hệ.<br>• Khởi tạo dự án Flutter theo kiến trúc Feature-First, cấu hình Theme Material 3 (Dark/Light).<br>• Tích hợp Firebase Auth (Google Sign-In), thiết kế 5 bảng CSDL trên Supabase & SQLite cục bộ (`sqflite`).<br>• Đăng ký Google Cloud Console và cấu hình Google Maps API Key. | • **Phạm Văn Hưng (Trưởng nhóm):** Phân tích SRS, khởi tạo khung dự án Flutter, cấu hình Firebase Auth & Supabase.<br>• **Trịnh Trung Kiên:** Thiết kế UI/UX Prototype Figma 5 phân hệ, xây dựng Theme Material 3 & widget dùng chung.<br>• **Đỗ Việt Tiến:** Nghiên cứu API Dịch thuật, thiết kế bảng `messages`, cấu hình kênh Supabase Realtime.<br>• **Cao Đức Đạo:** Đăng ký Maps API Key, cấu hình AndroidManifest & quyền GPS thiết bị.<br>• **Trương Tuấn Hải:** Thiết kế Use Case, Activity Diagram và CSDL SQLite cục bộ (`sqflite`). | Bản đặc tả SRS, Figma Prototype, Khung dự án Flutter chạy được, CSDL Supabase & SQLite sẵn sàng. |
| **Tuần 2**<br>*(Lập trình các Phân hệ cốt lõi)* | • Lập trình xác thực Đăng nhập Google (Google Sign-In) và quản lý phiên làm việc.<br>• Xây dựng Màn hình Thử thách kỷ luật (`HomeQuestsScreen`), thanh trượt chọn ngày, thuật toán đếm chuỗi kỷ luật (Streak).<br>• Lập trình Phòng Chat thực chiến 1-1, tích hợp luồng tin nhắn Supabase Realtime và nút "Dịch tức thì" (Trung-Việt-Anh).<br>• Tích hợp Google Maps SDK, hiển thị điểm hẹn an toàn và thuật toán Check-in GPS (<50m) xác thực gặp mặt.<br>• Lập trình thuật toán ghép đôi bạn học bù trừ ngôn ngữ (Tandem Matching) trên Supabase. | • **Trịnh Trung Kiên (Chủ trì):** Lập trình giao diện Quests, thanh chọn ngày & UI Thẻ bạn học (`BuddyCard`).<br>• **Đỗ Việt Tiến (Chủ trì):** Lập trình giao diện Chat 1-1, tích hợp API Dịch tức thì & xử lý ghép cặp.<br>• **Cao Đức Đạo (Chủ trì):** Lập trình Google Maps SDK, định vị GPS, Check-in gặp mặt & Local Notification.<br>• **Phạm Văn Hưng:** Lập trình Đăng nhập Google, tích hợp Supabase Realtime Stream & đồng bộ Offline-First.<br>• **Trương Tuấn Hải:** Lập trình thuật toán ghép đôi bù trừ ngôn ngữ, logic tính Streak & Gợi ý mẫu câu. | Hoàn thành 3 phân hệ cốt lõi: Thử thách kỷ luật, Chat 1-1 dịch tức thì, Bản đồ Google Maps & Check-in GPS. |
| **Tuần 3**<br>*(Thống Kê, Test, Đóng Gói & Báo Cáo)* | • Lập trình Dashboard Thống kê Chỉ số Tự tin (Confidence Index), Ma trận nhiệt Heatmap cả tháng và BXH cặp đôi.<br>• Viết Unit Test, Widget Test và kiểm thử chức năng toàn diện trên thiết bị thật Android.<br>• Rà soát và tối ưu mã nguồn (đạt 0 cảnh báo `flutter analyze`), xuất bản file cài đặt `app-release.apk`.<br>• Hoàn thiện toàn bộ Báo cáo đồ án chi tiết (Word/PDF), Slide bảo vệ và kịch bản video demo sản phẩm. | • **Trương Tuấn Hải (Chủ trì):** Lập trình Dashboard Thống kê Chỉ số Tự tin, Heatmap, Bảng xếp hạng.<br>• **Cả nhóm (Tiến, Đạo, Kiên):** Kiểm thử toàn diện chức năng trên nhiều dòng máy Android, rà soát responsive.<br>• **Phạm Văn Hưng (Trưởng nhóm):** Tối ưu mã nguồn, đóng gói file `app-release.apk`, kiểm duyệt kỹ thuật.<br>• **Cả nhóm 09:** Hoàn thiện Báo cáo đồ án, Slide thuyết trình và chuẩn bị video demo sản phẩm. | File cài đặt `app-release.apk`, Báo cáo đồ án chi tiết (DOCX/PDF), Slide thuyết trình và Video demo. |

---

## PHẦN 4: KẾT LUẬN & CAM KẾT CỦA NHÓM

Đề cương Project cuối kỳ của Nhóm 09 được xây dựng chặt chẽ, sáng tạo và giải quyết trực diện bài toán rèn luyện kỹ năng giao tiếp thực tế của sinh viên và người học ngoại ngữ. Với sự kết hợp đột phá giữa **Kỷ luật cá nhân**, **Kèm cặp 2 chiều Online (Chat dịch tức thì)** và **Kèm Ngoài đời (Google Maps GPS Check-in)**, dự án đảm bảo tính khả thi kỹ thuật cao. Toàn thể 5 thành viên Nhóm 09 cam kết phối hợp kỷ luật, nộp bài đúng chuẩn Git/GitHub và hoàn thành đúng tiến độ.
