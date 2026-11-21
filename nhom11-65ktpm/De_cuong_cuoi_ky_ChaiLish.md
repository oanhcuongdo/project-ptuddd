**TRƯỜNG ĐẠI HỌC THỦY LỢI**

**KHOA CÔNG NGHỆ THÔNG TIN**

<img src="assets/media/image1.png" />

**ĐỀ CƯƠNG BÀI TẬP LỚN**

**PHÁT TRIỂN ỨNG DỤNG DI ĐỘNG**



**Đề tài: ChaiLish - Ứng dụng học tiếng Trung tích hợp AI chấm phát âm, luyện viết Hán tự**

> **Giảng viên hướng dẫn: Đỗ Oanh Cường**
>
> **Nhóm sinh viên thực hiện: Nhóm 11**

1.  Nguyễn Hồng Phúc - 2351170611

2.  Lê Tuấn Khanh - 2351170601

3.  Đinh Thị Hoa - 2351170593

4.  Chu Hữu Đệ - 2251172273

5.  Phạm Vũ Ngọc Bảo - 2251172249

Hà Nội, ngày 14 tháng 11 năm 2026

# **1. GIỚI THIỆU ĐỀ TÀI**

Hiện nay, nhu cầu học tiếng Trung ở Việt Nam tăng nhanh. Nhiều bạn trẻ học tiếng Trung để thi chứng chỉ HSK, đi du học, làm việc trong các doanh nghiệp Trung Quốc, Đài Loan hoặc phục vụ công việc thương mại, du lịch. Vì vậy, các ứng dụng hỗ trợ tự học tiếng Trung trên điện thoại ngày càng được quan tâm.

Tuy nhiên, người Việt khi học tiếng Trung thường gặp ba khó khăn chính. Thứ nhất là phát âm: tiếng Trung có 4 thanh điệu và thanh nhẹ, có các cặp âm dễ nhầm như zh/z, ch/c, sh/s, j/q/x và nguyên âm ü. Thứ hai là chữ viết: Hán tự có nhiều nét, phải viết đúng thứ tự nét và đúng bộ thủ. Thứ ba là ghi nhớ từ vựng: nếu không ôn tập đúng lúc thì người học rất nhanh quên.

Nhiều ứng dụng học ngoại ngữ hiện nay chỉ lưu dữ liệu trên máy, không có tài khoản người dùng, chưa phản hồi chi tiết về thanh điệu và chưa kiểm tra được nét viết. Người tự học cũng thường không biết nên học gì trước, học gì sau và dễ bỏ dở giữa chừng vì thiếu một lộ trình rõ ràng.

Từ lý do đó, theo định hướng của giảng viên hướng dẫn, nhóm em chọn đề tài **ChaiLish - Ứng dụng học tiếng Trung tích hợp AI chấm phát âm, luyện viết Hán tự** . Đây là hệ thống được nhóm xây dựng mới từ đầu, gồm ứng dụng Android viết bằng Flutter và một máy chủ (server) quản lý người dùng.

Ứng dụng giúp người dùng tự học theo một lộ trình có sẵn từ con số 0 đến HSK 2. Người học đăng ký tài khoản, học lần lượt từng bài trên lộ trình, nghe mẫu, luyện phát âm và được chấm điểm thanh điệu, luyện viết Hán tự theo đúng thứ tự nét, ôn tập bằng flashcard và theo dõi tiến độ học. Cuối mỗi bài, người học trò chuyện với trợ lý AI về chủ đề vừa học và được phân tích ngữ pháp từng câu trả lời. Dữ liệu học tập được đồng bộ lên server, nhờ đó người học có thể đổi điện thoại mà không mất dữ liệu.

Máy chủ cung cấp REST API để đăng ký, đăng nhập, quản lý tài khoản, lưu tiến độ học, phân phối bài học, chấm phát âm online và làm trung gian gọi trợ lý AI.

# **2. LÝ DO CHỌN ĐỀ TÀI**

Nhóm em chọn đề tài này vì học tiếng Trung là nhu cầu thực tế, có nhiều người dùng tiềm năng và dễ kiểm thử với chính các bạn sinh viên trong trường. Các chức năng như chấm thanh điệu và kiểm tra nét viết cũng dễ demo trực quan khi báo cáo.

Bên cạnh đó, nhóm đã có kinh nghiệm với Flutter, SQLite, nhận dạng giọng nói và thuật toán so sánh chuỗi qua bài thực hành TH3. Đề tài lần này được nhóm thiết kế và lập trình lại từ đầu, giúp mọi thành viên đều được tham gia viết code ở cả phía ứng dụng và phía server.

Việc bổ sung server giúp đề tài đầy đủ hơn về mặt kỹ thuật. Nhóm được thực hành thiết kế API, xác thực bằng JWT, phân quyền người dùng, đồng bộ dữ liệu giữa thiết bị và máy chủ và triển khai hệ thống bằng Docker. Đây là các kiến thức sát với công việc thực tế của lập trình viên ứng dụng di động.

Ngoài ra, đề tài có tính mới so với nhiều ứng dụng hiện có: kết hợp chấm phát âm có phân tích thanh điệu, kiểm tra nét viết, hiển thị âm Hán Việt để người Việt dễ ghi nhớ, và có lộ trình học chi tiết để người dùng tự học mà không cần giáo viên.

# **3. MỤC TIÊU ĐỀ TÀI**

## **3.1. Mục tiêu tổng quát**

Xây dựng hệ thống ChaiLish gồm ứng dụng di động hỗ trợ người Việt tự học tiếng Trung (phát âm, thanh điệu, chữ viết và từ vựng) và máy chủ quản lý người dùng, đồng bộ dữ liệu học tập và phân phối nội dung bài học.

## **3.2. Mục tiêu cụ thể**

- Hệ thống cần thực hiện được các nội dung sau:

- Xây dựng lộ trình học có sẵn từ người mới bắt đầu đến HSK 2, chia thành các chặng và bài học, mở khóa lần lượt theo kết quả học.

- Xây dựng bộ từ vựng HSK 1-2 (khoảng 300 từ) kèm Hán tự, pinyin, nghĩa tiếng Việt, âm Hán Việt và câu ví dụ.

- Cho phép người dùng đăng ký, đăng nhập, đăng xuất, quên mật khẩu; tài khoản được quản lý trên server.

- Xây dựng chức năng luyện phát âm tiếng Trung: nghe mẫu bằng TTS, thu âm, nhận dạng giọng nói tiếng Trung và chấm điểm theo phụ âm đầu, vần và thanh điệu.

