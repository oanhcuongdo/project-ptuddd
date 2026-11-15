# HealthyLife — Trợ lý kỷ luật và lối sống lành mạnh

Đề cương cuối kỳ học phần Phát triển ứng dụng di động — Nhóm 06, 65KTPM.
Trạng thái: kế hoạch phát triển và khung Flutter, chưa triển khai chức năng. Phân công và tiến độ dưới đây là đề xuất để nhóm thống nhất.

## 1. GIỚI THIỆU ĐỀ TÀI

Sinh viên và người đi làm thường khó duy trì tập luyện, bữa ăn và giấc ngủ khi lịch học, giờ làm hoặc ca trực thay đổi. Ứng dụng nhắc việc đơn giản có thể ghi nhận hoàn thành nhưng chưa giúp lựa chọn hoạt động phù hợp và sắp xếp chúng vào thời gian thực tế.

HealthyLife hỗ trợ người dùng xây dựng thói quen lành mạnh: khai báo điều kiện cá nhân, nhận gợi ý môn thể thao và bữa ăn, duyệt lịch sinh hoạt, ghi nhật ký và theo dõi tiến độ. Hệ thống hướng tới duy trì kỷ luật có thể thực hiện được, thay vì áp một lịch cố định cho mọi người.

Đề tài nâng cấp trực tiếp bài “Xây dựng ứng dụng kỷ luật cá nhân với Flutter” nhóm đã học: kế thừa CRUD thói quen, đánh dấu hằng ngày, lưu cục bộ và thống kê; bổ sung hồ sơ cá nhân, bộ gợi ý, lịch tránh xung đột, đồng bộ cloud, camera và GPS.

## 2. LÝ DO CHỌN ĐỀ TÀI

Bài toán gần gũi với cả bốn thành viên, có thể demo bằng các hồ sơ sinh viên, nhân viên văn phòng và người làm ca. Điểm khác biệt là kết nối mục tiêu với hoàn cảnh và lịch thực tế, không chỉ đếm số lần bấm hoàn thành.

Ứng dụng tận dụng kiến thức Flutter và các dịch vụ Firebase, Supabase đã học, đồng thời thực hành xin quyền camera/vị trí, xử lý ngoại tuyến, bảo vệ dữ liệu cá nhân và kiểm thử trên điện thoại thật.

Nhóm chọn triển khai gợi ý theo quy tắc có giải thích trước; AI chỉ là phần mở rộng. Không cần dùng nhiều dịch vụ trùng chức năng: Firebase phụ trách danh tính và thông báo đẩy, Supabase phụ trách dữ liệu và ảnh riêng tư, SQLite phụ trách dữ liệu cục bộ.

## 3. MỤC TIÊU ĐỀ TÀI

### 3.1. Mục tiêu tổng quát

Xây dựng ứng dụng Flutter tiếng Việt giúp người trưởng thành quản lý thói quen, vận động, bữa ăn và giờ giấc sinh hoạt thông qua lịch cá nhân hóa, nhắc nhở và phản hồi tiến độ. Android là nền tảng nghiệm thu chính; Web phục vụ hồ sơ, lịch và thống kê; iOS chuẩn bị khung và chưa cam kết kiểm thử khi thiếu macOS/thiết bị.

### 3.2. Mục tiêu cụ thể

- Thu thập đủ thông tin để gợi ý, cho phép xem/sửa/xóa dữ liệu và thay đổi mục tiêu.
- Đề xuất môn thể thao, hoạt động và món ăn từ danh mục đã kiểm duyệt, hiển thị lý do phù hợp và cho phép đổi lựa chọn.
- Tạo lịch tuần có kiểm tra ca làm, khoảng bận, thời gian di chuyển và nghỉ; chỉ áp dụng khi người dùng xác nhận.
- Duy trì thói quen, nhật ký vận động/bữa ăn/giấc ngủ, streak, tỷ lệ hoàn thành và tổng kết tuần.
- Dùng camera ghi ảnh bữa ăn; GPS ghi tuyến đi bộ/chạy trong phiên do người dùng bật; quyền bị từ chối vẫn có luồng nhập tay.
- Hỗ trợ nhật ký ngoại tuyến, đồng bộ không tạo bản ghi trùng và nhắc việc cục bộ.
- Kiểm chứng quyền riêng tư bằng ba tài khoản, kiểm thử thuật toán gợi ý/lịch và demo trên Android thật.

### 3.3. Phạm vi và giới hạn

Phạm vi cốt lõi: tài khoản, hồ sơ, danh mục môn tập/món ăn, gợi ý theo quy tắc, lịch tuần, CRUD thói quen, nhật ký, nhắc lịch, thống kê, ảnh bữa ăn, GPS trong phiên và đồng bộ nhật ký. Không triển khai tất cả tính năng mở rộng trước khi luồng chính ổn định.

Đối tượng demo là người từ 18 tuổi, có thể tự lựa chọn hoạt động sinh hoạt thông thường. Ứng dụng hỗ trợ lối sống, không chẩn đoán hoặc kê thực đơn điều trị. Không tự đặt thâm hụt năng lượng, mục tiêu giảm cân nhanh hoặc tăng cường độ tập theo ảnh/chỉ số đơn lẻ. Người có tình trạng cần tư vấn chuyên môn được dùng lịch thủ công và nhập hướng dẫn đã được chuyên gia xác nhận, không nhận kế hoạch tự động.

