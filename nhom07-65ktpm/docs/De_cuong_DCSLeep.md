# TRƯỜNG ĐẠI HỌC THỦY LỢI
## KHOA CÔNG NGHỆ THÔNG TIN

---

# ĐỀ CƯƠNG BÀI TẬP LỚN
### HỌC PHẦN: PHÁT TRIỂN ỨNG DỤNG CHO CÁC THIẾT BỊ DI ĐỘNG

**Đề tài:** **DCSleep – Ứng dụng hỗ trợ xây dựng kỷ luật và cải thiện thói quen ngủ bằng trí tuệ nhân tạo**  
**Giảng viên hướng dẫn:** ThS. Đỗ Oanh Cường  
**Lớp:** 65KTPM  
**Nhóm sinh viên thực hiện:** Nhóm 7  
1. **Mã Khánh Linh** – 2351170602 *(Nhóm trưởng)*  
2. **Vũ Bá Đài** – 2351170577 *(Thành viên)*  
3. **Dương Quốc Vượng** – 2351170634 *(Thành viên)*  
4. **Lê Văn Dân** – 2251161963 *(Thành viên)*  

*Hà Nội, tháng 11 năm 2026*

---

## 1. GIỚI THIỆU ĐỀ TÀI
Trong cuộc sống hiện đại, nhiều người có lịch sinh hoạt thiếu ổn định do học tập, công việc, giải trí và thói quen sử dụng điện thoại vào ban đêm. Không ít người thường xuyên thức khuya, ngủ không đủ thời lượng, ngủ và thức dậy không đúng giờ hoặc ngủ trưa kéo dài. Những thói quen này có thể khiến cơ thể mệt mỏi, giảm khả năng tập trung và ảnh hưởng đến chất lượng sinh hoạt hằng ngày.

Trên thực tế, người dùng thường đặt báo thức hoặc ghi nhớ giờ đi ngủ một cách thủ công. Các công cụ này chủ yếu nhắc thời gian, chưa hỗ trợ người dùng xây dựng kế hoạch ngủ phù hợp, theo dõi mức độ thực hiện mục tiêu và điều chỉnh thói quen dựa trên nhật ký ngủ. Người dùng cũng khó tìm được lời khuyên phù hợp với lịch học tập, làm việc và tình trạng sinh hoạt của bản thân.

Từ thực tế đó, nhóm lựa chọn đề tài **DCSleep – Ứng dụng hỗ trợ xây dựng kỷ luật và cải thiện thói quen ngủ bằng trí tuệ nhân tạo**. Ứng dụng được phát triển bằng Flutter, hướng tới nền tảng Android và có thể mở rộng sang iOS. Người dùng có thể thiết lập lịch ngủ, đặt mục tiêu, ghi nhận thời gian ngủ thực tế, quản lý giấc ngủ ngắn, nhận thông báo nhắc nhở và xem thống kê tiến độ.

Bên cạnh các chức năng quản lý cơ bản, DCSleep tích hợp trợ lý AI thông qua API mô hình ngôn ngữ như Gemini hoặc OpenAI để giải đáp câu hỏi phổ biến về vệ sinh giấc ngủ, phân tích nhật ký do người dùng cung cấp và gợi ý điều chỉnh thói quen. Ứng dụng cũng xem xét các tính năng hỗ trợ hạn chế sử dụng điện thoại trước giờ ngủ. Google Family Link được đề cập như một công cụ phụ huynh có thể tự cấu hình trên thiết bị của trẻ; đề tài không giả định có API công khai để ứng dụng bên thứ ba trực tiếp điều khiển Family Link.

Đề tài phù hợp với môn học vì nhóm có thể vận dụng kiến thức Flutter/Dart, thiết kế giao diện di động, quản lý trạng thái, cơ sở dữ liệu, thông báo cục bộ, tích hợp API và xử lý dữ liệu người dùng.

---

## 2. LÝ DO CHỌN ĐỀ TÀI
Nhóm lựa chọn đề tài DCSleep vì giấc ngủ là nhu cầu thiết yếu nhưng thói quen ngủ thiếu khoa học khá phổ biến, đặc biệt ở học sinh, sinh viên và người trẻ. Đây là vấn đề gần gũi, dễ khảo sát trong phạm vi lớp học và có thể xây dựng thành ứng dụng di động với các chức năng cụ thể.

