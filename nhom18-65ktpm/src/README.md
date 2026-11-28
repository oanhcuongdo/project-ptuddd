# Ứng dụng Kết nối & Tình nguyện Xe máy — Nhóm 18 (65KTPM)

Tài liệu hướng dẫn làm việc nhóm, phân chia nhiệm vụ, quy trình Git/GitHub và thiết lập môi trường phát triển cho các thành viên **Nhóm 18 – Lớp 65KTPM**, học phần *Phát triển Ứng dụng cho các Thiết bị Di động* (GVHD: ThS. Đỗ Oanh Cường).

- **Công nghệ:** Flutter (chỉ hỗ trợ Android trong phạm vi môn học) + Supabase (Auth, PostgreSQL/PostGIS, Storage, Realtime, Edge Functions) + Google Maps + Firebase Cloud Messaging (FCM).
- **Kho lưu trữ làm việc của nhóm (`origin`):** `https://github.com/lucthuan1601/project-ptuddd.git`
- **Kho lưu trữ gốc môn học (`upstream`):** `https://github.com/oanhcuongdo/project-ptuddd.git`
- **Thư mục nhóm:** `nhom18-65ktpm/` | **Nhánh chính của nhóm:** `nhom/nhom18-65ktpm`
- **Tài liệu liên quan:**
  - Báo cáo phân tích & đặc tả hệ thống: [UngDungKetNoi&TinhNguyenXeMay.docx](../UngDungKetNoi&TinhNguyenXeMay.docx)
  - Danh sách thành viên: [danhsachnhom.md](../danhsachnhom.md)
  - Hướng dẫn khởi tạo CSDL & tài khoản test: [supabase/README.md](../supabase/README.md)
  - Đặc tả Use Case UC-08 → UC-15: [dac-ta-use-case-uc08-uc15.md](../dac-ta-use-case-uc08-uc15.md)
  - Quy định nộp bài chung của môn học: [project-ptuddd/README.md](../../README.md)

---

## 1. Phân chia nhiệm vụ theo tài liệu đặc tả & Trạng thái bàn giao

Toàn bộ phân công dưới đây được xây dựng trực tiếp từ tài liệu đặc tả [UngDungKetNoi&TinhNguyenXeMay.docx](../UngDungKetNoi&TinhNguyenXeMay.docx) (Mục 2.1–2.4 `STRQ/FEAT/NFR`, Mục IV đặc tả `UC-01 → UC-15`, Mục V thiết kế kiến trúc & 5 bảng CSDL).

### 1.1. Bảng phân công tổng quan (theo Mục 2.4 báo cáo)

| STT | Họ và Tên | Mã SV | Vai trò | Nhánh Git | Phần tài liệu | Phạm vi `STRQ` / `UC` phần mã nguồn |
| :-: | --- | --- | --- | --- | --- | --- |
| 1 | **Lục Văn Thuận** | `2351170624` | Trưởng nhóm | `nhom/nhom18-65ktpm` | Thu thập & phân tích yêu cầu (Mục I, II); rà soát chéo toàn bộ báo cáo | Hạ tầng Flutter + Supabase (5 bảng, RLS, RPC PostGIS, Storage, seed) + Firebase; **STRQ-1 / UC-01**; review & merge PR |
| 2 | **Trần Văn Hồng Quân** | `2351170613` | Thành viên | `feat/quan-rider` | Đặc tả **UC-01 → UC-07** (Mục 4.1 → 4.7) | Phân hệ Khách hàng (Rider): **STRQ-2 → STRQ-7** (`FEAT-2.1 → 7.2`) / **UC-02 → UC-06** (phối hợp **UC-01** phần Rider) |
| 3 | **Hoàng Tùng** | `2351170630` | Thành viên | `feat/tung-sos-volunteer` | Đặc tả **UC-08 → UC-15** (Mục 4.8 → 4.15) | Luồng SOS, Đánh giá & Tình nguyện viên: **STRQ-8, 9, 14, 15, 16, 17** (`FEAT-8.1, 9.1, 14.1–17.1`) / **UC-07, UC-08, UC-11 (TNV), UC-12, UC-13** + Edge Function **FCM** |
| 4 | **Nguyễn Khắc Minh Hiếu** | `2251162000` | Thành viên | `feat/hieu-owner-admin` | Sơ đồ Use Case tổng quát & phân rã 4 tác nhân (Mục 3.4, 3.5) | Phân hệ Chủ tiệm (Owner) & Quản trị (Admin): **STRQ-10 → 13, 18, 19** (`FEAT-10.1, 10.2, 13.1, 18.1, 19.1`) / **UC-09, UC-10, UC-11 (Chủ tiệm), UC-14, UC-15** |

### 1.2. Bảng đối chiếu 15 Use Case (`UC-01` → `UC-15`)