- Xây dựng chức năng luyện viết Hán tự: xem hoạt ảnh thứ tự nét, tô theo nét mờ, viết tự do và được kiểm tra từng nét.

- Xây dựng trợ lý ôn bài AI: trò chuyện theo chủ đề sau mỗi bài học, có câu trả lời mẫu và phân tích ngữ pháp, chỉ ra lỗi sai trong câu trả lời của người học.

- Xây dựng flashcard ôn tập từ vựng theo thuật toán lặp lại ngắt quãng (SM-2).

- Xây dựng bài kiểm tra ngắn theo dạng đề HSK (nghe, đọc, chọn Hán tự).

- Xây dựng các chức năng tạo động lực: streak, mục tiêu hằng ngày, thống kê, nhắc nhở, gợi ý bài tập theo lỗi hay sai.

- Đồng bộ dữ liệu học tập giữa ứng dụng và server theo hướng offline-first: không có mạng vẫn học được, có mạng thì tự đồng bộ.

- Xây dựng server cung cấp REST API, lưu dữ liệu bằng PostgreSQL, xác thực bằng JWT, mỗi người dùng chỉ truy cập được dữ liệu của mình.

- Bổ sung bảng xếp hạng và huy hiệu để tăng động lực học.

- Đóng gói server bằng Docker, triển khai lên máy chủ có HTTPS và viết kiểm thử tự động cho cả app và server.

# **4. KIẾN TRÚC TỔNG THỂ HỆ THỐNG**

Hệ thống ChaiLish được thiết kế theo mô hình client - server gồm bốn phần chính:

- Ứng dụng di động Flutter (Android).

- Máy chủ API (Backend).

- Cơ sở dữ liệu và lưu trữ.

- Các dịch vụ giọng nói và AI bên ngoài.

## **4.1. Ứng dụng di động Flutter**

Ứng dụng là nơi người học sử dụng hằng ngày. Mã nguồn được tổ chức theo chức năng (mỗi thư mục features là một module do một thành viên phụ trách) và quản lý trạng thái bằng Riverpod.

Ứng dụng đảm nhiệm các chức năng:

- Đăng ký, đăng nhập và lưu token đăng nhập an toàn trên máy.

- Hiển thị bài học HSK, từ vựng, pinyin, nghĩa, âm Hán Việt.

- Thu âm, nhận dạng giọng nói và chấm điểm phát âm, thanh điệu.

- Hiển thị hoạt ảnh thứ tự nét và kiểm tra nét viết Hán tự.

- Flashcard ôn tập, bài kiểm tra ngắn.

- Lưu dữ liệu cục bộ bằng SQLite để học được khi không có mạng.

- Đồng bộ kết quả học tập lên server khi có mạng.

- Hiển thị tiến độ, streak, bảng xếp hạng và gửi thông báo nhắc nhở.

## **4.2. Máy chủ API (Backend)**

Máy chủ được viết bằng Python FastAPI, cung cấp REST API cho ứng dụng di động. Tài liệu API được sinh tự động bằng Swagger (OpenAPI).

Máy chủ đảm nhiệm các chức năng:

- Đăng ký, đăng nhập, cấp và làm mới JWT (access token và refresh token).

- Kiểm tra token ở mỗi yêu cầu, bảo đảm mỗi người dùng chỉ đọc/ghi được dữ liệu của chính mình.

- Nhận và lưu dữ liệu đồng bộ từ ứng dụng: lượt luyện, điểm, streak, thẻ ôn tập.

- Phân phối nội dung bài học theo phiên bản, ứng dụng chỉ tải phần thay đổi. Nội dung do nhóm soạn thành file dữ liệu và nạp vào server bằng script.

- Lưu vị trí của người học trên lộ trình: bài đã hoàn thành, bài đang mở, điểm từng bài.

- Tổng hợp thống kê và bảng xếp hạng.

- Cung cấp API chấm phát âm online: nhận bản ghi âm từ ứng dụng, gọi dịch vụ chấm phát âm (Azure) bằng khóa lưu trên server và trả kết quả về theo định dạng chung.

- Làm trung gian gọi Claude API cho trợ lý ôn bài AI: dựng ngữ cảnh bài học, giới hạn số lượt, ghi nhận chi phí.

- Ghi log truy cập và log lỗi.

## **4.3. Cơ sở dữ liệu và lưu trữ**

Hệ thống dùng hai lớp lưu trữ:

- SQLite trên điện thoại: lưu bài học, kết quả luyện tập và hàng đợi đồng bộ (sync_outbox) để học offline.

- PostgreSQL trên server: lưu tài khoản, lộ trình, nội dung bài học và toàn bộ lịch sử học tập đã đồng bộ.

- Thư mục lưu file (hoặc dịch vụ lưu trữ đối tượng): lưu ảnh đại diện, file âm thanh mẫu và file xuất báo cáo.

Các bảng dữ liệu chính trên server:

| **Bảng** | **Nội dung lưu trữ** |
|:---|:---|
| users | Tài khoản: email, mật khẩu đã băm (bcrypt), họ tên, trạng thái tài khoản, ngày tạo |
| refresh_tokens | Phiên đăng nhập, thời hạn, thiết bị đăng nhập |
| courses, lessons, words | Giáo trình HSK, bài học, từ vựng (Hán tự, pinyin, nghĩa, Hán Việt, ví dụ), số phiên bản nội dung |
| characters | Dữ liệu chữ Hán: số nét, bộ thủ, dữ liệu đường nét dùng cho hoạt ảnh và kiểm tra nét viết |
| attempts | Lượt luyện phát âm: người dùng, từ/câu, chế độ chấm (offline/online), điểm tổng, điểm thanh điệu, thời gian |
| pronunciation_requests | Nhật ký gọi API chấm phát âm online: người dùng, nhà cung cấp, thời lượng âm thanh, thời gian xử lý, trạng thái, chi phí ước tính |
| syllable_results | Kết quả từng âm tiết: phụ âm đầu, vần, thanh điệu đúng/sai |
| writing_attempts | Lượt luyện viết: chữ, số nét sai, số lần gợi ý, điểm |
| srs_cards | Thẻ ôn tập: hệ số dễ, khoảng cách ôn, ngày ôn tiếp theo |
| daily_stats, streaks | Số phút học, số lượt, điểm trung bình theo ngày; streak hiện tại và kỷ lục |
| path_stages, path_nodes | Lộ trình học: các chặng, thứ tự bài trong chặng, điều kiện mở khóa (điểm tối thiểu) |
| user_path_progress | Tiến độ của người học trên lộ trình: bài đã mở, đã hoàn thành, điểm cao nhất, số sao |
| ai_conversations, ai_messages | Phiên trò chuyện với trợ lý AI theo từng bài, nội dung từng lượt, số token sử dụng |
| grammar_feedback | Kết quả phân tích ngữ pháp từng câu trả lời: lỗi, cách sửa, loại lỗi, điểm ngữ pháp liên quan, điểm số |