Các ứng dụng báo thức thông thường chủ yếu hỗ trợ người dùng thức dậy đúng giờ. Trong khi đó, DCSleep tập trung vào toàn bộ quá trình hình thành thói quen: đặt mục tiêu, chuẩn bị trước giờ ngủ, duy trì lịch ngủ, ghi nhận kết quả và xem lại tiến độ. Việc có nhật ký và thống kê giúp người dùng nhận biết mức độ ổn định của lịch sinh hoạt thay vì chỉ dựa vào cảm giác.

Nhóm lựa chọn Flutter vì có thể xây dựng ứng dụng đa nền tảng từ một mã nguồn, hỗ trợ phát triển giao diện nhanh và có hệ sinh thái thư viện phong phú. Việc tích hợp AI tạo điểm khác biệt cho đề tài: người dùng có thể trao đổi bằng ngôn ngữ tự nhiên và nhận gợi ý dựa trên thông tin mà họ chủ động cung cấp.

Ngoài ra, đề tài có phạm vi đủ rộng để phân chia cho bốn thành viên nhưng vẫn có thể giới hạn phiên bản đầu tiên ở các chức năng thiết yếu. Các chức năng đo chuyên sâu như xác định chính xác chu kỳ ngủ hoặc các giai đoạn ngủ không nằm trong phạm vi cam kết nếu không có thiết bị chuyên dụng.

---

## 3. MỤC TIÊU ĐỀ TÀI

### 3.1. Mục tiêu tổng quát
Xây dựng ứng dụng di động DCSleep hỗ trợ người dùng hình thành và duy trì thói quen ngủ lành mạnh thông qua việc thiết lập lịch ngủ, quản lý giấc ngủ ngắn, ghi nhật ký, theo dõi tiến độ và nhận tư vấn từ trợ lý AI. Ứng dụng sử dụng Flutter/Dart làm nền tảng phát triển, kết hợp cơ sở dữ liệu lưu trữ và các dịch vụ thông báo, API AI.

### 3.2. Mục tiêu cụ thể
Hệ thống dự kiến thực hiện các nội dung sau:
- Xây dựng ứng dụng di động có giao diện trực quan, dễ sử dụng và phù hợp với chủ đề sức khỏe giấc ngủ.
- Cho phép người dùng đăng ký, đăng nhập hoặc sử dụng chế độ phù hợp với phạm vi triển khai của nhóm.
- Cho phép thiết lập giờ đi ngủ, giờ thức dậy và mục tiêu thời lượng ngủ.
- Xây dựng lịch nhắc chuẩn bị đi ngủ, nhắc đi ngủ và nhắc thức dậy bằng thông báo trên thiết bị.
- Cho phép ghi nhận giờ bắt đầu ngủ, giờ thức dậy và cảm nhận sau khi ngủ.
- Hỗ trợ thiết lập giấc ngủ ngắn, bộ đếm thời gian và nhắc kết thúc giấc ngủ trưa.
- Hiển thị lịch sử ngủ và thống kê theo ngày, tuần hoặc tháng.
- Tính toán chỉ số tuân thủ mục tiêu dựa trên dữ liệu nhật ký, không xem đây là chẩn đoán y tế.
- Tích hợp trợ lý AI để trả lời câu hỏi phổ biến và đưa ra gợi ý dựa trên dữ liệu người dùng cung cấp.
- Cung cấp nội dung hướng dẫn vệ sinh giấc ngủ, thư giãn và xây dựng thói quen trước khi ngủ.
- Cho phép người dùng quản lý cài đặt thông báo và quyền riêng tư.
- Khảo sát khả năng hỗ trợ người dùng hạn chế thời gian màn hình; hướng dẫn sử dụng Digital Wellbeing hoặc Family Link khi phù hợp, không phụ thuộc vào API Family Link không được công bố.
- Kiểm thử các chức năng chính và hoàn thiện phiên bản có thể trình diễn.

---

## 4. KIẾN TRÚC TỔNG THỂ HỆ THỐNG
DCSleep được thiết kế theo mô hình ứng dụng di động gồm các thành phần chính:
1. Flutter Mobile Application.
2. Sleep Management Module.
3. AI Assistant và dịch vụ API.
4. Notification Service.
5. Database và Cloud Services.
6. Các thiết lập hỗ trợ quản lý thời gian sử dụng thiết bị của hệ điều hành.

