# Đặc Tả Use Case UC-01 Đến UC-07

- **Nhóm:** Nhóm 18 – 65KTPM
- **Đề tài:** Ứng dụng Kết nối Cứu hộ & Tình nguyện Xe máy
- **Người thực hiện:** Trần Văn Hồng Quân (2351170613)
- **Phạm vi:** Phân hệ Khách hàng (Rider) & Hạ tầng người dùng: UC-01 → UC-07

---

## 4.1 Bảng đặc tả UC-01: Đăng nhập / Đăng ký

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Đăng nhập / Đăng ký (UC-01) |
| **Tác nhân chính** | Rider, Shop Owner, Volunteer, Admin |
| **Mục đích (mô tả)** | Cho phép người dùng tạo tài khoản mới hoặc đăng nhập vào hệ thống bằng Email/Mật khẩu qua Supabase Auth để xác thực danh tính và phân quyền truy cập chức năng tương ứng. |
| **Mức độ ưu tiên** | Rất cao |
| **Điều kiện kích hoạt** | Người dùng mở ứng dụng lần đầu hoặc nhấn chọn "Đăng nhập" / "Đăng ký" trên màn hình chào mừng. |
| **Điều kiện tiên quyết** | Ứng dụng đã được cài đặt trên thiết bị di động và có kết nối Internet. |
| **Điều kiện thành công** | Xác thực thành công, phiên đăng nhập được lưu lại; người dùng được chuyển hướng tới màn hình chính tương ứng với vai trò (Rider, Shop Owner, Volunteer, Admin). |
| **Điều kiện thất bại** | Đăng nhập/Đăng ký không thành công do sai thông tin xác thực, tài khoản đã tồn tại hoặc lỗi mạng. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `email` | String | Có | Người dùng nhập | Địa chỉ email đăng nhập hợp lệ |
| `password` | String | Có | Người dùng nhập | Mật khẩu tối thiểu 6 ký tự |
| `full_name` | String | Có (khi ĐK) | Người dùng nhập | Họ và tên người dùng |
| `phone` | String | Có (khi ĐK) | Người dùng nhập | Số điện thoại liên hệ (10 chữ số) |
| `role` | String | Có (khi ĐK) | Người dùng chọn | Vai trò: `rider`, `owner`, `volunteer` |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `session` | UserSession | Thiết bị (Client) | Phiên xác thực Supabase Auth |
| `user_record` | Row in `users` | CSDL (PostgreSQL) | Bản ghi người dùng với vai trò tương ứng |
| `target_screen` | Screen | UI | Chuyển tới RiderShell / OwnerShell / VolunteerShell / AdminShell |

**Luồng sự kiện chính:**
1. Người dùng mở ứng dụng và chọn "Đăng nhập".
2. Hệ thống hiển thị biểu mẫu nhập Email và Mật khẩu.
3. Người dùng nhập đầy đủ thông tin Email, Mật khẩu và bấm nút "Đăng nhập".
4. Hệ thống gửi thông tin xác thực đến Supabase Auth.
5. Supabase Auth xác thực thông tin thành công và trả về User ID.
6. Hệ thống truy vấn thông tin vai trò (role) người dùng trong bảng `users` trên PostgreSQL.
7. Hệ thống lưu lại phiên đăng nhập thành công và chuyển hướng người dùng đến giao diện tương ứng với vai trò (Rider/Owner/Volunteer/Admin).

**Luồng sự kiện thay thế:**
- Luồng Đăng ký tài khoản mới: Tại bước 1, nếu chọn "Đăng ký", hệ thống hiển thị Form đăng ký (Họ tên, SĐT, Email, Mật khẩu, Chọn vai trò Rider/Owner/Volunteer). Người dùng điền thông tin và bấm "Đăng ký". Hệ thống tạo User trên Supabase Auth và tạo bản ghi trong bảng `users` với vai trò tương ứng. Rider được chuyển tới màn hình chính; Owner được chuyển tới form đăng ký tiệm (UC-09); Volunteer được chuyển tới form hồ sơ Tình nguyện viên (UC-13).