| Mã UC | Tên Use Case | Tác nhân | STRQ / FEAT tương ứng | Người phụ trách code | Mức độ ưu tiên |
| :---: | --- | --- | --- | --- | :---: |
| **UC-01** | Đăng nhập / Đăng ký | Rider, Owner, Volunteer, Admin | `STRQ-1` (`FEAT-1.1, 1.2`) | **Thuận** *(Quân phối hợp)* | Rất cao |
| **UC-02** | Định vị vị trí hiện tại | Rider, Owner, Volunteer | `STRQ-2` (`FEAT-2.1, 2.2`) | **Quân** | Rất cao |
| **UC-03** | Tìm kiếm Tiệm sửa xe & Cây xăng | Rider | `STRQ-3, 4` (`FEAT-3.1, 3.2, 4.1`) | **Quân** | Rất cao |
| **UC-04** | Xem chi tiết địa điểm | Rider | `STRQ-5` (`FEAT-5.1`) | **Quân** | Cao |
| **UC-05** | Gọi điện nhanh Hotline | Rider | `STRQ-6` (`FEAT-6.1`) | **Quân** | Rất cao |
| **UC-06** | Chỉ đường (Navigation) | Rider, Owner, Volunteer | `STRQ-7` (`FEAT-7.1, 7.2`) | **Quân** | Cao |
| **UC-07** | Gửi yêu cầu Cứu hộ SOS | Rider | `STRQ-8` (`FEAT-8.1`) | **Tùng** | Rất cao |
| **UC-08** | Đánh giá & Viết nhận xét | Rider | `STRQ-9` (`FEAT-9.1`) | **Tùng** | Trung bình |
| **UC-09** | Đăng ký & Quản lý tiệm | Shop Owner | `STRQ-10, 12` (`FEAT-10.1`) | **Hiếu** | Cao |
| **UC-10** | Ghim vị trí tiệm trên bản đồ | Shop Owner | `STRQ-11` (`FEAT-10.2`) | **Hiếu** | Cao |
| **UC-11** | Cập nhật trạng thái hoạt động | Shop Owner, Volunteer | `STRQ-13, 16` (`FEAT-13.1, 16.1`) | **Hiếu** *(Owner)* / **Tùng** *(TNV)* | Trung bình |
| **UC-12** | Tiếp nhận yêu cầu SOS | Shop Owner, Volunteer | `STRQ-14, 17` (`FEAT-14.1, 14.2, 17.1`) | **Tùng** *(Hiếu gắn vào Owner)* | Rất cao |
| **UC-13** | Đăng ký Hồ sơ Tình nguyện viên | Volunteer | `STRQ-15` (`FEAT-15.1`) | **Tùng** | Cao |
| **UC-14** | Quản lý tài khoản, Tiệm & TNV | Admin | `STRQ-18` (`FEAT-18.1`) | **Hiếu** | Cao |
| **UC-15** | Thống kê hệ thống | Admin | `STRQ-19` (`FEAT-19.1`) | **Hiếu** | Trung bình |

### 1.3. Chi tiết công việc từng thành viên theo đặc tả

#### 1.3.1. Lục Văn Thuận — Trưởng nhóm (`nhom/nhom18-65ktpm`)

- **Nền tảng & CSDL (Mục 5.2, 5.3, `NFR-01`, `NFR-03`) — *Đã hoàn thành*:**
  - Khởi tạo dự án Flutter, `core/` (`env.dart`, `supabase_client.dart`, `theme.dart`, `validators.dart`), 5 model (`lib/models/`) kèm unit test, 5 hợp đồng repository (`lib/repositories/`) và 4 shell rỗng (`lib/core/shells/`).
  - Triển khai 5 bảng PostgreSQL/PostGIS (`users`, `shops`, `volunteer_profiles`, `sos_requests`, `reviews`), chính sách RLS (`02_rls.sql`), Trigger (`handle_new_user`, bảo vệ cột nhạy cảm, `refresh_shop_rating`), 5 hàm RPC (`get_nearby_shops`, `get_nearby_volunteers`, `accept_sos`, `complete_sos`, `get_sos_contact`) và 3 bucket Storage (`shop-images`, `avatars`, `id-cards`).
- **UC-01: Đăng nhập / Đăng ký (`features/auth/`, `core/auth_gate.dart`) — *Đã có nền tảng, cần hoàn thiện phần liên kết*:**
  - Đã xong: Đăng nhập/đăng ký Email-Mật khẩu qua Supabase Auth, cấm tự chọn vai trò `admin`, chặn tài khoản `status = 'banned'`, lưu phiên và phân luồng theo vai trò.
  - Cần làm tiếp:
    1. Cấu hình Firebase project và lưu `users.fcm_token` sau khi đăng nhập để phục vụ luồng đẩy thông báo SOS (`NFR-02`).
    2. Sau khi các module hoàn thiện, nối luồng thay thế UC-01: tài khoản `owner` chưa có tiệm chuyển thẳng tới form đăng ký tiệm (UC-09), tài khoản `volunteer` chưa có hồ sơ chuyển tới form hồ sơ TNV (UC-13).
    3. Review PR, rà soát `flutter analyze` / `flutter test`, merge vào `nhom/nhom18-65ktpm` và mở PR nộp bài vào `upstream/main`.

#### 1.3.2. Trần Văn Hồng Quân — Phân hệ Khách hàng / Rider (`feat/quan-rider`)