Mở rộng sau nghiệm thu cốt lõi: đọc bước chân qua Health Connect, AI đề xuất nhãn món ăn để người dùng xác nhận, xuất lịch hệ thống và thử thách nhóm chia sẻ kết quả tự nguyện. Không làm nhận diện bệnh, đo nhịp tim qua camera, theo dõi GPS liên tục, mạng xã hội công khai hoặc kết nối thiết bị đeo riêng.

## 4. KIẾN TRÚC TỔNG THỂ HỆ THỐNG

### 4.1. Ứng dụng Flutter và phân lớp

Luồng xử lý: màn hình/trạng thái → nghiệp vụ gợi ý/lập lịch → repository → SQLite hoặc dịch vụ cloud. Mỗi feature có data, domain, presentation; không gọi cloud trực tiếp từ widget. Giữ main.dart là khung Flutter; tài liệu này chưa đồng nghĩa đã triển khai logic.

Các module: auth, profile, habits, planner, recommendations, activity, nutrition, sleep, insights và notifications. core dành cho thành phần dùng chung về thời gian, thiết bị và đồng bộ khi triển khai thực tế.

### 4.2. Firebase

Firebase Authentication phụ trách Google/email và phiên đăng nhập. Supabase được cấu hình tin cậy JWT Firebase qua third-party auth; định danh quyền lấy từ token đã xác minh, không tin UID do client tự gửi. FCM dùng cho thông báo sự kiện từ server khi có nhu cầu; nhắc lịch cá nhân ưu tiên local notifications để không lệ thuộc mạng.

### 4.3. Supabase và mô hình dữ liệu

Supabase PostgreSQL lưu dữ liệu nghiệp vụ; Storage bucket riêng tư lưu ảnh bữa ăn; Edge Functions dành cho thao tác đặc quyền như xóa tài khoản và proxy AI nếu triển khai. Không lưu thêm cùng dữ liệu trong Firestore.

- profiles: Firebase UID, tên, nhóm tuổi, múi giờ, nghề nghiệp và điều kiện sinh hoạt; thông tin nhạy cảm chỉ thu khi thực sự cần và được đồng ý.
- availability_blocks: khoảng bận/làm ca, thời gian di chuyển, quy tắc lặp, ngày ngoại lệ; hỗ trợ khoảng qua nửa đêm.
- goals, habits, habit_logs: mục tiêu và lịch lặp; mỗi thói quen chỉ có một kết quả cho mỗi ngày địa phương, không tính trùng khi đồng bộ.
- exercise_catalog, meal_catalog: môn tập/bài tập, thời lượng, thiết bị, mức kinh nghiệm; món ăn, nguyên liệu, dị nguyên, chi phí và thời gian chuẩn bị; lưu nguồn và trạng thái kiểm duyệt.
- plans, plan_items: phiên bản lịch, loại hoạt động, thời điểm bắt đầu/kết thúc, trạng thái nháp/đã duyệt/hoàn thành/bỏ qua và lý do gợi ý.
- activity_sessions, route_points: buổi tập và tọa độ trong phiên, thời lượng/quãng đường ước tính; không lưu tuyến GPS nếu người dùng không chọn lưu.
- meal_logs, sleep_logs: ảnh/tên bữa ăn đã xác nhận; giờ ngủ/thức tự khai báo, cảm nhận; không suy ra chất lượng giấc ngủ từ việc không dùng điện thoại.
- reminder_preferences, device_tokens, consents: giờ yên lặng, cấu hình nhắc, token riêng từng thiết bị và lựa chọn quyền dữ liệu; chủ tài khoản mới được đọc/sửa.

### 4.4. Dữ liệu cục bộ, đồng bộ và bảo mật

SQLite lưu nhật ký, lịch đã tải và hàng đợi thay đổi khi mất mạng. Mỗi thay đổi có UUID, owner_uid và thời điểm/phiên bản; retry phải idempotent. Nhật ký độc lập được thêm một lần; sửa cùng bản ghi từ hai thiết bị phải phát hiện xung đột phiên bản và cho chọn, không âm thầm ghi đè. Không cho hai phiên bản lịch cùng được kích hoạt cho một tuần.

RLS cô lập dữ liệu theo UID; Storage policies bảo vệ ảnh, URL xem ngắn hạn. Không nhúng service-role key hoặc AI API key vào Flutter. Ảnh không tự chia sẻ; loại thông tin EXIF vị trí trước khi upload. Khi đăng xuất phải hủy nhắc việc của tài khoản, xóa cache riêng và xử lý nhật ký chưa đồng bộ bằng lựa chọn rõ ràng; không đẩy hàng đợi tài khoản cũ dưới tài khoản mới.

Người dùng được xuất/xóa nhật ký và yêu cầu xóa tài khoản cùng ảnh, tuyến đường, device token. Không đưa ảnh, tọa độ hoặc thông tin sức khỏe vào log lỗi. Khi xóa ngoại tuyến phải lưu tác vụ chờ, không báo xóa cloud thành công khi chưa xác nhận.

## 5. LUỒNG HOẠT ĐỘNG CHÍNH

