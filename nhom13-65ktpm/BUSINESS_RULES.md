# Business Rules & Validation — TLU PeerLearn

Tài liệu này tổng hợp toàn bộ quy tắc nghiệp vụ (**BR-01** đến **BR-10**) và quy tắc kiểm tra dữ liệu đầu vào (**Validation**) mà mọi module phải tuân thủ.

---

## 1. Quy Tắc Nghiệp Vụ Cốt Lõi (Business Rules)

| Mã | Quy tắc nghiệp vụ |
| :--- | :--- |
| **BR-01** | Một sinh viên có thể đăng ký làm Mentor hoặc Mentee ở nhiều học phần khác nhau, nhưng **trong cùng một học phần chỉ được giữ một vai trò duy nhất** (`UNIQUE(user_id, course_id)`). |
| **BR-02** | Mỗi Phòng học tập (`Study Room`) phải gắn với một học phần cụ thể và có ít nhất một Mentor làm chủ phòng. |
| **BR-03** | Người dùng chỉ được truy cập nội dung bên trong phòng học khi lời mời kết nối hoặc yêu cầu tham gia đã ở trạng thái `Accepted` (hoặc có quyền `admin`). |
| **BR-04** | Chỉ cho phép tải lên tài liệu định dạng `.pdf` và `.docx` với dung lượng $\le 5\text{MB}$/tệp; mỗi lần tạo nội dung AI chỉ chọn **tối đa 2 tệp** và chỉ trích xuất **tối đa 15.000 ký tự đầu tiên**. |
| **BR-05** | Tài liệu được sử dụng để tạo bài ôn tập phải thuộc phòng học mà người tạo có quyền truy cập. |
| **BR-06** | Nội dung Flashcard/Quiz do AI tạo ra mặc định ở trạng thái `draft`, bắt buộc phải qua bước kiểm duyệt và phát hành (`published`) của Mentor trước khi hiển thị cho thành viên khác. |
| **BR-07** | Hệ thống lưu trữ phiên bản câu hỏi tại thời điểm làm bài (hoặc khóa chỉnh sửa đề đã có lượt làm bài) để đảm bảo kết quả lịch sử của Mentee không bị sai lệch. |
| **BR-08** | Mỗi lượt làm Quiz được lưu thành một bản ghi độc lập; điểm số và thống kê được tính hoàn toàn từ dữ liệu làm bài thực tế bằng truy vấn DB, không phụ thuộc AI. |
| **BR-09** | Mentor có quyền ghi nhận buổi học, điểm danh và tải lên minh chứng độc lập; trạng thái tự xác nhận của Mentee được lưu song song và **không chặn** việc hoàn tất báo cáo của Mentor. |
| **BR-10** | Mentee chỉ được phép tự xác nhận tham gia buổi học cho chính tài khoản của mình. |

---

## 2. Quy Tắc Validate Dữ Liệu Đầu Vào (Input Validation)

- **Tài khoản & Hồ sơ (`ACC`):**
  - `Họ và tên`: Bắt buộc, không được để trống.
  - `Mã sinh viên`: Bắt buộc khi đăng ký tài khoản sinh viên; định dạng **10 chữ số** (VD: `2351170574`, regex `^\d{10}$`).
  - `Email`: Bắt buộc, đúng định dạng email (`@`).
  - `Mật khẩu`: Bắt buộc, tối thiểu 6 ký tự.
  - `Số điện thoại`: Nếu nhập, phải là 10–11 chữ số (`^\d{10,11}$`).
- **Đăng ký Mentor/Mentee (`ACC-04`, `ACC-05`):**
  - `Học phần`: Bắt buộc chọn.
  - `Điểm tổng kết (Mentor)`: Bắt buộc, số thực từ `0.0` đến `10.0`.
  - `Lịch rảnh`: Chọn từ 21 khung giờ chuẩn (`0..20`).
- **Tài liệu & Minh chứng (`DOC`, `SES`):**
  - Tài liệu: Chỉ `.pdf` hoặc `.docx`, dung lượng $\le 5\text{MB}$ (`5 * 1024 * 1024` bytes).
  - Ảnh minh chứng buổi học: Nén xuống $< 500\text{KB}$ trước khi upload.