- **Thư mục phụ trách:** `lib/core/shells/rider_shell.dart`, `lib/features/map/`, `lib/features/shop/`, `lib/features/call/`, `lib/features/navigation/`.
- **Đầu việc chi tiết theo đặc tả Mục 4.2 → 4.6 (`NFR-01`, `NFR-04`):**
  1. **UC-02 – Định vị vị trí hiện tại (`FEAT-2.1, 2.2`):**
     - Kiểm tra quyền vị trí & dịch vụ GPS; lấy tọa độ thực tế bằng `Geolocator.getCurrentPosition()`.
     - Đưa tâm bản đồ Google Maps về vị trí người dùng kèm Marker chấm xanh, nút *"Vị trí của tôi"*, và Reverse Geocoding hiển thị tên đường/phường/xã trên thanh địa chỉ top bar.
     - *Ngoại lệ & dự phòng bắt buộc:* GPS yếu → dùng vị trí gần nhất đã lưu kèm cảnh báo độ chính xác thấp; GPS tắt → hiện hộp thoại dẫn tới Cài đặt thiết bị; từ chối quyền vị trí → đặt tâm bản đồ mặc định tại trung tâm Hà Nội và vô hiệu hóa tìm kiếm gần đây.
  2. **UC-03 – Tìm kiếm Tiệm sửa xe & Cây xăng (`FEAT-3.1, 3.2, 4.1`):**
     - Gọi `ShopRepository.nearby()` (RPC `get_nearby_shops` lọc `status = 'approved'`, phản hồi < 2 giây theo `NFR-01`).
     - Hỗ trợ thanh tìm kiếm theo từ khóa (tên tiệm/tên đường), lọc danh mục (`repair_shop` / `gas_station`), chọn bán kính (`1km`, `3km`, `5km`, `10km`; mặc định `3km`) và công tắc *"Chỉ hiển thị tiệm đang mở"* (`is_open = true`).
     - Render Marker biểu tượng riêng cho Tiệm sửa xe / Cây xăng trên bản đồ và danh sách thẻ vuốt phía dưới (tên, khoảng cách, rating, trạng thái); lắng nghe **Supabase Realtime** bảng `shops` để cập nhật ngay trạng thái đóng/mở cửa.
     - *Ngoại lệ bắt buộc:* Không có địa điểm phù hợp → thông báo và gợi ý mở rộng lên `5km`/`10km`; mất mạng → báo lỗi kèm nút *"Thử lại"*.
  3. **UC-04 – Xem chi tiết địa điểm (`FEAT-5.1`):**
     - Gọi `ShopRepository.byId(shopId)` và `ReviewRepository.listByShop(shopId)`.
     - Hiển thị đầy đủ: ảnh mặt tiền (`image_url`, dùng ảnh placeholder khi lỗi tải ảnh), tên cơ sở, tên chủ tiệm, SĐT hotline, địa chỉ, giờ mở–đóng cửa (`open_time`–`close_time`), Badge trạng thái (*Đang mở cửa* – xanh / *Đóng cửa* – đỏ), điểm trung bình `rating`, `review_count` và danh sách nhận xét.
     - Gắn 4 nút hành động: **Gọi ngay** (UC-05), **Chỉ đường** (UC-06), **Gửi cứu hộ SOS** (mở UC-07 của Tùng), **Đánh giá** (mở UC-08 của Tùng).
     - *Ngoại lệ bắt buộc:* Địa điểm không tồn tại / đã bị xóa → báo lỗi và quay lại màn hình trước.
  4. **UC-05 – Gọi điện nhanh Hotline (`FEAT-6.1`):**
     - Khởi chạy `tel:<phone>` qua `url_launcher` (`launchUrl()`).
     - *Ngoại lệ bắt buộc:* Tiệm chưa có SĐT → báo *"Tiệm hiện chưa cập nhật số điện thoại liên hệ"*; thiết bị không hỗ trợ gọi thoại → thông báo lỗi rõ ràng.
  5. **UC-06 – Chỉ đường / Navigation (`FEAT-7.1, 7.2`):**
     - Luồng chính: Gọi Google Maps Directions API (phương tiện xe máy) từ Origin GPS → Destination GPS, vẽ đường Polyline màu xanh lam trên bản đồ kèm thanh tổng quan khoảng cách (km) và thời gian dự kiến (phút).
     - Luồng thay thế: Nút *"Mở Google Maps ngoài"* qua URL scheme `https://www.google.com/maps/dir/?api=1&destination=lat,lng`.
     - *Ngoại lệ bắt buộc:* Không tìm được tuyến đường hoặc lỗi API → thông báo và gợi ý chuyển sang Google Maps ngoài.
     - Tách màn hình/hàm chỉ đường dùng chung để Tùng & Hiếu tái sử dụng trong UC-12.

#### 1.3.3. Hoàng Tùng — Luồng SOS, Đánh giá, Tình nguyện viên & FCM (`feat/tung-sos-volunteer`)