## **4.4. Dịch vụ giọng nói và AI**

Hệ thống sử dụng các dịch vụ sau:

- Nhận dạng giọng nói của Android với ngôn ngữ zh-CN (miễn phí, chạy mặc định).

- Azure AI Speech - Pronunciation Assessment cho tiếng Trung (zh-CN), chấm trực tiếp từ âm thanh, chính xác hơn chấm offline (gói F0 miễn phí). Chỉ server gọi dịch vụ này, khóa Azure lưu trong biến môi trường trên server, không đưa vào ứng dụng.

- Text-to-Speech tiếng Trung của hệ điều hành để đọc mẫu ở tốc độ thường và chậm.

- Claude API (Anthropic) cho trợ lý ôn bài AI. Chỉ server gọi API này, khóa API được lưu trong biến môi trường trên server, không đưa vào ứng dụng.

## **4.5. Các API chính**

| **Phương thức** | **Đường dẫn** | **Chức năng** |
|:---|:---|:---|
| POST | /api/auth/register | Đăng ký tài khoản |
| POST | /api/auth/login | Đăng nhập, trả về access token và refresh token |
| POST | /api/auth/refresh | Làm mới access token |
| POST | /api/auth/forgot-password | Gửi mã OTP đặt lại mật khẩu qua email |
| GET / PUT | /api/me | Xem và sửa hồ sơ cá nhân, mục tiêu học |
| GET | /api/lessons?since_version= | Tải bài học mới hoặc đã thay đổi |
| POST | /api/sync/push | Gửi các bản ghi học tập chưa đồng bộ |
| GET | /api/sync/pull | Lấy dữ liệu học tập về thiết bị mới |
| GET | /api/leaderboard?period=week | Bảng xếp hạng theo tuần |
| GET | /api/path | Lấy lộ trình học kèm trạng thái mở khóa của người dùng |
| POST | /api/path/nodes/{id}/complete | Ghi nhận hoàn thành bài, mở khóa bài tiếp theo |
| POST | /api/placement-test | Nộp bài kiểm tra đầu vào, xác định điểm bắt đầu trên lộ trình |
| GET | /api/daily-plan | Kế hoạch học hôm nay: bài mới, thẻ cần ôn, chữ cần luyện viết |
| POST | /api/ai/conversations | Bắt đầu phiên trò chuyện ôn bài cho một bài học |
| POST | /api/ai/conversations/{id}/messages | Gửi câu trả lời của người học, nhận câu trả lời tiếp theo của AI (streaming) và kết quả phân tích ngữ pháp |
| GET | /api/ai/conversations/{id} | Xem lại phiên trò chuyện và các lỗi đã được chỉ ra |
| POST | /api/pronunciation/assess | Gửi bản ghi âm (WAV) và câu mẫu, server chấm bằng Azure và trả kết quả theo định dạng chung |
| GET | /api/pronunciation/status | Kiểm tra chấm online có sẵn không và số lượt còn lại hôm nay |

# **5. LUỒNG HOẠT ĐỘNG CHÍNH**

## **5.1. Đăng nhập và đồng bộ dữ liệu**

- Người dùng mở ứng dụng lần đầu, chọn đăng ký hoặc đăng nhập.

- Server kiểm tra thông tin, trả về access token và refresh token.

- Ứng dụng lưu token vào bộ nhớ bảo mật, tải hồ sơ và tải bài học theo phiên bản mới nhất.

- Khi học, mọi kết quả được ghi vào SQLite trước, đồng thời thêm vào hàng đợi đồng bộ.

- Khi có mạng, ứng dụng gửi hàng đợi lên server; server lưu và trả về trạng thái đã nhận.

- Khi đăng nhập trên máy mới, ứng dụng tải lại toàn bộ lịch sử học tập từ server.

## **5.2. Học theo lộ trình**

- Lần đầu sử dụng, người học chọn bắt đầu từ đầu hoặc làm bài kiểm tra đầu vào.

- Hệ thống xác định điểm bắt đầu và hiển thị bản đồ lộ trình.

- Mỗi ngày, trang chủ hiển thị kế hoạch học hôm nay: bài mới, thẻ cần ôn, chữ cần viết lại.

- Người học mở bài tiếp theo, lần lượt học từ mới, luyện phát âm, luyện viết và làm bài ôn.

- Đạt từ 70 điểm trở lên thì bài được đánh dấu hoàn thành và bài tiếp theo được mở khóa.

- Hết mỗi chặng, người học làm bài kiểm tra cuối chặng để chuyển sang chặng mới.

## **5.3. Ôn bài cùng trợ lý AI**

- Học xong một bài, người học bấm Ôn bài cùng AI.

- Ứng dụng gửi yêu cầu lên server; server lấy chủ đề, từ vựng và điểm ngữ pháp người học đã học tới bài này để dựng ngữ cảnh cho AI.

- Server gọi Claude API; AI đóng vai theo chủ đề bài (ví dụ người bán hàng) và mở đầu cuộc trò chuyện.

- Ứng dụng hiển thị câu của AI (Hán tự, pinyin, nghĩa tiếng Việt) và gợi ý câu trả lời mẫu.

- Người học trả lời bằng cách gõ hoặc nói; khi nói, câu trả lời được chấm phát âm như phần luyện phát âm.

- Server trả về câu tiếp theo của AI kèm kết quả phân tích ngữ pháp dạng JSON; ứng dụng hiển thị lỗi sai và cách sửa.

- Kết thúc phiên (khoảng 5-8 lượt), ứng dụng tổng kết điểm, các lỗi ngữ pháp và lưu để gợi ý ôn tập.

## **5.4. Luyện phát âm và thanh điệu**

- Người học chọn bài học, chọn từ hoặc câu cần luyện.

- Ứng dụng hiển thị Hán tự, pinyin, nghĩa và cho nghe mẫu.

- Người học bấm micro và đọc; ứng dụng vừa nhận dạng giọng nói vừa ghi âm.