### 5.1. Đầu vào cá nhân hóa

- Bắt buộc: xác nhận đủ 18 tuổi, múi giờ, mục tiêu (duy trì thói quen/ngủ đều/vận động thường xuyên), mức vận động hiện tại và số buổi/thời lượng có thể dành mỗi tuần.
- Công việc: sinh viên/văn phòng/di chuyển/lao động thể lực/làm ca; giờ bắt đầu/kết thúc từng ngày, khoảng bận, thời gian đi lại, mức ngồi nhiều và ngày nghỉ. Không chỉ dựa vào tên nghề để đoán lịch.
- Thể thao: môn thích/không thích, kinh nghiệm, tập trong nhà/ngoài trời, thiết bị sẵn có, ngân sách và giới hạn vận động người dùng muốn áp dụng.
- Giấc ngủ: giờ ngủ/thức hiện tại, giờ mong muốn và ngày làm ca. Không áp mốc “22 giờ” cho mọi người; cho đặt khoảng ngủ theo lịch và thay đổi dần do người dùng duyệt.
- Ăn uống: dị ứng và nguyên liệu cần tránh, chế độ ăn/sở thích, số bữa, ngân sách, khả năng nấu và thời gian chuẩn bị. Khi dị ứng chưa xác nhận thì chưa bật gợi ý món ăn.
- Tùy chọn: chiều cao/cân nặng để ghi tiến độ cá nhân, mức mệt tự đánh giá, ảnh bữa ăn và dữ liệu thiết bị. Không bắt buộc thu địa chỉ, ngày sinh đầy đủ hoặc vị trí liên tục.
- Kiểm tra trước gợi ý: dữ liệu thiếu, khung giờ vô lý, mục tiêu không phù hợp điều kiện và tự khai báo cần chuyên gia; chỉ yêu cầu thông tin liên quan, cho nhập lịch thủ công khi không đủ điều kiện.

### 5.2. Gợi ý và tạo lịch

Bước 1: chuẩn hóa ngày/giờ theo múi giờ, mở rộng ca làm qua nửa đêm và tính các khoảng trống sau thời gian đi lại, ngủ và lịch bận.

Bước 2: lọc cứng hoạt động theo giới hạn tự khai báo, thiết bị, thời lượng và điều kiện; lọc món theo toàn bộ dị nguyên/nguyên liệu cần tránh. Món không rõ thành phần không được coi là an toàn; nếu không còn lựa chọn phải trả trạng thái không có gợi ý phù hợp, không nới ràng buộc.

Bước 3: xếp hạng ứng viên đã hợp lệ theo sở thích, thời gian, ngân sách và sự đa dạng. Hiển thị lý do cụ thể: “đi bộ vì bạn thích hoạt động ngoài trời, không cần thiết bị và còn 20 phút rảnh”. Đây là quy tắc sản phẩm, không phải mô hình dự báo hiệu quả sức khỏe.

Bước 4: xếp hoạt động vào khoảng trống, tránh chồng giờ, giữ giờ yên lặng và các mục đã khóa. Đề xuất bữa ăn theo lịch/ngân sách; giờ ăn/ngủ đều có thể chỉnh. Nếu thiếu thời gian, đánh dấu mục chưa xếp được và gợi ý giảm số buổi hoặc đổi hoạt động, không nhồi lịch hoặc tự sửa giờ làm.

Bước 5: người dùng xem lịch nháp, đổi món/môn tập, kéo giờ và xác nhận. Chỉ lịch đã duyệt mới tạo nhắc. Khi đổi ca làm hoặc bỏ lỡ, hệ thống đề xuất bản điều chỉnh và giữ nguyên lịch sử đã hoàn thành; không tự tăng khối lượng tập để bù.

### 5.3. Ghi nhận và phản hồi

Người dùng hoàn thành/bỏ qua với lý do, chụp ảnh bữa ăn hoặc nhập tay, ghi nhật ký ngủ và bật phiên đi bộ/chạy. Tổng kết tuần so sánh kế hoạch với thực tế, đề xuất điều chỉnh nhỏ để người dùng duyệt. Không phạt bằng mất toàn bộ tiến độ khi một ngày nghỉ hoặc thiếu dữ liệu.

Ví dụ demo: người làm văn phòng 08:00–17:00 có 30 phút đi lại và thích đi bộ nhận lịch tập ở khoảng trống đã khai báo; người làm ca 22:00–06:00 nhận lịch ngủ và nghỉ theo ca qua ngày. Các giờ trong demo là dữ liệu kiểm thử, không phải chỉ định sức khỏe.

## 6. CÔNG NGHỆ SỬ DỤNG

### 6.1. Flutter, Dart và SQLite

Flutter cho giao diện tiếng Việt Android/Web; Dart triển khai quy tắc và bộ lập lịch độc lập để kiểm thử. SQLite cho lưu cục bộ trên Android. Web phải chọn adapter lưu cục bộ tương thích khi triển khai; nghiệm thu Web trực tuyến trước, không cam kết SQLite native chạy nguyên trạng trên trình duyệt.

### 6.2. Firebase Authentication và Messaging