**Luồng sự kiện ngoại lệ:**
- Định dạng Email không hợp lệ hoặc Mật khẩu quá ngắn (< 6 ký tự): Hệ thống hiển thị thông báo lỗi ngay trên Form.
- Sai Email hoặc Mật khẩu: Supabase Auth trả về lỗi xác thực, hệ thống thông báo: "Email hoặc mật khẩu không chính xác".
- Email đã được sử dụng (khi Đăng ký): Hệ thống thông báo: "Email này đã được đăng ký tài khoản khác".
- Tài khoản bị khóa: Tại bước 6, nếu trường `status = "banned"`, hệ thống từ chối truy cập và chuyển hướng tới màn hình khóa tài khoản (`BannedScreen`).

---

## 4.2 Bảng đặc tả UC-02: Định vị vị trí hiện tại

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Định vị vị trí hiện tại (UC-02) |
| **Tác nhân chính** | Rider, Shop Owner, Volunteer, Google Maps API |
| **Mục đích (mô tả)** | Tự động truy vấn tọa độ GPS hiện tại của thiết bị qua gói geolocator và hiển thị Marker vị trí người dùng trên bản đồ Google Maps làm mốc cho các thao tác tìm kiếm và phát tín hiệu cứu hộ. |
| **Mức độ ưu tiên** | Rất cao |
| **Điều kiện kích hoạt** | Người dùng mở màn hình Bản đồ chính hoặc nhấn nút "Vị trí của tôi" (My Location) trên giao diện ứng dụng. |
| **Điều kiện tiên quyết** | Thiết bị di động đã bật dịch vụ vị trí (GPS/Location Services) và ứng dụng đã được cấp quyền truy cập vị trí. |
| **Điều kiện thành công** | Lấy thành công tọa độ Lat/Lng thực tế, tâm bản đồ tự động di chuyển đến vị trí người dùng kèm Marker chấm xanh hiển thị tương ứng. |
| **Điều kiện thất bại** | Không thể lấy tọa độ do GPS bị tắt, ứng dụng bị từ chối quyền hoặc lỗi phần cứng thiết bị. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `gps_signal` | Hardware GPS | Có | Thiết bị | Tín hiệu vệ tinh / mạng tế bào |
| `tap_location_btn` | Event | Không | UI | Thao tác bấm nút "Vị trí của tôi" |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `latitude, longitude` | Double | Client State | Tọa độ địa lý người dùng |
| `address_text` | String | Top Bar UI | Tên đường, phường, quận đọc từ Reverse Geocoding |
| `user_marker` | Marker | Google Map UI | Marker chấm xanh tại vị trí người dùng |

**Luồng sự kiện chính:**
1. Người dùng mở màn hình Bản đồ chính hoặc bấm biểu tượng "Vị trí của tôi".
2. Hệ thống kiểm tra quyền truy cập vị trí của ứng dụng.
3. Hệ thống gọi phương thức `Geolocator.getCurrentPosition()` để lấy tọa độ thực tế.
4. Tọa độ (latitude, longitude) được trả về cho ứng dụng.
5. Hệ thống cập nhật vị trí tâm bản đồ Google Maps và hiển thị Marker tùy chỉnh tại vị trí người dùng.
6. Hệ thống thực hiện Reverse Geocoding để chuyển tọa độ thành tên đường/phường/xã hiển thị lên thanh địa chỉ top bar.

**Luồng sự kiện thay thế:**
- Định vị theo vị trí cố định gần nhất: Trường hợp tín hiệu GPS yếu, hệ thống tự động sử dụng tọa độ vị trí được lưu ở lần truy cập gần nhất (`Geolocator.getLastKnownPosition()`) để hiển thị tạm thời kèm cảnh báo độ chính xác thấp.

