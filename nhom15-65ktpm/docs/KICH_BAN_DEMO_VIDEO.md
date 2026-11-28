# Kịch Bản Quay Video Demo Đồ Án (Video Demonstration Script)

- **Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD) - Lớp 65KTPM  
- **Đề tài:** Ứng dụng học toán Finger Math (Toán ngón tay) tương tác hai bàn tay kết hợp AI trợ lý giọng nói cho trẻ 4–6 tuổi (Finger Math Kids App)  
- **Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  
- **Nhóm thực hiện:** Nhóm 15 (Dương Nguyên Anh, Phạm Duy Thái, Nguyễn Thị Thu Hoài, Nguyễn Thị Cẩm Ly)  
- **Thời lượng khuyến nghị:** 4 - 5 phút  
- **Độ phân giải:** 1080p (Full HD), 60fps  

---

## PHÂN CẢNH CHI TIẾT VIDEO DEMO

### 🎬 Phân cảnh 1: Giới thiệu tổng quan đề tài & Triết lý thiết kế (0:00 - 0:45)
- **Giao diện quay:** Màn hình chính [`HomeScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/screens/home_screen.dart) rực rỡ, linh vật gấu trúc Panda, ngọn lửa chuỗi ngày học liên tiếp (Streak), 3 thẻ cấp độ học và nút chế độ luyện tập tự do.
- **Lời thuyết minh:**
  > *"Kính chào thầy Đỗ Oanh Cường và các bạn. Em là Dương Nguyên Anh, đại diện Nhóm 15 - Lớp 65KTPM xin được trình bày video demo sản phẩm đồ án: **Finger Math Kids App** - Ứng dụng học toán ngón tay Finger Math tương tác hai bàn tay, rèn luyện tư duy cho trẻ mầm non từ 4 đến 6 tuổi kết hợp AI trợ lý giọng nói tiếng Việt.*  
  > *Ứng dụng được thiết kế theo triết lý **Không chữ (Zero-Text UI)** với biểu tượng lớn, màu sắc sinh động, âm thanh vui nhộn và **chỉ giới hạn ở phép Cộng và phép Trừ** trong phạm vi 0 đến 99, hoàn toàn phù hợp với tâm lý tiếp thu của trẻ nhỏ."*
- **Thao tác trên màn hình:**
  - Chạm vào linh vật gấu trúc Panda để kích hoạt giọng đọc chào mừng tiếng Việt vui nhộn.
  - Lướt xem chuỗi ngày học Streak và 3 cấp độ bài học được minh họa trực quan.

---

### 🎬 Phân cảnh 2: Đột phá Bàn tay Finger Math tương tác Flashcard trực quan (0:45 - 2:00)
- **Giao diện quay:** Mở popup **Bàn Tay Finger Math Tự Do**.
- **Lời thuyết minh:**
  > *"Điểm đổi mới đột phá và trực quan nhất của nhóm là hệ thống **Toán ngón tay Finger Math chuẩn 2 bàn tay** sử dụng trực tiếp bộ thẻ bài Flashcard 1D chuẩn:*  
  > *- **Tay Phải (Right Hand):** Đảm nhiệm Hàng Đơn Vị từ 0 đến 9. Trong đó, ngón cái mang giá trị là 5, bốn ngón dài mỗi ngón có giá trị là 1. Khi kết hợp ngón cái 5 với 1 ngón trỏ sẽ tạo thành số 6; thêm ngón giữa thành 7; thêm ngón áp út thành 8; và xòe cả bàn tay là số 9.*  
  > *- **Tay Trái (Left Hand):** Đảm nhiệm Hàng Chục từ 10 đến 90. Ngón cái mang giá trị 50, các ngón dài mang giá trị 10.*  
  > *- Khi kết hợp 2 bàn tay, trẻ có thể tính toán linh hoạt từ 0 đến 99.*  
  > *Trẻ có thể chạm trực tiếp vào thẻ bài để chuyển số hoặc bấm vào dãy phím số chọn nhanh (0 đến 9) bên dưới.*  
  > *Đồng thời, nhóm tích hợp nút tra cứu biểu tượng dấu hỏi **📖** để phụ huynh và trẻ xem nhanh toàn bộ quy ước Flashcard gốc và hai bộ công thức **Anh bạn nhỏ (tổng = 5)** và **Anh bạn lớn (tổng = 10, phối hợp 2 tay)**.*  
  > *Bấm nút **'Đọc Số Này Cho Bé Nghe'**, AI sẽ phát âm tiếng Việt giải thích cặn kẽ trạng thái ngón tay cho bé."*
- **Thao tác trên màn hình:**
  - Bấm chọn số 6 trên Tay Phải $\rightarrow$ hiển thị ngay thẻ bài Flashcard số `6` (ngón cái + 1 ngón trỏ).
  - Bấm chọn số 7 $\rightarrow$ thẻ bài chuyển sang số `7` (ngón cái + 2 ngón dài).
  - Bấm chọn số 8 $\rightarrow$ thẻ bài chuyển sang số `8`.
  - Trên Tay Trái: Bấm chọn số 30 $\rightarrow$ Tay Trái hiển thị 3 ngón dài (30), kết hợp thành số `38` (Tay trái 30, Tay phải 8).
  - Nhấn nút **"📖 Bảng quy ước & công thức"** để hiển thị hình ảnh toàn bộ bảng Flashcard 1D gốc và bảng công thức Anh bạn nhỏ, Anh bạn lớn.
  - Nhấn nút **"Đọc Số Này Cho Bé Nghe"** để nghe AI phát âm tiếng Việt giải thích trạng thái 2 bàn tay.

---

### 🎬 Phân cảnh 3: Bài học theo cấp độ & Công thức Anh bạn nhỏ, Anh bạn lớn (2:00 - 3:15)
- **Giao diện quay:** Màn hình làm bài tập [`LessonPlayScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/3_lessons_flash_anzan/presentation/screens/lesson_play_screen.dart).
- **Lời thuyết minh:**
  > *"Trong các bài học, hệ thống áp dụng chặt chẽ các công thức toán tư duy ngón tay:*  
  > *- **Công thức Anh Bạn Nhỏ (cặp số có tổng bằng 5):** Ví dụ phép tính $+4 = +5 - 1$, chú mascot AI sẽ nhắc nhở bé: 'Tay Phải xòe ngón cái 5, gập 1 ngón dài'.*  
  > *- **Công thức Anh Bạn Lớn (cặp số có tổng bằng 10):** Khi cộng vượt qua 10, ví dụ $6 + 7$, mascot sẽ hướng dẫn bé phối hợp 2 bàn tay: 'Bung 1 ngón Tay Trái (+10), gập 3 ngón bạn lớn ở Tay Phải (-3)'.*  
  > *Đặc biệt, trẻ 4-6 tuổi chưa biết gõ phím có thể nhấn nút **Micro AI** để trả lời trực tiếp bằng giọng nói tiếng Việt. Bộ lọc NLP của nhóm sẽ tự động loại bỏ từ đệm dạ thưa để nhận diện đáp án chính xác."*