### 4.1. Flutter Mobile Application
Flutter là nền tảng xây dựng giao diện và xử lý tương tác chính. Ứng dụng gồm các màn hình trang chủ, lịch ngủ, nhật ký, thống kê, trợ lý AI và cài đặt. Dart được sử dụng để triển khai logic phía ứng dụng, kiểm tra dữ liệu đầu vào và kết nối các dịch vụ.

### 4.2. Sleep Management Module
Module quản lý giấc ngủ đảm nhiệm việc tạo mục tiêu, lưu lịch ngủ dự kiến, ghi nhận thời gian ngủ thực tế, quản lý giấc ngủ ngắn và tính toán mức độ hoàn thành mục tiêu. Các kết quả được trình bày dưới dạng lịch sử và biểu đồ để người dùng dễ theo dõi.

### 4.3. AI Assistant và dịch vụ API
Trợ lý AI tiếp nhận câu hỏi và dữ liệu nhật ký mà người dùng đồng ý chia sẻ, sau đó gửi yêu cầu đến API của mô hình ngôn ngữ như Gemini hoặc OpenAI. Phần gọi API nên được thực hiện thông qua lớp dịch vụ trung gian hoặc backend để hạn chế việc để lộ khóa API trong mã nguồn ứng dụng. AI chỉ cung cấp thông tin giáo dục và gợi ý thói quen chung, không chẩn đoán bệnh hoặc thay thế chuyên gia y tế.

### 4.4. Notification Service
Dịch vụ thông báo sử dụng thông báo cục bộ của thiết bị để nhắc người dùng chuẩn bị đi ngủ, đến giờ đi ngủ, thức dậy hoặc kết thúc giấc ngủ ngắn. Ứng dụng cần xử lý quyền thông báo, múi giờ, lịch nhắc lặp lại và trường hợp người dùng thay đổi lịch.

### 4.5. Database và Cloud Services
Dữ liệu cơ bản được lưu cục bộ bằng SQLite để hỗ trợ sử dụng ngoại tuyến (Offline-First). Để đồng bộ nhiều thiết bị và quản lý tài khoản trực tuyến, nhóm sử dụng **Supabase (PostgreSQL)**. Các dữ liệu chính gồm hồ sơ người dùng, mục tiêu ngủ, lịch ngủ, nhật ký ngủ, lịch sử giấc ngủ ngắn và lịch sử trao đổi AI theo chính sách lưu trữ được công bố.

### 4.6. Hỗ trợ quản lý thời gian sử dụng thiết bị
Ứng dụng có thể cung cấp hướng dẫn bật chế độ Không làm phiền, Focus hoặc Digital Wellbeing trên Android. Google Family Link có thể được phụ huynh cấu hình riêng để quản lý thiết bị của trẻ. Theo phạm vi tích hợp được xác định cho đề tài, nhóm không cam kết đọc hoặc thay đổi trực tiếp dữ liệu, giờ đi ngủ hay giới hạn ứng dụng của Family Link thông qua API công khai.

---

## 5. LUỒNG HOẠT ĐỘNG CHÍNH
Luồng hoạt động tổng quát của hệ thống như sau:
1. Người dùng mở DCSleep và đăng nhập hoặc tạo hồ sơ sử dụng.
2. Người dùng nhập một số thông tin cơ bản phục vụ việc thiết lập mục tiêu, chẳng hạn lịch học tập/làm việc và giờ cần thức dậy.
3. Hệ thống đề xuất khung giờ ngủ tham khảo; người dùng xem và tự điều chỉnh mục tiêu.
4. Người dùng lưu giờ đi ngủ, giờ thức dậy và lịch nhắc.
5. Đến thời điểm đã thiết lập, ứng dụng gửi thông báo nhắc người dùng chuẩn bị đi ngủ hoặc thức dậy.
6. Người dùng ghi nhận giờ ngủ thực tế và cảm nhận sau khi thức dậy.
7. Nếu có ngủ trưa, người dùng chọn thời lượng giấc ngủ ngắn và khởi động bộ đếm.
8. Hệ thống lưu nhật ký, đối chiếu với mục tiêu và cập nhật thống kê.
9. Người dùng mở trợ lý AI, đặt câu hỏi hoặc yêu cầu gợi ý dựa trên nhật ký đã chọn chia sẻ.
10. AI trả về câu trả lời và đề xuất điều chỉnh thói quen phù hợp ở mức tham khảo.
11. Người dùng xem biểu đồ, đánh giá tiến độ và điều chỉnh mục tiêu cho những ngày tiếp theo.