**Luồng sự kiện ngoại lệ:**
- Chưa bật GPS thiết bị: Tại bước 2, nếu GPS bị tắt, hệ thống hiển thị hộp thoại yêu cầu: "Vui lòng bật định vị GPS để sử dụng tính năng này" kèm nút dẫn tới Cài đặt thiết bị.
- Chưa cấp quyền truy cập vị trí: Hệ thống hiển thị hộp thoại xin cấp quyền (Allow Location Access). Nếu người dùng chọn "Từ chối", hệ thống đặt tâm bản đồ mặc định tại trung tâm Hà Nội (`21.0285, 105.8542`) và vô hiệu hóa các tính năng tìm kiếm gần đây.

---

## 4.3 Bảng đặc tả UC-03: Tìm kiếm Tiệm sửa xe & Cây xăng

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Tìm kiếm Tiệm sửa xe & Cây xăng (UC-03) |
| **Tác nhân chính** | Rider (Khách hàng) |
| **Mục đích (mô tả)** | Cho phép người dùng tìm kiếm, tra cứu và lọc các tiệm sửa xe hoặc cây xăng trong phạm vi bán kính chọn trước xung quanh vị trí GPS hiện tại, hiển thị dạng danh sách hoặc Marker biểu tượng trên bản đồ. |
| **Mức độ ưu tiên** | Rất cao |
| **Điều kiện kích hoạt** | Người dùng nhập từ khóa vào ô tìm kiếm, chọn Filter danh mục (Tiệm sửa xe / Cây xăng) hoặc thay đổi bán kính quét (1km, 3km, 5km, 10km). |
| **Điều kiện tiên quyết** | Hệ thống đã xác định được vị trí GPS hiện tại của người dùng (UC-02 thành công). |
| **Điều kiện thành công** | Danh sách các địa điểm phù hợp tiêu chí được tải về thành công và các Marker biểu tượng tương ứng hiển thị trực quan trên bản đồ. |
| **Điều kiện thất bại** | Không truy vấn được dữ liệu địa điểm do lỗi kết nối mạng hoặc không có địa điểm thỏa mãn bán kính tìm kiếm. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `p_lat, p_lng` | Double | Có | Hệ thống (UC-02) | Tọa độ GPS tâm tìm kiếm |
| `p_radius_m` | Integer | Có | UI | Bán kính quét: 1000, 3000, 5000, 10000 m |
| `p_category` | String | Không | UI | Lọc loại hình: `'repair_shop'` hoặc `'gas_station'` |
| `p_open_only` | Boolean | Không | UI | Chỉ lấy tiệm đang mở cửa (`is_open = true`) |
| `search_query` | String | Không | UI | Từ khóa tìm kiếm theo tên hoặc tên đường |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `shops_list` | List<Shop> | UI Carousel | Danh sách các tiệm kèm khoảng cách `distance_m` |
| `shop_markers` | Set<Marker> | Google Map UI | Marker cam (tiệm sửa xe) hoặc xanh lam (cây xăng) |

**Luồng sự kiện chính:**
1. Người dùng chọn danh mục "Tiệm sửa xe" hoặc "Cây xăng" trên thanh công cụ nhanh.
2. Hệ thống lấy tọa độ hiện tại làm tâm và thiết lập bán kính mặc định (3km).
3. Hệ thống gửi truy vấn RPC không gian địa lý PostGIS (`get_nearby_shops`) lọc các bản ghi trong bảng `shops` thỏa mãn khoảng cách và điều kiện `status = 'approved'`.
4. Hệ thống tính toán khoảng cách thực tế từ vị trí người dùng đến từng điểm.
5. Hệ thống render các Marker tùy chỉnh (biểu tượng Tiệm sửa xe/Cây xăng) lên bản đồ Google Maps và cập nhật danh sách hiển thị vuốt ở phía dưới màn hình.
6. Người dùng có thể chọn một địa điểm trong danh sách hoặc bấm trực tiếp vào Marker để xem thông tin tóm tắt.

