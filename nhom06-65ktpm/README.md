> **Đề tài cuối kỳ hiện hành (15/11/2026): HealthyLife — Trợ lý kỷ luật và lối sống lành mạnh**, nâng cấp bài ứng dụng kỷ luật cá nhân (chủ đề 6 bên dưới).
>
> - [Đề tài chi tiết, cấu trúc, kế hoạch và quy trình Git](src/README.md)
> - [Danh sách và phân công thành viên](danhsachnhom.md)
> - [Báo cáo Word theo mẫu](docs/HealthyLife_Nhom06_De_cuong.docx)
>
> Hiện là đề cương và khung Flutter, chưa viết chức năng. Các báo cáo StudyHub là bản cũ, không phải đề tài đang thực hiện.

# Nhóm 06 — 65KTPM
Yêu cẩu của project cuối kỳ: Sinh viên cần xây dựng một đề cương chi tiết cho Project cuối kỳ dựa trên các ứng dụng đã được phân tích và thiết kế trong suốt học kỳ. Đề cương phải thể hiện rõ mục tiêu, phạm vi, các chức năng chính và kế hoạch thực hiện của Project. Sản phẩm cuối cùng sẽ là một bản đề cương hoàn chỉnh, trình bày rõ ràng, logic và có tính khả thi.
- Tổng hợp các ứng dụng đã phân tích, thiết kế trong học kỳ
- Lựa chọn một ứng dụng phù hợp để làm Project cuối kỳ
- Xây dựng đề cương chi tiết: mục tiêu, phạm vi, chức năng chính, kế hoạch thực hiện


Nhóm đã từng làm những chủ đề sau:
1. Xây dựng Ứng dụng Quản lý Chi tiêu dựa trên mã nguồn Cashew có sẵn: link github https://github.com/jameskokoska/Cashew
Trong bài tập này, sinh viên sẽ thực hiện triển khai và tùy chỉnh ứng dụng quản lý chi tiêu từ dự án mã nguồn mở Cashew trên GitHub. Nhiệm vụ yêu cầu bạn phải thiết lập môi trường phát triển, chạy ứng dụng thành công và thực hiện một số thay đổi về giao diện hoặc tính năng theo yêu cầu. Đây là cơ hội để bạn làm quen với việc đọc hiểu codebase thực tế và quy trình deploy ứng dụng.
Checklist yêu cầu của chủ đề này:
- Fork và Clone mã nguồn dự án Cashew từ GitHub về máy cá nhân
- Cài đặt các phụ thuộc (dependencies) và cấu hình môi trường theo hướng dẫn trong file README
- Khởi chạy ứng dụng trên local và kiểm tra các chức năng cơ bản (thêm/sửa/xóa chi tiêu)
- Thực hiện tùy chỉnh ít nhất một tính năng hoặc thay đổi giao diện (UI) để cá nhân hóa ứng dụng
- Đóng gói sản phẩm và gửi link GitHub repository cùng ảnh chụp màn hình kết quả

2. TH1: Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew
Nhiệm vụ của sinh viên là thiết kế và triển khai một ứng dụng quản lý tài liệu học tập (như lưu trữ bài giảng, bài tập, tài liệu tham khảo) áp dụng đúng các nguyên lý của kiến trúc Cashew. Sinh viên cần tập trung vào việc phân tách các lớp xử lý, đảm bảo tính mô-đun hóa và khả năng mở rộng của hệ thống. Sản phẩm cuối cùng bao gồm mã nguồn hoàn chỉnh và tài liệu mô tả sơ đồ kiến trúc.
Checklist yêu cầu của chủ đề này:
- Phân tích yêu cầu chức năng và thiết kế sơ đồ luồng dữ liệu cho ứng dụng quản lý tài liệu.
- Thiết lập cấu trúc thư mục và phân lớp hệ thống theo đúng tiêu chuẩn của kiến trúc Cashew.
- Triển khai các chức năng cốt lõi: Thêm, sửa, xóa và tìm kiếm tài liệu học tập.
- Kiểm thử tính đúng đắn của việc phân tách logic giữa các lớp trong kiến trúc.
- Đóng gói mã nguồn và viết báo cáo giải trình về cách áp dụng kiến trúc Cashew vào dự án.