- **Thư mục phụ trách:** `lib/core/shells/volunteer_shell.dart`, `lib/features/sos/`, `lib/features/review/`, `lib/features/volunteer/`, thư mục Edge Function FCM trong `supabase/`.
- **Đầu việc chi tiết theo đặc tả Mục 4.7, 4.8, 4.11 (TNV), 4.12, 4.13 (`NFR-02`, `NFR-04`):**
  1. **UC-07 – Gửi yêu cầu Cứu hộ SOS (`FEAT-8.1`):**
     - Triển khai `SupabaseSosRepository` theo hợp đồng `SosRepository`.
     - Dialog gửi SOS: chọn 1 trong 4 loại sự cố đúng ràng buộc DB (`'Hết xăng'`, `'Thủng lốp'`, `'Hỏng động cơ'`, `'Khác'`), ô ghi chú tình trạng xe, kiểm tra `contact_phone`, tự lấy tọa độ GPS hiện tại → tạo bản ghi trong `sos_requests` với `status = 'pending'`.
     - Màn hình *"Đang chờ cứu hộ..."* (radar quét) lắng nghe **Supabase Realtime** thay đổi trạng thái bản ghi SOS; khi chuyển sang `accepted` thì gọi RPC `get_sos_contact(sosId)` để hiển thị tên + SĐT người tiếp nhận.
     - *Luồng thay thế & ngoại lệ bắt buộc:* Cho phép bấm *"Hủy yêu cầu SOS"* khi còn `pending` (`status = 'cancelled'`); **tự động hủy sau 5 phút (timeout)** nếu chưa có người nhận và gợi ý gọi trực tiếp; nếu không có tiệm/TNV hoạt động quanh khu vực → hiển thị thông báo kèm danh sách hotline khẩn cấp.
  2. **UC-08 – Đánh giá & Viết nhận xét (`FEAT-9.1`):**
     - Triển khai `SupabaseReviewRepository` theo hợp đồng `ReviewRepository` (`listByShop`, `upsert` — mỗi rider 1 review/tiệm theo constraint `reviews_one_per_rider`).
     - Hộp thoại đánh giá: thanh chọn 1–5 sao, ô nhập bình luận tối đa 500 ký tự (có bộ đếm ký tự còn lại, tự cắt khoảng trắng đầu/cuối). Sau khi lưu, trigger DB `trg_refresh_shop_rating` tự tính lại `shops.rating` & `shops.review_count` → làm mới danh sách đánh giá ngay.
     - *Luồng thay thế & ngoại lệ bắt buộc:* Hỗ trợ mở từ gợi ý *"Đánh giá dịch vụ"* sau khi ca SOS do tiệm nhận chuyển sang `completed` (UC-12); chặn gửi khi chưa chọn số sao hoặc > 500 ký tự; xử lý lỗi RLS (tài khoản `banned`) và mất mạng (giữ lại dữ liệu nhập + nút *"Thử lại"*).
  3. **UC-13 – Đăng ký Hồ sơ Tình nguyện viên (`FEAT-15.1`):**
     - Triển khai `SupabaseVolunteerRepository` theo hợp đồng `VolunteerRepository`.
     - Form tạo/sửa hồ sơ: SĐT liên hệ (10 số bắt đầu bằng `0`), danh sách kỹ năng (`skills` — bắt buộc ≥ 1 kỹ năng: vá xe, kích bình, tiếp xăng, kéo xe...), dụng cụ mang theo (`tools`), bán kính hỗ trợ (`service_radius_km` từ `1–20 km`, gợi ý `3km/5km/10km`), chọn vị trí hoạt động chính (mặc định GPS hiện tại, lưu cột `location` dạng EWKT `SRID=4326;POINT(lng lat)`), tải ảnh giấy tờ xác minh (JPG/PNG ≤ 5 MB) lên bucket private **`id-cards/<user_id>/<file>`**.
     - Hồ sơ mới lưu `status = 'pending'`, `is_available = false`; hiển thị trạng thái chờ duyệt hoặc lý do từ chối để sửa gửi lại. *Luồng thay thế:* sửa kỹ năng/dụng cụ/bán kính giữ nguyên `approved`; sửa SĐT hoặc ảnh giấy tờ đưa về `pending` để Admin duyệt lại.
  4. **UC-11 (phần Tình nguyện viên) – Bật/tắt Sẵn sàng hỗ trợ (`FEAT-16.1`):**
     - Thay thế `VolunteerShell`: công tắc `volunteer_profiles.is_available` chỉ hoạt động khi `status = 'approved'`; khi bật, cập nhật đồng thời tọa độ GPS hiện tại (`updateLocation`). Vị trí TNV **không hiển thị công khai** trên bản đồ Rider để bảo vệ quyền riêng tư.
     - *Ngoại lệ bắt buộc:* Lỗi mạng → trả công tắc về trạng thái cũ + báo lỗi; đang có ca SOS `accepted` → yêu cầu hoàn thành ca trước khi tạm nghỉ.
  5. **UC-12 – Tiếp nhận & xử lý yêu cầu SOS (`FEAT-14.1, 14.2, 17.1`):**
     - Lắng nghe `sos_requests` (`status = 'pending'`) qua Supabase Realtime + FCM; phát âm thanh/rung và hiển thị Pop-up khẩn cấp (khoảng cách, vị trí trên bản đồ, loại sự cố, SĐT khách hàng).
     - Nút **Tiếp nhận** **bắt buộc** gọi RPC `accept_sos(p_sos_id, p_shop_id / p_volunteer_id)`; nếu đã có người khác nhận trước → báo *"Ca cứu hộ này đã được người khác tiếp nhận"* và đóng Pop-up. Nút **Từ chối** đóng Pop-up cục bộ, giữ trạng thái `pending`. Nếu Rider hủy đơn → tự động đóng Pop-up.
     - Màn hình *"Ca cứu hộ đang xử lý"*: nút **Gọi điện khách hàng** (dùng UC-05), nút **Chỉ đường** (dùng UC-06) và nút **Hoàn thành ca cứu hộ** gọi RPC `complete_sos(p_sos_id)` (tự cập nhật `status = 'completed'`, `completed_at` và tăng `completed_count` cho TNV).
     - Thiết kế màn hình/Pop-up nhận SOS độc lập theo tham số (`shopId` hoặc `volunteerId`) để **Hiếu tích hợp trực tiếp vào `OwnerShell`**.
  6. **Supabase Edge Function & FCM (`NFR-02` ≤ 3 giây):**
     - Thiết lập Database Webhook trên `sos_requests` (`INSERT`) gọi Edge Function truy vấn `get_nearby_shops(..., 5000, open_only=true)` và `get_nearby_volunteers(...)`, lấy `users.fcm_token` và bắn Push Notification qua FCM với payload `{ "sos_id", "issue_type", "lat", "lng" }`.

#### 1.3.4. Nguyễn Khắc Minh Hiếu — Phân hệ Chủ tiệm & Quản trị (`feat/hieu-owner-admin`)