**Luồng sự kiện thay thế:**
- Tìm kiếm theo từ khóa: Người dùng nhập chuỗi văn bản (ví dụ: "Sửa xe Honda") vào thanh SearchBar. Hệ thống thực hiện query lọc theo tên tiệm và hiển thị kết quả tìm kiếm tương ứng.
- Lọc tiệm đang mở cửa: Người dùng bật công tắc "Chỉ hiển thị tiệm đang mở". Hệ thống lọc kết quả thỏa mãn điều kiện `is_open = true`.

**Luồng sự kiện ngoại lệ:**
- Không tìm thấy địa điểm nào: Tại bước 4, nếu không có địa điểm nào thỏa mãn bán kính chọn, hệ thống hiển thị thông báo: "Không tìm thấy tiệm sửa xe/cây xăng nào quanh bạn" và gợi ý mở rộng bán kính lên 5km/10km.
- Mất kết nối mạng: Hệ thống hiển thị thông báo lỗi mạng và cung cấp nút "Thử lại".

---

## 4.4 Bảng đặc tả UC-04: Xem chi tiết địa điểm

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Xem chi tiết địa điểm (UC-04) |
| **Tác nhân chính** | Rider (Khách hàng) |
| **Mục đích (mô tả)** | Hiển thị đầy đủ thông tin hồ sơ của tiệm sửa xe hoặc cây xăng được chọn, bao gồm: tên tiệm, chủ tiệm, số điện thoại, địa chỉ, giờ đóng/mở cửa, hình ảnh mặt tiền, Badge trạng thái hoạt động và danh sách các đánh giá từ người dùng khác. |
| **Mức độ ưu tiên** | Cao |
| **Điều kiện kích hoạt** | Người dùng nhấn vào một Marker trên bản đồ hoặc chọn một thẻ địa điểm trong danh sách tìm kiếm (UC-03). |
| **Điều kiện tiên quyết** | Địa điểm được chọn tồn tại trong cơ sở dữ liệu hệ thống. |
| **Điều kiện thành công** | Trang thông tin Chi tiết Địa điểm được tải và hiển thị đầy đủ thông tin, các phím chức năng hành động (Gọi điện, Chỉ đường, Gửi SOS, Đánh giá) sẵn sàng tương tác. |
| **Điều kiện thất bại** | Không thể tải thông tin chi tiết do địa điểm đã bị xóa hoặc do sự cố kết nối cơ sở dữ liệu. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `shop_id` | UUID | Có | Hệ thống | Mã định danh của tiệm sửa xe / cây xăng |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `shop_detail` | Shop | UI | Thông tin chi tiết metadata, badge mở/đóng, hotline |
| `reviews_list` | List<Review> | UI | Danh sách bình luận và số sao đánh giá |
| `action_buttons` | Widgets | UI | Nút "Gọi ngay", "Chỉ đường", "Cứu hộ SOS", "Đánh giá" |

**Luồng sự kiện chính:**
1. Người dùng bấm chọn một tiệm sửa xe hoặc cây xăng trên bản đồ/danh sách.
2. Hệ thống gửi mã Shop ID truy vấn dữ liệu chi tiết trong bảng `shops` trên PostgreSQL.
3. Hệ thống đồng thời tải danh sách bình luận trong bảng `reviews` liên kết của tiệm đó.
4. Hệ thống hiển thị Màn hình Detail gồm: Ảnh bìa/mặt tiền, Tên cơ sở, Tên chủ tiệm, SĐT hotline, Địa chỉ chi tiết, Giờ hoạt động, Badge trạng thái "Đang mở cửa" hoặc "Đóng cửa".
5. Hệ thống hiển thị các nút hành động nhanh: "Gọi ngay", "Chỉ đường", "Gửi cứu hộ SOS" và "Đánh giá".

**Luồng sự kiện thay thế:** Không có.

**Luồng sự kiện ngoại lệ:**
- Lỗi tải dữ liệu hoặc tiệm không tồn tại: Tại bước 2, nếu ID không hợp lệ hoặc dữ liệu bị xóa, hệ thống thông báo: "Địa điểm không còn tồn tại trên hệ thống" và quay lại màn hình trước.
- Không tải được hình ảnh: Hệ thống hiển thị ảnh placeholder mặc định thay thế cho ảnh bị lỗi.

