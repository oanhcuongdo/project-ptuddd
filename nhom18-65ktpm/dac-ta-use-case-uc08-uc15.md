# Đặc Tả Use Case UC-08 Đến UC-15

- **Nhóm:** Nhóm 18 – 65KTPM
- **Đề tài:** Ứng dụng Kết nối Cứu hộ & Tình nguyện Xe máy
- **Người thực hiện:** Hoàng Tùng (2351170630)
- **Phạm vi:** UC-08 → UC-15 (phần tiếp nối UC-01 → UC-07)

**Quy ước chung cho bảng Đầu vào / Đầu ra:**

- **Nguồn** của đầu vào: *Người dùng nhập* (form/thao tác trên UI), *Hệ thống* (lấy tự động từ phiên đăng nhập, GPS, ngữ cảnh màn hình), *CSDL* (đọc từ Supabase PostgreSQL), *API ngoài* (Google Maps).
- **Đích** của đầu ra: *CSDL* (bảng trên Supabase PostgreSQL), *Storage* (Supabase Storage), *UI* (hiển thị trên màn hình tác nhân), *Realtime/FCM* (đẩy tới thiết bị khác).
- Tên cột/bảng khớp với mục 5.3 *Thiết kế Cơ sở dữ liệu* (`users`, `shops`, `sos_requests`, `reviews`, `volunteer_profiles`).

---

## 4.8 Bảng đặc tả UC-08: Đánh giá & Viết nhận xét

| Mục | Nội dung |
| --- | --- |
| Tên use case | Đánh giá & Viết nhận xét (UC-08) |
| Tác nhân chính | Rider (Khách hàng) |
| Mục đích (mô tả) | Cho phép khách hàng chấm điểm mức độ hài lòng (1–5 sao) kèm bình luận về chất lượng dịch vụ của tiệm sửa xe/cây xăng, giúp người dùng khác tham khảo khi lựa chọn. |
| Mức độ ưu tiên | Trung bình |
| Điều kiện kích hoạt | Rider nhấn nút "Đánh giá" tại màn hình Chi tiết địa điểm (UC-04), hoặc nhấn gợi ý "Đánh giá dịch vụ" sau khi ca cứu hộ SOS do tiệm tiếp nhận chuyển sang `completed` (UC-12). |
| Điều kiện tiên quyết | Rider đã đăng nhập (UC-01), tài khoản `status = 'active'`; tiệm được đánh giá có `status = 'approved'`. |
| Điều kiện thành công | Một bản ghi mới được thêm vào bảng `reviews`; `rating` (trung bình) và `review_count` của tiệm trong bảng `shops` được tính lại; đánh giá mới hiển thị ngay trên trang chi tiết tiệm. |
| Điều kiện thất bại | Đánh giá không được lưu do chưa chọn số sao, nội dung vượt giới hạn, tài khoản bị khóa hoặc mất kết nối mạng. Dữ liệu `shops` giữ nguyên. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã tiệm (`shop_id`) | UUID | Có | Tồn tại trong `shops`, `status = 'approved'` | Hệ thống (ngữ cảnh màn hình Chi tiết tiệm) |
| 2 | Mã khách hàng (`rider_id`) | UUID | Có | Lấy từ phiên đăng nhập, `role = 'rider'` | Hệ thống (Supabase Auth – `auth.uid()`) |
| 3 | Số sao (`rating`) | SMALLINT | Có | Số nguyên 1 ≤ rating ≤ 5 | Người dùng chọn trên thanh sao |
| 4 | Nội dung nhận xét (`comment`) | TEXT | Không | Tối đa 500 ký tự, tự động cắt khoảng trắng đầu/cuối | Người dùng nhập |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Bản ghi đánh giá mới (`id`, `shop_id`, `rider_id`, `rating`, `comment`, `created_at`) | Row bảng `reviews` | CSDL | Lưu đánh giá của Rider |
| 2 | Điểm trung bình mới (`shops.rating`) | NUMERIC(2,1) | CSDL | `AVG(reviews.rating)` của tiệm, làm tròn 1 chữ số thập phân |
| 3 | Tổng lượt đánh giá mới (`shops.review_count`) | INTEGER | CSDL | `review_count + 1` |
| 4 | Thông báo "Gửi đánh giá thành công" | Chuỗi (SnackBar) | UI | Hiển thị cho Rider |
| 5 | Danh sách đánh giá & điểm trung bình đã làm mới | Danh sách `reviews` + điểm `rating` | UI | Trang chi tiết tiệm hiển thị đánh giá mới nhất ở đầu |
| 6 | Thông báo lỗi (khi thất bại) | Chuỗi | UI | Xem luồng ngoại lệ |

**Luồng sự kiện chính**

1. Rider nhấn nút "Đánh giá" tại màn hình chi tiết tiệm.
2. Hệ thống hiển thị hộp thoại đánh giá gồm thanh chọn số sao (1–5) và ô nhập nhận xét (đếm ký tự còn lại).
3. Rider chọn số sao và (tùy chọn) nhập nội dung nhận xét.
4. Rider nhấn "Gửi đánh giá".
5. Hệ thống kiểm tra dữ liệu: đã chọn số sao trong khoảng 1–5, nhận xét không quá 500 ký tự.
6. Hệ thống thêm bản ghi vào bảng `reviews` với `shop_id`, `rider_id` lấy từ phiên đăng nhập.
7. Trigger CSDL tính lại `rating` trung bình và `review_count` của tiệm trong bảng `shops`.
8. Hệ thống hiển thị thông báo thành công, đóng hộp thoại và làm mới danh sách đánh giá, điểm trung bình trên trang chi tiết tiệm.

**Luồng sự kiện thay thế**

- **A1 – Đánh giá từ gợi ý sau ca SOS:** Tại bước 1, nếu Rider mở từ thông báo "Ca cứu hộ đã hoàn thành" (UC-12), hệ thống tự điền `shop_id` của tiệm đã tiếp nhận ca và chuyển thẳng tới bước 2.
- **A2 – Hủy đánh giá:** Tại bước 3–4, nếu Rider nhấn "Hủy" hoặc đóng hộp thoại, hệ thống không lưu dữ liệu và quay về màn hình chi tiết tiệm.

**Luồng sự kiện ngoại lệ**

- **E1 – Chưa chọn số sao:** Tại bước 5, hệ thống báo *"Vui lòng chọn số sao trước khi gửi"*, giữ nguyên nội dung đã nhập.
- **E2 – Nhận xét quá dài:** Tại bước 5, hệ thống báo *"Nội dung nhận xét không được vượt quá 500 ký tự"*.
- **E3 – Tài khoản bị khóa:** Tại bước 6, chính sách RLS từ chối thao tác ghi; hệ thống báo *"Tài khoản của bạn đã bị khóa, không thể gửi đánh giá"*.
- **E4 – Mất kết nối mạng:** Tại bước 6, hệ thống báo *"Không thể kết nối mạng, vui lòng thử lại sau"*, giữ nguyên dữ liệu trong hộp thoại và hiển thị nút "Thử lại".