- Nếu kết nối được server và còn lượt chấm online: ứng dụng gửi bản ghi âm và câu mẫu lên API chấm phát âm; server gọi Azure, chuẩn hóa kết quả và trả về.

- Nếu không có mạng, server lỗi, quá thời gian chờ hoặc hết lượt: ứng dụng tự chuyển sang engine offline trên máy.

- Engine offline: chuỗi Hán tự nhận dạng được chuyển thành pinyin có thanh điệu, căn chỉnh với âm tiết mẫu, chấm phụ âm đầu, vần và thanh điệu.

- Cả hai cách chấm trả về cùng một định dạng kết quả, nên màn hình phản hồi hiển thị giống nhau và ghi rõ đang dùng chế độ nào.

- Màn hình phản hồi hiển thị điểm, tô màu âm tiết sai, chỉ rõ sai thanh nào và đưa mẹo phát âm.

- Kết quả được lưu và đồng bộ lên server.

## **5.5. Luyện viết Hán tự**

- Người học chọn chữ cần luyện, xem hoạt ảnh thứ tự nét.

- Người học tô theo nét mờ, sau đó chuyển sang viết tự do trên khung ô vuông.

- Sau mỗi nét, hệ thống so sánh nét vừa viết với nét chuẩn về vị trí, hướng và hình dạng.

- Nếu viết sai, hệ thống báo lỗi và nhấp nháy nét đúng để gợi ý.

- Viết xong chữ, hệ thống tính điểm dựa trên số nét sai và số lần gợi ý, lưu kết quả.

# **6. CÔNG NGHỆ SỬ DỤNG**

## **6.1. Flutter và Dart**

Flutter được dùng để xây dựng ứng dụng di động vì viết một lần chạy được trên Android và iOS, giao diện đẹp và nhóm đã quen với framework này.

Các thư viện chính:

- flutter_riverpod để quản lý trạng thái.

- sqflite để lưu dữ liệu cục bộ.

- speech_to_text và record để nhận dạng giọng nói, thu âm.

- flutter_tts để đọc mẫu tiếng Trung.

- fl_chart để vẽ biểu đồ thống kê.

- flutter_local_notifications để nhắc học hằng ngày.

- http để gọi REST API; flutter_secure_storage để lưu token.

- CustomPainter của Flutter để vẽ khung luyện viết, hoạt ảnh nét chữ và nhận nét người dùng viết.

## **6.2. Python FastAPI và PostgreSQL**

Lý do chọn FastAPI:

- Viết API nhanh, mã nguồn ngắn gọn.

- Tự sinh tài liệu Swagger để kiểm thử và báo cáo.

- Hỗ trợ kiểm tra dữ liệu đầu vào bằng Pydantic.

- Dễ viết kiểm thử tự động bằng pytest.

Trên server sử dụng:

- SQLAlchemy và Alembic để làm việc với PostgreSQL và quản lý thay đổi CSDL.

- JWT để xác thực, bcrypt để băm mật khẩu.

- Giới hạn số lần đăng nhập sai để chống dò mật khẩu.

## **6.3. Dữ liệu ngôn ngữ và dịch vụ giọng nói**

- CC-CEDICT: từ điển Trung - Anh mở, dùng để tra pinyin cho chuỗi Hán tự nhận dạng được.

- Make Me a Hanzi: bộ dữ liệu mở về thứ tự nét và đường nét của chữ Hán, dùng cho hoạt ảnh và kiểm tra nét viết.

- Danh sách từ vựng HSK: nhóm tự soạn nghĩa tiếng Việt và âm Hán Việt cho từng từ.

- Nhận dạng giọng nói Android (zh-CN), Text-to-Speech tiếng Trung trên ứng dụng.

- Azure AI Speech (zh-CN) cho chấm phát âm online, được gọi qua server.

## **6.4. Claude API (Anthropic)**

Claude API được dùng cho trợ lý ôn bài AI. Server gọi API bằng thư viện Python chính thức của Anthropic.

- Model mặc định: Claude Opus 5.5 cho chất lượng phân tích ngữ pháp tốt nhất; có thể chuyển sang Claude Haiku 5.5 để giảm chi phí chỉ bằng cách đổi cấu hình trên server.

- Structured output: yêu cầu AI trả kết quả phân tích ngữ pháp theo khuôn JSON cố định để ứng dụng hiển thị.

- Streaming: trả câu trả lời của AI về dần để người học không phải chờ lâu.

- Prompt caching: lưu đệm phần hướng dẫn và ngữ cảnh bài học để giảm chi phí và thời gian phản hồi.

## **6.5. Docker và triển khai**

- Docker và Docker Compose để đóng gói server và CSDL.

- Nginx làm reverse proxy, cấu hình HTTPS.

- Triển khai lên VPS hoặc dịch vụ cloud.

- Sao lưu CSDL định kỳ.

## **6.6. GitHub và Trello**

GitHub được dùng để:

- Lưu mã nguồn ứng dụng và server.

- Review code qua Pull Request.

- Chạy kiểm thử tự động bằng GitHub Actions (flutter test, pytest).

Trello được dùng để:

- Phân công công việc.

- Theo dõi tiến độ.

- Quản lý nhiệm vụ nhóm.

# **7. CÁC CHỨC NĂNG CHÍNH**

## **7.1. Đăng ký, đăng nhập và tài khoản**

Ứng dụng cho phép người dùng:

- Đăng ký tài khoản bằng email và mật khẩu.

- Đăng nhập, đăng xuất, tự đăng nhập lại khi mở ứng dụng.

- Quên mật khẩu, đặt lại bằng mã OTP gửi qua email.

- Sửa hồ sơ: họ tên, ảnh đại diện, trình độ, mục tiêu phút học mỗi ngày, giờ nhắc học.

- Đăng nhập trên nhiều thiết bị và giữ nguyên tiến độ học.

## **7.2. Lộ trình học có sẵn**

Lộ trình là trung tâm của ứng dụng, giúp người dùng tự học mà không cần giáo viên:

- Lộ trình đi từ người mới bắt đầu (pinyin, thanh điệu, nét cơ bản) đến HSK 1 rồi HSK 2, chia thành các chặng, mỗi chặng gồm nhiều bài.

- Mỗi bài kết hợp đủ các kỹ năng: học từ mới, luyện phát âm, luyện viết chữ, ôn tập và kết thúc bằng phần trò chuyện ôn bài cùng trợ lý AI.

