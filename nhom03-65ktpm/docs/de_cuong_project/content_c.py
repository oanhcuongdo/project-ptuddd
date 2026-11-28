# -*- coding: utf-8 -*-
"""Nội dung Mục 5–6, tài liệu tham khảo và phụ lục."""

from docx.shared import Cm, Pt

from docx_helpers import ReportBuilder


def add_section_5_6(b: ReportBuilder):
    b.h1("5. KẾ HOẠCH THỰC HIỆN")

    b.h2("5.1. Phương pháp và quy trình")
    b.p(
        "Nhóm áp dụng quy trình phát triển lặp theo tinh thần Scrum rút gọn, phù hợp với quy "
        "mô năm thành viên và thời gian tám tuần. Dự án được chia thành bốn sprint, mỗi sprint "
        "kéo dài hai tuần. Mỗi sprint bắt đầu bằng buổi lập kế hoạch, có kiểm tra tiến độ giữa "
        "sprint và kết thúc bằng buổi review – demo cho cả nhóm."
    )
    b.p("Chu kỳ làm việc hằng tuần được tổ chức như sau:", indent=True)
    for text in (
        "Thứ Hai: họp kế hoạch tuần, chốt đầu việc, người phụ trách và tiêu chí hoàn thành.",
        "Thứ Tư: kiểm tra tiến độ, xử lý vướng mắc và cập nhật rủi ro.",
        "Thứ Sáu: review kết quả, demo phần đã làm, cập nhật bảng công việc và tài liệu.",
        "Cuối sprint: tổng kết, chạy kiểm thử hồi quy, cập nhật backlog và điều chỉnh kế hoạch.",
    ):
        b.bullet(text)
    b.p(
        "Công cụ làm việc gồm GitHub cho mã nguồn và pull request, GitHub Actions cho kiểm "
        "tra tự động, bảng công việc trực tuyến cho backlog, Figma cho thiết kế giao diện, "
        "Supabase Dashboard và Firebase Console cho cấu hình dịch vụ. Quy ước Git gồm nhánh "
        "feature hoặc fix, commit theo tiền tố feat, fix, docs, test, refactor, chore; mọi "
        "thay đổi vào nhánh chính phải qua pull request và có ít nhất một người review."
    )
    b.p(
        "Definition of Done của mỗi đầu việc gồm: chức năng chạy được trên Android và Web; "
        "có kiểm thử cho logic mới; flutter analyze không lỗi; không commit khóa bí mật; tài "
        "liệu liên quan được cập nhật; pull request được review và merge."
    )

    b.h2("5.2. Phân công nhóm")
    b.p(
        "Phân công dựa trên thế mạnh và kinh nghiệm của từng thành viên, đồng thời bảo đảm "
        "mỗi người sở hữu một mảng xuyên suốt từ thiết kế đến kiểm thử. Khối lượng được cân "
        "đối để tránh dồn việc vào một thành viên."
    )
    b.table_caption("Phân công công việc trong nhóm")
    b.table(
        ["Thành viên", "Vai trò", "Phụ trách chính", "Sản phẩm bàn giao", "Khối lượng"],
        [
            [
                "Minh",
                "Nhóm trưởng",
                "Kiến trúc, xác thực, schema/RLS, quản lý tài liệu cốt lõi, review",
                "Sơ đồ kiến trúc, schema, auth, CRUD, review PR",
                "Cao",
            ],
            [
                "Đạt",
                "Thành viên",
                "Giao diện responsive, design system, danh sách/form/dialog, build Web",
                "Component dùng chung, ảnh chụp ba breakpoint, bản Web",
                "Trung bình",
            ],
            [
                "Hạnh",
                "Thành viên",
                "Tag, vị trí vật lý, bản đồ OpenStreetMap, phương án nhập tay",
                "Tag service/UI, màn hình vị trí, bản đồ",
                "Trung bình",
            ],
            [
                "Quân",
                "Thành viên",
                "Chia sẻ quyền, luồng mượn, thông báo và badge",
                "Share dialog, màn hình mượn, thông báo trong ứng dụng",
                "Cao",
            ],
            [
                "Đăng",
                "Thành viên",
                "Gợi ý tài liệu, kiểm thử, CI, đóng gói, báo cáo",
                "Hàm chấm điểm, test plan/report, APK/Web, báo cáo",
                "Cao",
            ],
        ],
        widths=[2.0, 2.3, 6.1, 4.2, 1.4],
        font_size=9.5,
        header_size=9.8,
        align_center=[4],
    )
    b.p(
        "Ngoài phần việc chính, cả nhóm cùng tham gia kiểm thử chéo, viết tài liệu, chuẩn bị "
        "dữ liệu demo và review sản phẩm của nhau. Khi một thành viên bị quá tải, nhóm ưu "
        "tiên điều chuyển các đầu việc độc lập sang người có năng lực phù hợp thay vì dồn "
        "việc vào nhóm trưởng."
    )

    b.h2("5.3. Tiến độ thực hiện")
    b.p(
        "Tiến độ dự kiến được chia theo tuần, gắn với bốn sprint và các cột mốc kiểm tra. "
        "Bảng 13 trình bày nội dung chính, sản phẩm và người phụ trách của từng tuần. Thời "
        "gian có thể điều chỉnh trong phạm vi một tuần dự phòng nhưng không thay đổi thứ tự "
        "ưu tiên P0. Sơ đồ tiến độ tổng quan được minh họa trong Hình 2."
    )
    b.table_caption("Tiến độ thực hiện dự kiến theo tuần")
    b.table(
        ["Tuần", "Thời gian", "Sprint", "Nội dung chính", "Sản phẩm", "Phụ trách"],
        [
            ["1", "16–22/11", "S1", "Khởi động, chốt phạm vi, baseline kiến trúc, schema v1, wireframe, cấu hình môi trường", "Backlog, schema v1, wireframe, kho mã nguồn", "Minh, cả nhóm"],
            ["2", "23–29/11", "S1", "Xác thực Email/Google, đồng bộ users, RLS nền tảng, khung responsive, CI", "Đăng nhập, hồ sơ, skeleton, pipeline", "Minh, Đạt"],
            ["3", "30/11–06/12", "S2", "CRUD tài liệu, form validation, upload/xóa tệp, trang chi tiết, trạng thái lỗi", "Luồng tài liệu cốt lõi", "Minh, Đạt"],
            ["4", "07–13/12", "S2", "Tìm kiếm, lọc danh mục, tag, lưới responsive, kiểm thử widget", "Tìm kiếm/tag, báo cáo test đợt 1", "Hạnh, Đạt"],
            ["5", "14–20/12", "S3", "Chia sẻ viewer/editor, thu hồi quyền, kiểm thử RLS, state machine mượn", "Chia sẻ, borrow service, test RLS", "Quân, Minh"],
            ["6", "21–27/12", "S3", "Màn hình mượn, thông báo/badge, vị trí/bản đồ, gợi ý tài liệu", "Tính năng P1/P2, tích hợp", "Quân, Hạnh, Đăng"],
            ["7", "28/12–03/01", "S4", "Kiểm thử end-to-end, UAT, hiệu năng, rà soát responsive, sửa lỗi", "Bản RC1, báo cáo kiểm thử", "Cả nhóm"],
            ["8", "04–10/01", "S4", "Đóng gói APK/Web, hoàn thiện tài liệu, slide, video demo, tổng duyệt", "Bản phát hành, báo cáo, demo", "Đăng, cả nhóm"],
        ],
        widths=[1.1, 2.1, 1.1, 6.3, 3.6, 1.8],
        font_size=8.9,
        header_size=9.2,
        align_center=[0, 2],
    )
    b.figure(
        "assets/gantt.png",
        "Kế hoạch tiến độ tám tuần theo bốn sprint",
        width_cm=15.4,
    )

    b.h2("5.4. Cột mốc và sản phẩm")
    b.p(
        "Các cột mốc được dùng để kiểm tra tiến độ thay vì chỉ dựa vào cảm nhận. Mỗi cột mốc "
        "có sản phẩm minh chứng và điều kiện đạt rõ ràng; nếu không đạt, nhóm điều chỉnh kế "
        "hoạch ngay trong tuần kế tiếp."
    )
    b.table_caption("Cột mốc thực hiện và điều kiện đạt")
    b.table(
        ["Mốc", "Thời điểm", "Sản phẩm minh chứng", "Điều kiện đạt"],
        [
            ["M0", "16/11/2026", "Kế hoạch sprint, backlog, môi trường phát triển", "Cả nhóm truy cập được kho, chạy được ứng dụng khung"],
            ["M1", "29/11/2026", "Xác thực, schema v1, RLS nền tảng, khung giao diện", "Đăng nhập/đăng xuất đúng; build Android và Web thành công"],
            ["M2", "13/12/2026", "CRUD tài liệu, tệp, tìm kiếm, danh mục, tag", "Luồng P0 chạy end-to-end; kiểm thử widget đạt"],
            ["M3", "27/12/2026", "Chia sẻ, mượn, thông báo, vị trí/gợi ý", "Ma trận quyền đúng; luồng mượn hợp lệ; tích hợp dịch vụ ổn định"],
            ["M4", "03/01/2027", "Bản RC1, báo cáo kiểm thử, danh sách lỗi", "Không còn lỗi nghiêm trọng; P0 đạt 100%; P1 đạt tối thiểu 90%"],
            ["M5", "10/01/2027", "APK, bản Web, báo cáo, slide, video", "Bộ sản phẩm đầy đủ; demo trơn tru; tài liệu khớp mã nguồn"],
        ],
        widths=[1.2, 2.8, 5.5, 6.5],
        font_size=9.6,
        align_center=[0],
    )

    b.h2("5.5. Kế hoạch kiểm thử")
    b.p(
        "Kiểm thử được thực hiện song song với phát triển, không dồn vào cuối dự án. Mỗi "
        "thành viên chịu trách nhiệm kiểm thử phần mình làm; nhóm thực hiện kiểm thử chéo và "
        "kiểm thử tổng thể trước khi phát hành. Dữ liệu kiểm thử gồm bốn tài khoản ở bốn vai "
        "trò, 50–200 tài liệu, 20 tag và các tệp PDF, DOCX, PNG có kích thước khác nhau."
    )
    b.table_caption("Kế hoạch kiểm thử theo loại")
    b.table(
        ["Loại kiểm thử", "Phạm vi", "Cách thực hiện", "Tiêu chí đạt"],
        [
            ["Đơn vị", "Service, hàm chấm điểm gợi ý, state machine mượn, kiểm tra quyền", "flutter test", "Tất cả test đạt; logic chính có test"],
            ["Widget", "Form, danh sách, trạng thái loading/empty/error, responsive", "flutter test", "Test đạt; không tràn layout tại 360/768/1440 px"],
            ["Tích hợp", "Đăng nhập, CRUD, upload, chia sẻ, mượn, thông báo", "integration_test và kiểm thử thủ công", "Luồng chính và luồng lỗi hoạt động đúng"],
            ["Bảo mật/RLS", "Chủ sở hữu, viewer, editor, người ngoài", "Kiểm thử SQL/API với bốn tài khoản", "Từ chối mặc định; không lộ dữ liệu trái phép"],
            ["UAT", "05 sinh viên, 10 kịch bản sử dụng", "Checklist và quan sát", "Tối thiểu 4/5 người dùng hoàn thành không trợ giúp"],
            ["Hiệu năng", "200 tài liệu, tệp 20 MB, gợi ý", "DevTools, log thời gian", "Danh sách dưới 2 giây; gợi ý dưới 300 ms"],
            ["Tĩnh và build", "Mã nguồn, APK, Web", "flutter analyze, CI, build", "0 lỗi analyze; build thành công"],
        ],
        widths=[2.8, 5.2, 4.3, 3.7],
        font_size=9.5,
        header_size=9.8,
    )
    b.p(
        "Các ca kiểm thử bảo mật được thiết kế theo hướng phủ định: người dùng cố truy cập "
        "tài liệu không được chia sẻ, viewer cố sửa, editor cố xóa hoặc chia sẻ tiếp, người "
        "ngoài cố đọc bảng permissions. Kết quả mong đợi là hệ thống từ chối và không trả về "
        "dữ liệu. Đây là bằng chứng quan trọng để đánh giá tính đúng đắn của RLS."
    )

    b.h2("5.6. Quản lý rủi ro")
    b.p(
        "Nhóm nhận diện các rủi ro có khả năng ảnh hưởng đến tiến độ hoặc chất lượng, đồng "
        "thời xác định biện pháp giảm thiểu và người theo dõi. Bảng 16 được rà soát tại mỗi "
        "buổi họp tuần."
    )
    b.table_caption("Danh sách rủi ro và biện pháp giảm thiểu")
    b.table(
        ["Mã", "Rủi ro", "Khả năng / ảnh hưởng", "Biện pháp giảm thiểu"],
        [
            ["R1", "Tích hợp Firebase – Supabase JWT phức tạp, có thể chậm tiến độ", "Cao / Cao", "Làm prototype ngay tuần 1; phương án dự phòng là chuyển sang Supabase Auth và giữ Google OAuth"],
            ["R2", "Cấu hình RLS sai gây lộ dữ liệu", "Trung bình / Cao", "Nguyên tắc từ chối mặc định; kiểm thử bốn vai trò; review chéo mọi policy"],
            ["R3", "Mở rộng phạm vi quá mức", "Cao / Trung bình", "Khóa phạm vi sau tuần 4; mọi thay đổi phải ghi nhật ký và đổi lại ưu tiên"],
            ["R4", "Khối lượng không đều giữa các thành viên", "Trung bình / Trung bình", "Chia đầu việc nhỏ; review chéo; tuần 7 có thời gian dự phòng"],
            ["R5", "Tải tệp lớn hoặc tệp lỗi làm hỏng luồng", "Trung bình / Trung bình", "Giới hạn 20 MB; hiển thị tiến trình; dọn tệp mồ côi; kiểm thử tệp lỗi"],
            ["R6", "Bản đồ hoặc FCM trên Web bị hạn chế", "Trung bình / Trung bình", "Dùng OpenStreetMap không cần khóa; fallback thông báo trong ứng dụng"],
            ["R7", "Tiến độ bị ảnh hưởng bởi kỳ thi và ngày lễ", "Trung bình / Trung bình", "Đưa cột mốc sớm hơn hạn nộp; giữ tuần 7 làm buffer; ưu tiên P0"],
            ["R8", "Mất dữ liệu hoặc thay đổi schema ngoài kiểm soát", "Thấp / Cao", "Migration có phiên bản; sao lưu dữ liệu mẫu; thử trên môi trường staging"],
        ],
        widths=[1.1, 5.1, 3.0, 6.8],
        font_size=9.3,
        header_size=9.5,
        align_center=[0, 2],
    )

    b.h2("5.7. Tiêu chí nghiệm thu")
    b.p(
        "Dự án được coi là hoàn thành khi đáp ứng các tiêu chí chức năng, kỹ thuật và tài "
        "liệu. Bảng 17 trình bày tiêu chí và trọng số đánh giá đề xuất; trọng số có thể điều "
        "chỉnh theo hướng dẫn của giảng viên nhưng không thay đổi bản chất tiêu chí."
    )
    b.table_caption("Tiêu chí nghiệm thu và trọng số đánh giá")
    b.table(
        ["Hạng mục", "Tiêu chí đạt", "Trọng số"],
        [
            ["Chức năng", "100% chức năng P0 hoạt động; tối thiểu 90% P1; P2 có demo nếu hoàn thành", "30%"],
            ["Kiến trúc và mã nguồn", "Phân lớp đúng; không truy vấn DB trong widget; flutter analyze 0 lỗi; review đầy đủ", "20%"],
            ["Giao diện và trải nghiệm", "Responsive tại 360/768/1440 px; đủ trạng thái loading/empty/error; tiếng Việt rõ ràng", "15%"],
            ["Bảo mật dữ liệu", "RLS đúng cho bốn vai trò; không lộ khóa bí mật; phân quyền nhất quán", "10%"],
            ["Kiểm thử", "Kiểm thử đơn vị, widget, tích hợp đạt; CI chạy; UAT tối thiểu 4/5", "10%"],
            ["Tài liệu", "README, kiến trúc, schema/RLS, test report đầy đủ và khớp mã nguồn", "10%"],
            ["Làm việc nhóm", "Tiến độ đúng cột mốc; pull request được review; báo cáo tuần đầy đủ", "5%"],
        ],
        widths=[3.6, 10.6, 1.8],
        font_size=10,
        align_center=[2],
    )
    b.p(
        "Ngoài các tiêu chí trên, sản phẩm phải không còn lỗi nghiêm trọng hoặc lỗi chặn luồng "
        "chính. Các lỗi giao diện nhỏ được phép tồn tại nếu không ảnh hưởng đến chức năng và "
        "được ghi rõ trong báo cáo. Mọi nội dung chưa hoàn thành phải được nêu trung thực "
        "trong phần hạn chế thay vì che giấu."
    )

    b.h2("5.8. Cơ chế theo dõi và báo cáo")
    b.p(
        "Tiến độ được theo dõi qua bảng công việc và lịch sử commit, không chỉ qua báo cáo "
        "miệng. Mỗi thành viên cập nhật trạng thái đầu việc trước buổi họp thứ Sáu; nhóm "
        "trưởng tổng hợp thành báo cáo tuần gồm việc đã làm, việc tiếp theo, vướng mắc và rủi "
        "ro. Báo cáo được lưu trong kho tài liệu để phục vụ đánh giá quá trình."
    )
    b.p(
        "Các chỉ số theo dõi chính gồm: tỷ lệ đầu việc P0 hoàn thành, số pull request đã "
        "merge, số lỗi mở theo mức độ, tỷ lệ kiểm thử đạt và mức độ sẵn sàng của bản build. "
        "Nếu tỷ lệ P0 hoàn thành thấp hơn 80% ở cuối tuần 6, nhóm kích hoạt phương án cắt "
        "giảm P2 và tập trung toàn bộ nguồn lực cho P0, P1."
    )

    b.h1("6. KẾT LUẬN")
    b.p(
        "Đề cương đã tổng hợp ba ứng dụng được phân tích, thiết kế trong học kỳ và lựa chọn "
        "Ứng dụng Quản lý Tài liệu Học tập cho Project cuối kỳ. Quyết định dựa trên bộ tiêu "
        "chí có trọng số, kết quả đánh giá và mức độ phù hợp với yêu cầu học phần. Ứng dụng "
        "không chỉ có giá trị thực tiễn với sinh viên mà còn cho phép nhóm vận dụng nhiều "
        "kiến thức quan trọng về dữ liệu, bảo mật, giao diện đa nền tảng và kiểm thử."
    )
    b.p(
        "Phạm vi dự án được xác định rõ theo ba mức ưu tiên, với sản phẩm tối thiểu gồm xác "
        "thực, quản lý tài liệu, tìm kiếm, tag, chia sẻ quyền, giao diện responsive và kiểm "
        "thử. Các chức năng mượn, thông báo, vị trí và gợi ý được triển khai theo năng lực và "
        "thời gian còn lại. Cách phân mức này bảo đảm dự án có thể hoàn thành trong tám tuần "
        "mà vẫn giữ được chiều sâu kỹ thuật."
    )
    b.p(
        "Kế hoạch thực hiện gồm bốn sprint, phân công theo thế mạnh, kiểm thử song song, quản "
        "lý rủi ro và cơ chế theo dõi hằng tuần. Với các điều kiện đã nêu, dự án có tính khả "
        "thi cao và có thể tạo ra một sản phẩm hoàn chỉnh, có tài liệu, có kiểm thử và có thể "
        "demo trước hội đồng. Nhóm cam kết thực hiện đúng phạm vi, cập nhật thay đổi minh "
        "bạch và báo cáo trung thực kết quả đạt được."
    )

    b.h1("TÀI LIỆU THAM KHẢO")
    refs = [
        "Nhóm 03. (2026). Đặc tả yêu cầu – Ứng dụng Quản lý Tài liệu Học tập (SPEC), phiên bản 2.2. Kho mã nguồn nhóm 03 – 65KTPM.",
        "Nhóm 03. (2026). Đặc tả use case – Ứng dụng Quản lý Tài liệu Học tập, phiên bản 2.2. Kho mã nguồn nhóm 03 – 65KTPM.",
        "Nhóm 03. (2026). Kế hoạch phân công công việc. Kho mã nguồn nhóm 03 – 65KTPM.",
        "Nhóm 03. (2026). Báo cáo hoàn thành dự án Document Management App. Kho mã nguồn nhóm 03 – 65KTPM.",
        "Nhóm 03. (2026). Báo cáo phân tích yêu cầu và giải trình kiến trúc Cashew. Kho mã nguồn nhóm 03 – 65KTPM.",
        "Demizo. (2026). Daily You, phiên bản 3.7.0 [mã nguồn]. GitHub. https://github.com/Demizo/Daily_You.",
        "Nhóm SpeakWell. (2026). Báo cáo SpeakWell – đối chiếu 7 mục checklist. Kho mã nguồn SpeakWell.",
        "Flutter Team. (2026). Flutter documentation. https://docs.flutter.dev.",
        "Supabase. (2026). Row Level Security. https://supabase.com/docs/guides/database/postgres/row-level-security.",
        "Firebase. (2026). Firebase Authentication và Cloud Messaging. https://firebase.google.com/docs.",
        "Sommerville, I. (2016). Software Engineering (10th ed.). Pearson.",
        "Pressman, R. S., & Maxim, B. R. (2020). Software Engineering: A Practitioner's Approach (9th ed.). McGraw-Hill.",
    ]
    for idx, ref in enumerate(refs, start=1):
        p = b.doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.9)
        p.paragraph_format.first_line_indent = Cm(-0.9)
        p.paragraph_format.line_spacing = 1.3
        p.paragraph_format.space_after = Pt(4)
        p.alignment = 0
        run = p.add_run(f"[{idx}]\t{ref}")
        from docx_helpers import _set_run_font
        _set_run_font(run, size=12)

    # ---------------------------------------------------------------- phụ lục
    b.h1("PHỤ LỤC A. CHECKLIST ĐỐI CHIẾU YÊU CẦU")
    b.p(
        "Bảng dưới đây đối chiếu từng yêu cầu của đề bài với nội dung tương ứng trong đề "
        "cương, giúp kiểm tra tính đầy đủ trước khi nộp."
    )
    b.table_caption("Checklist đối chiếu yêu cầu và nội dung đáp ứng")
    b.table(
        ["Yêu cầu", "Nội dung đáp ứng", "Vị trí", "Trạng thái"],
        [
            ["Tổng hợp các ứng dụng đã phân tích, thiết kế trong học kỳ", "Daily You, SpeakWell, Quản lý Tài liệu Học tập; mục tiêu, công nghệ, kết quả, đánh giá", "Mục 2, Bảng 1", "Đạt"],
            ["Lựa chọn một ứng dụng phù hợp", "Bộ tiêu chí có trọng số, bảng điểm, quyết định và lý do", "Mục 3, Bảng 2–3", "Đạt"],
            ["Mục tiêu của dự án", "Mục tiêu tổng quát, 07 mục tiêu cụ thể, mục tiêu học thuật", "Mục 4.2, Bảng 5", "Đạt"],
            ["Phạm vi của dự án", "Phạm vi chức năng P0–P2, ngoài phạm vi, giả định và ràng buộc", "Mục 4.3, Bảng 6", "Đạt"],
            ["Chức năng chính", "10 nhóm chức năng F01–F10 gắn use case và ưu tiên", "Mục 4.4, Bảng 8", "Đạt"],
            ["Kế hoạch thực hiện", "04 sprint, tiến độ 08 tuần, phân công, cột mốc, kiểm thử, rủi ro", "Mục 5, Bảng 12–17", "Đạt"],
            ["Sản phẩm bàn giao", "Mã nguồn, APK, Web, tài liệu, kiểm thử, báo cáo, demo", "Mục 4.7, Bảng 11", "Đạt"],
            ["Kiểm thử và nghiệm thu", "Kế hoạch kiểm thử theo loại, tiêu chí và trọng số nghiệm thu", "Mục 5.5, 5.7", "Đạt"],
            ["Quản lý rủi ro", "08 rủi ro, mức độ và biện pháp giảm thiểu", "Mục 5.6, Bảng 16", "Đạt"],
            ["Hình thức học thuật", "Khổ A4, Times New Roman 13, giãn dòng 1,5, đánh số bảng/hình, mục lục, tài liệu tham khảo", "Toàn bộ", "Đạt"],
        ],
        widths=[4.2, 7.1, 3.1, 1.6],
        font_size=9.4,
        header_size=9.6,
        align_center=[3],
    )

    b.h1("PHỤ LỤC B. MA TRẬN USE CASE – CHỨC NĂNG – PHÂN CÔNG")
    b.p(
        "Ma trận dưới đây liên kết mười lăm use case với nhóm chức năng, sprint triển khai và "
        "người phụ trách. Ma trận được dùng để kiểm tra độ phủ khi lập kế hoạch và khi nghiệm "
        "thu."
    )
    b.table_caption("Ma trận use case – chức năng – sprint – người phụ trách")
    b.table(
        ["Use case", "Tên use case", "Chức năng", "Sprint", "Phụ trách"],
        [
            ["UC-01", "Đăng nhập và đồng bộ người dùng", "F01", "S1", "Minh"],
            ["UC-02", "Thêm tài liệu học tập", "F02", "S2", "Minh"],
            ["UC-03", "Cập nhật tài liệu", "F02", "S2", "Minh"],
            ["UC-04", "Xóa tài liệu và tệp đính kèm", "F02", "S2", "Minh"],
            ["UC-05", "Tìm kiếm, lọc và xem danh sách", "F03", "S2", "Minh"],
            ["UC-06", "Gán tag và lọc theo tag", "F04", "S2", "Hạnh"],
            ["UC-07", "Ghi nhận vị trí và xem bản đồ", "F09", "S3", "Hạnh"],
            ["UC-08", "Chia sẻ quyền truy cập tài liệu", "F05", "S3", "Quân"],
            ["UC-09", "Yêu cầu mượn tài liệu", "F07", "S3", "Quân"],
            ["UC-10", "Nhận thông báo về yêu cầu mượn", "F08", "S3", "Quân"],
            ["UC-11", "Xem gợi ý tài liệu", "F10", "S3", "Đăng"],
            ["UC-12", "Xem chi tiết tài liệu", "F02", "S2", "Minh"],
            ["UC-13", "Điều hướng và trạng thái giao diện", "F06", "S1–S4", "Đạt"],
            ["UC-14", "Đăng xuất", "F01", "S1", "Minh"],
            ["UC-15", "Xem và quản lý thông báo", "F08", "S3", "Quân"],
        ],
        widths=[1.7, 7.2, 2.2, 2.0, 2.9],
        font_size=9.8,
        align_center=[0, 2, 3, 4],
    )
    b.p(
        "Ghi chú: S1–S4 tương ứng bốn sprint trong Mục 5.3. Các use case P0 thuộc S1–S2 phải "
        "hoàn thành trước cột mốc M2; các use case P1 thuộc S3 hoàn thành trước M3; các use "
        "case P2 được kiểm tra tại M4 và chỉ đưa vào demo nếu đạt tiêu chí chất lượng."
    )