Dùng một nguồn danh tính Firebase Authentication; tích hợp JWT với Supabase ở tuần đầu. Local notifications theo múi giờ cho lịch cá nhân; FCM chỉ dùng thông báo server, không xem là bộ hẹn giờ chính xác. Token thiết bị phải cập nhật và hủy liên kết khi đăng xuất.

### 6.3. Supabase Database, Storage và Edge Functions

PostgreSQL/RLS cho dữ liệu quan hệ; Storage cho ảnh; migration và seed danh mục được quản lý cùng mã nguồn. Edge Functions giữ bí mật và thực hiện thao tác server. Realtime chỉ bổ sung khi cần đồng bộ màn hình nhiều thiết bị; không thay thế cơ chế xử lý xung đột.

### 6.4. Camera, GPS và dữ liệu vận động

Camera/thư viện ảnh: chọn ảnh bữa ăn, nén ảnh, giới hạn dung lượng và loại tệp, bỏ EXIF; bản cốt lõi người dùng tự xác nhận tên món, không suy ra calo hay chất gây dị ứng từ ảnh.

GPS: chỉ thu trong phiên đang mở màn hình, có Start/Pause/Stop và chỉ báo đang ghi. Dừng thu khi ứng dụng ra nền trong bản cốt lõi; cho lưu phần đã ghi và nhập bổ sung. Lọc điểm có độ chính xác kém, không cộng khoảng cách qua lúc tạm dừng; quãng đường là ước tính, không chứng minh cường độ tập hay calo.

Health Connect là mở rộng Android: xin quyền đọc bước chân tối thiểu, tổng hợp dữ liệu tránh đếm trùng nhiều nguồn, không mặc định thiết bị nào cũng có dữ liệu. Khi không hỗ trợ hoặc bị từ chối vẫn nhập tay; không thu bước chân bằng GPS cả ngày.

### 6.5. Công cụ, phụ thuộc dự kiến và nguồn tham khảo

Dùng GitHub cho mã nguồn, review và minh chứng; Flutter analyze, unit/widget/integration tests cho kiểm tra. Nhóm dự kiến đánh giá firebase_core/firebase_auth/firebase_messaging, supabase_flutter, thư viện SQLite tương thích nền tảng, local notifications/timezone, image_picker và geolocator khi bắt đầu code; chưa cài thêm dependency ở giai đoạn khung. AI nếu làm phải gọi qua server, có đồng ý riêng, hạn mức chi phí và fallback quy tắc khi lỗi.

- WHO — Physical activity guidelines: https://www.who.int/publications/i/item/9789240015128/
- WHO — Healthy diet: https://www.who.int/news-room/fact-sheets/detail/healthy-diet
- CDC — About Sleep: https://www.cdc.gov/sleep/about/
- Supabase — Firebase Auth integration: https://supabase.com/docs/guides/auth/third-party/firebase-auth
- Android — Health Connect data types: https://developer.android.com/health-and-fitness/health-connect/data-types

Nguồn được tham khảo ngày 15/11/2026. Nhóm phải biên soạn và kiểm duyệt danh mục/quy tắc trước demo, lưu nguồn/phiên bản; không chuyển khuyến nghị chung thành đơn điều trị cá nhân. Các nguồn sức khỏe là nền tảng tham khảo, chưa chứng minh hiệu quả của ứng dụng.

## 7. CÁC CHỨC NĂNG CHÍNH

### 7.1. Tài khoản và hồ sơ

Đăng nhập, đăng xuất, cập nhật nghề/lịch ca, mục tiêu và sở thích; quản lý đồng ý dữ liệu và quyền thiết bị. Có nút xuất/xóa dữ liệu và quy trình xóa tài khoản.

### 7.2. Thói quen và kỷ luật cá nhân

Thêm/sửa/xóa hoặc tạm dừng thói quen, chọn ngày lặp và giờ nhắc, đánh dấu hoàn thành/bỏ qua, xem streak. Chỉ tính ngày đến hạn theo múi giờ; ngày nghỉ không phá streak, lịch sử không thay đổi khi sửa quy tắc cho tương lai.

### 7.3. Bộ gợi ý có giải thích

Gợi ý môn thể thao và món ăn từ danh mục phù hợp hồ sơ; hiển thị lý do, điều kiện và lựa chọn thay thế. Nhận phản hồi thích/không phù hợp để xếp hạng lần sau. Thiếu dữ liệu hoặc không có ứng viên phù hợp phải nói rõ thay vì tạo gợi ý bất kỳ.

### 7.4. Lịch tuần tích hợp

Lịch ngày/tuần kết hợp làm việc, di chuyển, vận động, bữa ăn và ngủ; thêm thủ công, kéo giờ, khóa mục, kiểm tra xung đột. Ca qua đêm, đổi múi giờ, ngày ngoại lệ và đổi lịch nhắc được xử lý rõ. Chỉ bản đã duyệt được kích hoạt.

### 7.5. Nhật ký tập luyện và GPS

Chọn môn tập, ghi thời lượng và cảm nhận, nhập tay hoặc ghi phiên GPS. Xem lịch sử, tuyến đường nếu chọn lưu, khoảng cách ước tính; không công khai vị trí bắt đầu/kết thúc.

### 7.6. Nhật ký bữa ăn và camera