---

## 4.9 Bảng đặc tả UC-09: Đăng ký & Quản lý tiệm

| Mục | Nội dung |
| --- | --- |
| Tên use case | Đăng ký & Quản lý tiệm (UC-09) |
| Tác nhân chính | Shop Owner (Chủ tiệm sửa xe) |
| Mục đích (mô tả) | Cho phép chủ tiệm tạo mới hồ sơ tiệm (tên, loại hình, hotline, giờ mở/đóng cửa, ảnh mặt tiền, vị trí) hoặc chỉnh sửa hồ sơ đã có. Hồ sơ mới ở trạng thái chờ Admin phê duyệt (UC-14) trước khi hiển thị công khai trên bản đồ. |
| Mức độ ưu tiên | Cao |
| Điều kiện kích hoạt | Chủ tiệm chọn mục "Quản lý tiệm" trên thanh điều hướng, hoặc được chuyển tới tự động ngay sau khi đăng ký tài khoản vai trò Owner (UC-01). |
| Điều kiện tiên quyết | Chủ tiệm đã đăng nhập với `role = 'owner'`, tài khoản `status = 'active'`, thiết bị có kết nối Internet. |
| Điều kiện thành công | Hồ sơ tiệm mới được lưu vào bảng `shops` với `status = 'pending'`, hoặc thông tin chỉnh sửa được cập nhật thành công; ảnh mặt tiền (nếu có) được lưu trên Supabase Storage. |
| Điều kiện thất bại | Không lưu được hồ sơ do thiếu trường bắt buộc, dữ liệu sai định dạng, tải ảnh thất bại hoặc mất kết nối. Dữ liệu cũ (nếu có) giữ nguyên. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã chủ tiệm (`owner_id`) | UUID | Có | Lấy từ phiên đăng nhập, `role = 'owner'` | Hệ thống (Supabase Auth) |
| 2 | Mã tiệm (`shop_id`) | UUID | Chỉ khi sửa | Tiệm thuộc sở hữu của `owner_id` | CSDL (hồ sơ tiệm hiện có) |
| 3 | Tên tiệm (`name`) | VARCHAR(150) | Có | 3–150 ký tự | Người dùng nhập |
| 4 | Loại hình (`category`) | VARCHAR(30) | Có | `'repair_shop'` (Tiệm sửa xe) hoặc `'gas_station'` (Cây xăng) | Người dùng chọn |
| 5 | SĐT hotline (`phone`) | VARCHAR(20) | Có | Số điện thoại Việt Nam 10 chữ số, bắt đầu bằng 0 | Người dùng nhập |
| 6 | Giờ mở cửa (`open_time`) | TIME | Có | Định dạng HH:mm | Người dùng chọn (Time Picker) |
| 7 | Giờ đóng cửa (`close_time`) | TIME | Có | Định dạng HH:mm, khác `open_time` | Người dùng chọn (Time Picker) |
| 8 | Ảnh mặt tiền | Tệp ảnh | Không (khuyến nghị) | JPG/PNG, dung lượng ≤ 5 MB | Người dùng chọn từ thư viện/camera |
| 9 | Vĩ độ, Kinh độ (`latitude`, `longitude`) | DOUBLE PRECISION | Có | Kết quả trả về từ UC-10 | UC-10 (include) |
| 10 | Địa chỉ chi tiết (`address`) | TEXT | Có | Chuỗi địa chỉ từ Reverse Geocoding (UC-10), cho phép sửa tay | UC-10 / Người dùng chỉnh |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Bản ghi tiệm mới/cập nhật (`id`, `owner_id`, `name`, `category`, `phone`, `address`, `latitude`, `longitude`, `open_time`, `close_time`, `image_url`) | Row bảng `shops` | CSDL | Tạo mới (INSERT) hoặc cập nhật (UPDATE) |
| 2 | Tọa độ không gian (`location`) | GEOGRAPHY(Point, 4326) | CSDL | Sinh từ `ST_MakePoint(longitude, latitude)` phục vụ truy vấn bán kính UC-03, UC-07 |
| 3 | Trạng thái kiểm duyệt (`status`) | VARCHAR(20) | CSDL | `'pending'` với hồ sơ mới; giữ nguyên `'approved'` khi chỉ sửa giờ/ảnh/SĐT; chuyển về `'pending'` khi đổi tên, loại hình hoặc vị trí |
| 4 | URL ảnh mặt tiền (`image_url`) | TEXT | Storage + CSDL | Ảnh tải lên bucket `shop-images`, URL công khai lưu vào `shops.image_url` |
| 5 | Thông báo kết quả | Chuỗi | UI | "Đăng ký tiệm thành công, vui lòng chờ Quản trị viên phê duyệt" hoặc "Cập nhật thông tin tiệm thành công" |
| 6 | Màn hình Tổng quan quản lý tiệm | Giao diện | UI | Hiển thị thông tin tiệm và nhãn trạng thái (Chờ duyệt / Đã duyệt / Bị từ chối) |

**Luồng sự kiện chính**

1. Chủ tiệm chọn mục "Quản lý tiệm".
2. Hệ thống kiểm tra chủ tiệm đã có hồ sơ tiệm chưa: nếu chưa, hiển thị form trống; nếu có, hiển thị form với dữ liệu hiện tại.
3. Chủ tiệm nhập/sửa tên tiệm, loại hình, SĐT hotline, giờ mở – đóng cửa và chọn ảnh mặt tiền.
4. Chủ tiệm chọn "Chọn vị trí trên bản đồ" để ghim tọa độ tiệm (*include* UC-10); hệ thống điền tọa độ và địa chỉ trả về vào form.
5. Chủ tiệm nhấn "Đăng ký tiệm" (hồ sơ mới) hoặc "Lưu thay đổi" (hồ sơ cũ).
6. Hệ thống kiểm tra dữ liệu: các trường bắt buộc không trống, SĐT đúng định dạng, giờ đóng khác giờ mở, ảnh đúng định dạng và dung lượng.
7. Hệ thống tải ảnh mới (nếu có) lên Supabase Storage và nhận về URL công khai.
8. Hệ thống ghi dữ liệu vào bảng `shops`; hồ sơ mới được gán `status = 'pending'`.
9. Hệ thống hiển thị thông báo thành công và chuyển về màn hình Tổng quan quản lý tiệm.

**Luồng sự kiện thay thế**

- **A1 – Sửa thông tin nhạy cảm của tiệm đã duyệt:** Tại bước 8, nếu chủ tiệm thay đổi tên tiệm, loại hình hoặc vị trí của tiệm đang `approved`, hệ thống chuyển `status` về `'pending'` để Admin duyệt lại và báo *"Thông tin thay đổi cần được Quản trị viên duyệt lại"*.
- **A2 – Hồ sơ bị từ chối:** Tại bước 2, nếu hồ sơ đang `rejected`, hệ thống hiển thị lý do từ chối (từ UC-14) phía trên form; sau khi chủ tiệm sửa và gửi lại, `status` chuyển về `'pending'`.

