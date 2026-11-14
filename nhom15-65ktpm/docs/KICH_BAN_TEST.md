# Kịch Bản Kiểm Thử Toàn Diện (Comprehensive Test Plan)

Dự án: **Soroban Kids App**  
Nhóm: **Nhóm 15 - Lớp 65KTPM**

---

## 1. Mục Tiêu Kiểm Thử
- Đảm bảo tính toán chính xác tuyệt đối của Bàn tính ảo Soroban (CustomPainter).
- Đảm bảo thuật toán NLP trích xuất chính xác số đếm tiếng Việt từ giọng trẻ em.
- Đảm bảo thuật toán Gia sư AI Thích ứng điều chỉnh độ khó hợp lý theo năng lực.
- Đảm bảo logic chuỗi Streak và quản lý phiên học ổn định.

---

## 2. Danh Mục Ca Kiểm Thử Đơn Vị (Unit Test Cases)

### 2.1. Kiểm thử Bàn tính ảo Soroban (`abacus_engine_test.dart`)
| Mã Test | Mô Tả Kịch Bản | Dữ Liệu Đầu Vào | Kết Quả Mong Đợi | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_AB_01** | Trạng thái ban đầu của cột Soroban | Cột khởi tạo mặc định | Giá trị = 0 (Hạt trên ở trên, 4 hạt dưới ở dưới) | Pass |
| **TC_AB_02** | Kích hoạt hạt trên (giá trị 5) | Kéo hạt trên xuống chạm xà ngang | Giá trị cột = 5 | Pass |
| **TC_AB_03** | Kích hoạt 3 hạt dưới (giá trị 3) | Đẩy 3 hạt dưới lên chạm xà ngang | Giá trị cột = 3 | Pass |
| **TC_AB_04** | Kết hợp hạt trên và 4 hạt dưới | Kéo hạt trên xuống + đẩy 4 hạt dưới lên | Giá trị cột = 9 (giá trị tối đa của 1 cột) | Pass |
| **TC_AB_05** | Reset bàn tính ảo | Gọi hàm `reset()` trên bàn tính 4 cột | Toàn bộ 4 cột trở về 0, tổng giá trị bàn tính = 0 | Pass |

### 2.2. Kiểm thử Bóc tách số tiếng Việt (`number_extractor_test.dart`)
| Mã Test | Mô Tả Kịch Bản | Chuỗi Văn Bản Nhận Diện Từ Giọng Nói | Kết Quả Trích Xuất | Trạng Thái |
| :---: | :--- | :--- | :---: | :---: |
| **TC_NLP_01** | Đọc số đơn lẻ | `"năm"` hoặc `"số 5"` | `5` | Pass |
| **TC_NLP_02** | Câu nói tự nhiên kèm từ dạ thưa | `"dạ thưa cô kết quả bằng mười lăm ạ"` | `15` | Pass |
| **TC_NLP_03** | Khẩu ngữ phương ngữ tiếng Việt | `"hai mươi mốt"`, `"hai mươi lăm"` | `21`, `25` | Pass |
| **TC_NLP_04** | Câu nói không chứa số hợp lệ | `"con không biết ạ"` | `null` (Thông báo bé đọc lại) | Pass |

### 2.3. Kiểm thử Gia sư AI Thích ứng (`adaptive_tutor_test.dart`)
| Mã Test | Mô Tả Kịch Bản | Lịch Sử 5 Lần Làm Bài Gần Nhất | Hành Động Thích Ứng Của AI | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_AI_01** | Bé làm bài rất nhanh và đúng 100% | 5/5 câu đúng, thời gian TB = 1.2s | Tăng cấp độ hoặc giảm thời gian Flash Anzan thêm 200ms | Pass |
| **TC_AI_02** | Bé làm sai nhiều và mất bình tĩnh | 1/5 câu đúng, thời gian TB = 6.5s | Kích hoạt chế độ hướng dẫn thị phạm từng bước (Guided Highlight) | Pass |
| **TC_AI_03** | Bé duy trì phong độ ổn định | 4/5 câu đúng, thời gian TB = 3.0s | Giữ nguyên độ khó hiện tại và phát lời khen động viên | Pass |

---

## 3. Lệnh Thực Thi Bộ Kiểm Thử
```bash
cd nhom15-65ktpm/src
flutter test
```
Tất cả các ca kiểm thử trên được cài đặt sẵn tại thư mục `test/` và đạt tỷ lệ vượt qua 100%.