- Bài được mở khóa lần lượt: đạt tối thiểu 70 điểm mới mở bài tiếp theo; mỗi bài được chấm từ 1 đến 3 sao.

- Người đã biết tiếng Trung có thể làm bài kiểm tra đầu vào để bắt đầu ở chặng phù hợp.

- Mỗi ngày ứng dụng tự lập kế hoạch học theo mục tiêu phút/ngày: bài mới trên lộ trình, thẻ cần ôn và chữ cần luyện viết lại.

- Màn hình bản đồ lộ trình hiển thị bài đã xong, bài đang học, bài còn khóa và phần trăm hoàn thành từng chặng.

## **7.3. Bài học HSK**

Bài học được chia theo cấp độ HSK 1, HSK 2 và theo chủ đề (chào hỏi, gia đình, số đếm, mua sắm...). Mỗi từ vựng hiển thị:

- Hán tự (giản thể).

- Pinyin có dấu thanh điệu.

- Nghĩa tiếng Việt.

- Âm Hán Việt (ví dụ 学习 - học tập) giúp người Việt dễ nhớ.

- Câu ví dụ và nút nghe mẫu.

## **7.4. Luyện phát âm và thanh điệu**

Đây là chức năng cốt lõi của ứng dụng. Hệ thống so sánh lời người học đọc với câu mẫu theo từng âm tiết tiếng Trung:

- Tách mỗi âm tiết thành phụ âm đầu, vần và thanh điệu (ví dụ xué = x + ue + thanh 2).

- Căn chỉnh chuỗi âm tiết người học đọc với chuỗi mẫu bằng thuật toán Levenshtein có trọng số.

- Giảm điểm ít hơn với các cặp người Việt hay nhầm: zh/z, ch/c, sh/s, j/q/x, ü/u, thanh 2/thanh 3.

- Tính điểm Độ chính xác, Độ đúng thanh điệu, Độ đầy đủ, Độ trôi chảy.

- Hiển thị biểu đồ thanh điệu mẫu để người học hình dung cao độ.

Có hai chế độ chấm, ứng dụng tự chọn (người dùng cũng có thể chọn trong Cài đặt):

- Chấm online qua server: khi có kết nối, ứng dụng gửi bản ghi âm lên API chấm phát âm của server. Server gọi Azure chấm trực tiếp từ âm thanh nên chính xác hơn, đặc biệt với thanh điệu. Khóa API chỉ nằm trên server nên không bị lộ khi giải nén file APK; server giới hạn số lượt mỗi người mỗi ngày và xóa bản ghi âm sau khi chấm.

- Chấm offline trên máy: dùng engine so sánh âm tiết ở trên, không cần mạng, không tốn chi phí. Đây là chế độ dự phòng khi mất mạng hoặc hết lượt chấm online.

## **7.5. Luyện viết Hán tự**

Chức năng luyện viết gồm ba chế độ:

- Xem: hoạt ảnh vẽ từng nét theo đúng thứ tự, kèm số nét và bộ thủ.

- Tô: chữ mẫu hiện mờ, người học tô từng nét, hệ thống kiểm tra từng nét.

- Viết tự do: chỉ có khung ô vuông, người học viết từ trí nhớ.

Thuật toán kiểm tra nét: lấy mẫu lại nét người học viết thành các điểm cách đều, so sánh với đường trung tâm của nét chuẩn về điểm đầu, điểm cuối, hướng và khoảng cách trung bình. Nét được chấp nhận nếu sai lệch nhỏ hơn ngưỡng cho phép; viết sai thứ tự hoặc sai hướng sẽ bị báo lỗi.

## **7.6. Flashcard và ôn tập ngắt quãng**

- Từ đã học được tự động thêm vào bộ thẻ ôn tập.

- Các dạng thẻ: nhìn Hán tự chọn nghĩa, nghe âm chọn Hán tự, nhìn pinyin viết Hán tự.

- Người học tự đánh giá mức nhớ; thuật toán SM-2 tính ngày ôn tiếp theo.

- Trang chủ hiển thị số thẻ cần ôn hôm nay.

## **7.7. Trợ lý ôn bài AI**

Sau mỗi bài học, người học trò chuyện với trợ lý AI về chủ đề vừa học:

- AI đóng vai theo tình huống của bài và chỉ dùng từ vựng, ngữ pháp người học đã học tới bài đó.

- Mỗi câu của AI hiển thị Hán tự, pinyin, nút nghe và nút bật/tắt nghĩa tiếng Việt.

- Có câu trả lời mẫu do AI đưa ra để người học tham khảo khi chưa biết trả lời.

- Người học trả lời bằng cách gõ hoặc nói; câu nói được chấm thêm phát âm và thanh điệu.

Sau mỗi câu trả lời, hệ thống phân tích ngữ pháp:

- Tách câu của người học thành các thành phần: chủ ngữ, vị ngữ, tân ngữ, trạng ngữ, lượng từ.

- Đặt câu của người học cạnh câu trả lời mẫu của AI để so sánh.

- Liệt kê từng lỗi: đoạn sai, cách sửa, loại lỗi (trật tự từ, sai lượng từ, thiếu 了, nhầm 不/没...) và giải thích bằng tiếng Việt.

- Cho điểm câu trả lời và gắn với điểm ngữ pháp tương ứng trong bài.

- Lỗi được lưu lại để gợi ý ôn đúng điểm ngữ pháp hay sai.

Để kiểm soát chất lượng và chi phí: server giới hạn số lượt trò chuyện mỗi ngày, giới hạn độ dài câu, chỉ cho AI nói về chủ đề bài học và hiển thị lưu ý phân tích do AI tạo có thể chưa chính xác. Đây là chức năng duy nhất cần kết nối mạng.

## **7.8. Bài kiểm tra ngắn**

- Đề gồm câu nghe, câu đọc hiểu, câu chọn Hán tự đúng và câu điền pinyin.

- Có bài kiểm tra cuối mỗi chặng; đạt yêu cầu mới mở chặng tiếp theo.

- Chấm điểm ngay, hiển thị đáp án và giải thích.

## **7.9. Phản hồi và gợi ý bài tập**

- Tô màu âm tiết đúng/sai, chỉ rõ sai phụ âm đầu, vần hay thanh điệu.

- Mẹo khẩu hình và lỗi người Việt hay gặp cho từng âm.

- Gợi ý bài luyện thêm dựa trên các âm, thanh điệu và chữ hay sai trong lịch sử.