**Luồng sự kiện ngoại lệ**

- **E1 – Thiếu thông tin bắt buộc:** Tại bước 6, hệ thống tô đỏ các trường thiếu và báo *"Vui lòng nhập đầy đủ các thông tin bắt buộc"*.
- **E2 – Sai định dạng:** Tại bước 6, hệ thống báo *"Số điện thoại không hợp lệ"* hoặc *"Giờ đóng cửa phải khác giờ mở cửa"* ngay dưới trường tương ứng.
- **E3 – Ảnh không hợp lệ:** Tại bước 6, ảnh không phải JPG/PNG hoặc lớn hơn 5 MB, hệ thống báo *"Ảnh phải có định dạng JPG/PNG và dung lượng không quá 5 MB"*.
- **E4 – Tải ảnh thất bại:** Tại bước 7, hệ thống báo *"Không thể tải ảnh lên, vui lòng kiểm tra kết nối hoặc chọn ảnh khác"* và hủy tiến trình lưu form.
- **E5 – Mất kết nối mạng:** Tại bước 8, hệ thống báo lỗi kết nối, giữ nguyên dữ liệu đã nhập trên form để gửi lại.

---

## 4.10 Bảng đặc tả UC-10: Ghim vị trí tiệm trên bản đồ

| Mục | Nội dung |
| --- | --- |
| Tên use case | Ghim vị trí tiệm trên bản đồ (UC-10) |
| Tác nhân chính | Shop Owner (Chủ tiệm); tác nhân phụ: Google Maps API |
| Mục đích (mô tả) | Xác định chính xác tọa độ địa lý (vĩ độ, kinh độ) và địa chỉ văn bản của tiệm, làm căn cứ hiển thị Marker trên bản đồ và tính khoảng cách cho Rider tìm kiếm (UC-03) và gửi SOS (UC-07). |
| Mức độ ưu tiên | Cao |
| Điều kiện kích hoạt | Trong form Tạo/Sửa hồ sơ tiệm (UC-09), chủ tiệm nhấn "Chọn vị trí trên bản đồ". |
| Điều kiện tiên quyết | Chủ tiệm đã đăng nhập và đang ở màn hình Tạo/Sửa hồ sơ tiệm (UC-09); thiết bị có kết nối Internet để tải bản đồ. |
| Điều kiện thành công | Cặp tọa độ (latitude, longitude) và chuỗi địa chỉ được trả về và điền vào form UC-09 (được lưu vào CSDL khi chủ tiệm lưu form). |
| Điều kiện thất bại | Không xác định được tọa độ (bản đồ không tải được, chủ tiệm hủy thao tác); form UC-09 giữ nguyên vị trí cũ (nếu có). |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Tọa độ khởi tạo tâm bản đồ | (lat, lng) DOUBLE | Có | Ưu tiên: tọa độ tiệm đã lưu → vị trí GPS hiện tại (UC-02) → tâm mặc định của thành phố | CSDL / Hệ thống (Geolocator) |
| 2 | Vị trí Marker được chọn | (lat, lng) DOUBLE | Có | −90 ≤ lat ≤ 90; −180 ≤ lng ≤ 180; nằm trong lãnh thổ Việt Nam | Người dùng kéo bản đồ / thả Marker |
| 3 | Từ khóa tìm địa chỉ | Chuỗi | Không | Tên đường, phường/xã, quận/huyện (khi định vị thủ công) | Người dùng nhập trên thanh tìm kiếm |
| 4 | Địa chỉ văn bản | Chuỗi | Có | Kết quả Reverse Geocoding cho tọa độ Marker | API ngoài (Google Geocoding API) |
| 5 | Lệnh xác nhận vị trí | Thao tác nhấn nút | Có | Nút "Xác nhận vị trí này" | Người dùng |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Vĩ độ, Kinh độ (`latitude`, `longitude`) | DOUBLE PRECISION | Form UC-09 → CSDL `shops` | Tọa độ tiệm đã xác nhận |
| 2 | Địa chỉ chi tiết (`address`) | TEXT | Form UC-09 → CSDL `shops` | Chuỗi địa chỉ từ Reverse Geocoding |
| 3 | Tọa độ không gian (`location`) | GEOGRAPHY(Point, 4326) | CSDL `shops` | Sinh từ cặp tọa độ khi lưu form UC-09 |
| 4 | Marker và thẻ địa chỉ xem trước | Giao diện | UI | Hiển thị vị trí đang chọn và địa chỉ tương ứng trước khi xác nhận |

**Luồng sự kiện chính**

1. Chủ tiệm nhấn "Chọn vị trí trên bản đồ" trong form UC-09.
2. Hệ thống mở màn hình bản đồ Google Maps, đặt tâm tại tọa độ tiệm đã lưu hoặc vị trí GPS hiện tại của thiết bị.
3. Chủ tiệm di chuyển bản đồ hoặc kéo Marker tới đúng vị trí cửa hàng.
4. Khi Marker dừng lại, hệ thống gọi Google Reverse Geocoding API để lấy địa chỉ văn bản và hiển thị trên thẻ xem trước.
5. Chủ tiệm kiểm tra địa chỉ và nhấn "Xác nhận vị trí này".
6. Hệ thống trả cặp tọa độ và địa chỉ về form UC-09 rồi đóng màn hình bản đồ.

**Luồng sự kiện thay thế**

- **A1 – Định vị bằng tìm kiếm địa chỉ:** Tại bước 3, chủ tiệm nhập địa chỉ vào thanh tìm kiếm; hệ thống gọi Geocoding API, di chuyển bản đồ và Marker tới kết quả đầu tiên, sau đó tiếp tục bước 4.
- **A2 – Hủy chọn vị trí:** Tại bước 3–5, chủ tiệm nhấn "Quay lại"; hệ thống đóng bản đồ, form UC-09 giữ nguyên vị trí cũ.

**Luồng sự kiện ngoại lệ**

- **E1 – Không cấp quyền vị trí:** Tại bước 2, nếu chưa có quyền truy cập vị trí, hệ thống yêu cầu cấp quyền; nếu chủ tiệm từ chối, bản đồ đặt tâm mặc định và chủ tiệm định vị thủ công theo luồng A1.
- **E2 – Reverse Geocoding thất bại:** Tại bước 4, nếu API lỗi hoặc không có kết quả, hệ thống hiển thị *"Không xác định được địa chỉ, vui lòng nhập địa chỉ thủ công"* và cho phép chủ tiệm tự nhập địa chỉ (tọa độ vẫn được giữ).
- **E3 – Vị trí ngoài phạm vi phục vụ:** Tại bước 5, nếu tọa độ nằm ngoài lãnh thổ Việt Nam, hệ thống báo *"Vị trí không nằm trong phạm vi phục vụ"* và không cho xác nhận.
- **E4 – Mất kết nối mạng:** Tại bước 2, bản đồ không tải được, hệ thống báo lỗi kết nối và hiển thị nút "Thử lại".