Gợi ý món dựa nguyên liệu, dị ứng, ngân sách và thời gian nấu; chọn thay thế, chụp/chọn ảnh và ghi nhận món thực tế. Không khẳng định món không chứa dị nguyên chỉ bằng ảnh. Chỉ hiển thị dinh dưỡng tham khảo nếu danh mục có nguồn và khẩu phần rõ.

### 7.7. Giấc ngủ và nhịp sinh hoạt

Đặt khoảng ngủ mong muốn, nhắc chuẩn bị ngủ, ghi giờ ngủ/thức và mức tỉnh táo tự đánh giá. Hiển thị tính đều đặn theo tuần và hỗ trợ ca đêm, không khẳng định đã đo thời gian ngủ thực tế bằng cảm biến.

### 7.8. Nhắc nhở và giờ yên lặng

Nhắc theo lịch đã duyệt, tạm hoãn/bỏ qua, cấu hình giờ yên lặng và tần suất. Đổi/xóa lịch phải hủy nhắc cũ; không gửi trùng từ local và FCM. Thông báo màn hình khóa mặc định không lộ chi tiết sức khỏe; nếu quyền bị tắt có hướng dẫn và danh sách việc trong app.

### 7.9. Dashboard và tổng kết tuần

Hiển thị tỷ lệ hoàn thành, streak, thời lượng tập và lịch ngủ tự ghi; phân biệt “chưa ghi nhận” với “không hoàn thành”. Ghi nguồn nhập tay/thiết bị; không gọi điểm kỷ luật là điểm sức khỏe hoặc bảo đảm cải thiện bệnh lý.

### 7.10. Chức năng nâng cao sau cốt lõi

Health Connect đọc bước chân; AI gợi ý nhãn món để xác nhận; xuất lịch có sự đồng ý; thử thách nhóm chỉ chia sẻ số liệu tổng hợp được người dùng chọn. Chỉ chọn triển khai khi còn thời gian và có thiết bị/dịch vụ phù hợp, không đưa vào tiêu chí bắt buộc của bản sáu tuần.

## 8. PHÂN QUYỀN NGƯỜI DÙNG

### 8.1. Người dùng cá nhân

Chỉ đọc/sửa/xóa hồ sơ, lịch, nhật ký, ảnh và vị trí của chính mình. Mặc định không có chia sẻ công khai; tài khoản khác biết ID bản ghi cũng không được truy cập. Danh mục đã kiểm duyệt được đọc chung nhưng người dùng không tự sửa nội dung gốc.

### 8.2. Biên tập danh mục và tác vụ server

Nhóm quản lý danh mục thông qua seed/migration và quy trình review, chưa xây cổng quản trị. Thao tác server kiểm tra token/quyền và xử lý xóa dữ liệu; không cấp quyền đọc hồ sơ cá nhân cho thành viên nhóm chỉ vì họ làm nội dung.

### 8.3. Kiểm thử quyền và đồng ý

Dùng A, B và C: A có dữ liệu, B có dữ liệu độc lập, C thử truy cập ID/ảnh của A. Tất cả truy cập chéo phải bị chặn ở Database/Storage và Edge Functions. Kiểm tra đăng xuất/đổi tài khoản, thu hồi quyền camera/GPS, xóa ảnh và xóa tài khoản không để lộ cache hoặc tiếp tục thu dữ liệu.

## 9. PHÂN CÔNG CÔNG VIỆC

Mỗi thành viên chịu trách nhiệm cả triển khai, kiểm thử và tài liệu module phụ trách; review chéo trước merge. Tỷ lệ đóng góp, email và lớp sinh hoạt chờ nhóm xác nhận, không mặc định chia đều khi chưa có minh chứng.

| Họ và tên | Module phụ trách | Công việc phối hợp | Sản phẩm nghiệm thu |
| --- | --- | --- | --- |
| Nguyễn Thế Trưởng — 2351170626 | Nhóm trưởng; auth, profile, planner | Kiến trúc, tích hợp Firebase–Supabase, review và PR | Hồ sơ, lịch không xung đột/ca đêm, bản tích hợp và test planner |
| Phương Văn Đức — 2351170585 | habits, sleep, notifications | UI/UX responsive, streak và nhắc lịch cục bộ | CRUD thói quen, nhật ký ngủ, nhắc không trùng, test múi giờ/streak |
| Hàn Hoàng Hà — 2051063882 | activity; Database/Storage, sync | GPS, SQLite, RLS, xóa dữ liệu; hỗ trợ schema toàn nhóm | Phiên GPS và fallback, migration/policies, đồng bộ retry và test ba tài khoản |
| Nguyễn Đăng Đại — 2351170578 | nutrition, recommendations, insights | Camera, danh mục món/môn tập, tổng hợp kiểm thử/báo cáo | Nhật ký ảnh, gợi ý lọc dị ứng/thiết bị, dashboard, báo cáo và demo |

### 9.1. Kế hoạch sáu tuần từ khi nhóm chốt đề cương