## **7.10. Tiến độ và nhắc nhở**

- Streak, mục tiêu phút học mỗi ngày, vòng tiến độ hôm nay.

- Biểu đồ phút học, điểm trung bình, lịch học 12 tuần.

- Độ chính xác theo từng thanh điệu và từng phụ âm.

- Số chữ Hán đã viết thành thạo, số từ đã thuộc.

- Thông báo nhắc học hằng ngày và nhắc khi sắp mất streak.

## **7.11. Bảng xếp hạng và huy hiệu**

- Mỗi hoạt động học được cộng điểm kinh nghiệm (XP).

- Bảng xếp hạng theo tuần trên toàn hệ thống.

- Huy hiệu khi đạt mốc: 7 ngày liên tiếp, 100 chữ đã viết, hoàn thành HSK 1.

# **8. PHÂN QUYỀN NGƯỜI DÙNG**

Hệ thống phục vụ một nhóm người dùng là người học. Việc phân quyền được thực hiện ở mức dữ liệu trên server.

## **8.1. Người học**

Người học có thể:

- Đăng ký, đăng nhập, sửa hồ sơ và mục tiêu học.

- Làm bài kiểm tra đầu vào, học theo lộ trình có sẵn.

- Học bài, luyện phát âm, luyện viết, ôn flashcard, làm bài kiểm tra cuối chặng.

- Trò chuyện ôn bài với trợ lý AI và xem lại các lỗi ngữ pháp.

- Xem tiến độ, lịch sử, bảng xếp hạng, huy hiệu.

## **8.2. Bảo vệ dữ liệu người dùng**

- Mọi API (trừ đăng ký, đăng nhập, quên mật khẩu) đều yêu cầu access token hợp lệ.

- Server lấy mã người dùng từ token, không tin mã người dùng do ứng dụng gửi lên; mỗi người chỉ đọc và ghi được dữ liệu học tập của chính mình.

- Bảng xếp hạng chỉ hiển thị tên hiển thị và điểm XP, không lộ email hay thông tin cá nhân khác.

- API chấm phát âm online và trợ lý AI được giới hạn số lượt theo từng tài khoản để tránh lạm dụng.

- Mật khẩu được băm bằng bcrypt; khóa Azure và khóa Claude chỉ lưu trên server.

# **9. PHÂN CÔNG CÔNG VIỆC**

Nguyên tắc phân công: tất cả thành viên đều viết code. Vì đây là bài tập lớn môn Phát triển ứng dụng di động, ứng dụng Flutter là phần chính: mỗi người sở hữu trọn một nhóm màn hình và chức năng trong ứng dụng (giao diện, logic, lưu dữ liệu, kiểm thử), chiếm phần lớn khối lượng công việc của người đó. Phần server được chia theo đúng chức năng mỗi người làm trong ứng dụng, để mỗi người làm trọn một chức năng từ ứng dụng đến server. Module được tách theo thư mục để hạn chế xung đột khi gộp code.

Bảng tổng hợp phân công:

<table>
<colgroup>
<col style="width: 21%" />
<col style="width: 27%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr>
<th style="text-align: left;"><strong>Họ và tên</strong></th>
<th style="text-align: left;"><strong>Phần ứng dụng Flutter (phần chính)</strong></th>
<th style="text-align: left;"><strong>Phần server</strong></th>
<th style="text-align: left;"><strong>Nhiệm vụ chính</strong></th>
</tr>
</thead>
<tbody>
<tr>
<td style="text-align: left;"><p>Nguyễn Hồng Phúc</p>
<p>(Nhóm trưởng)</p></td>
<td style="text-align: left;">Thiết kế UI/UX, khung ứng dụng, màn hình trò chuyện với AI, màn hình phân tích ngữ pháp và tổng kết phiên AI</td>
<td style="text-align: left;">Khung server, CSDL PostgreSQL, xác thực JWT, phân quyền, module trợ lý AI (gọi Claude API), Docker và triển khai</td>
<td style="text-align: left;">Thiết kế giao diện và kiến trúc, code lõi server và trọn tính năng trợ lý AI (server, màn hình trò chuyện, màn hình phân tích ngữ pháp), review code, tích hợp</td>
</tr>
<tr>
<td style="text-align: left;">Lê Tuấn Khanh</td>
<td style="text-align: left;">Thu âm, nhận dạng giọng nói zh-CN, TTS tiếng Trung, tra pinyin bằng CC-CEDICT, engine chấm phát âm offline, chọn chế độ chấm online/offline, màn hình luyện phát âm, màn hình phản hồi sau khi chấm phát âm</td>
<td style="text-align: left;">API chấm phát âm online (gọi Azure); API bài học và phân phối nội dung theo phiên bản</td>
<td style="text-align: left;">Code toàn bộ phần giọng nói và luyện phát âm trong ứng dụng, từ thu âm đến màn hình phản hồi</td>
</tr>
<tr>
<td style="text-align: left;">Đinh Thị Hoa</td>
<td style="text-align: left;">Màn hình danh sách bài học, chi tiết bài học, chi tiết từ vựng, flashcard và thuật toán ôn tập SM-2, huy hiệu; soạn mẹo phát âm và bộ dữ liệu kiểm thử engine</td>
<td style="text-align: left;">Định dạng file dữ liệu bài học và script nạp nội dung vào server</td>
<td style="text-align: left;">Code màn hình bài học, flashcard ôn tập và huy hiệu; soạn dữ liệu HSK 1-2 và mẹo phát âm</td>
</tr>
<tr>
<td style="text-align: left;">Chu Hữu Đệ</td>
<td style="text-align: left;">CSDL SQLite, màn hình đăng ký/đăng nhập/hồ sơ/cài đặt, đồng bộ offline-first, thông báo nhắc nhở, bảng xếp hạng, màn hình luyện viết Hán tự, thuật toán kiểm tra nét viết</td>
<td style="text-align: left;">API người dùng, đồng bộ, bảng xếp hạng</td>
<td style="text-align: left;">Code luồng tài khoản, đồng bộ dữ liệu, bảng xếp hạng và trọn chức năng luyện viết Hán tự</td>
</tr>
<tr>
<td style="text-align: left;">Phạm Vũ Ngọc Bảo</td>
<td style="text-align: left;">Bản đồ lộ trình, mở khóa bài, kiểm tra đầu vào, kế hoạch học hằng ngày, bài kiểm tra ngắn, trang chủ, thống kê tiến độ</td>
<td style="text-align: left;">API lộ trình, kế hoạch học, thống kê</td>
<td style="text-align: left;">Code lộ trình học, bài kiểm tra, thống kê; điều phối kiểm thử, làm slide và thuyết trình</td>
</tr>
</tbody>
</table>