---

## 4.11 Bảng đặc tả UC-11: Cập nhật trạng thái hoạt động

| Mục | Nội dung |
| --- | --- |
| Tên use case | Cập nhật trạng thái hoạt động (UC-11) |
| Tác nhân chính | Shop Owner (Chủ tiệm), Volunteer (Tình nguyện viên) |
| Mục đích (mô tả) | Cung cấp công tắc chuyển nhanh trạng thái hoạt động theo thời gian thực: Chủ tiệm bật/tắt "Đang mở cửa / Tạm đóng cửa" (`shops.is_open`); Tình nguyện viên bật/tắt "Sẵn sàng hỗ trợ / Tạm nghỉ" (`volunteer_profiles.is_available`). Trạng thái quyết định việc tiệm hiển thị là mở trên bản đồ và việc nhận thông báo SOS. |
| Mức độ ưu tiên | Trung bình |
| Điều kiện kích hoạt | Chủ tiệm hoặc Tình nguyện viên gạt công tắc trạng thái trên màn hình Bảng điều khiển (Dashboard). |
| Điều kiện tiên quyết | Đã đăng nhập; tiệm (Owner) hoặc hồ sơ TNV (Volunteer) có `status = 'approved'`; tài khoản `status = 'active'`. Với Volunteer: đã cấp quyền vị trí (UC-02). |
| Điều kiện thành công | Trường `is_open` hoặc `is_available` được cập nhật; Marker tiệm trên bản đồ Rider đổi trạng thái qua Supabase Realtime; TNV sẵn sàng được đưa vào danh sách nhận SOS (UC-07, UC-12). |
| Điều kiện thất bại | Không cập nhật được do mất mạng, hồ sơ chưa duyệt hoặc đang có ca SOS chưa hoàn thành; công tắc trở về trạng thái cũ. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã người dùng (`user_id`) và vai trò (`role`) | UUID, VARCHAR | Có | `role` ∈ {`'owner'`, `'volunteer'`} | Hệ thống (phiên đăng nhập) |
| 2 | Mã tiệm (`shop_id`) | UUID | Có (Owner) | Tiệm thuộc sở hữu của người dùng, `status = 'approved'` | CSDL |
| 3 | Mã hồ sơ TNV (`volunteer_profiles.id`) | UUID | Có (Volunteer) | Hồ sơ của người dùng, `status = 'approved'` | CSDL |
| 4 | Trạng thái mới (`is_open` hoặc `is_available`) | BOOLEAN | Có | `true` / `false` | Người dùng gạt Toggle Switch |
| 5 | Vị trí GPS hiện tại | (lat, lng) DOUBLE | Có (Volunteer bật sẵn sàng) | Lấy tại thời điểm bật công tắc | Hệ thống (Geolocator – UC-02) |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | `shops.is_open` mới | BOOLEAN | CSDL | Trạng thái mở/đóng cửa của tiệm (Owner) |
| 2 | `volunteer_profiles.is_available` mới | BOOLEAN | CSDL | Trạng thái sẵn sàng nhận SOS (Volunteer) |
| 3 | `volunteer_profiles.location` mới | GEOGRAPHY(Point, 4326) | CSDL | Vị trí hiện tại của TNV, dùng cho hàm `get_nearby_volunteers` |
| 4 | Sự kiện thay đổi bảng `shops` | Realtime event | Realtime → App Rider | Marker tiệm đổi màu/nhãn "Đang mở cửa" ↔ "Đóng cửa" |
| 5 | Nhãn trạng thái và SnackBar "Cập nhật trạng thái thành công" | Giao diện | UI | Hiển thị cho chủ tiệm/TNV |

**Luồng sự kiện chính** (Chủ tiệm)

1. Chủ tiệm mở Bảng điều khiển quản lý tiệm.
2. Hệ thống hiển thị công tắc trạng thái hiện tại (`is_open`).
3. Chủ tiệm gạt công tắc để đổi trạng thái (VD: chuyển sang "Tạm đóng cửa" khi nghỉ đột xuất).
4. Hệ thống kiểm tra chủ tiệm không có ca SOS đang ở trạng thái `accepted` (khi chuyển sang đóng cửa).
5. Hệ thống cập nhật `shops.is_open` trên Supabase PostgreSQL.
6. Supabase Realtime đẩy thay đổi tới các ứng dụng Rider đang mở bản đồ; Marker tiệm được cập nhật.
7. Hệ thống hiển thị SnackBar xác nhận cập nhật thành công.

**Luồng sự kiện thay thế**

- **A1 – Tình nguyện viên bật/tắt sẵn sàng:** Tại bước 3, nếu người dùng là Volunteer, hệ thống lấy vị trí GPS hiện tại và cập nhật `volunteer_profiles.is_available` cùng `location`. Chỉ TNV có `is_available = true` mới nhận SOS; vị trí TNV không hiển thị công khai trên bản đồ để bảo vệ quyền riêng tư. Khi TNV tắt sẵn sàng, hệ thống ngừng gửi SOS tới thiết bị đó.

**Luồng sự kiện ngoại lệ**

- **E1 – Mất kết nối mạng:** Tại bước 5, công tắc trở về vị trí cũ và hệ thống báo *"Lỗi kết nối, không thể cập nhật trạng thái"*.
- **E2 – Đang xử lý ca cứu hộ:** Tại bước 4, nếu có ca SOS `accepted` chưa hoàn thành, hệ thống báo *"Vui lòng hoàn thành ca cứu hộ đang xử lý trước khi tạm nghỉ"* và giữ nguyên trạng thái.
- **E3 – Hồ sơ chưa được duyệt hoặc bị khóa:** Tại bước 2, công tắc bị vô hiệu hóa kèm ghi chú *"Hồ sơ đang chờ phê duyệt"* hoặc *"Hồ sơ đã bị khóa"*.
- **E4 – Không lấy được GPS (Volunteer):** Tại luồng A1, nếu không lấy được vị trí, hệ thống báo *"Không xác định được vị trí, vui lòng bật GPS"* và không bật trạng thái sẵn sàng.

---

## 4.12 Bảng đặc tả UC-12: Tiếp nhận yêu cầu SOS