3. Phát triển Ứng dụng Quản lý Tài liệu Đa nền tảng với Flutter, Firebase và Supabase
Sinh viên thực hiện nâng cấp ứng dụng Quản lý Tài liệu bằng cách tích hợp hệ sinh thái Cloud để quản lý người dùng và dữ liệu. Nhiệm vụ yêu cầu triển khai xác thực Google qua Firebase, lưu trữ tệp tin vật lý và quản lý cơ sở dữ liệu quan hệ thông qua Supabase. Trọng tâm của bài tập là xây dựng cơ chế phân quyền truy cập, cho phép chia sẻ tài liệu an toàn giữa các người dùng và kiểm thử tính toàn vẹn của dữ liệu trên nhiều tài khoản khác nhau.
Checklist yêu cầu của chủ đề này:
- Thiết lập dự án Firebase và tích hợp chức năng đăng nhập bằng tài khoản Google cho ứng dụng Flutter.
- Xây dựng cấu trúc lưu trữ file trên Firebase Storage và kết nối với bảng quản lý thông tin tài liệu trên Supabase.
- Thiết kế cơ sở dữ liệu trên Supabase bao gồm các bảng: Người dùng, Tài liệu, và Quyền chia sẻ (Permissions).
- Triển khai chức năng tìm kiếm, cập nhật thông tin tài liệu và tính năng chia sẻ tài liệu cho người dùng khác.
- Thiết lập chính sách bảo mật (Row Level Security - RLS) trên Supabase để phân quyền truy cập tài liệu.
- Tiến hành kiểm thử (Testing) luồng hoạt động của ứng dụng bằng ít nhất 3 tài khoản người dùng khác nhau để xác minh quyền hạn.

4. TH2: Phát triển Hệ thống Quản lý Tài liệu Đa nền tảng
Sinh viên thực hiện xây dựng một ứng dụng quản lý tài liệu chạy trên nhiều nền tảng sử dụng Flutter, kết hợp sức mạnh của Firebase và Supabase. Hệ thống yêu cầu triển khai các tính năng nâng cao như gắn thẻ (tagging), định vị tài liệu (location), cơ chế chia sẻ/mượn tài liệu giữa người dùng và thuật toán gợi ý tài liệu phù hợp. Mục tiêu là tạo ra một giải pháp lưu trữ thông minh, có khả năng tương tác cao và quản lý dữ liệu thời gian thực.
Checklist yêu cầu của chủ đề này:
- Thiết kế kiến trúc hệ thống và mô hình dữ liệu kết hợp giữa Firebase (Authentication/Messaging) và Supabase (Database/Storage).
- Xây dựng giao diện người dùng đa nền tảng bằng Flutter, đảm bảo tính đáp ứng (responsive) cho Mobile và Web.
- Triển khai tính năng phân loại tài liệu bằng Tag và tích hợp bản đồ/vị trí để quản lý vị trí vật lý của tài liệu.
- Xây dựng luồng nghiệp vụ cho phép người dùng yêu cầu mượn và chia sẻ quyền truy cập tài liệu cho người khác.
- Phát triển thuật toán Recommendation đơn giản để gợi ý tài liệu dựa trên sở thích hoặc tag của người dùng.
- Kiểm thử toàn diện các tính năng và đóng gói sản phẩm.