- **Thư mục phụ trách:** `lib/core/shells/owner_shell.dart`, `lib/core/shells/admin_shell.dart`, `lib/features/owner/`, `lib/features/admin/`.
- **Đầu việc chi tiết theo đặc tả Mục 4.9, 4.10, 4.11 (Owner), 4.14, 4.15 (`NFR-03`, `NFR-04`):**
  1. **UC-09 – Đăng ký & Quản lý tiệm (`FEAT-10.1`):**
     - Triển khai CRUD cho Chủ tiệm tại `lib/features/owner/data/owner_shop_repository.dart` (tách khỏi `ShopRepository` chỉ đọc của Rider để tránh conflict merge; gồm lấy tiệm của `owner_id`, tạo mới, cập nhật thông tin, bật/tắt `is_open`, tải ảnh lên `shop-images`).
     - Biểu mẫu tạo/sửa hồ sơ tiệm: tên tiệm (`3–150` ký tự), loại hình (`'repair_shop'` / `'gas_station'`), SĐT hotline (10 chữ số bắt đầu bằng `0`), giờ mở cửa & giờ đóng cửa (`open_time`, `close_time` qua Time Picker, khác nhau), tải ảnh mặt tiền (JPG/PNG ≤ 5 MB) bằng `image_picker` lên bucket public **`shop-images/<user_id>/<file>`**, tọa độ & địa chỉ từ UC-10.
     - Hồ sơ mới lưu `status = 'pending'` chờ Admin duyệt (UC-14). Trigger `protect_shop_columns()` trên DB tự động chuyển `status` về `'pending'` và đặt `is_open = false` khi sửa tên/loại/vị trí của tiệm `approved` (A1) hoặc gửi lại hồ sơ `rejected` (A2, xóa `rejection_reason`). *Ngoại lệ bắt buộc:* Thiếu trường bắt buộc → đánh dấu đỏ + báo lỗi; tải ảnh thất bại → báo lỗi và hủy tiến trình lưu form.
  2. **UC-10 – Ghim vị trí tiệm trên bản đồ (`FEAT-10.2`):**
     - Mở bản đồ Google Maps tương tác từ form UC-09 (tâm mặc định là GPS hiện tại hoặc tọa độ đã lưu trước đó của tiệm).
     - Cho phép kéo bản đồ / kéo thả Marker, tự gọi Google Reverse Geocoding API hiển thị chuỗi địa chỉ xem trước (cho phép sửa tay) và nút *"Xác nhận vị trí này"* trả `(latitude, longitude, address)` về form UC-09 (`shops.location` PostGIS được DB tự sinh từ `latitude`/`longitude`).
     - *Ngoại lệ bắt buộc:* Bị từ chối quyền GPS → cho phép nhập tên đường/thành phố trên thanh tìm kiếm bản đồ để định vị thủ công.
  3. **UC-11 (phần Chủ tiệm) & tích hợp UC-12 trên `OwnerShell` (`FEAT-13.1`):**
     - Thay thế `OwnerShell` thành Dashboard Chủ tiệm: hiển thị trạng thái kiểm duyệt tiệm (`pending`/`approved`/`rejected`/`banned`), công tắc Toggle **Đang mở cửa / Tạm đóng cửa** (`shops.is_open`, chỉ bật được khi `status = 'approved'`), hiển thị SnackBar xác nhận.
     - *Ngoại lệ bắt buộc:* Mất mạng → trả công tắc về trạng thái cũ + báo lỗi; đang có ca SOS ở trạng thái `accepted` → yêu cầu hoàn thành ca trước khi đóng cửa.
     - Gắn widget/tab tiếp nhận ca SOS (UC-12 của Tùng, truyền `shopId`) vào `OwnerShell`.
  4. **UC-14 – Quản lý tài khoản, Tiệm & Tình nguyện viên (`FEAT-18.1`):**
     - Thay thế `AdminShell` thành Admin Dashboard gồm 3 mục quản lý: **Tiệm sửa xe / Cây xăng** (chờ duyệt & danh sách chung), **Hồ sơ Tình nguyện viên** (chờ duyệt & danh sách chung) và **Tài khoản người dùng**.
     - Xem chi tiết từng hồ sơ (ảnh mặt tiền từ `shop-images`, ảnh giấy tờ xác minh TNV từ bucket private `id-cards` qua signed URL, SĐT, vị trí, kỹ năng).
     - Hành động: **Phê duyệt** (`status = 'approved'`), **Từ chối** (`status = 'rejected'` kèm nhập lý do), **Khóa / Mở khóa** tài khoản hoặc tiệm vi phạm (`status = 'banned'` / `'active'`).
     - *Ngoại lệ bắt buộc:* Tài khoản không có quyền `admin` bị RLS từ chối → báo *"Bạn không có quyền thực hiện thao tác này"*; mất mạng → báo lỗi và giữ nguyên trạng thái cũ.
  5. **UC-15 – Thống kê hệ thống (`FEAT-19.1`):**
     - Màn hình Báo cáo thống kê trên Admin Dashboard với bộ lọc thời gian (`7 ngày`, `30 ngày` – mặc định, `Tháng hiện tại`).
     - Truy vấn tổng hợp (aggregate) từ `users`, `shops`, `volunteer_profiles`, `sos_requests` hiển thị các thẻ KPI (tổng người dùng, tiệm, cây xăng, TNV, lượt SOS, tỷ lệ hoàn thành) và biểu đồ trực quan theo thời gian (phân theo tiệm / TNV tiếp nhận).
     - Cung cấp nút *"Xuất dữ liệu"* tải về báo cáo chi tiết (CSV). *Ngoại lệ:* Không có dữ liệu trong khoảng chọn → báo *"Không có dữ liệu trong khoảng thời gian đã chọn"* và đưa các thẻ KPI về `0`.

### 1.4. Trạng thái bàn giao hiện tại