## **9.1. Nguyễn Hồng Phúc - Thiết kế giao diện, kiến trúc, lõi server, trợ lý AI**

- Thiết kế UI/UX toàn bộ ứng dụng trên Figma (màu sắc, font, bộ thành phần giao diện dùng chung, luồng màn hình) để cả nhóm code theo.

- Ứng dụng: dựng khung dự án Flutter (cấu trúc thư mục, Riverpod, điều hướng, theme, lớp gọi API dùng chung).

- Ứng dụng: code màn hình trò chuyện ôn bài với AI (bong bóng hội thoại, Hán tự, pinyin, nghĩa, nút nghe, câu trả lời mẫu, trả lời bằng bàn phím hoặc giọng nói qua dịch vụ nhận dạng của Khanh), nhận dữ liệu streaming từ API AI do Phúc viết.

- Ứng dụng: code màn hình hiển thị phân tích ngữ pháp (thành phần câu, so sánh với câu mẫu, danh sách lỗi và cách sửa) và màn hình tổng kết sau phiên trò chuyện với AI.

- Server: dựng khung FastAPI, thiết kế CSDL PostgreSQL và migration Alembic, code API đăng ký, đăng nhập, refresh token, middleware phân quyền.

- Triển khai: viết Dockerfile, Docker Compose, cấu hình Nginx HTTPS, GitHub Actions.

- Server - trợ lý AI: code module gọi Claude API (streaming, prompt caching), dựng ngữ cảnh theo bài học (từ vựng, điểm ngữ pháp đã học), viết hướng dẫn vai trò cho AI theo từng chủ đề.

- Server - trợ lý AI: định nghĩa khuôn JSON phân tích ngữ pháp, kiểm tra và lưu kết quả vào CSDL; giới hạn lượt dùng mỗi người mỗi ngày, ghi nhận token và chi phí.

- Server - trợ lý AI: chuẩn bị bộ câu kiểm thử (câu đúng, câu sai điển hình của người Việt) để đánh giá độ chính xác của phân tích ngữ pháp.

- Kiểm thử: widget test màn hình trò chuyện AI và màn hình phân tích ngữ pháp; test API xác thực và API trợ lý AI.

## **9.2. Lê Tuấn Khanh - Giọng nói và luyện phát âm**

- Ứng dụng: code dịch vụ thu âm và nhận dạng giọng nói zh-CN, xử lý quyền micro, trạng thái đang nghe.

- Ứng dụng: code dịch vụ TTS tiếng Trung (tốc độ thường và chậm), nghe lại bản ghi.

- Ứng dụng: code bộ chuẩn hóa chuỗi nhận dạng (bỏ dấu câu, đổi số sang chữ Hán) và bộ chuyển Hán tự sang pinyin có thanh điệu dựa trên CC-CEDICT, xử lý chữ đa âm và biến điệu thanh 3, chữ 不, 一.

- Ứng dụng: code engine chấm phát âm offline trên máy: tách âm tiết thành phụ âm đầu, vần, thanh điệu; căn chỉnh Levenshtein có trọng số; bảng cặp âm dễ nhầm của người Việt; công thức tính điểm; trả kết quả theo cùng định dạng với API chấm online.

- Ứng dụng: code dịch vụ chọn chế độ chấm: gọi API chấm online khi có mạng, tự chuyển sang engine offline khi mất mạng, lỗi, quá thời gian chờ hoặc hết lượt; ghi âm WAV để gửi lên server.

- Ứng dụng: code màn hình luyện phát âm (nghe mẫu, bấm micro, chuyển sang phản hồi).

- Ứng dụng: code màn hình phản hồi sau khi chấm phát âm (điểm tổng và các điểm thành phần, tô màu âm tiết đúng/sai, bảng so sánh phụ âm đầu - vần - thanh điệu chuẩn với người học đọc, hiển thị mẹo phát âm, nút Luyện ngay với bài tập gợi ý), nhận kết quả từ engine offline hoặc từ API chấm online.

- Server: code API chấm phát âm online: nhận file ghi âm, kiểm tra định dạng và độ dài, gọi Azure Pronunciation Assessment zh-CN bằng khóa lưu trên server, chuyển kết quả sang định dạng chung giống engine offline, xóa file sau khi chấm, giới hạn lượt và ghi nhật ký sử dụng.

- Server: code API bài học, từ vựng, phân phối nội dung theo phiên bản; script nhập dữ liệu CC-CEDICT và Make Me a Hanzi vào CSDL.

- Kiểm thử: unit test cho engine chấm điểm offline (dùng bộ dữ liệu kiểm thử Hoa soạn), chuyển pinyin, biến điệu, chuẩn hóa văn bản, chuyển đổi kết quả Azure; test chuyển chế độ khi mất mạng; widget test màn hình luyện phát âm và màn hình phản hồi.

## **9.3. Đinh Thị Hoa - Bài học, flashcard, huy hiệu và nội dung**

- Ứng dụng: code màn hình danh sách bài học, chi tiết bài học, chi tiết từ vựng.

- Ứng dụng: code flashcard ôn tập: tự thêm từ đã học vào bộ thẻ, các dạng thẻ (nhìn Hán tự chọn nghĩa, nghe âm chọn Hán tự, nhìn pinyin viết Hán tự), hiệu ứng lật thẻ, nút tự đánh giá mức nhớ.

- Ứng dụng: code thuật toán lặp lại ngắt quãng SM-2 (hệ số dễ, khoảng cách ôn, ngày ôn tiếp theo) và màn hình ôn tập hôm nay; cung cấp số thẻ cần ôn cho trang chủ và kế hoạch học của Bảo.

- Ứng dụng: code hệ thống huy hiệu: danh sách huy hiệu và điều kiện đạt (7 ngày liên tiếp, 100 chữ đã viết, thuộc 100 từ, hoàn thành HSK 1...), kiểm tra điều kiện sau mỗi lượt học dựa trên XP, streak và thống kê, màn hình bộ sưu tập huy hiệu và hiệu ứng khi nhận huy hiệu mới.

- Server: thống nhất định dạng file dữ liệu bài học, lộ trình, từ vựng và viết script kiểm tra, nạp nội dung vào server, tăng số phiên bản khi cập nhật.