- **Thao tác trên màn hình:**
  1. Màn hình hiện phép tính: `6 + 7 = ?`
  2. Quan sát gợi ý công thức Anh Bạn Lớn hiển thị trên bong bóng mascot Panda.
  3. Bung 1 ngón tay trái và 3 ngón tay phải $\rightarrow$ số 13 $\rightarrow$ Nhấn nút "Gửi Đáp Án".
  4. Câu tiếp theo: Nhấn nút Micro và nói to: *"Dạ kết quả là chín ạ"*.
  5. AI bóc tách ra số `9`, chấm đúng, phát lời khen động viên và chuyển câu hỏi tiếp theo.

---

### 🎬 Phân cảnh 4: Tính nhẩm siêu tốc Flash Anzan & Gia sư thích ứng (3:15 - 4:15)
- **Giao diện quay:** Màn hình [`FlashAnzanScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/3_lessons_flash_anzan/presentation/screens/flash_anzan_screen.dart).
- **Lời thuyết minh:**
  > *"Chế độ Flash Anzan rèn luyện khả năng tính nhẩm chớp nhoáng của trẻ qua các con số xuất hiện từ 0.5 giây đến 1.5 giây.*  
  > *Thuật toán **Gia sư thích ứng (Adaptive Learning Engine)** của nhóm sẽ liên tục theo dõi tốc độ phản xạ và độ chính xác của bé:*  
  > *- Nếu bé làm đúng và nhanh $\ge 80\% \rightarrow$ AI tự động tăng độ khó và đẩy tốc độ chớp số nhanh hơn 200ms.*  
  > *- Nếu bé gặp khó khăn $\rightarrow$ AI tự động hạ nhịp độ và chuyển sang chế độ gợi ý từng bước."*
- **Thao tác trên màn hình:**
  1. Bấm **Bắt đầu chớp số**: Đếm ngược `3.. 2.. 1..` $\rightarrow$ chớp số: `+3`, `+5`, `-2`.
  2. Màn hình hiển thị dấu hỏi `?`.
  3. Bung ngón tay Finger Math số `6` và nhấn xác nhận kết quả.
  4. Hộp thoại chúc mừng xuất hiện cùng thông báo tự động tăng tốc độ chớp số từ AI.

---

### 🎬 Phân cảnh 5: Quản lý thói quen Gamification & Báo cáo phụ huynh (4:15 - 4:50)
- **Giao diện quay:** Cổng phụ huynh [`ParentalGateDialog`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/widgets/parental_gate_dialog.dart) và màn hình [`ParentDashboardScreen`](file:///d:/adrstu/cuoiki/nhom15-65ktpm/src/lib/features/2_gamification_parent/presentation/screens/parent_dashboard_screen.dart).
- **Lời thuyết minh:**
  > *"Để giúp bé xây dựng thói quen tự giác, ứng dụng duy trì **chuỗi ngày học liên tiếp (Streak)** với huy hiệu ngôi sao khích lệ.*  
  > *Khu vực phụ huynh được bảo vệ bằng **Cổng khóa phụ huynh (Parental Gate)** nhằm ngăn bé bấm nhầm vào cài đặt. Tại đây, phụ huynh có thể theo dõi biểu đồ cột trực quan (`fl_chart`) về số bài tập con đã làm trong tuần, tỷ lệ trả lời đúng và thiết lập nhắc học cố định lúc 19:00 hàng ngày."*
- **Thao tác trên màn hình:**
  1. Bấm biểu tượng Cài đặt trên góc phải màn hình Home.
  2. Giải phép tính cộng xác thực người lớn để mở khóa Cổng phụ huynh.
  3. Xem biểu đồ cột số lượng bài tập theo các ngày trong tuần và tỷ lệ chính xác.

---

### 🎬 Phân cảnh 6: Tổng kết & Lời cảm ơn (4:50 - 5:10)
- **Giao diện quay:** Màn hình chính hoặc slide kết luận với thông tin Nhóm 15.
- **Lời thuyết minh:**
  > *"Sản phẩm của nhóm đã hoàn thành 100% mục tiêu đề ra, vượt qua toàn bộ 19 ca kiểm thử tự động với độ phủ toàn diện và không có lỗi biên dịch. Nhóm 15 xin chân thành cảm ơn thầy Đỗ Oanh Cường đã tận tình hướng dẫn trong suốt học phần. Kính chúc thầy luôn dồi dào sức khỏe và công tác tốt!"*
- **Hình ảnh kết thúc:** Logo nhóm 15, danh sách 4 thành viên và thông tin môn học.