| Mục | Nội dung |
| --- | --- |
| Tên use case | Tiếp nhận yêu cầu SOS (UC-12) |
| Tác nhân chính | Shop Owner (Chủ tiệm), Volunteer (Tình nguyện viên) – người tiếp nhận; Rider – người tạo yêu cầu (tác nhân phụ) |
| Mục đích (mô tả) | Cho phép chủ tiệm hoặc TNV nhận cảnh báo cứu hộ khẩn cấp ở gần, xem thông tin sự cố, quyết định Tiếp nhận hoặc Từ chối và xác nhận hoàn thành ca cứu hộ. Mỗi ca chỉ được gán cho đúng một người tiếp nhận. |
| Mức độ ưu tiên | Rất cao |
| Điều kiện kích hoạt | Có yêu cầu SOS mới (`status = 'pending'`) trong bán kính phục vụ; hệ thống đẩy thông báo FCM và hiển thị Pop-up khẩn cấp trên thiết bị người nhận. |
| Điều kiện tiên quyết | Người nhận đã đăng nhập; tiệm `is_open = true` hoặc TNV `is_available = true`, đều `status = 'approved'`; thiết bị đã đăng ký `fcm_token`. |
| Điều kiện thành công | Ca SOS chuyển sang `accepted` và gán đúng một trong `accepted_shop_id` / `accepted_volunteer_id`; khi hỗ trợ xong chuyển sang `completed` kèm `completed_at`. Nếu người nhận từ chối, ca vẫn `pending` cho người khác. |
| Điều kiện thất bại | Ca đã được người khác nhận trước, đã bị Rider hủy (`cancelled`) hoặc hết thời gian chờ; người nhận không được gán vào ca. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã yêu cầu (`request_id` = `sos_requests.id`) | UUID | Có | Ca đang `status = 'pending'` | Hệ thống (payload thông báo FCM / Realtime) |
| 2 | Thông tin ca SOS: `issue_type`, `note`, `contact_phone`, `latitude`, `longitude`, `created_at` | VARCHAR, TEXT, DOUBLE, TIMESTAMPTZ | Có | Đọc từ bản ghi `sos_requests` | CSDL |
| 3 | Vị trí hiện tại của người nhận | (lat, lng) DOUBLE | Có | Dùng tính khoảng cách tới điểm sự cố | Hệ thống (Geolocator – UC-02) |
| 4 | Mã người tiếp nhận (`shop_id` hoặc `volunteer_profiles.id`) | UUID | Có | Khớp vai trò người đăng nhập | Hệ thống (phiên đăng nhập + CSDL) |
| 5 | Quyết định | Enum | Có | `accept` (Tiếp nhận) / `reject` (Từ chối) | Người dùng nhấn nút |
| 6 | Xác nhận hoàn thành | Thao tác nhấn nút | Có (khi kết thúc ca) | Chỉ người đã tiếp nhận ca mới thực hiện được | Người dùng nhấn "Hoàn thành ca cứu hộ" |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Pop-up khẩn cấp (loại sự cố, khoảng cách, vị trí trên bản đồ, SĐT Rider) kèm âm thanh/rung | Giao diện | UI người nhận | Hiển thị khi có ca mới |
| 2 | `sos_requests.status = 'accepted'` + `accepted_shop_id` **hoặc** `accepted_volunteer_id` | VARCHAR, UUID | CSDL | Gán ca cho người tiếp nhận (UPDATE có điều kiện `WHERE status = 'pending'`) |
| 3 | Thông tin người hỗ trợ (tên tiệm/TNV, SĐT, vị trí) | Realtime event | Realtime → App Rider | Màn hình Rider chuyển từ "Đang chờ cứu hộ..." sang "Đã có người tiếp nhận" |
| 4 | Lệnh đóng Pop-up trên thiết bị khác | Realtime event | Realtime → App tiệm/TNV khác | Ca không còn khả dụng |
| 5 | Màn hình "Ca cứu hộ đang xử lý" (nút Gọi điện – UC-05, Chỉ đường – UC-06) | Giao diện | UI người nhận | Hỗ trợ di chuyển tới điểm sự cố |
| 6 | `sos_requests.status = 'completed'`, `completed_at = NOW()` | VARCHAR, TIMESTAMPTZ | CSDL | Kết thúc ca cứu hộ |
| 7 | `volunteer_profiles.completed_count + 1` | INTEGER | CSDL | Chỉ khi người tiếp nhận là TNV |
| 8 | Thông báo "Ca cứu hộ đã hoàn thành" (kèm gợi ý đánh giá nếu là tiệm – UC-08) | FCM / Realtime | App Rider | Kết thúc phía Rider |

**Luồng sự kiện chính**

1. Khi có ca SOS `pending` trong bán kính phục vụ, hệ thống phát âm thanh/rung và hiển thị Pop-up khẩn cấp trên thiết bị các tiệm đang mở cửa và TNV đang sẵn sàng.
2. Người nhận xem nhanh loại sự cố, ghi chú, khoảng cách, vị trí trên bản đồ và SĐT liên hệ của Rider.
3. Người nhận nhấn "Tiếp nhận".
4. Hệ thống thực hiện cập nhật có điều kiện `UPDATE sos_requests SET status = 'accepted', accepted_... = <id> WHERE id = <request_id> AND status = 'pending'`.
5. Cập nhật thành công: Rider nhận thông tin người hỗ trợ qua Supabase Realtime; Pop-up trên thiết bị các tiệm/TNV khác tự đóng.
6. Hệ thống chuyển người nhận sang màn hình "Ca cứu hộ đang xử lý" với nút Gọi điện (UC-05) và Chỉ đường (UC-06).
7. Sau khi hỗ trợ xong, người nhận nhấn "Hoàn thành ca cứu hộ"; hệ thống cập nhật `status = 'completed'`, `completed_at` (và `completed_count` nếu là TNV).
8. Rider nhận thông báo hoàn thành; nếu người hỗ trợ là tiệm sửa xe, hệ thống gợi ý Rider đánh giá dịch vụ (UC-08).

**Luồng sự kiện thay thế**

- **A1 – Người nhận từ chối:** Tại bước 3, nếu chọn "Từ chối", Pop-up đóng trên thiết bị người đó; trạng thái ca không đổi (`pending`) để người khác tiếp nhận.
- **A2 – Bỏ qua thông báo:** Nếu người nhận không thao tác trong 60 giây, Pop-up tự thu nhỏ vào danh sách "Yêu cầu SOS gần bạn"; người nhận vẫn có thể mở lại và tiếp nhận khi ca còn `pending`.
- **A3 – Rider hủy yêu cầu:** Khi ca còn `pending`, nếu Rider hủy (`status = 'cancelled'`), Pop-up trên mọi thiết bị người nhận tự đóng kèm thông báo *"Khách hàng đã hủy yêu cầu cứu hộ"*.

**Luồng sự kiện ngoại lệ**

- **E1 – Ca đã có người tiếp nhận:** Tại bước 4, câu lệnh cập nhật không tác động bản ghi nào; hệ thống báo *"Ca cứu hộ này đã được người khác tiếp nhận"* và đóng Pop-up.
- **E2 – Người nhận đang có ca khác:** Tại bước 3, nếu người nhận đang có ca `accepted` chưa hoàn thành, nút "Tiếp nhận" bị vô hiệu hóa kèm ghi chú *"Bạn đang xử lý một ca cứu hộ khác"*.
- **E3 – Mất kết nối mạng:** Tại bước 4 hoặc 7, hệ thống báo lỗi kết nối và cho phép thử lại; trạng thái ca trên CSDL không thay đổi cho tới khi cập nhật thành công.