- Dữ liệu: soạn bộ từ HSK 1-2 (nghĩa tiếng Việt, âm Hán Việt, câu ví dụ).

- Dữ liệu: soạn mẹo phát âm và lỗi người Việt hay gặp cho từng phụ âm đầu, vần, thanh điệu (khẩu hình, cách đặt lưỡi, ví dụ so sánh với âm tiếng Việt), lưu dạng file dữ liệu để màn hình phản hồi của Khanh hiển thị.

- Dữ liệu: soạn bộ dữ liệu kiểm thử engine chấm điểm: các cặp câu mẫu và câu đọc sai điển hình của người Việt (sai thanh 2/3, nhầm zh/z, j/q/x, ü/u, bỏ âm cuối -n/-ng) kèm kết quả mong đợi.

- Kiểm thử: unit test thuật toán SM-2 và điều kiện nhận huy hiệu; widget test cho màn hình bài học, flashcard và huy hiệu; test script nạp dữ liệu.

## **9.4. Chu Hữu Đệ - Tài khoản, đồng bộ, bảng xếp hạng, luyện viết Hán tự**

- Ứng dụng: code CSDL SQLite (tạo bảng, repository đọc/ghi, nâng cấp phiên bản).

- Ứng dụng: code màn hình đăng ký, đăng nhập, quên mật khẩu, hồ sơ cá nhân, cài đặt; lưu token bằng flutter_secure_storage.

- Ứng dụng: code cơ chế đồng bộ offline-first: hàng đợi sync_outbox, gửi khi có mạng, thử lại khi lỗi, tải dữ liệu về máy mới.

- Ứng dụng: code thông báo nhắc học hằng ngày và nhắc sắp mất streak.

- Ứng dụng: code màn hình bảng xếp hạng theo tuần và cách tính XP.

- Ứng dụng: code màn hình luyện viết Hán tự: khung ô vuông, hoạt ảnh thứ tự nét bằng CustomPainter, chế độ tô nét và viết tự do, hiệu ứng báo nét sai và gợi ý nét đúng.

- Ứng dụng: code thuật toán kiểm tra nét viết (lấy mẫu lại nét thành các điểm cách đều, so khớp với đường trung tâm của nét chuẩn, phát hiện sai thứ tự và sai hướng, tính điểm chữ).

- Server: code API hồ sơ người dùng, API đồng bộ push/pull, API quên mật khẩu gửi OTP qua email, API bảng xếp hạng.

- Kiểm thử: test repository SQLite, test đồng bộ khi mất mạng, test tính XP, unit test thuật toán kiểm tra nét viết, widget test màn hình luyện viết, test API người dùng.

## **9.5. Phạm Vũ Ngọc Bảo - Lộ trình học, kiểm tra, tiến độ**

- Ứng dụng: code bài kiểm tra ngắn (nghe, đọc, chọn Hán tự, điền pinyin) và chấm điểm.

- Ứng dụng: code trang chủ, streak, mục tiêu ngày, màn hình thống kê bằng fl_chart.

- Ứng dụng: code màn hình bản đồ lộ trình, logic mở khóa bài, chấm sao, bài kiểm tra đầu vào và kế hoạch học hằng ngày.

- Server: code API lộ trình, tiến độ trên lộ trình, kế hoạch học hằng ngày, thống kê.

- Kiểm thử: unit test tính streak, logic mở khóa bài; điều phối kiểm thử với người dùng thật; làm slide và thuyết trình.

## **9.6. Công việc chung**

- Mỗi thành viên tự viết kiểm thử và tài liệu cho module của mình, tạo Pull Request để người khác review.

- Cả nhóm cùng kiểm thử với tối thiểu 15 người dùng, nhiều giọng nói khác nhau.

- Cả nhóm cùng viết báo cáo cuối kỳ, mỗi người viết phần mình phụ trách.

# **10. KẾT QUẢ MONG ĐỢI**

Sau khi hoàn thành, nhóm mong muốn đạt được các kết quả sau:

- Ứng dụng Android học tiếng Trung chạy ổn định, giao diện tiếng Việt.

- Có bộ từ vựng HSK 1-2 khoảng 300 từ, đầy đủ pinyin, nghĩa và âm Hán Việt.

- Người dùng đăng ký, đăng nhập và đồng bộ dữ liệu được giữa nhiều thiết bị.

- Chấm phát âm có phân tích phụ âm đầu, vần và thanh điệu.

- Luyện viết Hán tự có hoạt ảnh thứ tự nét và kiểm tra từng nét.

- Trợ lý ôn bài AI trò chuyện theo chủ đề bài học, có câu trả lời mẫu và phân tích, chỉ ra lỗi ngữ pháp.

- Flashcard ôn tập theo thuật toán SM-2.

- Lộ trình học hoàn chỉnh từ người mới bắt đầu đến HSK 2, mở khóa bài theo kết quả, có kiểm tra đầu vào và kế hoạch học hằng ngày.

- Server REST API có tài liệu Swagger, quản lý tài khoản người dùng và bảo vệ dữ liệu theo từng tài khoản.

- Hệ thống được đóng gói bằng Docker và triển khai được lên Internet với HTTPS.

- Có kiểm thử tự động cho engine chấm điểm, kiểm tra nét viết và API.

- Kiểm thử với tối thiểu 15 người dùng thật và so sánh kết quả chấm offline với Azure.

# **11. KẾT LUẬN**

Đề tài ChaiLish giúp nhóm xây dựng từ đầu một hệ thống hoàn chỉnh gồm ứng dụng di động và máy chủ, trong đó mọi thành viên đều tham gia lập trình. Thông qua đề tài, nhóm hiểu rõ hơn về thiết kế API, xác thực và phân quyền, đồng bộ dữ liệu offline-first và triển khai server.

Flutter được dùng để xây dựng ứng dụng học tiếng Trung với các chức năng nổi bật là chấm thanh điệu, luyện viết Hán tự, ôn tập ngắt quãng và trợ lý ôn bài AI. FastAPI và PostgreSQL được dùng để quản lý người dùng và dữ liệu học tập; Claude API được dùng cho trò chuyện và phân tích ngữ pháp.

Nhìn chung, hệ thống ChaiLish đáp ứng được yêu cầu của bài tập lớn, có thể demo trực quan và có thể phát triển thêm trong tương lai như mở rộng lên HSK 3-6, nhận dạng chữ viết tay để tra từ, luyện hội thoại tự do với AI bằng giọng nói và phát hành trên iOS.