5. Xây dựng và Việt hóa ứng dụng Daily You từ mã nguồn có sẵn: link github https://github.com/Demizo/Daily_You.git
Nhiệm vụ của bạn là triển khai một ứng dụng hoàn chỉnh dựa trên mã nguồn (source code) được cung cấp. Sau khi ứng dụng chạy ổn định, bạn cần thực hiện chuyển đổi toàn bộ giao diện và nội dung hiển thị sang tiếng Việt. Mục tiêu là đảm bảo ứng dụng hoạt động mượt mà và mang lại trải nghiệm người dùng thuần Việt, chính xác về thuật ngữ chuyên môn.
Checklist yêu cầu của chủ đề này:
- Thiết lập môi trường phát triển và cài đặt các thư viện cần thiết từ source code
- Build và chạy ứng dụng thành công trên máy cục bộ (localhost)
- Rà soát toàn bộ các tệp ngôn ngữ, giao diện (UI) và thông báo hệ thống
- Thực hiện dịch và thay thế toàn bộ nội dung tiếng Anh sang tiếng Việt
- Kiểm tra lại toàn bộ chức năng để đảm bảo việc thay đổi ngôn ngữ không gây lỗi hiển thị hoặc vận hành

6. Xây dựng ứng dụng kỷ luật cá nhân với Flutter
Nhiệm vụ yêu cầu sinh viên xây dựng hoàn chỉnh một ứng dụng di động giúp theo dõi và quản lý thói quen hàng ngày nhằm rèn luyện kỷ luật cá nhân. Sinh viên cần áp dụng các kiến thức về Flutter bao gồm UI/UX cơ bản, quản lý state, lưu trữ dữ liệu cục bộ và tích hợp các widget tương tác.
Checklist yêu cầu của chủ đề này:
- Thiết kế giao diện người dùng với màn hình danh sách thói quen, màn hình thêm/sửa thói quen và màn hình thống kê tiến độ
- Cài đặt tính năng thêm, xóa, sửa thói quen với các thuộc tính như tên, mô tả, tần suất và thời gian nhắc nhở
- Triển khai hệ thống đánh dấu hoàn thành thói quen hàng ngày với giao diện trực quan
- Lưu trữ dữ liệu thói quen sử dụng SQLite hoặc SharedPreferences để dữ liệu không bị mất khi tắt ứng dụng
- Xây dựng màn hình thống kê hiển thị tỷ lệ hoàn thành thói quen theo ngày, tuần và tháng

7. TH3: Xây dựng ứng dụng học tiếng Anh với tính năng phân tích phát âm AI
Sinh viên cần xây dựng một ứng dụng học tiếng Anh hoàn chỉnh với hai tính năng chính: (1) tính kỷ luật như nhắc nhở luyện tập hàng ngày, theo dõi chuỗi ngày luyện tập (streak), thống kê tiến độ học tập; (2) phân tích và chấm điểm phát âm tiếng Anh bằng AI, so sánh phát âm của người dùng với phiên âm chuẩn và đưa ra gợi ý cải thiện. Ứng dụng cần có giao diện thân thiện và lưu trữ dữ liệu người dùng.
Checklist yêu cầu của chủ đề này:
- Thiết kế cơ sở dữ liệu để lưu trữ thông tin người dùng, lịch sử luyện tập và kết quả phân tích phát âm
- Xây dựng tính năng theo dõi tiến độ học tập: đếm số ngày luyện tập liên tiếp (streak), thống kê thời gian học, đặt mục tiêu hàng ngày
- Tích hợp API nhận dạng giọng nói (speech recognition) để thu âm và xử lý phát âm của người dùng
- Sử dụng mô hình AI hoặc thuật toán so sánh âm vị (phoneme comparison) để phân tích độ chính xác phát âm và chấm điểm
- Xây dựng module phản hồi: hiển thị điểm số, đánh dấu các âm thanh phát âm sai, đề xuất bài tập cải thiện
- Tạo hệ thống thông báo nhắc nhở luyện tập hàng ngày và giao diện hiển thị tiến độ học tập
- Kiểm thử ứng dụng với nhiều người dùng và các giọng nói khác nhau để đảm bảo độ chính xác của phân tích AI