---

## 4.13 Bảng đặc tả UC-13: Đăng ký Hồ sơ Tình nguyện viên

| Mục | Nội dung |
| --- | --- |
| Tên use case | Đăng ký Hồ sơ Tình nguyện viên (UC-13) |
| Tác nhân chính | Volunteer (Tình nguyện viên) |
| Mục đích (mô tả) | Cho phép TNV khai báo SĐT liên hệ, kỹ năng hỗ trợ (vá xe, kích bình, tiếp xăng, kéo xe...), dụng cụ mang theo, khu vực và bán kính sẵn sàng hỗ trợ, kèm giấy tờ xác minh. Hồ sơ phải được Admin duyệt (UC-14) trước khi TNV được nhận SOS. |
| Mức độ ưu tiên | Cao |
| Điều kiện kích hoạt | Ngay sau khi đăng ký tài khoản vai trò Volunteer (UC-01), hoặc TNV chọn mục "Hồ sơ tình nguyện" trên trang cá nhân. |
| Điều kiện tiên quyết | Đã đăng nhập với `role = 'volunteer'`, tài khoản `status = 'active'`; ứng dụng đã được cấp quyền vị trí (UC-02). |
| Điều kiện thành công | Hồ sơ được lưu vào `volunteer_profiles` với `status = 'pending'`, `is_available = false` (hồ sơ mới) hoặc được cập nhật thành công; ảnh xác minh lưu trên Supabase Storage. |
| Điều kiện thất bại | Không lưu được do thiếu trường bắt buộc, sai định dạng, tải ảnh xác minh thất bại hoặc mất kết nối. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã tài khoản (`user_id`) | UUID | Có | Lấy từ phiên đăng nhập; mỗi tài khoản chỉ có 1 hồ sơ (UNIQUE) | Hệ thống (Supabase Auth) |
| 2 | Họ tên | VARCHAR(100) | Có | Tự điền từ `users.full_name`, cho phép xem lại | CSDL `users` |
| 3 | SĐT liên hệ (`phone`) | VARCHAR(20) | Có | Số điện thoại Việt Nam 10 chữ số, bắt đầu bằng 0; mặc định lấy `users.phone` | Người dùng nhập / CSDL |
| 4 | Danh sách kỹ năng (`skills`) | TEXT[] | Có | Chọn ≥ 1 trong: vá xe, kích bình, tiếp xăng, kéo xe, sửa điện, khác | Người dùng chọn (checkbox) |
| 5 | Dụng cụ mang theo (`tools`) | TEXT | Không | Tối đa 300 ký tự | Người dùng nhập |
| 6 | Ảnh CCCD / giấy tờ xác minh | Tệp ảnh | Có (hồ sơ mới) | JPG/PNG, dung lượng ≤ 5 MB | Người dùng chụp / chọn từ thư viện |
| 7 | Vị trí hoạt động chính (`location`) | (lat, lng) DOUBLE | Có | Mặc định vị trí GPS hiện tại, có thể chọn lại trên bản đồ | Hệ thống (UC-02) / Người dùng chọn |
| 8 | Bán kính hỗ trợ (`service_radius_km`) | SMALLINT | Có | Số nguyên 1–20 km (gợi ý nhanh 3 / 5 / 10 km), mặc định 5 | Người dùng chọn |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Bản ghi hồ sơ (`id`, `user_id`, `phone`, `skills`, `tools`, `id_card_url`, `service_radius_km`, `location`) | Row bảng `volunteer_profiles` | CSDL | Tạo mới hoặc cập nhật |
| 2 | Trạng thái hồ sơ (`status`) và `is_available` | VARCHAR, BOOLEAN | CSDL | Hồ sơ mới: `status = 'pending'`, `is_available = false` |
| 3 | URL ảnh xác minh (`id_card_url`) | TEXT | Storage + CSDL | Ảnh lưu ở bucket riêng tư `volunteer-docs`, chỉ chủ hồ sơ và Admin xem được |
| 4 | Thông báo "Hồ sơ đã được gửi, vui lòng chờ Quản trị viên phê duyệt" | Chuỗi | UI | Hiển thị cho TNV |
| 5 | Nhãn trạng thái hồ sơ trên trang cá nhân | Giao diện | UI | Chờ duyệt / Đã duyệt / Bị từ chối (kèm lý do) |

**Luồng sự kiện chính**

1. TNV chọn mục "Hồ sơ tình nguyện" (hoặc được chuyển tới tự động sau khi đăng ký).
2. Hệ thống hiển thị form hồ sơ: trống nếu chưa có hồ sơ, hoặc hiển thị dữ liệu cũ để chỉnh sửa.
3. TNV nhập SĐT, chọn kỹ năng, nhập dụng cụ, chọn bán kính hỗ trợ và tải ảnh giấy tờ xác minh.
4. TNV xác nhận khu vực hoạt động chính (mặc định vị trí GPS hiện tại, có thể chọn lại trên bản đồ).
5. TNV nhấn "Gửi hồ sơ".
6. Hệ thống kiểm tra dữ liệu: SĐT đúng định dạng, có ít nhất 1 kỹ năng, bán kính trong 1–20 km, đã có ảnh xác minh hợp lệ.
7. Hệ thống tải ảnh xác minh lên Supabase Storage và lưu hồ sơ vào `volunteer_profiles` với `status = 'pending'`, `is_available = false`.
8. Hệ thống thông báo đã gửi hồ sơ và hiển thị trạng thái "Chờ duyệt" trên trang cá nhân.

**Luồng sự kiện thay thế**

- **A1 – Cập nhật hồ sơ đã duyệt:** Nếu TNV chỉ sửa kỹ năng, dụng cụ, vị trí hoặc bán kính, hệ thống cập nhật trực tiếp và giữ `status = 'approved'`. Nếu thay đổi SĐT hoặc giấy tờ xác minh, hồ sơ chuyển về `'pending'`, `is_available = false` để Admin duyệt lại.
- **A2 – Gửi lại hồ sơ bị từ chối:** Tại bước 2, nếu hồ sơ đang `rejected`, hệ thống hiển thị lý do từ chối (UC-14); sau khi TNV sửa và gửi lại, `status` chuyển về `'pending'`.

**Luồng sự kiện ngoại lệ**

