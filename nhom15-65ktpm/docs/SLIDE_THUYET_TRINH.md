# Dàn Ý Slide Thuyết Trình Báo Cáo Đồ Án (Presentation Deck Outline)

**Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD) - Lớp 65KTPM  
**Đề tài:** Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói (Soroban Kids App)  
**Giảng viên hướng dẫn:** Thầy Đỗ Oanh Cường  
**Nhóm thực hiện:** Nhóm 15 (Dương Nguyên Anh, Phạm Duy Thái, Nguyễn Thị Thu Hoài, Nguyễn Thị Cẩm Ly)  

---

### SLIDE 1: TRANG TIÊU ĐỀ (TITLE SLIDE)
- **Tiêu đề chính:** SOROBAN KIDS APP
- **Tiêu đề phụ:** Ứng dụng học toán Soroban tương tác và rèn luyện tư duy cho trẻ 4-6 tuổi kết hợp AI trợ lý giọng nói.
- **Thông tin:**
  - Giảng viên hướng dẫn: Thầy Đỗ Oanh Cường
  - Lớp học phần: 65KTPM
  - Nhóm sinh viên thực hiện: Nhóm 15
- **Hình ảnh gợi ý:** Logo linh vật Panda, bàn tính Soroban ảo nhiều màu sắc tươi vui.

---

### SLIDE 2: BỐI CẢNH & TÍNH CẤP THIẾT
- **Đặc thù lứa tuổi 4–6:** Giai đoạn vàng phát triển não bộ; tuy nhiên trẻ chưa biết đọc/viết chữ và dễ mất tập trung.
- **Rào cản của phương pháp truyền thống:** Sách vở in khô khan, bàn tính gỗ cồng kềnh, thiếu sự tương tác và phản hồi kịp thời.
- **Giải pháp của nhóm 15:** Ứng dụng di động hóa bàn tính Soroban với giao diện Không chữ (Zero-Text UI) kết hợp hướng dẫn bằng giọng nói tiếng Việt đa giác quan.

---

### SLIDE 3: MỤC TIÊU & ĐỊNH HƯỚNG CỐT LÕI
1. **Phạm vi toán học:** Giới hạn độc quyền ở **phép Cộng và phép Trừ** (phạm vi 0–99), bảo đảm tính vừa sức và không gây quá tải cho trẻ mầm non.
2. **Tương tác trực quan 60fps:** Bé gảy hạt bàn tính ảo trên màn hình như bàn tính thật.
3. **AI giọng nói tiếng Việt:** Bé đọc to đáp án bằng lời nói, AI tự động nhận dạng và chấm đúng/sai.
4. **Gia sư thích ứng (Adaptive Learning):** Tự động điều chỉnh độ khó và tốc độ theo năng lực của từng bé.
5. **Kỷ luật thói quen:** Duy trì chuỗi Streak và báo cáo biểu đồ trực quan cho phụ huynh.

---

### SLIDE 4: TỔNG QUAN KIẾN TRÚC HỆ THỐNG
- **Mô hình kiến trúc:** Feature-First Clean Architecture chia 4 tầng rõ ràng (`core/`, `shared/`, `features/`, `test/`).
- **Giao ước dữ liệu (Data Contract):** Khóa cứng 3 Entity chung ngay từ đầu (`ChildProfile`, `SorobanQuestion`, `AttemptLog`) giúp 4 thành viên code độc lập bằng mock data mà không xung đột mã nguồn.
- **Sơ đồ phân hệ:** 4 module tính năng tương ứng với 4 thành viên.

---

### SLIDE 5: MODULE 1 - BÀN TÍNH ẢO SOROBAN (Dương Nguyên Anh)
- **Công nghệ cốt lõi:** Lập trình đồ họa với `CustomPainter`.
- **Cơ chế mô phỏng:**
  - Hạt trên (giá trị 5): Kéo xuống sát xà ngang kích hoạt +5.
  - 4 hạt dưới (mỗi hạt giá trị 1): Đẩy lên sát xà ngang kích hoạt +1 đến +4.
  - Hiệu ứng đổ bóng 3D, thanh định vị có chấm đơn vị (Unit Dots).
- **Trải nghiệm xúc giác:** Tích hợp âm thanh gảy hạt "tách" và rung nhẹ (Haptic Feedback) khi hạt chạm xà ngang.

---

### SLIDE 6: MODULE 2 - ZERO-TEXT UI & GAMIFICATION (Phạm Duy Thái)
- **Triết lý Zero-Text UI:** Thay thế toàn bộ chữ viết phức tạp bằng biểu tượng lớn, màu sắc sinh động và giọng đọc nhân vật hoạt hình Panda.
- **Chuỗi ngày học liên tiếp (Streak):** Tự động tính toán ngày học liên tục, mở khóa huy hiệu ngôi sao để khích lệ bé.
- **Khu vực Phụ huynh (Parental Dashboard):**
  - Cổng bảo vệ (Parental Gate) bằng phép cộng kiểm tra để ngăn bé bấm nhầm.
  - Biểu đồ cột trực quan (`fl_chart`) theo dõi số câu đúng trong tuần và tỷ lệ chính xác.
  - Thiết lập thông báo nhắc học cố định lúc 19:00 hàng ngày.