- Tuần 1: chốt mockup, đầu vào, mô hình dữ liệu và danh mục mẫu; Trưởng thử JWT Firebase–Supabase, Hà thử RLS/Storage/SQLite, Đức thử local notifications, Đại thử camera. Chốt khả năng GPS trên máy thật; chưa triển khai mở rộng.
- Tuần 2: Trưởng hoàn thiện hồ sơ/lịch bận; Đức CRUD thói quen/nhật ký ngủ; Hà schema/đồng bộ nhật ký cơ bản; Đại danh mục và lọc gợi ý. Điều kiện: dữ liệu được lưu đúng tài khoản, thiếu đầu vào có xử lý.
- Tuần 3: Trưởng lịch nháp/ca đêm/xung đột; Đức streak/nhắc; Hà RLS và hàng đợi retry; Đại xếp hạng/lý do và nhật ký ảnh. Điều kiện: bộ ca kiểm thử gợi ý và planner chạy được.
- Tuần 4: Hà GPS Start/Pause/Stop và lưu phiên; Đại dashboard; Đức nhắc theo lịch đã duyệt; Trưởng tích hợp luồng từ hồ sơ tới hoàn thành. Kiểm tra quyền bị từ chối và ngoại tuyến; nếu trễ thì cắt mở rộng.
- Tuần 5: cả nhóm kiểm thử đa thiết bị/tài khoản, xung đột sync, đổi ca/múi giờ và xóa dữ liệu; review chéo Trưởng–Đại, Đức–Hà. Chỉ làm một mở rộng nếu toàn bộ cốt lõi đạt và còn thời gian.
- Tuần 6: sửa lỗi, đo kết quả kiểm thử, cập nhật đóng góp, chụp minh chứng Android/Web, hoàn thiện báo cáo, tập demo và mở PR nộp bài cho giảng viên.

### 9.2. Phối hợp Git và rủi ro tiến độ

Làm trên nhánh nhom06-65ktpm của kho Fork; tính năng có thể dùng feature/nhom06/<tinh-nang> và PR nội bộ về nhánh nhóm. Trước làm phải pull, chỉ stage nhom06-65ktpm/, commit dạng feat/fix/docs(nhom06-65ktpm): mô tả rồi push origin. Không commit/push main, không push upstream hoặc sửa thư mục nhóm khác.

Nhóm trưởng review, chạy kiểm tra rồi tích hợp; giảng viên duyệt và merge PR từ nhánh nhóm của Fork về main kho gốc. README trong src ghi chi tiết lệnh và cách xử lý conflict.

Rủi ro chính: JWT/RLS, độ tin cậy nhắc trên thiết bị, GPS/pin, đa nền tảng và phạm vi lớn. Phải thử kỹ thuật ở tuần 1; ưu tiên Android/cốt lõi, nhập tay khi thiếu cảm biến, không hứa hẹn thông báo đúng tuyệt đối khi hệ điều hành hạn chế. AI/Health Connect không được chặn việc hoàn thành bản chính.

## 10. KẾT QUẢ MONG ĐỢI

### 10.1. Sản phẩm bàn giao

Ứng dụng Android với luồng đăng nhập → hồ sơ → gợi ý → duyệt lịch → nhắc/ghi nhận → tổng kết; Web có hồ sơ/lịch/thống kê trực tuyến và trạng thái rõ cho tính năng thiết bị không hỗ trợ. Kho mã nguồn có migration, seed danh mục có nguồn, hướng dẫn môi trường, báo cáo, minh chứng và lịch sử đóng góp. Các phần chưa làm phải ghi rõ.

### 10.2. Tiêu chí nghiệm thu và kiểm thử

- Gợi ý: loại mọi ứng viên chứa nguyên liệu cần tránh, thiếu thành phần hoặc thiết bị không đáp ứng; có lý do; không có ứng viên thì trả trống, không phá ràng buộc. Kiểm tra bằng danh mục fixture xác định trước.
- Planner: ca 22:00–06:00, lịch bận chồng nhau, không đủ khoảng trống, đổi ca, mục đã khóa, đổi múi giờ; không xếp chồng và không sửa lịch đã hoàn thành.
- Streak/giấc ngủ: ngày nghỉ, ngày chưa tới hạn, qua nửa đêm, sửa lịch tương lai; không đếm trùng hoặc xem thiếu dữ liệu là đã thất bại.
- Notifications: duyệt/sửa/xóa lịch, đăng xuất, tắt quyền, giờ yên lặng và khởi động lại thiết bị; không nhắc tài khoản cũ hoặc tạo nhắc trùng. Ghi rõ giới hạn thực tế của thiết bị.
- Camera/GPS: từ chối/thu hồi quyền, không có thiết bị, ảnh lỗi/quá lớn, tạm dừng/ra nền, mất tín hiệu; có nhập tay và không thu ngầm. So sánh tuyến với một lộ trình thử, báo sai số quan sát thay vì đặt độ chính xác giả định.
- Sync/bảo mật: offline rồi online, retry cùng UUID, sửa xung đột hai máy, đổi tài khoản, truy cập chéo A/B/C, URL ảnh, xóa tài khoản; không trùng nhật ký hoặc rò dữ liệu.
- Chất lượng: flutter analyze không lỗi, unit tests quy tắc/planner/streak và integration tests luồng chính đạt; demo Android thật và Web. Báo cáo ghi số ca đạt/tổng ca và lỗi còn lại sau kiểm thử, chưa công bố kết quả khi chưa chạy.

## 11. KẾT LUẬN

