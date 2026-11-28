# DCSleep – Ứng dụng Hỗ trợ Xây dựng Kỷ luật và Cải thiện Thói quen Ngủ bằng Trí tuệ Nhân tạo

> **Học phần:** Phát triển ứng dụng cho các thiết bị di động  
> **Giảng viên hướng dẫn:** ThS. Đỗ Oanh Cường  
> **Lớp:** 65KTPM  
> **Nhóm thực hiện:** Nhóm 07  

---

## 📌 Giới Thiệu Dự Án
**DCSleep** là ứng dụng di động được xây dựng bằng **Flutter & Dart**, hỗ trợ người dùng (đặc biệt là sinh viên và người trẻ) hình thành và duy trì thói quen ngủ lành mạnh, khoa học thông qua:
- ⏰ **Thiết lập mục tiêu giấc ngủ:** Quản lý giờ đi ngủ, giờ thức dậy và thời lượng ngủ mục tiêu.
- 🔔 **Hệ thống nhắc nhở thông minh:** Lên lịch nhắc chuẩn bị ngủ và báo thức bằng `flutter_local_notifications`.
- ⚡ **Quản lý giấc ngủ ngắn (Power Nap):** Bộ đếm thời gian thông minh 10 – 20 phút xua tan cơn mệt mỏi buổi trưa.
- 📖 **Nhật ký giấc ngủ & Biểu đồ tiến độ:** Ghi nhận cảm nhận sau khi thức dậy, trực quan hóa mức độ tuân thủ bằng biểu đồ `fl_chart`.
- 🤖 **Trợ lý AI Sleep Assistant:** Tích hợp mô hình ngôn ngữ lớn (Gemini API) tư vấn vệ sinh giấc ngủ và gợi ý điều chỉnh thói quen cá nhân hóa.
- 🔒 **Quản lý thời gian màn hình & Chế độ Offline:** Hướng dẫn bật Digital Wellbeing/Không làm phiền, lưu trữ dữ liệu an toàn bằng SQLite/Firebase.

---

## 👥 Danh Sách Thành Viên Nhóm 07
| STT | Họ và tên | Mã sinh viên | Lớp | Vai trò | Trách nhiệm chính |
|:---:|:---|:---:|:---:|:---:|:---|
| 1 | **Mã Khánh Linh** | 2351170602 | 65KTPM | **Trưởng nhóm** | Giao diện chính, Quản lý tài khoản & hồ sơ, Điều hướng và Tích hợp ứng dụng |
| 2 | **Vũ Bá Đài** | 2351170577 | 65KTPM | **Thành viên** | Phân hệ Lịch ngủ, Nhắc nhở thông báo cục bộ và Bộ đếm Power Nap |
| 3 | **Dương Quốc Vượng** | 2351170634 | 65KTPM | **Thành viên** | Tích hợp Trợ lý AI Sleep Assistant (Gemini API), Thiết kế Prompt & Chat UI |
| 4 | **Lê Văn Dân** | 2251161963 | 65KTPM | **Thành viên** | Thiết kế CSDL (SQLite/Firebase), Nhật ký giấc ngủ, Biểu đồ thống kê `fl_chart` |

---

## 📄 Tài Liệu Đề Cương Chi Tiết
Toàn văn bản đề cương chi tiết 11 mục của nhóm được lưu trữ tại:  
👉 [docs/De_cuong_DCSLeep.md](docs/De_cuong_DCSLeep.md)  
*(Bản định dạng Word: [docs/De_cuong_DCSLeep.docx](docs/De_cuong_DCSLeep.docx))*
