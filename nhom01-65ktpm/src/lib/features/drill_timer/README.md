# Module: Bộ Đếm Phiên Tập Huấn Luyện (Drill Timer & Cloud Log)

> **Người phụ trách:** Bùi Đức Hiệp  
> **Chức năng chính:** Quản lý bấm giờ đếm ngược bài tập bóng đá, chuyển hiệp giải lao, tổng kết phiên tập và đồng bộ Supabase Cloud.

---

## Cấu Trúc Thư Mục Module
- `models/`: Định nghĩa các cấu trúc dữ liệu (`DrillItem`, `DrillSession`).
- `services/`: Xử lý logic đếm ngược thời gian và dịch vụ đồng bộ đám mây Supabase.
- `views/`: Các màn hình giao diện chính (chọn bài tập, đồng hồ bấm giờ, tổng kết buổi tập, lịch sử).
- `widgets/`: Các thành phần giao diện dùng chung (mặt đồng hồ số, vòng tiến trình, cụm nút điều khiển).
