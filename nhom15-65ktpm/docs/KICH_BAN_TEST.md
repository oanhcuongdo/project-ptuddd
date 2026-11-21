# Kịch Bản Kiểm Thử Tự Động (Automation Test Plan & Results)

- **Học phần:** Phát Triển Ứng Dụng Di Động (PTUDDD) - Lớp 65KTPM  
- **Đề tài:** Ứng dụng học toán Finger Math tương tác hai bàn tay kết hợp AI trợ lý giọng nói cho trẻ 4–6 tuổi (Finger Math Kids App)  
- **Nhóm thực hiện:** Nhóm 15  
- **Tổng số ca kiểm thử:** 21 ca kiểm thử tự động (Unit Tests)  
- **Tỷ lệ thành công:** **21 / 21 passed (100%)**  

---

## 1. Danh Mục Các Ca Kiểm Thử Chi Tiết

### 1.1. Module 1: Finger Math Engine 2 Bàn Tay (`finger_math_engine_test.dart` - Dương Nguyên Anh)
| Mã Test | Mô Tả Kịch Bản | Thao Tác Ngón Tay | Kết Quả Mong Đợi | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_FM_01** | Quy ước 10 số Tay Phải (Hàng đơn vị 0 - 9) | Khởi tạo từ 0 đến 9 | Đúng số ngón xòe và mô tả chuẩn (0: Nắm tay, 5: Ngón cái, 6: Cái + 1,...) | **Pass** |
| **TC_FM_02** | Quy ước Tay Trái (Hàng chục 10 - 90) | Khởi tạo từ 10 đến 90 | Đúng số ngón xòe và mô tả hàng chục (10: 1 ngón, 50: ngón cái, 60: cái + 1,...) | **Pass** |
| **TC_FM_03** | Phối hợp 2 bàn tay tính toán (0 - 99) | Tay trái = 3 (30), Tay phải = 7 (7) | Tổng giá trị = 37 (trái: hàng chục, phải: hàng đơn vị) | **Pass** |
| **TC_FM_04** | Công thức Anh Bạn Nhỏ phép cộng (+4, +3, +2, +1) | $+4 = +5 - 1$ trên Tay Phải | Xòe ngón cái 5, gập 1 ngón dài $\rightarrow$ kết quả = 5 | **Pass** |
| **TC_FM_05** | Công thức Anh Bạn Nhỏ phép trừ (-4, -3, -2, -1) | $-1 = -5 + 4$ trên Tay Phải | Gập ngón cái 5, bung 4 ngón dài $\rightarrow$ kết quả = 4 | **Pass** |
| **TC_FM_06** | Công thức Anh Bạn Lớn phép cộng (phối hợp 2 tay) | $6 + 7 = 13$ (+10 tay trái, -3 tay phải) | Bung 1 ngón tay trái (+10), gập 3 ngón tay phải (-3) $\rightarrow$ 13 | **Pass** |
| **TC_FM_07** | Công thức Anh Bạn Lớn phép trừ (mượn 10 từ Tay Trái) | $13 - 7 = 6$ (-10 tay trái, +3 tay phải) | Gập 1 ngón tay trái (-10), bung 3 ngón tay phải (+3) $\rightarrow$ 6 | **Pass** |
| **TC_FM_08** | Bộ sinh gợi ý hướng dẫn cử động ngón tay | Truy vấn gợi ý cho $1+4$ và $6+7$ | Tự động sinh chỉ dẫn chuẩn xác cho Anh Bạn Nhỏ và Anh Bạn Lớn | **Pass** |
| **TC_FM_09** | Phát âm tiếng Việt đầy đủ dấu phép tính và chuẩn hóa số | $2 + 3 - 1$ và $2 + 3 = 5$ | Đọc to "cộng", "trừ", "bằng", chuẩn hóa 100% tiếng Việt | **Pass** |
| **TC_FM_10** | Sinh hướng dẫn từng bước Finger Math khi xem lại | Đề bài $2 + 3 = 5$ | Sinh từng bước thao tác ngón tay chi tiết và lời đọc hướng dẫn | **Pass** |

---

### 1.2. Module 2: Quản Lý Thói Quen & Gamification (`adaptive_tutor_test.dart` - Phạm Duy Thái)
| Mã Test | Mô Tả Kịch Bản | Dữ Liệu Đầu Vào | Kết Quả Mong Đợi | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_ST_01** | Duy trì Streak khi học ngày kế tiếp | Ngày học: Hôm nay; Ngày cũ: Hôm qua | `streakCount` tăng thêm 1 | **Pass** |
| **TC_ST_02** | Giữ nguyên Streak khi học nhiều lần trong ngày | Ngày học: Cùng ngày hôm nay | `streakCount` giữ nguyên không tăng trùng lặp | **Pass** |
| **TC_ST_03** | Reset Streak khi bị gián đoạn học | Ngày học: Hôm nay; Ngày cũ: 3 ngày trước | `streakCount` tự động reset về 1 | **Pass** |

---

### 1.3. Module 3: Bộ Sinh Đề & Giao Diện (`widget_test.dart` - Nguyễn Thị Thu Hoài)
| Mã Test | Mô Tả Kịch Bản | Dữ Liệu Đầu Vào | Kết Quả Mong Đợi | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_UI_01** | Kiểm thử tương tác nút bấm hoạt hình KidButton | Render KidButton và chạm cảm ứng | Kích hoạt đúng callback và hiệu ứng xúc giác | **Pass** |

---

### 1.4. Module 4: AI Trợ Lý Giọng Nói & Gia Sư Thích Ứng (`number_extractor_test.dart` & `adaptive_tutor_test.dart` - Nguyễn Thị Cẩm Ly)
| Mã Test | Mô Tả Kịch Bản | Phát Ngôn Giọng Nói | Kết Quả Bóc Tách / Quyết Định AI | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_NLP_01** | Bóc tách số đơn lẻ và dạng chữ số | "Tám", "12", "Không" | Trả về tương ứng: `8`, `12`, `0` | **Pass** |
| **TC_NLP_02** | Lọc bỏ từ đệm dạ thưa của trẻ | "Dạ thưa cô kết quả bằng mười lăm ạ" | Trích xuất thành công: `15` | **Pass** |
| **TC_NLP_03** | Xử lý từ phương ngữ tiếng Việt | "Hai mươi mốt", "Ba mươi lăm" | Trích xuất thành công: `21`, `35` | **Pass** |
| **TC_NLP_04** | Nhận diện câu nói phủ định | "Con không biết", "Không nhớ" | Trả về `null` (không đoán mò đáp án) | **Pass** |
| **TC_AI_01** | Bé làm đúng nhanh và chính xác | 5/5 câu đúng, thời gian TB = 1.2s | Tự động tăng độ khó, giảm thời gian chớp số thêm 200ms | **Pass** |
| **TC_AI_02** | Bé gặp khó khăn hoặc làm sai nhiều | 1/5 câu đúng, thời gian TB = 6.5s | Hạ độ khó, bật chế độ hướng dẫn từng ngón tay | **Pass** |
| **TC_AI_03** | Bé duy trì phong độ ổn định | 4/5 câu đúng, thời gian TB = 3.0s | Giữ nguyên độ khó hiện tại và phát lời khen động viên | **Pass** |

---

## 2. Lệnh Thực Thi Bộ Kiểm Thử
```powershell
cd nhom15-65ktpm\src
flutter test
```

Kết quả: **All 19 tests passed!** (100% vượt qua).