---

## 6. CÔNG NGHỆ SỬ DỤNG

### 6.1. Flutter và Dart
Flutter/Dart được sử dụng để xây dựng ứng dụng di động.  
- **Lý do lựa chọn:**
  - Có thể phát triển ứng dụng Android và mở rộng sang iOS.
  - Có hệ thống widget phong phú, thuận tiện xây dựng giao diện.
  - Hỗ trợ tích hợp API và các thư viện thông báo, biểu đồ, lưu trữ.
  - Phù hợp với kiến thức và môi trường học tập của nhóm.
- **Phạm vi ứng dụng:** Flutter/Dart dùng để xây dựng giao diện, xử lý tương tác, quản lý trạng thái, kiểm tra dữ liệu và kết nối các module.

### 6.2. Supabase (PostgreSQL) và SQLite
Nhóm lựa chọn mô hình cơ sở dữ liệu song song: SQLite dùng để lưu trữ dữ liệu cục bộ và hỗ trợ sử dụng ngoại tuyến; **Supabase (PostgreSQL)** được sử dụng để lưu trữ, xác thực tài khoản và đồng bộ dữ liệu đám mây trên nhiều thiết bị.  
- **Dữ liệu dự kiến gồm:**
  - `Users`: thông tin hồ sơ và tùy chọn người dùng.
  - `SleepGoals`: mục tiêu giờ ngủ, giờ thức dậy và thời lượng ngủ.
  - `SleepRecords`: thời điểm bắt đầu ngủ, thức dậy, thời lượng và ghi chú.
  - `NapRecords`: thời gian và thời lượng các giấc ngủ ngắn.
  - `Reminders`: cấu hình các lịch nhắc.
  - `AIConversations`: lịch sử trao đổi nếu người dùng bật chức năng lưu.

### 6.3. Gemini API hoặc OpenAI API
API mô hình ngôn ngữ được sử dụng để xây dựng trợ lý AI. Nhóm lựa chọn một nhà cung cấp phù hợp với hạn mức, chi phí và điều kiện sử dụng tại thời điểm triển khai. Ứng dụng gửi câu hỏi cùng phần dữ liệu cần thiết, nhận phản hồi và hiển thị cho người dùng. Không gửi dữ liệu cá nhân không cần thiết; cần thông báo rõ dữ liệu nào được gửi đến dịch vụ AI.

### 6.4. Thông báo cục bộ
Nhóm có thể sử dụng thư viện Flutter hỗ trợ local notifications để lập lịch thông báo trên thiết bị. Chức năng này phục vụ nhắc giờ ngủ, giờ thức dậy, nhắc chuẩn bị đi ngủ và bộ đếm giấc ngủ ngắn. Việc thông báo có thể chịu ảnh hưởng bởi quyền của người dùng, chế độ tiết kiệm pin và chính sách nền của hệ điều hành.

### 6.5. Biểu đồ và quản lý trạng thái
Thư viện biểu đồ như `fl_chart` có thể được sử dụng để trực quan hóa thời lượng ngủ theo ngày/tuần/tháng. Nhóm lựa chọn một giải pháp quản lý trạng thái phù hợp với cấu trúc dự án, ví dụ Provider, Riverpod hoặc Bloc; cần thống nhất một phương án trước khi triển khai.

### 6.6. Google Family Link và Digital Wellbeing
Google Family Link là ứng dụng/dịch vụ kiểm soát của phụ huynh, không được xem là API mở để DCSleep tùy ý truy cập hoặc điều khiển. Vì vậy, phiên bản bài tập lớn chỉ nên cung cấp nội dung hướng dẫn phụ huynh thiết lập Family Link và hướng dẫn người dùng sử dụng các tính năng Digital Wellbeing/Không làm phiền có sẵn trên thiết bị. Nếu hệ điều hành không cho phép ứng dụng truy cập một loại dữ liệu, nhóm không thu thập dữ liệu đó.

### 6.7. GitHub và công cụ quản lý công việc
GitHub được sử dụng để lưu trữ mã nguồn, quản lý nhánh, theo dõi thay đổi và phối hợp lập trình. Trello hoặc công cụ tương đương có thể được sử dụng để phân công nhiệm vụ, theo dõi tiến độ và ghi nhận các công việc cần hoàn thành.

---

## 7. CÁC CHỨC NĂNG CHÍNH