- **E1 – Thiếu thông tin bắt buộc:** Tại bước 6, hệ thống tô đỏ các trường thiếu và báo *"Vui lòng nhập đầy đủ các thông tin bắt buộc"*.
- **E2 – Sai định dạng:** Tại bước 6, hệ thống báo *"Số điện thoại không hợp lệ"* hoặc *"Bán kính hỗ trợ phải từ 1 đến 20 km"*.
- **E3 – Ảnh không hợp lệ hoặc tải ảnh thất bại:** Tại bước 6–7, hệ thống báo *"Không thể tải ảnh xác minh, vui lòng chọn ảnh JPG/PNG dưới 5 MB và thử lại"* và hủy tiến trình lưu.
- **E4 – Mất kết nối mạng:** Tại bước 7, hệ thống báo lỗi kết nối, giữ nguyên dữ liệu trên form để gửi lại.

---

## 4.14 Bảng đặc tả UC-14: Quản lý tài khoản, Tiệm & Tình nguyện viên

| Mục | Nội dung |
| --- | --- |
| Tên use case | Quản lý tài khoản, Tiệm & Tình nguyện viên (UC-14) |
| Tác nhân chính | Admin (Quản trị viên hệ thống) |
| Mục đích (mô tả) | Cung cấp công cụ để Admin phê duyệt/từ chối hồ sơ tiệm và hồ sơ TNV mới đăng ký, đồng thời khóa hoặc mở khóa tài khoản/tiệm khi phát hiện vi phạm. |
| Mức độ ưu tiên | Cao |
| Điều kiện kích hoạt | Admin chọn mục "Quản lý tài khoản, Tiệm & TNV" trên Admin Dashboard. |
| Điều kiện tiên quyết | Admin đã đăng nhập với tài khoản `role = 'admin'`. |
| Điều kiện thành công | Trạng thái hồ sơ tiệm/TNV chuyển thành `approved` hoặc `rejected`; tài khoản vi phạm chuyển `banned` (hoặc `active` khi mở khóa); người liên quan nhận được thông báo. |
| Điều kiện thất bại | Không thực hiện được thao tác do không đủ quyền, hồ sơ đã được Admin khác xử lý hoặc lỗi mạng; trạng thái cũ giữ nguyên. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã Admin (`admin_id`) | UUID | Có | `role = 'admin'` (kiểm tra bằng RLS) | Hệ thống (phiên đăng nhập) |
| 2 | Bộ lọc danh sách | Enum + Chuỗi | Không | Loại: Tiệm / TNV / Tài khoản; Trạng thái: pending / approved / rejected / banned; từ khóa tên, email, SĐT | Người dùng chọn/nhập |
| 3 | Đối tượng xử lý: `shop_id` / `volunteer_profiles.id` / `user_id` | UUID | Có | Tồn tại trong bảng tương ứng | Người dùng chọn từ danh sách |
| 4 | Hành động | Enum | Có | `approve` / `reject` / `ban` / `unban` | Người dùng nhấn nút |
| 5 | Lý do | TEXT | Có khi `reject` hoặc `ban` | 5–300 ký tự | Người dùng nhập |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Danh sách hồ sơ chờ duyệt và danh sách tài khoản | Danh sách bản ghi `shops`, `volunteer_profiles`, `users` | UI | Hiển thị theo bộ lọc, kèm số lượng chờ duyệt |
| 2 | Chi tiết hồ sơ (tên, ảnh mặt tiền/giấy tờ xác minh, SĐT, địa chỉ/vị trí, kỹ năng, ngày đăng ký) | Giao diện | UI | Phục vụ Admin kiểm tra |
| 3 | `shops.status` hoặc `volunteer_profiles.status` mới | VARCHAR(20) | CSDL | `'approved'` hoặc `'rejected'` |
| 4 | `users.status` mới (kèm `status` của tiệm/hồ sơ TNV liên quan) | VARCHAR(20) | CSDL | `'banned'` khi khóa; `'active'` (và khôi phục `'approved'`) khi mở khóa |
| 5 | `shops.is_open = false` / `volunteer_profiles.is_available = false` | BOOLEAN | CSDL | Khi khóa, tiệm bị ẩn khỏi bản đồ và ngừng nhận SOS |
| 6 | Thông báo kết quả kèm lý do | FCM | App chủ tiệm / TNV / người bị khóa | VD: "Tiệm của bạn đã được phê duyệt", "Hồ sơ bị từ chối: Giấy tờ không rõ ràng" |
| 7 | Thông báo thao tác thành công | Chuỗi (SnackBar) | UI Admin | Danh sách được làm mới |

**Luồng sự kiện chính** (Phê duyệt hồ sơ)

1. Admin chọn mục "Quản lý tài khoản, Tiệm & TNV".
2. Hệ thống tải danh sách tiệm chờ duyệt, hồ sơ TNV chờ duyệt và danh sách tài khoản.
3. Admin chọn một hồ sơ chờ duyệt để xem chi tiết.
4. Admin kiểm tra thông tin và nhấn "Phê duyệt".
5. Hệ thống cập nhật `status = 'approved'` trong `shops` hoặc `volunteer_profiles` (chỉ khi hồ sơ đang `pending`).
6. Hệ thống gửi thông báo tới chủ tiệm/TNV liên quan.
7. Tiệm được hiển thị công khai trên bản đồ; TNV được phép bật trạng thái sẵn sàng (UC-11) và nhận SOS.

**Luồng sự kiện thay thế**

- **A1 – Từ chối hồ sơ:** Tại bước 4, Admin chọn "Từ chối" và nhập lý do (VD: "Địa chỉ không chính xác", "Giấy tờ không rõ ràng"). Hệ thống cập nhật `status = 'rejected'` và gửi lý do tới tài khoản liên quan.
- **A2 – Khóa tài khoản vi phạm:** Admin chọn tài khoản/tiệm bị phản ánh, nhấn "Khóa tài khoản", nhập lý do và xác nhận. Hệ thống cập nhật `users.status = 'banned'`, chuyển tiệm/hồ sơ TNV liên quan sang `'banned'`, đặt `is_open`/`is_available = false`, ẩn tiệm khỏi bản đồ và ngừng gửi SOS.
- **A3 – Mở khóa tài khoản:** Admin chọn tài khoản `banned`, nhấn "Mở khóa" và xác nhận. Hệ thống khôi phục `users.status = 'active'` và trạng thái `'approved'` của tiệm/hồ sơ TNV liên quan.

**Luồng sự kiện ngoại lệ**

- **E1 – Không đủ quyền:** Nếu tài khoản thực hiện không có `role = 'admin'`, chính sách RLS từ chối và hệ thống báo *"Bạn không có quyền thực hiện thao tác này"*.
- **E2 – Thiếu lý do:** Tại A1/A2, nếu chưa nhập lý do, hệ thống báo *"Vui lòng nhập lý do"* và không thực hiện thao tác.
- **E3 – Hồ sơ đã được xử lý:** Tại bước 5, nếu hồ sơ không còn `pending` (Admin khác đã xử lý), hệ thống báo *"Hồ sơ này đã được xử lý"* và làm mới danh sách.
- **E4 – Khóa tài khoản đang xử lý SOS:** Tại A2, nếu người bị khóa đang có ca SOS `accepted`, hệ thống cảnh báo và chuyển ca đó về `pending` để người khác tiếp nhận trước khi khóa.
- **E5 – Mất kết nối mạng:** Hệ thống báo lỗi và giữ nguyên trạng thái cũ của hồ sơ/tài khoản.