HealthyLife nâng cấp bài kỷ luật cá nhân thành hệ thống hỗ trợ xây dựng lịch sống lành mạnh theo điều kiện người dùng. Đề cương kết hợp các chức năng cốt lõi khả thi, dữ liệu cloud, lưu cục bộ, camera và GPS, đồng thời tách rõ tính năng mở rộng để bảo đảm tiến độ.

Giá trị của đề tài nằm ở khả năng đưa gợi ý vào lịch thực tế, giải thích lựa chọn, ghi nhận tiến độ và bảo vệ dữ liệu. Hiệu quả cải thiện sức khỏe chưa được kiểm chứng và không phải cam kết nghiệm thu; nhóm sẽ đánh giá tính đúng đắn chức năng, khả năng sử dụng và sự nhất quán của dữ liệu.


## Cấu trúc dự án và môi trường

Hiện chỉ có khung Flutter, chưa viết giao diện/nghiệp vụ HealthyLife, chưa cấu hình Firebase/Supabase hoặc xin quyền thiết bị. Các chức năng trong đề cương là kế hoạch. Giữ mã khởi động Flutter, không thêm dependency cloud/cảm biến trước khi bắt đầu triển khai.

```text
src/
├── android/                    # Android là nền tảng nghiệm thu chính
├── ios/                        # Khung iOS, cần macOS/Xcode khi triển khai
├── web/                        # Hồ sơ, lịch và dashboard trực tuyến
├── lib/
│   ├── main.dart               # Khởi động mặc định, chưa có chức năng
│   ├── app/                    # Khởi tạo và điều hướng
│   ├── core/                   # Thành phần chung khi thực sự phát sinh
│   └── features/
│       ├── auth/
│       ├── profile/
│       ├── habits/
│       ├── planner/
│       ├── recommendations/
│       ├── activity/
│       ├── nutrition/
│       ├── sleep/
│       ├── insights/
│       └── notifications/
│           # Mỗi feature: data/, domain/, presentation/
├── assets/images/
├── assets/icons/
├── test/                       # Unit/widget tests sẽ bổ sung khi có logic
├── integration_test/           # Luồng chính, quyền thiết bị và sync
├── supabase/
│   ├── migrations/             # Chưa có schema/policies
│   ├── seed/                   # Danh mục mẫu có nguồn sẽ biên soạn sau
│   └── functions/              # Tác vụ server khi cần triển khai
├── pubspec.yaml
└── README.md
```

Các thư mục trống dùng `.gitkeep`. Firebase giữ danh tính/FCM; Supabase giữ nghiệp vụ/ảnh; SQLite giữ nhật ký ngoại tuyến. Không thêm Firestore cho cùng dữ liệu. Không tạo sẵn key hoặc xin camera/GPS khi chưa có chức năng giải thích nhu cầu sử dụng.

### Thiết lập và chạy khung

Khung sinh bằng Flutter 3.47.2, Dart yêu cầu `^3.13.2`. Cần Git, Flutter stable tương thích, Android SDK/emulator hoặc điện thoại; Chrome cho Web. Nhóm thống nhất SDK trước khi code.

Từ thư mục gốc repository:

```bash
cd nhom06-65ktpm/src
flutter --version
flutter doctor
flutter pub get
flutter analyze
flutter run -d chrome
# Android: flutter devices, rồi flutter run -d <device-id>
```

Hiện lệnh chạy chỉ mở khung mặc định. Khi có logic mới bổ sung unit/widget tests và chạy `flutter test`; integration tests cần dịch vụ thử nghiệm và Android thật. Không có tài khoản cloud thật hoặc dữ liệu cá nhân nào được tạo ở bước này.

### Thứ tự cấu hình khi bắt đầu code

1. Tạo Firebase project thử nghiệm, đăng ký Android ID `vn.edu.nhom06.healthylife` và Web; cấu hình provider đăng nhập.
2. Tạo Supabase project, kết nối third-party Firebase Auth; kiểm thử JWT/RLS bằng ba tài khoản trước các module phụ thuộc.
3. Viết migration/Storage policies và seed danh mục có nguồn; chỉ dùng dữ liệu giả trong demo/fixture.
4. Chọn package tương thích SDK và nền tảng; cấu hình local notifications, camera/GPS theo chức năng và quyền tối thiểu. Kiểm tra từ chối quyền, tắt quyền và ra nền.
5. Cấu hình SQLite trên Android và adapter Web tương ứng nếu triển khai ngoại tuyến Web. Mở rộng AI/Health Connect chỉ sau khi bản chính đạt.

Không commit service-role key, private key, service account, `.env` hay dữ liệu sức khỏe thật. Khóa bí mật chỉ ở server. Commit `pubspec.lock` của ứng dụng; không commit cache/build hoặc file nhị phân APK/IPA.

## Git theo quy định của giảng viên


Nguồn quy định: [README ngoài cùng](../../README.md). Tất cả lệnh Git bên dưới chạy từ **thư mục gốc repository**; nếu đang ở `src`, chạy `cd ../..` trước.

### Thiết lập một lần

Nhóm trưởng Fork kho `oanhcuongdo/project-ptuddd`, thêm ba thành viên làm Collaborator. `origin` phải là kho Fork của nhóm trưởng; `upstream` là kho thầy. Kho cục bộ đang dùng origin `trggg2185/project-ptdudd` (tên khác kho gốc); kiểm tra `git remote -v` trước khi thao tác, không tự đổi remote nếu chưa xác minh.