---

### SLIDE 7: MODULE 3 - LOGIC BÀI HỌC & FLASH ANZAN (Nguyễn Thị Thu Hoài)
- **Bộ sinh đề thông minh (Question Generator):** Chỉ sinh phép cộng trừ không âm ($0 \le \text{kết quả} \le 99$):
  - *Cấp độ 1:* Nhận diện và cộng trừ trực tiếp.
  - *Cấp độ 2:* Công thức Anh bạn nhỏ ($+4 = +5 - 1$, $+3 = +5 - 2$,...).
  - *Cấp độ 3:* Tính nhẩm nhanh Flash Anzan.
- **Flash Anzan siêu tốc:** Chuỗi số xuất hiện chớp nhoáng từ 0.5s đến 2.0s, kích thích bán cầu não phải hình dung hạt tính trong tâm trí.

---

### SLIDE 8: MODULE 4 - AI TRỢ LÝ GIỌNG NÓI & GIA SƯ THÍCH ỨNG (Nguyễn Thị Cẩm Ly)
- **Nhận dạng giọng nói trẻ em (`speech_to_text`):** Tối ưu thu âm âm vực cao của trẻ 4-6 tuổi.
- **Bộ xử lý NLP tiếng Việt (Vietnamese Number Extractor):**
  - Bóc tách số chính xác từ câu nói tự nhiên: *"Dạ bằng mười lăm ạ"* $\rightarrow$ `15`.
  - Tự động loại bỏ từ đệm và từ chối các câu phủ định như *"con không biết"*.
- **Thuật toán Gia sư thích ứng (Adaptive Learning Engine):**
  - Đúng nhanh $\ge 80\% \rightarrow$ tự động tăng tốc độ chớp số thêm 200ms.
  - Sai nhiều hoặc chậm $> 6\text{s} \rightarrow$ giảm tốc độ và kích hoạt chế độ hướng dẫn từng bước.

---

### SLIDE 9: QUY TRÌNH PHỐI HỢP & QUẢN TRỊ GIT (NHÓM 15)
- **Chiến lược phân nhánh:**
  - Nhánh chính của nhóm: `nhom15-65ktpm` (tạo Pull Request nộp bài).
  - 4 nhánh tính năng độc lập: `feat/abacus-core`, `feat/ui-gamification`, `feat/flash-anzan`, `feat/ai-voice`.
- **Nguyên tắc "Nhà ai nấy ở":** Mỗi thành viên chỉ làm việc trong thư mục feature được phân công, tránh xung đột 100%.
- **Pull Request #4:** Đã mở nộp bài thành công về kho lưu trữ của giảng viên.

---

### SLIDE 10: KẾT QUẢ KIỂM THỬ CHẤT LƯỢNG (TESTING & QA)
- **Tỷ lệ Unit Test:** **17/17 ca kiểm thử đạt 100% (Passed)**
  - 6 ca kiểm thử tính toán và tương tác bàn tính ảo Soroban.
  - 4 ca kiểm thử thuật toán NLP bóc tách số tiếng Việt.
  - 3 ca kiểm thử thuật toán gia sư thích ứng AI.
  - 3 ca kiểm thử logic chuỗi Streak.
  - 1 ca kiểm thử Widget KidButton.
- **Chất lượng mã nguồn:** `dart analyze` đạt chuẩn 0 lỗi (Errors), 0 cảnh báo (Warnings).

---

### SLIDE 11: DEMO SẢN PHẨM TRỰC TIẾP
- *Trình chiếu video demo 3–5 phút hoặc chạy ứng dụng trực tiếp:*
  1. Màn hình chính & Lời chào âm thanh của linh vật Panda.
  2. Thao tác gảy hạt bàn tính ảo Soroban 60fps.
  3. Bé trả lời phép tính bằng giọng nói tiếng Việt.
  4. Chế độ tính nhẩm Flash Anzan và AI tự động căn chỉnh tốc độ.
  5. Mở Cổng phụ huynh và xem biểu đồ tiến bộ tuần.

---

### SLIDE 12: KẾT LUẬN & HƯỚNG PHÁT TRIỂN
- **Kết luận:** Đồ án hoàn thành 100% các yêu cầu kỹ thuật và nghiệp vụ giáo dục cho trẻ mầm non; tuân thủ nghiêm ngặt mọi quy chuẩn của môn học.
- **Hướng phát triển:**
  - Tích hợp Vision AI (nhận diện cử chỉ bàn tay gảy hạt ngoài đời thực qua camera).
  - Mở rộng đấu trường thi đấu tính nhẩm Flash Anzan nhiều người chơi trực tuyến (Multiplayer).

---

### SLIDE 13: LỜI CẢM ƠN & HỎI ĐÁP (Q&A)
- *"Nhóm 15 xin chân thành cảm ơn Thầy Đỗ Oanh Cường đã tận tình hướng dẫn trong suốt học phần Phát Triển Ứng Dụng Di Động!"*
- Mời Thầy và các bạn đặt câu hỏi đóng góp cho nhóm.
