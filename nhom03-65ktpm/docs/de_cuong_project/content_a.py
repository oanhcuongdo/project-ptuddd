# -*- coding: utf-8 -*-
"""Nội dung Mục 1–3: mở đầu, tổng hợp và lựa chọn ứng dụng."""

from docx_helpers import ReportBuilder


def add_section_1_3(b: ReportBuilder):
    # ------------------------------------------------------------------ MỤC 1
    b.h1("1. MỞ ĐẦU", page_break=False)

    b.h2("1.1. Bối cảnh và lý do chọn đề tài")
    b.p(
        "Trong quá trình học tập ở bậc đại học, mỗi sinh viên phải quản lý một khối lượng "
        "lớn tài liệu khác nhau như bài giảng, đề cương ôn tập, bài tập nhóm, tài liệu tham "
        "khảo và các tệp đa phương tiện. Những tài liệu này thường được lưu rải rác trên "
        "điện thoại, máy tính, dịch vụ lưu trữ đám mây hoặc các ứng dụng nhắn tin. Việc phân "
        "tán dữ liệu làm cho sinh viên khó tìm lại tài liệu khi cần, khó chia sẻ có kiểm soát "
        "cho bạn học và dễ bỏ sót tài liệu quan trọng trước mỗi kỳ thi."
    )
    b.p(
        "Trong học kỳ, nhóm đã phân tích và thiết kế ba ứng dụng di động ở các mức độ khác "
        "nhau: Daily You, SpeakWell và Ứng dụng Quản lý Tài liệu Học tập. Mỗi ứng dụng đại "
        "diện cho một hướng tiếp cận riêng về lưu trữ cục bộ, xử lý thuật toán trên thiết bị "
        "và dịch vụ đám mây. Kết quả phân tích cho thấy nhu cầu quản lý tài liệu học tập có "
        "tính thực tiễn cao, phù hợp với mục tiêu của một dự án cuối kỳ và có thể triển khai "
        "trong thời gian giới hạn của học phần."
    )
    b.p(
        "Project cuối kỳ là cơ hội để nhóm chuyển các kết quả phân tích, thiết kế đã thực "
        "hiện thành một sản phẩm phần mềm có thể chạy được, đồng thời vận dụng đầy đủ quy "
        "trình phân tích yêu cầu, thiết kế kiến trúc, lập trình, kiểm thử và đóng gói. Vì "
        "vậy, việc xây dựng một đề cương chi tiết trước khi triển khai là cần thiết để thống "
        "nhất mục tiêu, phạm vi, chức năng và kế hoạch thực hiện giữa các thành viên."
    )

    b.h2("1.2. Mục đích của đề cương")
    b.p(
        "Đề cương này tổng hợp các ứng dụng đã được phân tích, thiết kế trong học kỳ; lựa "
        "chọn một ứng dụng phù hợp để thực hiện Project cuối kỳ; và xác lập kế hoạch triển "
        "khai chi tiết. Đề cương đóng vai trò là tài liệu định hướng cho nhóm trong suốt quá "
        "trình thực hiện, là cơ sở để giảng viên theo dõi tiến độ và là căn cứ để nghiệm thu "
        "sản phẩm cuối kỳ."
    )
    b.p("Các nội dung chính của đề cương gồm:", indent=True)
    for text in (
        "Tổng hợp mục tiêu, công nghệ, kết quả phân tích và mức độ phù hợp của từng ứng dụng.",
        "Lựa chọn ứng dụng theo bộ tiêu chí có trọng số, kèm lý do và điều kiện lựa chọn.",
        "Xác định mục tiêu, phạm vi, tác nhân, chức năng chính và kiến trúc của dự án.",
        "Xây dựng kế hoạch thực hiện theo tuần, phân công nhóm, kế hoạch kiểm thử và quản lý rủi ro.",
        "Xác định sản phẩm bàn giao và tiêu chí nghiệm thu để đánh giá mức độ hoàn thành.",
    ):
        b.bullet(text)

    b.h2("1.3. Phương pháp thực hiện")
    b.p(
        "Đề cương được xây dựng dựa trên phương pháp rà soát tài liệu và phân tích so sánh. "
        "Nhóm đã đọc lại các báo cáo phân tích, đặc tả yêu cầu, đặc tả use case, báo cáo "
        "kiến trúc và mã nguồn hiện có của từng ứng dụng; sau đó chuẩn hóa thông tin theo "
        "cùng một bộ tiêu chí để bảo đảm việc so sánh có căn cứ."
    )
    b.p("Quy trình thực hiện gồm bốn bước:", indent=True)
    b.numbered(1, "Rà soát và tổng hợp các tài liệu, mã nguồn, báo cáo đã có của từng ứng dụng.", "Bước 1 – ")
    b.numbered(2, "Xây dựng bộ tiêu chí lựa chọn, gán trọng số và cho điểm từng ứng dụng theo thang 1–5.", "Bước 2 – ")
    b.numbered(3, "Lựa chọn ứng dụng có điểm cao nhất, xác định phạm vi và mức ưu tiên chức năng.", "Bước 3 – ")
    b.numbered(4, "Phân rã công việc theo tuần, xác định sản phẩm, rủi ro, kế hoạch kiểm thử và tiêu chí nghiệm thu.", "Bước 4 – ")
    b.p(
        "Việc phân tích được giới hạn trong bối cảnh của học phần: nhóm gồm năm thành viên, "
        "thời gian thực hiện dự kiến tám tuần, sử dụng các gói dịch vụ miễn phí của Firebase "
        "và Supabase, thiết bị kiểm thử là điện thoại Android và trình duyệt web trên máy "
        "tính. Các nội dung nằm ngoài giới hạn này sẽ được ghi rõ trong phần phạm vi."
    )

    # ------------------------------------------------------------------ MỤC 2
    b.h1("2. TỔNG HỢP CÁC ỨNG DỤNG ĐÃ PHÂN TÍCH, THIẾT KẾ")

    b.h2("2.1. Cơ sở tổng hợp")
    b.p(
        "Trong học kỳ, nhóm đã thực hiện ba sản phẩm phân tích – thiết kế tương ứng với ba "
        "ứng dụng. Các sản phẩm được lưu trong kho mã nguồn của nhóm, bao gồm báo cáo phân "
        "tích, đặc tả yêu cầu, đặc tả use case, sơ đồ kiến trúc, mô hình dữ liệu, kế hoạch "
        "kiểm thử và mã nguồn tham khảo. Việc tổng hợp dựa trên các tài liệu này thay vì chỉ "
        "dựa trên mô tả giới thiệu, nhờ đó bảo đảm tính nhất quán giữa nhận định và minh chứng."
    )
    b.p(
        "Cần phân biệt hai giai đoạn của Ứng dụng Quản lý Tài liệu Học tập. Giai đoạn đầu "
        "được thiết kế theo kiến trúc Cashew với cơ sở dữ liệu SQLite/Drift, gồm hai bảng và "
        "bốn use case cốt lõi. Giai đoạn sau mở rộng sang kiến trúc đám mây với Firebase và "
        "Supabase, gồm mười hai bảng và mười lăm use case. Đây là hai phiên bản của cùng một "
        "ứng dụng, không phải hai ứng dụng độc lập; đề cương sử dụng phiên bản mở rộng làm "
        "cơ sở chính và kế thừa các nguyên tắc phân lớp của phiên bản Cashew."
    )

    b.h2("2.2. Kết quả phân tích, thiết kế của từng ứng dụng")

    b.h3("2.2.1. Ứng dụng Daily You")
    b.p(
        "Daily You là ứng dụng nhật ký cá nhân mã nguồn mở, hoạt động cục bộ trên thiết bị. "
        "Ứng dụng được viết bằng Flutter, sử dụng SQLite để lưu nhật ký và tệp đa phương tiện, "
        "kết hợp các cơ chế sao lưu, mã hóa và đồng bộ thư mục ngoài. Nhóm đã phân tích trực "
        "tiếp mã nguồn, cấu hình Android và chạy thử bản dựng trên thiết bị ảo."
    )
    b.p(
        "Kết quả phân tích xác định mười hai nhóm tính năng chính, gồm soạn và quản lý nhật "
        "ký, lịch dọc và ký ức, thư viện, thống kê cảm xúc, đa phương tiện, nhắc nhở, sao lưu "
        "có mã hóa, lưu trữ ngoài qua SAF, bảo mật sinh trắc học, nhập xuất dữ liệu, chia sẻ "
        "và giao diện đa ngôn ngữ. Báo cáo cũng đánh giá kiến trúc bốn lớp, cách xử lý tệp "
        "nguyên tử, quy trình sao lưu có kiểm tra toàn vẹn và các hạn chế về đồng bộ nhiều "
        "thiết bị."
    )
    b.p(
        "Giá trị tham khảo của Daily You nằm ở tư duy thiết kế ưu tiên quyền riêng tư, khả "
        "năng hoạt động khi không có mạng và cách tổ chức dữ liệu cục bộ. Tuy nhiên, đây là "
        "sản phẩm mã nguồn mở đã hoàn thiện, không phải thiết kế gốc của nhóm; việc chọn lại "
        "ứng dụng này sẽ khó chứng minh đóng góp cá nhân và không tận dụng được các đặc tả "
        "đã xây dựng."
    )

    b.h3("2.2.2. Ứng dụng SpeakWell")
    b.p(
        "SpeakWell là ứng dụng luyện nói và phát âm tiếng Anh trên thiết bị di động. Ứng dụng "
        "cho phép người học nghe câu mẫu, thu âm, nhận dạng giọng nói và nhận phản hồi về "
        "các âm vị đọc sai. Phần chấm điểm được thiết kế theo hướng chạy trên thiết bị, sử "
        "dụng chuyển chữ sang âm vị theo quy tắc và thuật toán so khớp có trọng số theo đặc "
        "trưng phát âm."
    )
    b.p(
        "Sản phẩm đã có báo cáo đối chiếu bảy mục yêu cầu, mô hình dữ liệu Supabase gồm hồ "
        "sơ và lịch sử luyện, giao diện tiến độ, nhắc nhở hằng tuần và bộ kiểm thử tự động "
        "gồm 105 trường hợp. Điểm mạnh của SpeakWell là quy trình kiểm thử chặt chẽ, thuật "
        "toán minh bạch và khả năng hoạt động khi không có kết nối mạng. Hạn chế chính là "
        "phụ thuộc vào chất lượng nhận dạng giọng nói của thiết bị và phạm vi ứng dụng hẹp, "
        "chỉ phục vụ một kỹ năng ngôn ngữ."
    )
    b.p(
        "Đây là sản phẩm có giá trị tham khảo về kiểm thử và thiết kế thuật toán, nhưng nếu "
        "chọn làm Project cuối kỳ thì nhóm khó mở rộng thêm nhiều chức năng trong tám tuần, "
        "đồng thời việc kiểm chứng chất lượng cần nhiều mẫu giọng nói thực tế – điều kiện "
        "không bảo đảm trong môi trường học phần."
    )

    b.h3("2.2.3. Ứng dụng Quản lý Tài liệu Học tập")
    b.p(
        "Ứng dụng Quản lý Tài liệu Học tập được nhóm thiết kế nhằm giải quyết trực tiếp bài "
        "toán lưu trữ và chia sẻ tài liệu của sinh viên. Ứng dụng hỗ trợ đăng nhập, thêm – "
        "sửa – xóa tài liệu, đính kèm tệp, phân loại theo danh mục và tag, tìm kiếm, xem chi "
        "tiết, chia sẻ quyền xem hoặc chỉnh sửa, gửi yêu cầu mượn tài liệu, nhận thông báo, "
        "ghi nhận vị trí vật lý và gợi ý tài liệu theo sở thích."
    )
    b.p(
        "Phiên bản Cashew ban đầu tập trung vào việc tách biệt giao diện khỏi cơ sở dữ liệu "
        "qua ba lớp: trình diễn, nghiệp vụ và dữ liệu. Phiên bản mở rộng kế thừa nguyên tắc "
        "này, bổ sung Firebase Authentication, Firebase Cloud Messaging, Supabase Postgres, "
        "Supabase Storage, Realtime và Edge Function để đổi token. Hệ thống có mười lăm use "
        "case, mười hai bảng dữ liệu, chính sách Row Level Security và giao diện responsive "
        "cho Android và Web."
    )
    b.p(
        "Đây là ứng dụng duy nhất do nhóm trực tiếp phân tích và thiết kế từ đầu, có đầy đủ "
        "đặc tả yêu cầu, đặc tả use case, sơ đồ kiến trúc, kế hoạch phân công, kế hoạch kiểm "
        "thử và báo cáo triển khai. Các tài liệu này có thể tái sử dụng trực tiếp cho Project "
        "cuối kỳ, giúp giảm thời gian khảo sát lại và tăng tính khả thi."
    )

    b.h2("2.3. Bảng tổng hợp và so sánh")
    b.table_caption("Tổng hợp các ứng dụng đã phân tích, thiết kế trong học kỳ")
    b.table(
        ["Ứng dụng", "Mục tiêu chính", "Công nghệ nổi bật", "Kết quả đã có", "Đánh giá chung"],
        [
            [
                "Daily You",
                "Nhật ký cá nhân cục bộ, bảo vệ dữ liệu riêng tư",
                "Flutter, SQLite, SAF, AES-256-GCM, WorkManager",
                "Báo cáo phân tích mã nguồn, kiến trúc, 12 nhóm tính năng và đánh giá",
                "Sản phẩm tham khảo; không phải thiết kế gốc của nhóm",
            ],
            [
                "SpeakWell",
                "Luyện phát âm tiếng Anh, chấm điểm theo âm vị",
                "Flutter, speech_to_text, G2P, Levenshtein có trọng số, Supabase",
                "Báo cáo 7 mục, 105 kiểm thử, APK và tài liệu thuật toán",
                "Sản phẩm hoàn thiện nhưng phụ thuộc ASR thiết bị, phạm vi hẹp",
            ],
            [
                "Quản lý Tài liệu Học tập",
                "Lưu trữ, tổ chức, chia sẻ và mượn tài liệu học tập",
                "Flutter, Firebase Auth/FCM, Supabase Postgres/Storage/Realtime",
                "SPEC, 15 use case, kiến trúc, schema/RLS, test plan, báo cáo triển khai",
                "Thiết kế gốc của nhóm, đầy đủ vòng đời, phù hợp nhất",
            ],
        ],
        widths=[2.4, 3.2, 3.6, 3.6, 3.2],
        font_size=9.5,
        header_size=9.5,
    )

    b.h2("2.4. Nhận xét chung")
    b.p(
        "Ba ứng dụng đều được phát triển bằng Flutter và hướng tới thiết bị di động, nhưng "
        "khác nhau về miền nghiệp vụ và cách tổ chức dữ liệu. Daily You đại diện cho hướng "
        "lưu trữ cục bộ, ưu tiên quyền riêng tư; SpeakWell đại diện cho hướng xử lý thuật "
        "toán trên thiết bị và kiểm thử chuyên sâu; Quản lý Tài liệu Học tập đại diện cho "
        "hướng ứng dụng nhiều người dùng, có xác thực, phân quyền và dịch vụ đám mây."
    )
    b.p(
        "Xét theo yêu cầu của Project cuối kỳ, ứng dụng Quản lý Tài liệu Học tập có lợi thế "
        "vượt trội vì vừa là thiết kế gốc của nhóm, vừa bao phủ nhiều nội dung kỹ thuật quan "
        "trọng như mô hình dữ liệu quan hệ, bảo mật RLS, lưu trữ tệp, giao diện đa nền tảng "
        "và kiểm thử nhiều tài khoản. Các ứng dụng còn lại phù hợp để tham khảo kỹ thuật "
        "nhưng không phải lựa chọn tối ưu cho việc triển khai trong học phần này."
    )

    # ------------------------------------------------------------------ MỤC 3
    b.h1("3. LỰA CHỌN ỨNG DỤNG CHO PROJECT CUỐI KỲ")

    b.h2("3.1. Tiêu chí lựa chọn")
    b.p(
        "Nhóm xây dựng sáu tiêu chí lựa chọn dựa trên yêu cầu của học phần và điều kiện thực "
        "tế của nhóm. Mỗi tiêu chí được gán trọng số theo mức độ ảnh hưởng đến khả năng hoàn "
        "thành dự án; tổng trọng số bằng 100%. Điểm của từng ứng dụng được cho theo thang "
        "1–5, trong đó 1 là thấp nhất và 5 là cao nhất."
    )
    b.table_caption("Bộ tiêu chí lựa chọn ứng dụng và trọng số")
    b.table(
        ["Tiêu chí", "Trọng số", "Cách đánh giá"],
        [
            [
                "C1. Mức độ phù hợp với yêu cầu học phần",
                "25%",
                "Có đủ nội dung di động, xác thực, dữ liệu, lưu trữ tệp, nhiều người dùng, kiến trúc và kiểm thử",
            ],
            [
                "C2. Mức độ đã phân tích, thiết kế",
                "20%",
                "Số lượng và chất lượng tài liệu, use case, mô hình dữ liệu, khả năng tái sử dụng",
            ],
            [
                "C3. Tính khả thi trong 8 tuần",
                "20%",
                "Độ phức tạp kỹ thuật, phụ thuộc dịch vụ, kỹ năng và số lượng thành viên",
            ],
            [
                "C4. Giá trị thực tiễn",
                "15%",
                "Mức độ giải quyết vấn đề của sinh viên và khả năng sử dụng thực tế",
            ],
            [
                "C5. Khả năng mở rộng và thể hiện kỹ thuật",
                "10%",
                "Cloud, phân quyền, realtime, responsive, thuật toán gợi ý",
            ],
            [
                "C6. Khả năng kiểm thử và đánh giá",
                "10%",
                "Tiêu chí rõ ràng, có thể kiểm thử tự động, có kịch bản demo",
            ],
        ],
        widths=[5.3, 2.0, 8.7],
        font_size=10.5,
        align_center=[1],
    )
    b.p(
        "Điểm tổng hợp của mỗi ứng dụng được tính theo công thức: D = Σ(wᵢ × sᵢ), trong đó "
        "wᵢ là trọng số của tiêu chí thứ i và sᵢ là điểm 1–5 của ứng dụng ở tiêu chí đó. "
        "Cách tính này cho phép so sánh định lượng nhưng vẫn giữ được vai trò của các tiêu "
        "chí quan trọng như mức độ phù hợp và tính khả thi."
    )

    b.h2("3.2. Đánh giá theo tiêu chí")
    b.p(
        "Kết quả cho điểm được trình bày trong Bảng 3. Thứ tự điểm tương ứng với sáu tiêu "
        "chí C1–C6. Daily You đạt điểm cao ở giá trị thực tiễn và khả năng thể hiện kỹ thuật "
        "nhưng thấp ở tính nguyên bản và mức độ phù hợp với yêu cầu xây dựng sản phẩm mới. "
        "SpeakWell có tài liệu và kiểm thử tốt nhưng phụ thuộc điều kiện nhận dạng giọng nói "
        "và khó mở rộng. Quản lý Tài liệu Học tập đạt điểm cao nhất ở hầu hết tiêu chí."
    )
    b.table_caption("Điểm đánh giá các ứng dụng theo bộ tiêu chí")
    b.table(
        ["Ứng dụng", "Điểm C1–C6 (1–5)", "Điểm có trọng số", "Xếp hạng"],
        [
            ["Daily You", "3 / 2 / 2 / 4 / 4 / 4", "2,95", "3"],
            ["SpeakWell", "3 / 4 / 3 / 4 / 4 / 4", "3,55", "2"],
            ["Quản lý Tài liệu Học tập", "5 / 5 / 4 / 5 / 5 / 5", "4,80", "1"],
        ],
        widths=[4.2, 6.4, 3.4, 2.0],
        font_size=10.5,
        align_center=[1, 2, 3],
    )
    b.p(
        "Với Quản lý Tài liệu Học tập, tiêu chí C3 chỉ đạt 4 điểm vì dự án có nhiều thành "
        "phần cần tích hợp như xác thực Firebase, Supabase, lưu trữ tệp, RLS, thông báo và "
        "bản đồ. Đây là rủi ro đã được nhận diện, không phải điểm yếu về ý tưởng. Nhóm sẽ "
        "giảm thiểu bằng cách chia dự án thành bốn sprint, ưu tiên các chức năng bắt buộc "
        "trước và chỉ triển khai các chức năng mở rộng khi còn thời gian."
    )

    b.h2("3.3. Quyết định lựa chọn")
    b.p(
        "Căn cứ kết quả đánh giá, nhóm lựa chọn ứng dụng Quản lý Tài liệu Học tập cho Project "
        "cuối kỳ. Quyết định này dựa trên bốn lý do chính:"
    )
    b.numbered(1, "Ứng dụng là thiết kế gốc của nhóm, có đầy đủ tài liệu từ yêu cầu đến kiểm thử nên bảo đảm tính kế thừa và tính nguyên bản.", "Thứ nhất – ")
    b.numbered(2, "Bài toán quản lý tài liệu học tập có giá trị thực tiễn rõ ràng, phù hợp với đối tượng người dùng là sinh viên.", "Thứ hai – ")
    b.numbered(3, "Dự án bao phủ nhiều kiến thức của học phần: thiết kế dữ liệu, xác thực, phân quyền, lưu trữ, giao diện đa nền tảng và kiểm thử.", "Thứ ba – ")
    b.numbered(4, "Phạm vi có thể điều chỉnh theo mức ưu tiên, bảo đảm vẫn có sản phẩm tối thiểu chạy được nếu thời gian bị thu hẹp.", "Thứ tư – ")
    b.p(
        "Nhóm cũng xác định rõ giới hạn của lựa chọn: dự án không nhằm xây dựng một hệ thống "
        "thương mại quy mô lớn mà tập trung vào một sản phẩm học phần hoàn chỉnh, có kiến "
        "trúc hợp lý, bảo mật dữ liệu cơ bản và quy trình kiểm thử minh bạch. Các chức năng "
        "được chia thành ba mức ưu tiên P0, P1 và P2; trong đó P0 là điều kiện bắt buộc để "
        "nghiệm thu, P1 là mục tiêu hoàn thiện và P2 là phần mở rộng nếu còn thời gian."
    )
    b.p(
        "Việc lựa chọn này cũng đặt ra yêu cầu về kỷ luật thực hiện: nhóm phải khóa phạm vi "
        "sau tuần thứ tư, kiểm soát thay đổi bằng nhật ký quyết định và bảo đảm mọi thành "
        "viên hiểu rõ phần việc của mình. Các nội dung chi tiết được trình bày trong Mục 4 "
        "và Mục 5."
    )