---

## 4.5 Bảng đặc tả UC-05: Gọi điện nhanh Hotline

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Gọi điện nhanh Hotline (UC-05) |
| **Tác nhân chính** | Rider (Khách hàng) |
| **Mục đích (mô tả)** | Kích hoạt trực tiếp trình gọi điện mặc định của hệ điều hành điện thoại (truyền tham số `tel:SĐT` qua gói `url_launcher`) giúp khách hàng nhanh chóng trao đổi trực tiếp với chủ tiệm hoặc cây xăng. |
| **Mức độ ưu tiên** | Rất cao |
| **Điều kiện kích hoạt** | Người dùng nhấn vào biểu tượng/nút "Gọi điện" tại màn hình Chi tiết tiệm (UC-04) hoặc danh sách kết quả nhanh. |
| **Điều kiện tiên quyết** | Địa điểm có đăng ký số điện thoại liên hệ hợp lệ; thiết bị di động hỗ trợ tính năng cuộc gọi thoại qua SIM. |
| **Điều kiện thành công** | Ứng dụng mở thành công Trình quay số (Dialer) của điện thoại với số điện thoại chủ tiệm được điền sẵn. |
| **Điều kiện thất bại** | Không thể khởi chạy URL Scheme cuộc gọi do thiết bị không hỗ trợ hoặc số điện thoại bị trống. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `phone_number` | String | Có | Dữ liệu `shop.phone` | Chuỗi số điện thoại hotline của tiệm |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `tel:URI` | Intent / URL Scheme | Hệ điều hành điện thoại | Trình quay số điện thoại mặc định |

**Luồng sự kiện chính:**
1. Người dùng bấm chọn nút "Gọi ngay" hoặc icon cuộc gọi tại trang thông tin tiệm.
2. Hệ thống trích xuất chuỗi số điện thoại từ tài liệu địa điểm và làm sạch ký tự thừa.
3. Hệ thống tạo đường dẫn URL Scheme dạng `tel:<phone_number>`.
4. Hệ thống gọi gói `url_launcher` kiểm tra khả năng thực thi bằng `launchUrl()`.
5. Hệ thống chuyển hướng người dùng sang ứng dụng Trình gọi điện thoại mặc định trên điện thoại với số điện thoại đã điền sẵn để người dùng thực hiện cuộc gọi.

**Luồng sự kiện thay thế:** Không có.

**Luồng sự kiện ngoại lệ:**
- Thiếu số điện thoại: Tại bước 2, nếu trường SĐT của tiệm bị trống, hệ thống hiển thị thông báo: "Tiệm hiện chưa cập nhật số điện thoại liên hệ".
- Thiết bị không hỗ trợ cuộc gọi (Máy tính bảng / Simulator): Tại bước 4, nếu không thể mở URL Scheme `tel:`, hệ thống thông báo lỗi: "Thiết bị không hỗ trợ tính năng cuộc gọi trực tiếp".

---