### 7.1. Giao diện ứng dụng
Ứng dụng dự kiến có các màn hình chính:
- Trang chủ / Tổng quan.
- Thiết lập mục tiêu và lịch ngủ.
- Nhật ký giấc ngủ.
- Giấc ngủ ngắn (Power Nap).
- Trợ lý AI Sleep Assistant.
- Thống kê và tiến độ.
- Thư viện kiến thức về giấc ngủ.
- Cài đặt tài khoản, thông báo và quyền riêng tư.

### 7.2. Trang chủ
Trang chủ hiển thị thông tin tổng quan để người dùng nhanh chóng nắm được kế hoạch trong ngày, gồm:
- Giờ đi ngủ và giờ thức dậy mục tiêu.
- Thời gian còn lại đến giờ đi ngủ hoặc giờ thức dậy tiếp theo.
- Tóm tắt nhật ký gần nhất.
- Tiến độ duy trì mục tiêu trong tuần.
- Lối tắt đến chức năng ngủ ngắn và trợ lý AI.

### 7.3. Thiết lập lịch ngủ
Người dùng có thể thiết lập giờ đi ngủ, giờ thức dậy, ngày áp dụng và mục tiêu thời lượng ngủ. Ứng dụng đưa ra gợi ý tham khảo dựa trên thông tin người dùng nhập, đồng thời cho phép người dùng chủ động thay đổi. Lịch ngủ có thể được điều chỉnh khi có thay đổi về lịch học hoặc công việc.

### 7.4. Nhắc nhở và báo thức
Chức năng cho phép người dùng:
- Đặt nhắc nhở trước giờ đi ngủ.
- Nhận thông báo khi đến giờ chuẩn bị ngủ.
- Thiết lập nhắc thức dậy.
- Bật/tắt hoặc thay đổi lịch nhắc.
- Chọn ngày lặp lại và âm thanh/thông báo phù hợp trong giới hạn hệ điều hành.

### 7.5. Quản lý giấc ngủ ngắn (Power Nap)
Người dùng có thể chọn thời lượng ngủ ngắn, khởi động bộ đếm và nhận thông báo khi hết thời gian. Ứng dụng có thể đưa ra khuyến nghị chung về giấc ngủ ngắn, chẳng hạn khoảng 10–20 phút đối với nhiều người trưởng thành, nhưng cần trình bày đây là gợi ý tham khảo chứ không phải quy tắc phù hợp cho tất cả mọi người.

### 7.6. Nhật ký giấc ngủ
Người dùng có thể nhập hoặc chỉnh sửa:
- Thời điểm bắt đầu ngủ.
- Thời điểm thức dậy.
- Thời lượng ngủ được tính từ dữ liệu thời gian.
- Số lần thức giấc hoặc ghi chú nếu người dùng muốn ghi nhận.
- Mức độ tỉnh táo/cảm nhận sau khi thức dậy.

*Ứng dụng sử dụng dữ liệu do người dùng nhập để tạo lịch sử. Nếu không kết nối thiết bị đeo hoặc nguồn dữ liệu được hỗ trợ, ứng dụng không khẳng định tự động đo chính xác thời điểm người dùng thực sự ngủ.*

### 7.7. Thống kê và đánh giá kỷ luật
Màn hình thống kê hiển thị thời lượng ngủ theo ngày, tuần hoặc tháng; số ngày đạt mục tiêu; mức chênh lệch giữa giờ ngủ dự kiến và giờ ngủ thực tế. Điểm kỷ luật, nếu triển khai, được tính theo tiêu chí minh bạch do nhóm định nghĩa, ví dụ tỷ lệ ngày người dùng ghi nhận và đạt khung giờ mục tiêu. Chỉ số này mang tính theo dõi thói quen, không phải điểm đánh giá sức khỏe.

### 7.8. AI Sleep Assistant
Trợ lý AI cho phép người dùng đặt câu hỏi bằng ngôn ngữ tự nhiên. Các tình huống sử dụng gồm:
- Hỏi về thói quen ngủ và vệ sinh giấc ngủ.
- Yêu cầu gợi ý cách điều chỉnh lịch ngủ khi thường xuyên thức khuya.
- Nhờ xây dựng kế hoạch thay đổi giờ ngủ từng bước.
- Hỏi về thời lượng ngủ ngắn và thói quen trước khi ngủ.
- Yêu cầu nhận xét xu hướng từ nhật ký ngủ mà người dùng chủ động chia sẻ.