---

## 4.15 Bảng đặc tả UC-15: Thống kê hệ thống

| Mục | Nội dung |
| --- | --- |
| Tên use case | Thống kê hệ thống (UC-15) |
| Tác nhân chính | Admin (Quản trị viên hệ thống) |
| Mục đích (mô tả) | Cung cấp báo cáo số liệu tổng quan và biểu đồ trực quan về hoạt động của ứng dụng: số người dùng theo vai trò, số tiệm sửa xe/cây xăng, số TNV, số lượt SOS và tỷ lệ hoàn thành, thời gian phản hồi trung bình. |
| Mức độ ưu tiên | Trung bình |
| Điều kiện kích hoạt | Admin chọn chức năng "Báo cáo thống kê" trên menu quản trị. |
| Điều kiện tiên quyết | Admin đã đăng nhập với `role = 'admin'`. |
| Điều kiện thành công | Chỉ số KPI và biểu đồ được tính toán, hiển thị đúng theo khoảng thời gian đã chọn; tệp báo cáo được xuất thành công (nếu Admin yêu cầu). |
| Điều kiện thất bại | Không tải được dữ liệu do lỗi truy vấn, khoảng thời gian không hợp lệ hoặc mất kết nối. |

**Đầu vào (Input)**

| STT | Dữ liệu | Kiểu dữ liệu | Bắt buộc | Ràng buộc / Định dạng | Nguồn |
| --- | --- | --- | --- | --- | --- |
| 1 | Mã Admin (`admin_id`) | UUID | Có | `role = 'admin'` | Hệ thống (phiên đăng nhập) |
| 2 | Khoảng thời gian | Enum hoặc (from_date, to_date) DATE | Có | 7 ngày / 30 ngày (mặc định) / Tháng hiện tại / Tùy chọn; `from_date ≤ to_date ≤ hôm nay`, tối đa 365 ngày | Người dùng chọn |
| 3 | Tiêu chí thống kê | Enum | Không | Người dùng / Tiệm & Cây xăng / TNV / Lượt SOS (mặc định: tất cả) | Người dùng chọn |
| 4 | Đơn vị nhóm theo thời gian | Enum | Không | Ngày / Tuần / Tháng (tự chọn theo độ dài khoảng thời gian) | Người dùng chọn / Hệ thống |
| 5 | Lệnh xuất dữ liệu | Thao tác nhấn nút | Không | Định dạng CSV | Người dùng nhấn "Xuất dữ liệu" |
| 6 | Dữ liệu nguồn từ `users`, `shops`, `volunteer_profiles`, `sos_requests`, `reviews` | Bản ghi | Có | Lọc theo `created_at` trong khoảng thời gian | CSDL |

**Đầu ra (Output)**

| STT | Dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- | --- |
| 1 | Thẻ KPI người dùng | Số nguyên | UI | Tổng người dùng, người dùng mới trong kỳ, phân theo vai trò (Rider/Owner/Volunteer), số tài khoản bị khóa |
| 2 | Thẻ KPI địa điểm | Số nguyên | UI | Số tiệm sửa xe, số cây xăng đã duyệt, số hồ sơ chờ duyệt, số tiệm đang mở cửa |
| 3 | Thẻ KPI tình nguyện viên | Số nguyên | UI | Số TNV đã duyệt, số TNV đang sẵn sàng, số hồ sơ chờ duyệt |
| 4 | Thẻ KPI cứu hộ SOS | Số nguyên, % , phút | UI | Tổng lượt SOS, số ca `completed` / `cancelled` / `pending`, tỷ lệ hoàn thành (%), thời gian từ lúc tạo đến lúc tiếp nhận trung bình (phút) |
| 5 | Biểu đồ đường lượt SOS theo thời gian | Chuỗi thời gian | UI | Phân tách ca do Tiệm và ca do TNV tiếp nhận |
| 6 | Biểu đồ cột người dùng/tiệm/TNV mới theo thời gian | Chuỗi thời gian | UI | Theo đơn vị nhóm đã chọn |
| 7 | Bảng xếp hạng top 5 tiệm và top 5 TNV | Danh sách | UI | Theo số ca SOS hoàn thành và điểm `rating` |
| 8 | Tệp báo cáo `thong-ke_<from>_<to>.csv` | Tệp CSV (UTF-8) | Thiết bị Admin | Chứa toàn bộ chỉ số và dữ liệu chuỗi thời gian của kỳ đã chọn |

**Luồng sự kiện chính**

1. Admin chọn "Báo cáo thống kê" trên menu quản trị.
2. Hệ thống mặc định truy vấn dữ liệu 30 ngày gần nhất.
3. Admin thay đổi bộ lọc thời gian và/hoặc tiêu chí thống kê (VD: "Tháng hiện tại").
4. Hệ thống gọi các hàm RPC tổng hợp (COUNT, AVG, GROUP BY theo thời gian) trên các bảng `users`, `shops`, `volunteer_profiles`, `sos_requests`, `reviews`.
5. Hệ thống tính các chỉ số KPI, xử lý dữ liệu chuỗi thời gian và vẽ biểu đồ.
6. Admin xem báo cáo.

**Luồng sự kiện thay thế**

- **A1 – Xuất dữ liệu:** Tại bước 6, Admin nhấn "Xuất dữ liệu"; hệ thống sinh tệp CSV cho kỳ đang xem, lưu vào thiết bị và báo *"Đã xuất báo cáo thành công"*.
- **A2 – Xem chi tiết một chỉ số:** Admin nhấn vào một thẻ KPI (VD: "Hồ sơ chờ duyệt"); hệ thống chuyển tới danh sách tương ứng trong UC-14.

**Luồng sự kiện ngoại lệ**

- **E1 – Không có dữ liệu:** Tại bước 5, nếu kỳ đã chọn không phát sinh dữ liệu, hệ thống báo *"Không có dữ liệu trong khoảng thời gian đã chọn"* và đưa các thẻ KPI về 0.
- **E2 – Khoảng thời gian không hợp lệ:** Tại bước 3, nếu ngày bắt đầu sau ngày kết thúc hoặc vượt quá 365 ngày, hệ thống báo *"Khoảng thời gian không hợp lệ"* và không truy vấn.
- **E3 – Không đủ quyền:** Nếu tài khoản không có `role = 'admin'`, RLS từ chối truy vấn và hệ thống báo *"Bạn không có quyền xem báo cáo"*.
- **E4 – Lỗi truy vấn / mất kết nối / xuất tệp thất bại:** Hệ thống báo *"Không thể tải dữ liệu báo cáo, vui lòng thử lại"* (hoặc *"Không thể xuất tệp báo cáo"*) kèm nút "Thử lại".