- **Đã có sẵn (nền tảng do Thuận dựng):**
  - Schema 5 bảng (`users`, `shops`, `sos_requests`, `reviews`, `volunteer_profiles`), RLS, RPC PostGIS, Storage và dữ liệu seed trong [`../supabase/`](../supabase/README.md).
  - 5 model (`lib/models/`) kèm unit test và 5 hợp đồng repository (`lib/repositories/`).
  - **UC-01:** Đăng nhập, đăng ký, chặn tài khoản `banned`, tự động điều hướng theo vai trò (`AuthGate`).
  - 4 màn hình khung rỗng (`lib/core/shells/`) để từng thành viên lắp ghép giao diện của mình.
- **Cần triển khai theo phân công Mục 1.3:** Toàn bộ màn hình & nghiệp vụ của Quân (`UC-02 → UC-06`), Tùng (`UC-07, 08, 11 TNV, 12, 13` + FCM), Hiếu (`UC-09, 10, 11 Chủ tiệm, 14, 15`) và hoàn thiện tích hợp Firebase/nối luồng bởi Thuận.

---

## 2. Thiết lập môi trường & Chạy ứng dụng lần đầu

### 2.1. Công cụ cần cài đặt

- **Git** (đã cấu hình tài khoản GitHub được thêm làm Collaborator vào kho `lucthuan1601/project-ptuddd`).
- **Flutter SDK** (Dart >= 3.x) và **Android Studio** (Android SDK + Emulator hoặc điện thoại Android bật *USB Debugging*).

### 2.2. Cấu hình định danh Git & lấy mã nguồn

Mỗi thành viên thiết lập đúng tên và email gắn với tài khoản GitHub để lịch sử commit ghi nhận chính xác đóng góp:

```bash
git config --global user.name "Ho Va Ten Cua Ban"
git config --global user.email "email_github_cua_ban@example.com"
```

Clone kho làm việc của nhóm và chuyển sang nhánh cá nhân đã tạo sẵn:

```bash
git clone https://github.com/lucthuan1601/project-ptuddd.git
cd project-ptuddd
git fetch origin

# Chọn ĐÚNG nhánh được phân công cho bạn:
git checkout --track origin/feat/quan-rider            # Quân
# git checkout --track origin/feat/tung-sos-volunteer  # Tùng
# git checkout --track origin/feat/hieu-owner-admin    # Hiếu
```

> **Lưu ý:** Không làm việc trên các nhánh cũ (`quan`, `khac-minh-hieu`, `Hoang-Tung`). Chỉ làm việc trên nhánh `feat/*` tương ứng ở trên.

### 2.3. Cấu hình biến môi trường và chạy app

Di chuyển vào thư mục mã nguồn Flutter `nhom18-65ktpm/src/`:

```bash
cd nhom18-65ktpm/src
flutter pub get

# Tạo file env.json từ file mẫu (file env.json đã được .gitignore bỏ qua)
# Windows (PowerShell):
Copy-Item env.json.example env.json
# macOS / Linux:
cp env.json.example env.json
```

1. Điền `SUPABASE_URL` và `SUPABASE_ANON_KEY` (anon/publishable key) vào `env.json` *(nhận thông tin từ Trưởng nhóm hoặc tạo project Supabase riêng và chạy SQL theo [`../supabase/README.md`](../supabase/README.md))*. **Tuyệt đối không dùng `service_role key` và không commit `env.json`.**
2. Thay `YOUR_GOOGLE_MAPS_API_KEY` trong `android/app/src/main/AndroidManifest.xml` bằng key của bạn khi chạy bản đồ *(không commit key thật lên GitHub)*.
3. Chạy ứng dụng:

```bash
flutter run --dart-define-from-file=env.json
```

Không có `env.json`, app vẫn mở được nhưng sẽ hiển thị màn hình hướng dẫn cấu hình.

### 2.4. Tài khoản test

Xem danh sách đầy đủ trong [`../supabase/README.md`](../supabase/README.md) (`rider1@test.local`, `owner1@test.local`, `owner2@test.local`, `volunteer1@test.local`, `volunteer2@test.local`, `admin@test.local`). Mật khẩu gợi ý: `123456`.

---

## 3. Quy trình làm việc nhóm với Git & GitHub

### 3.1. Nguyên tắc bắt buộc (theo quy định môn học)

1. **Cấm đụng vào nhánh `main`:** Tuyệt đối không commit hoặc push trực tiếp vào `main` (đã khóa bằng Branch Protection Rule).
2. **Chỉ thao tác trong `nhom18-65ktpm/`:** Không chỉnh sửa, đổi tên hoặc xóa `README.md`, `.gitignore` ở thư mục gốc repo hay thư mục của nhóm khác.
3. **Cấm `git add .` ở thư mục gốc:** Luôn kiểm tra `git status` và chỉ stage trong `nhom18-65ktpm/`.
4. **Không đẩy tệp rác / tệp bí mật:** Không commit `env.json`, `google-services.json`, `.env`, `build/`, `.dart_tool/`, `.gradle/`, `*.apk`, `.idea/`, `~$*` (file tạm khi đang mở Word).
5. **Không `git push --force`** lên nhánh chung `nhom/nhom18-65ktpm`.

### 3.2. Mô hình phân nhánh của nhóm

```text
upstream/main  (Kho giảng viên — chỉ Trưởng nhóm mở PR nộp bài cuối kỳ)
   └── nhom/nhom18-65ktpm  (Nhánh tích hợp chính của Nhóm 18 — chỉ Thuận merge PR)
         ├── feat/quan-rider          (Quân: UC-02 → UC-06)
         ├── feat/tung-sos-volunteer  (Tùng: UC-07, UC-08, UC-11 TNV, UC-12, UC-13, FCM)
         └── feat/hieu-owner-admin    (Hiếu: UC-09, UC-10, UC-11 Chủ tiệm, UC-14, UC-15)
```