*AI cần được giới hạn vai trò ở cung cấp thông tin phổ thông và hỗ trợ hình thành thói quen. Khi người dùng mô tả triệu chứng kéo dài, nghiêm trọng hoặc có dấu hiệu cần chăm sóc y tế, ứng dụng nên khuyến nghị tìm tư vấn từ nhân viên y tế thay vì tự đưa ra chẩn đoán.*

### 7.9. Thư viện phương pháp cải thiện giấc ngủ
Ứng dụng cung cấp các bài viết/nguyên tắc cơ bản như duy trì giờ ngủ ổn định, tạo môi trường ngủ yên tĩnh và thoải mái, hạn chế caffeine gần giờ ngủ, giảm ánh sáng và hoạt động kích thích trước khi ngủ, thư giãn bằng hít thở hoặc thiền nhẹ. Nội dung cần có nguồn tham khảo đáng tin cậy và được trình bày dưới dạng kiến thức phổ thông.

### 7.10. Quản lý thời gian sử dụng điện thoại
DCSleep có thể nhắc người dùng giảm sử dụng điện thoại trước giờ ngủ và cung cấp hướng dẫn bật chế độ Không làm phiền, Focus hoặc Digital Wellbeing. Với trẻ em, phụ huynh có thể được hướng dẫn tự cấu hình Google Family Link. Chức năng này không bao gồm việc DCSleep tự khóa thiết bị hoặc điều khiển Family Link nếu không có quyền/API chính thức.

### 7.11. Cài đặt và quyền riêng tư
Người dùng có thể chỉnh sửa hồ sơ, mục tiêu, thông báo, lựa chọn lưu lịch sử AI và quản lý dữ liệu cá nhân. Ứng dụng cần giải thích mục đích thu thập dữ liệu, chỉ lưu thông tin cần thiết và cho phép người dùng xóa dữ liệu trong phạm vi hệ thống hỗ trợ.

---

## 8. PHÂN QUYỀN NGƯỜI DÙNG
Trong phạm vi phiên bản đầu tiên, hệ thống tổ chức các nhóm người dùng sau:

### 8.1. Người dùng
Người dùng có thể:
- Tạo tài khoản, đăng nhập và đăng xuất nếu hệ thống triển khai xác thực.
- Thiết lập và chỉnh sửa mục tiêu ngủ.
- Tạo lịch nhắc và sử dụng bộ đếm giấc ngủ ngắn.
- Thêm, xem, sửa nhật ký ngủ của bản thân.
- Xem biểu đồ và tiến độ cá nhân.
- Trao đổi với trợ lý AI.
- Quản lý cài đặt thông báo và quyền riêng tư.

### 8.2. Quản trị viên (nếu triển khai backend quản trị)
Quản trị viên có thể quản lý nội dung hướng dẫn, theo dõi trạng thái hoạt động tổng quát và xử lý phản hồi kỹ thuật. Quản trị viên không nên xem nội dung nhật ký cá nhân hoặc hội thoại AI nếu không có mục đích, quyền hạn và cơ chế bảo vệ phù hợp.

### 8.3. Phụ huynh
Nếu nhóm mở rộng kịch bản dành cho trẻ em, phụ huynh có thể được hướng dẫn sử dụng các công cụ kiểm soát của hệ điều hành và Google Family Link. Vai trò này được thực hiện trong ứng dụng Family Link của Google; DCSleep không mặc nhiên có quyền truy cập dữ liệu hoặc thay đổi thiết lập của phụ huynh.

---

## 9. PHÂN CÔNG CÔNG VIỆC