```bash
git config --global user.name "Họ và tên của bạn"
git config --global user.email "email-da-dang-ky-github"
git clone https://github.com/trggg2185/project-ptdudd.git
cd project-ptdudd
git remote add upstream https://github.com/oanhcuongdo/project-ptuddd.git
git fetch origin
```

Nhóm trưởng tạo nhánh nếu nhánh nhóm chưa tồn tại (working tree phải sạch):

```bash
git checkout main
git pull upstream main
git checkout -b nhom06-65ktpm
git push -u origin nhom06-65ktpm
```

Thành viên vào nhánh đã được nhóm trưởng đẩy lên:

```bash
git checkout --track origin/nhom06-65ktpm
# Nếu đã có nhánh local:
git checkout nhom06-65ktpm
git pull origin nhom06-65ktpm
```

### Mỗi lần làm việc: pull → sửa → kiểm tra → commit → push

```bash
git checkout nhom06-65ktpm
git pull origin nhom06-65ktpm
# Làm việc chỉ trong nhom06-65ktpm/
git status
git add nhom06-65ktpm/
git diff --cached --name-only
git diff --cached
git commit -m "feat(nhom06-65ktpm): them lich ren luyen ca nhan"
git push origin nhom06-65ktpm
```

Mọi đường dẫn staged phải bắt đầu bằng `nhom06-65ktpm/`. Dùng `git restore --staged <duong-dan>` nếu add nhầm. Không dùng `git add .` ở root; không sửa root README/.gitignore hoặc thư mục nhóm khác. Không commit/push trực tiếp vào `main`, không push `upstream`, không force-push nhánh chung.

Thông điệp theo mẫu `<loai>(nhom06-65ktpm): <mo-ta>`: `feat` cho chức năng/mã mới, `fix` cho sửa lỗi, `docs` cho tài liệu. Ví dụ `docs(nhom06-65ktpm): cap nhat de cuong HealthyLife`.

### Làm song song bằng nhánh tính năng

```bash
git checkout nhom06-65ktpm
git pull origin nhom06-65ktpm
git checkout -b feature/nhom06/lich-ren-luyen
# Sửa, kiểm tra và commit theo mẫu trên
git push -u origin feature/nhom06/lich-ren-luyen
```

Mở PR nội bộ tại kho Fork: base `nhom06-65ktpm`, compare nhánh tính năng. Nhóm trưởng review và merge vào nhánh nhóm sau khi kiểm tra; không đưa PR tính năng thẳng vào `main` của thầy.

Nếu push bị từ chối vì người khác đã push trước, khi working tree sạch:

```bash
git pull --rebase origin nhom06-65ktpm
# Nếu conflict: trao đổi với tác giả, sửa từng file rồi:
git add nhom06-65ktpm/
git rebase --continue
# Kiểm tra ứng dụng trước khi push
git push origin nhom06-65ktpm
```

Nếu chưa giải quyết được, dùng `git rebase --abort` để quay lại trước rebase. Không ghi đè phần của bạn khác. Đồng bộ kho thầy định kỳ khi working tree sạch:

```bash
git checkout nhom06-65ktpm
git fetch upstream
git merge upstream/main
# Xử lý conflict, kiểm tra rồi:
git push origin nhom06-65ktpm
```

### Nộp bài và merge về kho thầy

1. Hoàn thiện `danhsachnhom.md`, mã nguồn, báo cáo và minh chứng; kiểm tra không có `.env`, service account, keystore, cache, build, APK/IPA.
2. Nhóm trưởng mở PR: **base repository** `oanhcuongdo/project-ptuddd`, **base** `main`; **head repository** kho Fork nhóm, **compare** `nhom06-65ktpm`.
3. Tiêu đề: `[Nộp bài] nhom06-65ktpm - HealthyLife - Trợ lý kỷ luật và lối sống lành mạnh`.
4. Nội dung nêu chức năng thực sự hoàn thành, cách chạy, kết quả kiểm thử và bốn thành viên. Kiểm tra Files changed chỉ có đường dẫn nhóm mình.
5. Giảng viên kiểm duyệt và merge PR về `main`; nhóm chỉ cập nhật nhánh nhóm khi được yêu cầu sửa.


## Tài liệu và nguồn tham khảo

- [Báo cáo Word HealthyLife](../docs/HealthyLife_Nhom06_De_cuong.docx) là đề cương hiện hành, dùng mẫu 11 mục của giảng viên.
- [Nguồn đề cương UTF-8](../docs/HealthyLife_Nhom06_De_cuong.md) và [script xuất Word](../docs/build_healthylife_report.py). Chạy từ gốc: `python -X utf8 nhom06-65ktpm/docs/build_healthylife_report.py` (cần python-docx). Script giữ định dạng mẫu và kiểm tra dấu tiếng Việt.
- [Danh sách thành viên](../danhsachnhom.md); [hướng dẫn của thầy](../../README.md).
- Các báo cáo StudyHub cũ được giữ làm lịch sử, không dùng nộp đề tài mới. Không sửa file mẫu `De_cuong_cuoi_ky.docx`.