### 3.3. Quy trình làm việc hằng ngày (7 bước)

**Bước 1 – Đồng bộ code mới nhất từ nhánh nhóm trước khi code:**

```bash
git checkout feat/<nhanh-cua-ban>
git fetch origin
git merge origin/nhom/nhom18-65ktpm
```

**Bước 2 – Lập trình trong đúng thư mục tính năng được giao** (xem Mục 4).

**Bước 3 – Kiểm tra chất lượng mã nguồn (bắt buộc trước khi commit/PR):**

```bash
cd nhom18-65ktpm/src
flutter analyze   # Phải đạt 0 issue
flutter test      # Toàn bộ test phải pass
```

**Bước 4 – Rà soát các tệp thay đổi (tại thư mục gốc `project-ptuddd/`):**

```bash
git status
```

Kiểm tra kỹ: đang ở đúng nhánh `feat/...` và **100% đường dẫn tệp thay đổi đều bắt đầu bằng `nhom18-65ktpm/`**, không lẫn `env.json` hay file build.

**Bước 5 – Stage tệp theo đúng đường dẫn nhóm:**

```bash
# Khuyến nghị chỉ định rõ tệp hoặc thư mục con đã sửa:
git add nhom18-65ktpm/src/lib/features/<module-cua-ban>/
# Hoặc toàn bộ thư mục nhóm sau khi đã kiểm tra kỹ git status:
git add nhom18-65ktpm/
```

**Bước 6 – Commit theo đúng quy tắc:**

```bash
git commit -m "<type>(<scope>): <mo ta ngan gon khong dau>"
```

**Bước 7 – Push lên nhánh cá nhân và mở Pull Request:**

```bash
git push origin feat/<nhanh-cua-ban>
```

### 3.4. Quy tắc đặt tên Commit

Định dạng bắt buộc: `<type>(<scope>): <mô tả ngắn gọn, tiếng Việt không dấu, viết thường>`.

| `type` | Mục đích sử dụng | Ví dụ chuẩn |
| --- | --- | --- |
| `feat` | Thêm tính năng, màn hình hoặc mã nguồn mới | `feat(rider): hien thi ban do GPS va tim tiem quanh day` |
| `fix` | Sửa lỗi logic, giao diện hoặc CSDL | `fix(sos): chan bam nhan ca trung lap tren man hinh TNV` |
| `docs` | Cập nhật tài liệu, README, báo cáo, `danhsachnhom.md` | `docs(nhom18): cap nhat huong dan lam viec nhom` |
| `chore` | Cấu hình project, thêm package, quyền Android | `chore(android): bo sung quyen thong bao FCM` |
| `refactor` | Tối ưu cấu trúc code nhưng không đổi hành vi | `refactor(owner): tach widget chon gio mo cua` |
| `test` | Bổ sung hoặc cập nhật unit/widget test | `test(review): them test kiem tra so sao hop le` |

**Quy ước `<scope>`:**
- Dùng `nhom18` cho thay đổi chung của nhóm (tài liệu, danh sách nhóm, cấu hình chung).
- Dùng tên phân hệ/module cho commit tính năng: `auth`, `rider`, `map`, `shop`, `sos`, `review`, `volunteer`, `owner`, `admin`, `db`, `core`, `android`.

### 3.5. Quy trình Pull Request, Review & Definition of Done (DoD)

1. Mở PR trên GitHub tại kho `lucthuan1601/project-ptuddd`:
   - **base:** `nhom/nhom18-65ktpm` ← **compare:** `feat/<nhanh-cua-ban>`
2. **Tiêu đề PR:** `[UC-xx] Mô tả ngắn tính năng` (ví dụ: `[UC-02,03] Bản đồ GPS và tìm kiếm tiệm gần đây`).
3. **Nội dung PR (Description)** cần có:
   - Danh sách UC / công việc đã hoàn thành.
   - Ảnh chụp màn hình hoặc video ngắn demo chạy trên máy thật / emulator.
   - Xác nhận đã chạy `flutter analyze` (0 issue) và `flutter test` (pass).
4. **Quyền merge:** **Chỉ Trưởng nhóm (Thuận)** review và merge PR vào `nhom/nhom18-65ktpm`. Sau khi PR được merge, các thành viên khác kéo lại `origin/nhom/nhom18-65ktpm` về nhánh của mình.
5. **Nộp bài cho Giảng viên (Trưởng nhóm thực hiện):** Mở PR từ `lucthuan1601/project-ptuddd` (`nhom/nhom18-65ktpm`) sang `oanhcuongdo/project-ptuddd` (`main`) với tiêu đề `[Nộp bài] nhom18-65ktpm - Ứng dụng Kết nối & Tình nguyện Xe máy`.

### 3.6. Xử lý nhanh các sự cố Git thường gặp

- **Lỡ `git add` nhầm tệp ngoài `nhom18-65ktpm/` hoặc `env.json`:**
  ```bash
  git restore --staged <duong-dan-tep-bi-nham>
  ```
- **Bị từ chối push (`rejected - non-fast-forward`):**
  ```bash
  git pull --rebase origin feat/<nhanh-cua-ban>
  git push origin feat/<nhanh-cua-ban>
  ```
- **Gặp xung đột (merge conflict):**
  - Không tự ý xóa hoặc ghi đè code của thành viên khác khi chưa trao đổi.
  - Sau khi giải quyết conflict, bắt buộc chạy lại `flutter analyze`, `flutter test` và test lại luồng liên quan trên máy trước khi commit.

---

## 4. Cấu trúc mã nguồn, Hợp đồng module & Điểm giáp ranh

### 4.1. Cấu trúc thư mục `lib/` & quyền sở hữu