## 4.6 Bảng đặc tả UC-06: Chỉ đường (Navigation)

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Chỉ đường (Navigation) (UC-06) |
| **Tác nhân chính** | Rider, Shop Owner, Volunteer, Google Maps API |
| **Mục đích (mô tả)** | Tính toán tuyến đường di chuyển tối ưu, vẽ Polyline trực tiếp trên bản đồ ứng dụng hoặc chuyển tiếp sang ứng dụng Google Maps Navigation ngoài để điều hướng đường đi từ vị trí người dùng tới địa điểm tiệm/cây xăng. |
| **Mức độ ưu tiên** | Cao |
| **Điều kiện kích hoạt** | Người dùng chọn nút "Chỉ đường" tại trang Chi tiết tiệm (UC-04) hoặc thẻ tiệm (UC-03). |
| **Điều kiện tiên quyết** | Đã xác định được tọa độ vị trí nguồn (Origin GPS) và tọa độ vị trí đích (Destination GPS). |
| **Điều kiện thành công** | Tuyến đường hiển thị trên bản đồ kèm thông tin khoảng cách (km) và thời gian dự kiến (phút), hoặc ứng dụng Google Maps mở ra với tuyến đường đi được thiết lập sẵn. |
| **Điều kiện thất bại** | Không thể tìm được tuyến đường đi do lỗi API chỉ đường hoặc lỗi kết nối mạng. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `originLat, originLng` | Double | Có | Hệ thống (UC-02) | Tọa độ GPS vị trí người dùng |
| `destLat, destLng` | Double | Có | Dữ liệu `shop` | Tọa độ GPS tiệm đích đến |
| `destinationTitle` | String | Có | Dữ liệu `shop` | Tên tiệm sửa xe / cây xăng đích đến |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `route_polyline` | Polyline | Bản đồ UI | Tuyến đường màu xanh nối từ Origin đến Destination |
| `distance_duration` | String | Card UI | Thông số khoảng cách (km) và thời gian xe máy ước tính |
| `external_map_intent` | URL Scheme | Ứng dụng Google Maps | Mở Google Maps ngoài với đích đến đã điền |

**Luồng sự kiện chính:**
1. Người dùng chọn nút "Chỉ đường" tại trang chi tiết địa điểm hoặc thẻ tiệm.
2. Hệ thống lấy tọa độ GPS hiện tại (Nguồn) và tọa độ địa điểm tiệm/cây xăng (Đích).
3. Hệ thống mở màn hình chỉ đường trực tiếp (`NavigationScreen`), tính toán khoảng cách và thời gian di chuyển bằng xe máy.
4. Hệ thống vẽ đường Polyline màu xanh lam nối từ điểm nguồn đến điểm đích trên bản đồ.
5. Hệ thống hiển thị thanh thông số tổng quan đường đi (Khoảng cách & Thời gian) ở góc dưới màn hình.

**Luồng sự kiện thay thế:**
- Mở ứng dụng Google Maps ngoài: Người dùng nhấn tùy chọn "Mở ứng dụng Google Maps ngoài". Hệ thống khởi tạo URL Scheme `https://www.google.com/maps/dir/?api=1&destination=lat,lng&travelmode=motorcycle` và mở ứng dụng Google Maps mặc định trên điện thoại để người dùng sử dụng điều hướng bằng giọng nói.

**Luồng sự kiện ngoại lệ:**
- Không tìm thấy tuyến đường hợp lệ: Tại bước 3, nếu không thể tìm được lộ trình, hệ thống thông báo: "Không thể tính toán tuyến đường đi đến vị trí này".
- Lỗi kết nối API: Hệ thống thông báo lỗi kết nối và tự động gợi ý chuyển sang ứng dụng Google Maps ngoài.

---

## 4.7 Bảng đặc tả UC-07: Gửi yêu cầu Cứu hộ SOS

| Mục | Nội dung |
| --- | --- |
| **Tên use case** | Gửi yêu cầu Cứu hộ SOS (UC-07) |
| **Tác nhân chính** | Rider (Khách hàng) |
| **Mục đích (mô tả)** | Cho phép người đi xe máy gặp sự cố khẩn cấp (thủng lốp, hết xăng, hỏng động cơ) phát tín hiệu cứu hộ SOS kèm tọa độ GPS thực tế, loại sự cố và ghi chú tới các tiệm sửa xe đang mở cửa và Tình nguyện viên đang sẵn sàng trong bán kính gần nhất. |
| **Mức độ ưu tiên** | Rất cao |
| **Điều kiện kích hoạt** | Người dùng nhấn nút "🚨 CỨU HỘ SOS" nổi bật trên giao diện chính (`RiderShell`) hoặc trang chi tiết tiệm. |
| **Điều kiện tiên quyết** | Khách hàng đã đăng nhập tài khoản và ứng dụng lấy thành công tọa độ GPS hiện tại. |
| **Điều kiện thành công** | Bản ghi SOS được khởi tạo trên bảng `sos_requests` ở trạng thái pending; thông báo Push Notification (FCM) được gửi tới thiết bị các chủ tiệm đang mở cửa và Tình nguyện viên đang sẵn sàng trong vùng phục vụ. |
| **Điều kiện thất bại** | Không thể gửi yêu cầu SOS do lỗi kết nối mạng hoặc không có tiệm sửa xe/Tình nguyện viên nào hoạt động trong khu vực. |