| Thành viên | Module phụ trách | Nhiệm vụ chính chi tiết |
| :--- | :--- | :--- |
| **Mã Khánh Linh**<br>*(2351170602 – Nhóm trưởng)* | **Giao diện, tài khoản, hồ sơ và Cơ sở dữ liệu (Database)** | Thiết kế cấu trúc Flutter, mô hình dữ liệu và cơ sở dữ liệu (SQLite & Supabase), trang chủ, đăng ký/đăng nhập, hồ sơ người dùng, điều hướng và tích hợp các màn hình. Quản trị chung dự án và điều phối nhóm. |
| **Vũ Bá Đài**<br>*(2351170577 – Thành viên)* | **Lịch ngủ, nhắc nhở và Power Nap** | Xây dựng thiết lập mục tiêu, lịch ngủ, thông báo cục bộ (`flutter_local_notifications`), bộ đếm giấc ngủ ngắn và xử lý thay đổi lịch. |
| **Dương Quốc Vượng**<br>*(2351170634 – Thành viên)* | **AI Sleep Assistant** | Tích hợp Gemini hoặc OpenAI API qua lớp dịch vụ phù hợp, thiết kế prompt, giao diện chat, xử lý lỗi và giới hạn an toàn của câu trả lời. |
| **Lê Văn Dân**<br>*(2251161963 – Thành viên)* | **Nhật ký giấc ngủ và Thống kê biểu đồ** | Xây dựng chức năng ghi nhận/chỉnh sửa/xem lịch sử nhật ký giấc ngủ, trực quan hóa biểu đồ thống kê (`fl_chart`), tính toán tiến độ kỷ luật, kiểm thử và hỗ trợ tích hợp toàn ứng dụng. |

*Cả nhóm cùng thống nhất giao diện, quy ước mã nguồn, kiểm thử tích hợp, viết báo cáo và chuẩn bị nội dung trình diễn.*

---

## 10. KẾT QUẢ MONG ĐỢI
Sau khi hoàn thành, nhóm mong muốn đạt được các kết quả sau:
- Xây dựng được ứng dụng DCSleep bằng Flutter/Dart có thể chạy trên thiết bị hoặc trình giả lập Android.
- Có giao diện chính và các màn hình chức năng rõ ràng, dễ sử dụng.
- Người dùng có thể thiết lập giờ ngủ, giờ thức dậy và mục tiêu ngủ.
- Ứng dụng có thể lập lịch và hiển thị thông báo nhắc nhở theo cấu hình.
- Người dùng có thể sử dụng bộ đếm giấc ngủ ngắn.
- Người dùng có thể ghi nhận và xem lại nhật ký ngủ.
- Ứng dụng hiển thị được thống kê cơ bản theo ngày/tuần và tiến độ thực hiện mục tiêu.
- Trợ lý AI có thể tiếp nhận câu hỏi và trả lời thông qua API được tích hợp.
- Dữ liệu được lưu cục bộ bằng SQLite và đồng bộ đám mây qua Supabase (PostgreSQL).
- Ứng dụng có nội dung hướng dẫn phương pháp cải thiện thói quen ngủ và quản lý thời gian sử dụng điện thoại.
- Có tài liệu hướng dẫn sử dụng, mã nguồn và kịch bản kiểm thử để trình diễn.
- Các chức năng nâng cao như đồng bộ dữ liệu từ thiết bị đeo, phân tích giai đoạn ngủ, khóa ứng dụng tự động hoặc tích hợp trực tiếp Family Link chỉ được xem xét nếu có đủ thời gian, quyền truy cập và API chính thức phù hợp.

---

## 11. KẾT LUẬN
Đề tài **DCSleep** hướng tới giải quyết một vấn đề gần gũi trong đời sống là xây dựng thói quen ngủ ổn định và lành mạnh. Thông qua ứng dụng, người dùng có thể thiết lập lịch ngủ, nhận nhắc nhở, quản lý giấc ngủ ngắn, ghi nhật ký và theo dõi tiến độ thực hiện mục tiêu.

Việc sử dụng Flutter/Dart giúp nhóm vận dụng kiến thức phát triển ứng dụng di động. Cơ sở dữ liệu hỗ trợ lưu trữ thông tin cá nhân và lịch sử ngủ; dịch vụ thông báo giúp nhắc nhở theo lịch; API Gemini hoặc OpenAI tạo ra trợ lý AI có khả năng giải đáp và gợi ý dựa trên dữ liệu người dùng cung cấp.

Đối với Google Family Link, nhóm xác định đây là công cụ hỗ trợ phụ huynh quản lý thiết bị được sử dụng độc lập, không phải API mà DCSleep có thể tùy ý điều khiển. Cách xác định phạm vi này giúp đề tài tập trung vào các chức năng khả thi, có thể triển khai và trình diễn trong thời gian bài tập lớn.

Nhìn chung, DCSleep có khả năng phát triển thành một ứng dụng di động thiết thực, kết hợp quản lý thói quen và AI. Trong tương lai, hệ thống có thể mở rộng thêm khả năng đồng bộ với thiết bị đeo hoặc nền tảng sức khỏe nếu có nguồn dữ liệu và quyền tích hợp phù hợp.
