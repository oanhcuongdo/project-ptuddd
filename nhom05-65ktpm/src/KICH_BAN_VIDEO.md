# Kịch bản video báo cáo TH3 – Speak Up (2–3 phút)

**Chuẩn bị:** emulator đang mở app ở màn "Chọn người học". Android Studio mở sẵn các tab file code. Micro máy tính đã bật cho emulator (Extended controls `⋯` → Microphone).

Mỗi cảnh ghi: 🖥️ màn hình · 👆 thao tác · 🎙️ lời nói. Thời gian trong ngoặc là ước lượng.

---

### Cảnh 1 – Mở đầu (15s)

🖥️ Emulator, màn "Chọn người học".
👆 Bấm **Thêm** → gõ tên → **Tạo**.

🎙️ Em xin báo cáo bài thực hành 3 của nhóm 5: ứng dụng học tiếng Anh **Speak Up**, viết bằng Flutter. Ứng dụng có hai phần chính: duy trì thói quen luyện tập, và chấm điểm phát âm bằng AI. Ứng dụng hỗ trợ nhiều người học trên một máy, mỗi người có dữ liệu riêng.

---

### Cảnh 2 – Mục 1: Cơ sở dữ liệu (20s)

🖥️ Android Studio → `app_database.dart`, `Ctrl+G` tới dòng 87.
👆 Cuộn qua 4 câu `CREATE TABLE`.

🎙️ Dữ liệu lưu bằng SQLite gồm 4 bảng: **users** lưu người học và cài đặt; **practice_sessions** lưu lịch sử luyện tập; **attempts** lưu từng lần nói và điểm; **phoneme_errors** lưu từng âm bị sai. Các bảng nối với nhau bằng khóa ngoại.

---

### Cảnh 3 – Mục 3, 4, 5: Thu âm, chấm điểm, phản hồi (60s) ⭐

🖥️ Emulator → bài **Âm /θ/ và /ð/ (TH)** → bấm **Tiếp** tới câu "I think three is enough".
👆 Bấm mic → đọc **"I sink tree is enough"** (cố ý sai) → chờ kết quả → cuộn xuống thẻ 💡.

🎙️ Ứng dụng dùng API nhận dạng giọng nói `speech_to_text`. Em sẽ cố ý đọc sai như lỗi thường gặp của người Việt… *(đọc)*

🎙️ Ứng dụng chấm điểm bằng cách chuyển cả câu mẫu và câu nghe được sang **chuỗi âm vị** theo từ điển CMU, rồi so khớp bằng thuật toán **Needleman–Wunsch**. Âm gần giống, như /θ/ và /t/, bị trừ nửa lỗi. Âm sai hẳn bị trừ một lỗi.

🎙️ Kết quả: điểm bị giảm, âm **/θ/ được tô đỏ**, ghi rõ *think: /θ/ → /s/*. Bên dưới là gợi ý sửa: cách đặt lưỡi, cặp từ để luyện như *think – sink* (bấm vào để nghe), và nút chuyển sang bài tập phù hợp.

---

### Cảnh 4 – Mục 2, 6: Tiến độ và nhắc nhở (35s)

🖥️ Emulator → quay về trang chủ → tab **Tiến độ** → tab **Cài đặt**.
👆 Chỉ vào thẻ streak; ở Cài đặt kéo slider mục tiêu, bấm **Giờ nhắc**.

🎙️ Sau khi luyện, **chuỗi ngày (streak)** tăng lên. Tab Tiến độ thống kê tổng thời gian học, điểm trung bình, biểu đồ 7 ngày gần nhất, và những âm hay sai nhất.

🎙️ Ở Cài đặt, người dùng **đặt mục tiêu số phút mỗi ngày**, và bật **nhắc nhở hằng ngày** theo giờ tùy chọn. Nội dung thông báo thay đổi theo chuỗi ngày hiện tại.

---

### Cảnh 5 – Mục 7: Kiểm thử (25s)

🖥️ Android Studio → Terminal (`Alt+F12`) → chạy `flutter test`.

🎙️ Nhóm có **18 unit test**, tất cả đều pass. Các test này mô phỏng nhiều giọng khác nhau: đọc TH thành T hoặc S, nuốt phụ âm cuối, lẫn V với B, lẫn R với L. Mỗi test kiểm tra ứng dụng phát hiện đúng âm sai. Nhóm cũng đã thử với *(số)* người thật, ứng dụng phát hiện đúng khoảng *(_%)* lỗi.

> ⚠️ Điền số liệu thật của nhóm. Nếu chưa thử với người thật, bỏ câu cuối.

---

### Cảnh 6 – Kết (10s)

🖥️ Trang chủ ứng dụng.

🎙️ Như vậy nhóm em đã hoàn thành đủ 7 mục trong checklist. Hạn chế là chưa chấm được trọng âm và ngữ điệu. Em cảm ơn thầy cô đã theo dõi.

---

**Tổng ≈ 2 phút 45 giây.** Muốn ngắn hơn thì bỏ câu thuật toán ở cảnh 3 và câu "nhiều người học" ở cảnh 1.