```text
lib/
  core/
    env.dart, supabase_client.dart, theme.dart, validators.dart  # Dùng chung (Thuận quản lý)
    auth_gate.dart               # Thuận (không tự sửa)
    shells/
      rider_shell.dart           # Quân (gắn nút gửi SOS của Tùng)
      owner_shell.dart           # Hiếu (gắn màn hình nhận SOS của Tùng)
      volunteer_shell.dart       # Tùng
      admin_shell.dart           # Hiếu
  models/                        # Thuận đã chốt — KHÔNG tự ý đổi tên trường/cột
  repositories/                  # Hợp đồng dùng chung — muốn đổi chữ ký hàm phải báo Thuận
  features/
    auth/                        # Thuận (UC-01)
    map/ shop/ call/ navigation/ # Quân (UC-02 → UC-06)
    sos/ review/ volunteer/      # Tùng (UC-07, UC-08, UC-11 phần TNV, UC-12, UC-13)
    owner/ admin/                # Hiếu (UC-09, UC-10, UC-11 phần Chủ tiệm, UC-14, UC-15)
```

Quy ước trong mỗi module: tổ chức thành `screens/`, `widgets/` và `data/` (lớp gọi Supabase đặt cạnh module, ví dụ `features/sos/data/supabase_sos_repository.dart`).

### 4.2. Hợp đồng Repository (`lib/repositories/`)

| Repository | Người phụ trách | Ghi chú triển khai |
| --- | --- | --- |
| `AuthRepository` | Thuận | Đã hoạt động ổn định, dùng trực tiếp |
| `ShopRepository` | Thuận (đọc) | `nearby()` gọi RPC `get_nearby_shops`; Quân dùng `nearby`/`byId` cho UC-02 → UC-04. Phần CRUD chủ tiệm đặt tại `features/owner/data/owner_shop_repository.dart` (Hiếu) |
| `ReviewRepository` | Tùng | UC-08 (`upsert` — mỗi rider 1 review/tiệm) và `listByShop` để Quân hiển thị trong UC-04 |
| `SosRepository` | Tùng | UC-07 (`create`/`cancel`) & UC-12 (`watchPending`/`accept`/`complete`/`contact`). Nhận ca **bắt buộc** qua RPC `accept_sos` |
| `VolunteerRepository` | Tùng | UC-13 & UC-11 phần TNV. `updateLocation` ghi EWKT: `SRID=4326;POINT(lng lat)` |

### 4.3. Các điểm giáp ranh cần thống nhất (không tự ý đổi)

1. **Quân ↔ Tùng (UC-04, UC-07, UC-08):**
   - Trên màn hình chính Rider (`RiderShell`) và màn hình Chi tiết tiệm (UC-04) do Quân xây dựng: đặt sẵn nút **Gửi SOS** (mở màn hình UC-07 của Tùng), nút **Đánh giá** (mở hộp thoại UC-08 của Tùng) và khu vực hiển thị danh sách review lấy qua `ReviewRepository.listByShop(shopId)`.
2. **Hiếu ↔ Tùng (UC-11, UC-12):**
   - **UC-11:** Chủ tiệm dùng `shops.is_open` (Hiếu), Tình nguyện viên dùng `volunteer_profiles.is_available` (Tùng) — hai luồng riêng, không gộp.
   - **UC-12:** Tùng xây dựng màn hình tiếp nhận & xử lý ca SOS dưới dạng widget/screen tái sử dụng theo tham số (`volunteerId` hoặc `shopId`) để Hiếu gắn trực tiếp vào `OwnerShell`.
3. **Khóa ca cứu hộ:** Chỉ RPC `accept_sos` được đổi `sos_requests.status` sang `accepted`; tuyệt đối không update trực tiếp bảng `sos_requests` từ client để tránh 2 người nhận trùng ca.
4. **Payload FCM (khi triển khai Edge Function):** `{ "sos_id", "issue_type", "lat", "lng" }`.
5. **Tệp dùng chung (`pubspec.yaml`, `models/`, `repositories/`, `core/`, `supabase/*.sql`):** Cần bổ sung thư viện hoặc chỉnh sửa schema phải trao đổi trên nhóm với Thuận trước để tránh conflict khi merge.

---

## 5. Phối hợp trong nhóm & Lỗi kỹ thuật thường gặp

### 5.1. Nguyên tắc phối hợp nội bộ

- **Trao đổi sớm khi bị chặn:** Nếu thiếu dữ liệu mẫu, bị lỗi RLS hay cần thêm package trong `pubspec.yaml`, báo ngay cho Thuận để xử lý tập trung trên nhánh `nhom/nhom18-65ktpm`.
- **Chia nhỏ PR:** Mỗi PR chỉ nên tập trung vào 1–2 Use Case hoàn chỉnh thay vì dồn quá nhiều thay đổi vào cuối kỳ.
- **Tôn trọng phạm vi code:** Không tự sửa code trong thư mục `features/` của thành viên khác nếu chưa thống nhất.

### 5.2. Lỗi kỹ thuật thường gặp

- `st_dwithin does not exist` → PostGIS chưa bật hoặc function thiếu `extensions` trong `search_path` (đã xử lý trong `supabase/03_functions.sql`).
- Đăng nhập xong quay lại form → chưa có dòng tương ứng trong `public.users`; kiểm tra trigger `on_auth_user_created` đã chạy.
- Bản đồ trắng → chưa thay Google Maps API key trong `AndroidManifest.xml` hoặc chưa bật billing/Maps SDK for Android.
- `permission denied for table ...` → thiếu policy RLS hoặc quyền `GRANT` tương ứng, không phải do sai API key.
