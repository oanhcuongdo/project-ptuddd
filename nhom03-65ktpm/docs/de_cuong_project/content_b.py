# -*- coding: utf-8 -*-
"""Nội dung Mục 4: đề cương chi tiết dự án."""

from docx_helpers import ReportBuilder


def add_section_4(b: ReportBuilder):
    b.h1("4. ĐỀ CƯƠNG CHI TIẾT DỰ ÁN")

    b.h2("4.1. Thông tin chung")
    b.p(
        "Dự án kế thừa mã nguồn và tài liệu thiết kế đã có, tập trung hoàn thiện các chức "
        "năng còn thiếu, chuẩn hóa kiến trúc, bổ sung kiểm thử và đóng gói sản phẩm. Bảng 4 "
        "tóm tắt các thông tin định danh của dự án."
    )
    b.table_caption("Thông tin chung của dự án")
    b.table(
        ["Hạng mục", "Nội dung"],
        [
            ["Tên đề tài", "Xây dựng ứng dụng Quản lý Tài liệu Học tập trên nền tảng di động"],
            ["Mã dự án", "DCM-03"],
            ["Loại dự án", "Hoàn thiện và mở rộng ứng dụng đã phân tích, thiết kế"],
            ["Nhóm thực hiện", "Nhóm 03 – Lớp 65KTPM, gồm 05 thành viên"],
            ["Học phần", "Phát triển ứng dụng di động"],
            ["Công nghệ", "Flutter và Dart; Firebase Authentication, Cloud Messaging; Supabase Postgres, Storage, Realtime; Edge Function"],
            ["Nền tảng", "Android và Web (ưu tiên Android cho demo chính)"],
            ["Kiến trúc", "Phân lớp theo định hướng Cashew; giao diện – nghiệp vụ – dữ liệu; RLS bảo vệ dữ liệu"],
            ["Thời gian", "08 tuần, từ 16/11/2026 đến 10/01/2027"],
            ["Sản phẩm cuối", "Mã nguồn, APK, bản Web, tài liệu kỹ thuật, báo cáo và bản demo"],
        ],
        widths=[3.4, 12.6],
        font_size=10.5,
        align_center=[],
    )

    b.h2("4.2. Mục tiêu của dự án")
    b.h3("4.2.1. Mục tiêu tổng quát")
    b.p(
        "Xây dựng một ứng dụng di động đa nền tảng giúp sinh viên lưu trữ, tổ chức, tìm kiếm, "
        "chia sẻ và mượn tài liệu học tập một cách thuận tiện, có kiểm soát quyền truy cập và "
        "bảo vệ dữ liệu cá nhân. Thông qua dự án, nhóm vận dụng đầy đủ quy trình phát triển "
        "phần mềm từ phân tích yêu cầu, thiết kế kiến trúc, lập trình, kiểm thử đến đóng gói "
        "và bàn giao sản phẩm."
    )
    b.h3("4.2.2. Mục tiêu cụ thể")
    b.p(
        "Các mục tiêu cụ thể được xây dựng theo nguyên tắc đo lường được, gắn với sản phẩm "
        "đầu ra và thời hạn của từng giai đoạn. Bảng 5 trình bày bảy mục tiêu M1–M7."
    )
    b.table_caption("Mục tiêu cụ thể và kết quả đo lường")
    b.table(
        ["Mã", "Mục tiêu cụ thể", "Kết quả đo lường"],
        [
            [
                "M1",
                "Hoàn thiện xác thực và hồ sơ người dùng bằng Email/Mật khẩu và Google; đồng bộ người dùng sang Supabase; hỗ trợ đăng xuất an toàn.",
                "Đăng nhập, đăng xuất và khôi phục phiên hoạt động đúng; bản ghi users khớp UID Firebase; không lộ phiên khi đăng xuất.",
            ],
            [
                "M2",
                "Hoàn thiện quản lý tài liệu: thêm, sửa, xóa, xem chi tiết, phân loại và đính kèm tệp.",
                "CRUD đầy đủ; tệp tải lên/xuống được; xóa tài liệu xóa cả tệp; tệp tối đa 20 MB; không để bản ghi mồ côi.",
            ],
            [
                "M3",
                "Xây dựng tìm kiếm, lọc theo danh mục và tag; hiển thị danh sách dạng lưới phù hợp từng kích thước màn hình.",
                "Tìm kiếm theo tiêu đề/mô tả; lọc kết hợp danh mục và tag; 200 tài liệu tải dưới 2 giây; có đủ trạng thái loading, empty, error.",
            ],
            [
                "M4",
                "Triển khai chia sẻ tài liệu với quyền người xem và người chỉnh sửa; thu hồi quyền; bảo vệ dữ liệu bằng RLS.",
                "Chủ sở hữu, viewer, editor và người ngoài có hành vi đúng ma trận quyền; kiểm thử bốn vai trò đều đạt; không truy cập trái phép.",
            ],
            [
                "M5",
                "Triển khai luồng mượn tài liệu và thông báo trong ứng dụng.",
                "Trạng thái pending → approved → returned và các nhánh rejected, cancelled hợp lệ; badge chưa đọc đúng; thông báo hiển thị trong ứng dụng.",
            ],
            [
                "M6",
                "Bảo đảm chất lượng đa nền tảng, responsive và kiểm thử.",
                "Không tràn layout tại 360, 768 và 1440 px; flutter analyze không lỗi; kiểm thử tự động đạt; build APK và Web thành công.",
            ],
            [
                "M7",
                "Triển khai các chức năng mở rộng nếu còn thời gian: vị trí vật lý và gợi ý tài liệu.",
                "Lưu và mở lại vị trí; bản đồ hiển thị hoặc có phương án nhập tay; gợi ý có lý do và phản hồi dưới 300 ms với 200 tài liệu.",
            ],
        ],
        widths=[1.3, 8.1, 6.6],
        font_size=9.8,
        header_size=10,
        align_center=[0],
    )

    b.h3("4.2.3. Mục tiêu học thuật")
    b.p("Ngoài mục tiêu sản phẩm, dự án hướng tới các mục tiêu học thuật sau:", indent=True)
    for text in (
        "Vận dụng quy trình phân tích yêu cầu, đặc tả use case và thiết kế kiến trúc vào một sản phẩm cụ thể.",
        "Thực hành thiết kế cơ sở dữ liệu quan hệ, chính sách bảo mật RLS và quản lý tệp trên dịch vụ đám mây.",
        "Rèn luyện kỹ năng lập trình Flutter, tổ chức mã nguồn phân lớp và xây dựng giao diện responsive.",
        "Áp dụng kiểm thử đơn vị, kiểm thử giao diện, kiểm thử tích hợp và kiểm thử bảo mật nhiều tài khoản.",
        "Rèn luyện làm việc nhóm qua Git, pull request, review chéo, quản lý công việc và viết tài liệu kỹ thuật.",
    ):
        b.bullet(text)

    b.h2("4.3. Phạm vi của dự án")
    b.h3("4.3.1. Phạm vi chức năng")
    b.p(
        "Phạm vi được chia theo nhóm chức năng và mức ưu tiên. Mức P0 là bắt buộc đối với "
        "sản phẩm tối thiểu; P1 là mục tiêu hoàn thiện; P2 chỉ thực hiện khi các mục P0 và P1 "
        "đã đạt tiêu chí nghiệm thu. Cách phân mức này giúp nhóm kiểm soát tiến độ và tránh "
        "mở rộng phạm vi quá mức."
    )
    b.table_caption("Phạm vi chức năng và mức ưu tiên")
    b.table(
        ["Nhóm phạm vi", "Nội dung", "Ưu tiên"],
        [
            ["Người dùng và xác thực", "Đăng nhập Email/Mật khẩu, Google; đồng bộ hồ sơ; đăng xuất; khôi phục phiên", "P0"],
            ["Tài liệu và tệp", "Thêm, sửa, xóa, xem chi tiết; danh mục; mô tả; tệp đính kèm tối đa 20 MB; tải xuống", "P0"],
            ["Tổ chức và tìm kiếm", "Tìm theo từ khóa; lọc danh mục; gắn nhiều tag; lọc tag; danh sách lưới", "P0"],
            ["Cộng tác và chia sẻ", "Chia sẻ viewer/editor; thu hồi quyền; RLS; màn hình tài liệu được chia sẻ", "P0"],
            ["Mượn và thông báo", "Yêu cầu mượn; duyệt, từ chối, hủy, trả; thời hạn; badge và thông báo trong ứng dụng", "P1"],
            ["Vị trí và gợi ý", "Ghi vị trí vật lý; bản đồ OpenStreetMap; gợi ý theo tag và lịch sử xem", "P2"],
            ["Nền tảng và chất lượng", "Android và Web; responsive; kiểm thử; CI; đóng gói APK/Web; tài liệu", "P0"],
        ],
        widths=[3.4, 10.2, 2.4],
        font_size=10.3,
        align_center=[2],
    )

    b.h3("4.3.2. Phạm vi ngoài dự án")
    b.p("Các nội dung sau không thuộc phạm vi của Project cuối kỳ:", indent=True)
    for text in (
        "Phát hành ứng dụng iOS native và đưa lên App Store; dự án chỉ build Android và Web.",
        "Trích xuất nội dung, OCR hoặc tìm kiếm toàn văn bên trong tệp PDF, Word hay slide.",
        "Chỉnh sửa cộng tác thời gian thực, chat, bình luận và đồng bộ nhiều người cùng sửa một tệp.",
        "Thanh toán, quảng cáo, gói thuê bao hoặc mô hình kinh doanh.",
        "Trang quản trị hệ thống, kiểm duyệt nội dung và mở chợ tài liệu công khai.",
        "Đồng bộ ngoại tuyến đầy đủ với giải quyết xung đột phức tạp; chỉ ưu tiên trải nghiệm trực tuyến ổn định.",
        "Hạ tầng production quy mô lớn, cân bằng tải, sao lưu đa vùng và cam kết SLA.",
    ):
        b.bullet(text)

    b.h3("4.3.3. Giả định và ràng buộc")
    for text in (
        "Nhóm có năm thành viên, mỗi thành viên dành tối thiểu 10–12 giờ mỗi tuần cho dự án.",
        "Thời gian thực hiện là tám tuần, bao gồm tuần dự phòng cho sửa lỗi và đóng gói.",
        "Sử dụng gói miễn phí của Firebase và Supabase; không phát sinh chi phí hạ tầng.",
        "Thiết bị kiểm thử gồm điện thoại/emulator Android và trình duyệt Chrome trên máy tính.",
        "Dữ liệu minh họa là tài liệu học tập không chứa thông tin cá nhân nhạy cảm.",
        "Mã nguồn và khóa bí mật không được đưa lên kho công khai; cấu hình được tách khỏi mã nguồn.",
    ):
        b.bullet(text)

    b.h2("4.4. Tác nhân và chức năng chính")
    b.h3("4.4.1. Tác nhân")
    b.p(
        "Hệ thống có bốn nhóm tác nhân người dùng và một nhóm hệ thống phụ trợ. Một người "
        "dùng có thể đồng thời là chủ sở hữu ở tài liệu này và là người mượn ở tài liệu khác, "
        "vì vậy quyền được xác định theo từng tài liệu chứ không chỉ theo tài khoản."
    )
    b.table_caption("Tác nhân của hệ thống")
    b.table(
        ["Tác nhân", "Mô tả"],
        [
            ["Khách", "Người mới mở ứng dụng, có thể đăng nhập hoặc dùng chế độ dùng thử ẩn danh ở mức hạn chế."],
            ["Sinh viên (chủ sở hữu)", "Người đã đăng nhập, sở hữu tài liệu; có toàn quyền thêm, sửa, xóa, chia sẻ và theo dõi yêu cầu mượn."],
            ["Người được chia sẻ", "Người được cấp quyền viewer hoặc editor trên một tài liệu cụ thể; không thể chuyển quyền sở hữu."],
            ["Người mượn", "Người gửi yêu cầu mượn, theo dõi trạng thái và trả tài liệu sau khi sử dụng."],
            ["Hệ thống phụ trợ", "Firebase Authentication, Firebase Cloud Messaging, Supabase PostgREST/Realtime/Storage và Edge Function."],
        ],
        widths=[4.2, 11.8],
        font_size=10.5,
    )

    b.h3("4.4.2. Chức năng chính")
    b.p(
        "Mười nhóm chức năng dưới đây bao phủ toàn bộ mười lăm use case đã đặc tả. Mỗi nhóm "
        "được gắn mã F, use case tương ứng và mức ưu tiên để thuận tiện cho việc lập kế hoạch "
        "và kiểm tra tiến độ."
    )
    b.table_caption("Các chức năng chính của ứng dụng")
    b.table(
        ["Mã", "Chức năng", "Mô tả", "Use case", "Ưu tiên"],
        [
            ["F01", "Xác thực và hồ sơ", "Đăng nhập Email/Google, đồng bộ người dùng, khôi phục phiên, đăng xuất", "UC-01, UC-14", "P0"],
            ["F02", "Quản lý tài liệu và tệp", "Thêm, sửa, xóa, xem chi tiết; đính kèm, tải xuống và xóa tệp", "UC-02, 03, 04, 12", "P0"],
            ["F03", "Danh sách, tìm kiếm, lọc", "Tìm theo từ khóa; lọc danh mục; lưới responsive; trạng thái loading/empty/error", "UC-05, UC-13", "P0"],
            ["F04", "Tag và lọc tag", "Tạo, gán, gỡ nhiều tag; lọc kết hợp nhiều tag", "UC-06", "P0"],
            ["F05", "Chia sẻ quyền", "Cấp quyền viewer/editor; đổi quyền; thu hồi; danh sách người được chia sẻ", "UC-08", "P0"],
            ["F06", "Giao diện responsive", "Bottom navigation, navigation rail, lưới nhiều cột, form và dialog thích ứng", "UC-13", "P0"],
            ["F07", "Mượn tài liệu", "Gửi yêu cầu, duyệt, từ chối, hủy, trả; kiểm tra trùng và thời hạn", "UC-09", "P1"],
            ["F08", "Thông báo và badge", "Thông báo trong ứng dụng, badge chưa đọc, đánh dấu đã đọc, mở nhanh tài liệu", "UC-10, UC-15", "P1"],
            ["F09", "Vị trí và bản đồ", "Lưu tọa độ, tên địa điểm, kệ; hiển thị bản đồ; nhập tay khi thiếu quyền", "UC-07", "P2"],
            ["F10", "Gợi ý tài liệu", "Tính điểm theo tag, độ mới và lượt xem; hiển thị lý do gợi ý", "UC-11", "P2"],
        ],
        widths=[1.1, 3.9, 6.9, 2.5, 1.6],
        font_size=9.6,
        header_size=9.8,
        align_center=[0, 3, 4],
    )
    b.p(
        "Luồng sử dụng cơ bản của một tài liệu gồm: người dùng đăng nhập, thêm tài liệu và "
        "tệp đính kèm, gán danh mục và tag, tìm kiếm hoặc lọc để mở chi tiết, sau đó chia sẻ "
        "cho bạn học hoặc gửi yêu cầu mượn. Chủ sở hữu theo dõi yêu cầu, duyệt hoặc từ chối; "
        "người mượn nhận thông báo và trả tài liệu khi hoàn tất. Luồng này được dùng làm kịch "
        "bản demo chính của dự án."
    )

    b.h2("4.5. Kiến trúc và mô hình dữ liệu")
    b.h3("4.5.1. Kiến trúc hệ thống")
    b.p(
        "Ứng dụng được tổ chức theo kiến trúc phân lớp, kế thừa tư tưởng tách biệt giữa giao "
        "diện, nghiệp vụ và dữ liệu của kiến trúc Cashew. Lớp giao diện gồm các trang và "
        "widget Flutter, chịu trách nhiệm hiển thị và tiếp nhận tương tác. Lớp nghiệp vụ gồm "
        "functions.dart, các service và model trung gian, chịu trách nhiệm kiểm tra dữ liệu, "
        "điều phối nghiệp vụ và gọi dịch vụ. Lớp dữ liệu gồm Supabase PostgREST, Storage, "
        "Realtime và các chính sách RLS; Firebase đảm nhận định danh và thông báo. Sơ đồ kiến "
        "trúc tổng thể được trình bày trong Hình 1."
    )
    b.p(
        "Luồng xử lý điển hình bắt đầu từ tương tác của người dùng trên giao diện. Widget "
        "không truy vấn cơ sở dữ liệu trực tiếp mà gọi hàm trong lớp nghiệp vụ. Lớp này xác "
        "thực dữ liệu, gọi service tương ứng và chuyển kết quả về model trung gian. Giao diện "
        "chỉ nhận model trung gian, nhờ đó có thể thay đổi công nghệ lưu trữ mà không phải "
        "viết lại toàn bộ màn hình."
    )
    b.p(
        "Với xác thực, Firebase Authentication trả về ID token. Edge Function kiểm tra token "
        "và đổi thành Supabase JWT để PostgREST áp dụng đúng chính sách RLS. Cách làm này "
        "tránh việc tin tưởng trực tiếp vào mã người dùng gửi lên và bảo đảm quyền truy cập "
        "được xác định ở phía máy chủ. Với thông báo, sự kiện được ghi vào bảng notifications; "
        "FCM gửi thông báo đẩy nếu người dùng đã cấp quyền, còn badge trong ứng dụng vẫn hoạt "
        "động khi không có quyền thông báo."
    )
    b.figure(
        "assets/architecture.png",
        "Kiến trúc tổng thể của ứng dụng Quản lý Tài liệu Học tập",
        width_cm=15.6,
    )
    b.p(
        "Về mặt tổ chức mã nguồn, dự án được chia thành các thư mục pages, widgets, services, "
        "struct và config; mỗi thư mục có trách nhiệm rõ ràng. Cấu hình Supabase và Firebase "
        "được tách khỏi mã nghiệp vụ, cho phép chuyển đổi môi trường phát triển và kiểm thử mà "
        "không sửa giao diện. Cách tổ chức này tạo điều kiện kiểm thử từng lớp độc lập và giảm "
        "rủi ro khi thay đổi dịch vụ bên ngoài."
    )

    b.h3("4.5.2. Mô hình dữ liệu")
    b.p(
        "Cơ sở dữ liệu gồm mười hai bảng, chia thành bốn nhóm: người dùng và phân loại, tài "
        "liệu và tệp, cộng tác và mượn, theo dõi và gợi ý. Bảng 9 tóm tắt các trường chính "
        "và mục đích của từng bảng."
    )
    b.table_caption("Mô hình dữ liệu chính của hệ thống")
    b.table(
        ["Bảng", "Trường chính", "Mục đích"],
        [
            ["users", "id (Firebase UID), email, display_name, avatar_url", "Hồ sơ người dùng và liên kết định danh"],
            ["categories", "id, name", "Phân loại mặc định: Bài giảng, Bài tập, Tham khảo"],
            ["documents", "id, user_id, category_id, title, description, file_url, storage_path, created_at, updated_at", "Thông tin tài liệu và tệp đính kèm"],
            ["tags", "id, name (unique), color", "Nhãn phân loại dùng chung"],
            ["document_tags", "document_id, tag_id", "Quan hệ nhiều – nhiều giữa tài liệu và tag"],
            ["permissions", "document_id, user_id, role, granted_by", "Quyền viewer/editor được chia sẻ"],
            ["borrow_requests", "id, document_id, requester_id, owner_id, status, message, requested_at, responded_at, due_date", "Luồng yêu cầu mượn và trạng thái"],
            ["notifications", "id, user_id, type, title, body, document_id, is_read, created_at", "Thông báo trong ứng dụng"],
            ["document_locations", "document_id (unique), latitude, longitude, place_name, shelf, note", "Vị trí vật lý của tài liệu"],
            ["document_views", "id, document_id, user_id, viewed_at", "Lịch sử xem phục vụ gợi ý"],
            ["user_interests", "user_id, tag_id, weight", "Trọng số sở thích theo tag"],
            ["device_tokens", "user_id, token, platform", "Token FCM theo thiết bị"],
        ],
        widths=[3.1, 7.1, 5.8],
        font_size=9.5,
        header_size=9.8,
    )
    b.p(
        "Các bảng đều bật Row Level Security. Nguyên tắc chung là từ chối mặc định: người "
        "dùng chỉ đọc được tài liệu của mình hoặc tài liệu được chia sẻ hợp lệ; chỉ chủ sở "
        "hữu được xóa và thay đổi quyền; người được chia sẻ ở mức viewer chỉ đọc, mức editor "
        "được cập nhật nhưng không được xóa hoặc chia sẻ tiếp. Các bảng phụ trợ như "
        "document_tags, document_locations và user_interests kế thừa quyền từ tài liệu hoặc "
        "người dùng tương ứng."
    )

    b.h3("4.5.3. Ràng buộc kiến trúc")
    for text in (
        "Widget trong thư mục pages và widgets không chứa câu truy vấn cơ sở dữ liệu trực tiếp.",
        "Mọi thao tác dữ liệu phải đi qua functions.dart và lớp service tương ứng.",
        "Giao diện chỉ làm việc với model trung gian trong thư mục struct, không phụ thuộc entity của thư viện dữ liệu.",
        "Mọi bảng dữ liệu người dùng phải bật RLS; không có bảng nào được phép truy cập công khai ngoài phạm vi thiết kế.",
        "Khóa bí mật, service role key và cấu hình môi trường không được commit lên kho mã nguồn.",
        "Mọi thay đổi schema phải đi kèm migration và được review trước khi áp dụng lên môi trường dùng chung.",
        "Kiến trúc phải được bảo vệ bằng kiểm thử tự động để tránh vi phạm phân lớp khi dự án mở rộng.",
    ):
        b.bullet(text)

    b.h2("4.6. Yêu cầu phi chức năng")
    b.p(
        "Các yêu cầu phi chức năng được xác định gắn với cách kiểm chứng cụ thể, tránh mô tả "
        "chung chung. Bảng 10 tổng hợp các yêu cầu chính."
    )
    b.table_caption("Yêu cầu phi chức năng và cách kiểm chứng")
    b.table(
        ["Nhóm", "Yêu cầu", "Cách kiểm chứng"],
        [
            ["Đa nền tảng", "Cùng một mã nguồn chạy được trên Android và Web.", "Build APK, build Web; chạy thử các luồng chính trên hai nền tảng."],
            ["Responsive", "Không tràn layout tại 360, 768 và 1440 px; điều hướng phù hợp.", "Widget test, ảnh chụp ba kích thước, kiểm tra thủ công."],
            ["Hiệu năng", "Danh sách 200 tài liệu tải dưới 2 giây; gợi ý dưới 300 ms; thông báo trong 10 giây.", "Đo bằng DevTools, log thời gian và dữ liệu mẫu."],
            ["Bảo mật", "RLS cho mọi bảng; kiểm tra token; không lộ khóa bí mật.", "Kiểm thử bốn vai trò; rà soát kho mã nguồn; kiểm tra biến môi trường."],
            ["Độ tin cậy", "Lỗi mạng có thông báo và nút thử lại; upload thất bại không tạo bản ghi mồ côi.", "Kiểm thử tình huống mất mạng, tệp quá lớn, upload bị hủy."],
            ["Khả dụng", "Có trạng thái loading, empty, error; thông báo tiếng Việt rõ ràng.", "Kiểm thử giao diện và đánh giá người dùng."],
            ["Bảo trì", "Phân lớp rõ; flutter analyze không lỗi; tài liệu kiến trúc và schema đầy đủ.", "Review mã nguồn, chạy analyze, đọc tài liệu."],
            ["Kiểm thử", "Có kiểm thử đơn vị, widget, tích hợp; CI chạy tự động.", "Pipeline GitHub Actions và báo cáo kiểm thử."],
        ],
        widths=[2.9, 8.1, 5.0],
        font_size=9.8,
        header_size=10,
    )

    b.h2("4.7. Sản phẩm bàn giao")
    b.p(
        "Sản phẩm bàn giao không chỉ là mã nguồn mà còn bao gồm tài liệu, kiểm thử và hướng "
        "dẫn tái lập. Điều này bảo đảm giảng viên có thể đánh giá cả quá trình lẫn kết quả, "
        "đồng thời thành viên mới có thể tiếp tục phát triển dự án."
    )
    b.table_caption("Danh mục sản phẩm bàn giao")
    b.table(
        ["Mã", "Sản phẩm", "Hình thức", "Tiêu chí hoàn thành"],
        [
            ["D1", "Mã nguồn ứng dụng", "Kho GitHub, nhánh nhóm, pull request", "Tái lập được; không chứa khóa bí mật; lịch sử commit rõ ràng"],
            ["D2", "Bản cài Android", "Tệp APK", "Cài và chạy các luồng P0 trên thiết bị/emulator"],
            ["D3", "Bản Web", "Thư mục build hoặc liên kết host", "Chạy trên Chrome; responsive tại ba kích thước"],
            ["D4", "Tài liệu kỹ thuật", "README, kiến trúc, schema, RLS, hướng dẫn cài đặt", "Đầy đủ, nhất quán với mã nguồn"],
            ["D5", "Hồ sơ kiểm thử", "Kế hoạch, test case, báo cáo kết quả, cấu hình CI", "Có minh chứng chạy test và kết quả"],
            ["D6", "Báo cáo và demo", "Báo cáo DOCX/PDF, slide, video demo", "Nộp đúng hạn; demo được luồng chính"],
            ["D7", "Hướng dẫn tái lập", "README và SETUP_GUIDE", "Thành viên mới chạy được trong 30 phút"],
        ],
        widths=[1.2, 4.4, 4.8, 5.6],
        font_size=9.8,
        header_size=10,
        align_center=[0],
    )
    b.p(
        "Mỗi sản phẩm bàn giao đều có người chịu trách nhiệm chính và được kiểm tra chéo bởi "
        "một thành viên khác. Trước khi nộp, nhóm thực hiện rà soát theo danh mục kiểm tra "
        "gồm: build thành công, không lỗi analyze, không lộ bí mật, tài liệu khớp mã nguồn và "
        "dữ liệu minh họa sạch."
    )