**Đầu vào (Input)**

| Tên trường | Kiểu dữ liệu | Bắt buộc | Nguồn | Mô tả |
| --- | --- | --- | --- | --- |
| `issue_type` | String | Có | Người dùng chọn | `'Hết xăng'`, `'Thủng lốp'`, `'Hỏng động cơ'`, `'Khác'` |
| `note` | String | Không | Người dùng nhập | Ghi chú thêm về sự cố hoặc vị trí cụ thể |
| `contact_phone` | String | Có | `users.phone` | Số điện thoại liên hệ khẩn cấp của khách |
| `latitude, longitude` | Double | Có | GPS thiết bị | Tọa độ GPS nơi xe bị sự cố |

**Đầu ra (Output)**

| Tên dữ liệu | Kiểu dữ liệu | Đích | Mô tả |
| --- | --- | --- | --- |
| `sos_request` | Row in `sos_requests` | CSDL (PostgreSQL) | Bản ghi SOS mới với `status = 'pending'` |
| `fcm_alert` | Push Notification | Thiết bị Thợ/TNV | Thông báo khẩn cấp kèm âm thanh báo động |
| `waiting_screen` | UI | Thiết bị Rider | Màn hình radar quét chờ tiếp nhận |

**Luồng sự kiện chính:**
1. Người dùng bấm nút "🚨 CỨU HỘ SOS".
2. Hệ thống hiển thị Hộp thoại chọn loại sự cố (Hết xăng, Thủng lốp, Hỏng động cơ, Khác) và ô nhập ghi chú ngắn.
3. Người dùng chọn loại sự cố, kiểm tra SĐT liên hệ và bấm "Phát tín hiệu cứu hộ".
4. Hệ thống đóng gói thông tin (Rider ID, SĐT, Tọa độ GPS, Loại sự cố, Thời gian) và lưu vào bảng `sos_requests` với trạng thái `status = 'pending'`.
5. Supabase Edge Functions kích hoạt phát thông báo Push Notification (FCM) kèm âm thanh cảnh báo tới ứng dụng của các Chủ tiệm đang mở cửa (`is_open = true`) và Tình nguyện viên đang sẵn sàng (`is_available = true`) trong bán kính 5km.
6. Giao diện khách hàng chuyển sang chế độ "Đang chờ cứu hộ..." biểu thị radar quét và sẵn sàng cập nhật khi có tiệm hoặc Tình nguyện viên nhận ca (UC-12).

**Luồng sự kiện thay thế:**
- Hủy tín hiệu SOS: Trong khi đơn còn ở trạng thái `pending` (chưa có chủ tiệm/Tình nguyện viên tiếp nhận), khách hàng có thể bấm nút "Hủy yêu cầu SOS". Hệ thống cập nhật trường `status = 'cancelled'` và đóng giao diện chờ cứu hộ.

**Luồng sự kiện ngoại lệ:**
- Không có tiệm nào trong khu vực: Tại bước 5, nếu không có tiệm sửa xe hoặc Tình nguyện viên nào đang hoạt động quanh bán kính quét, hệ thống hiển thị thông báo: "Hiện không có tiệm sửa xe hoặc tình nguyện viên nào hoạt động gần bạn. Vui lòng gọi trực tiếp hotline cứu hộ khẩn cấp." kèm danh sách SĐT hotline tổng đài.
- Quá thời gian chờ (Timeout 5 phút): Nếu sau 5 phút không có tiệm hoặc Tình nguyện viên nào bấm tiếp nhận, hệ thống tự động hủy đơn (`status = 'cancelled'`) và gợi ý người dùng gọi điện trực tiếp.
