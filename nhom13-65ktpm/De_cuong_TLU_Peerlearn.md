# ĐỀ CƯƠNG ĐỀ TÀI BÀI TẬP LỚN: TLU PEERLEARN

**Tên đề tài:** Xây dựng ứng dụng di động hỗ trợ tổ chức hoạt động học tập cộng tác giữa sinh viên, tích hợp AI trong tạo nội dung ôn tập.  
**Tên tiếng Anh:** Development of an AI-powered Collaborative Learning Mobile Application.

---

## Định hướng kiến trúc và nghiệp vụ cốt lõi

Hệ thống được thiết kế theo hướng tập trung hóa nghiệp vụ và tối ưu phạm vi ứng dụng trí tuệ nhân tạo. AI không tham gia vào các tác vụ quản lý hành chính như ghép nhóm, lập kế hoạch hay viết báo cáo, mà chỉ đảm nhận duy nhất một vai trò chuyên biệt: **sử dụng tài liệu học tập được chia sẻ trong phòng học để tạo bộ thẻ ghi nhớ (Flashcard) và câu hỏi trắc nghiệm (Quiz)**.

Trọng tâm sản phẩm xoay quanh ba trụ cột chính:
* **Kết nối Mentor – Mentee** thông qua cơ chế gợi ý tự động và tương tác chủ động (gửi/nhận lời mời kết nối), đồng thời tổ chức hoạt động hỗ trợ học tập bám sát chương trình của nhà trường.
* **Xây dựng không gian Phòng học tập (Study Room)** thống nhất để các thành viên chia sẻ tài liệu, cùng học tập và ôn luyện.
* **Ứng dụng AI** để chuyển hóa tài liệu thành học liệu ôn tập (kèm cơ chế kiểm duyệt trước khi phát hành), sau đó thống kê kết quả từng bài và tổng hợp tiến độ học tập dựa trên dữ liệu làm bài thực tế.

---

## 1. Mô tả tổng quan sản phẩm

**TLU PeerLearn** là ứng dụng di động hỗ trợ triển khai chương trình *"TLU Đồng hành học tập – Sinh viên hỗ trợ sinh viên"*.

Ứng dụng cho phép sinh viên đăng ký tham gia chương trình theo từng học phần với vai trò **Mentor** (người hỗ trợ) hoặc **Mentee** (người cần hỗ trợ). Dựa trên thông tin đăng ký, hệ thống tự động tính toán độ phù hợp và đề xuất danh sách kết nối tiềm năng. Sinh viên có thể chủ động tạo **Phòng học tập (Study Room)**, gửi lời mời kết nối hoặc xin tham gia phòng phù hợp, đồng thời mời thêm các thành viên khác cùng học phần vào phòng để mở rộng nhóm học tập.

Bên trong mỗi phòng học, các thành viên cùng xây dựng kho tài liệu chung (PDF, DOCX) và sử dụng AI để trích xuất nội dung thành các bộ Flashcard và Quiz phục vụ ôn tập. Hệ thống đồng thời hỗ trợ Mentor lập kế hoạch các buổi hỗ trợ, điểm danh, ghi nhận nội dung đã hướng dẫn và tải lên minh chứng thực tế. Mentee có thể tham gia làm bài ôn tập và tự xác nhận tham gia buổi học trên tài khoản cá nhân. Cán bộ phụ trách (Admin) được cung cấp giao diện giám sát tối giản trên thiết bị di động để theo dõi số liệu tổng quan và kiểm tra trực tiếp nhật ký, minh chứng các buổi học.

### Luồng nghiệp vụ tổng thể
Mô hình hoạt động tổng thể của hệ thống gồm hai luồng nghiệp vụ vận hành song song:
1. **Luồng 1 – Kết nối và tổ chức hoạt động hỗ trợ học tập:**
   Đăng ký Mentor/Mentee theo học phần $\rightarrow$ Hệ thống đề xuất kết nối phù hợp $\rightarrow$ Tạo Phòng học tập, gửi/chấp nhận lời mời kết nối & mời thêm thành viên $\rightarrow$ Lập kế hoạch học tập $\rightarrow$ Tổ chức buổi học, ghi nhận nội dung, điểm danh & tải lên minh chứng (Mentee tự xác nhận tham gia song song) $\rightarrow$ Admin theo dõi và hậu kiểm minh chứng trên di động.
2. **Luồng 2 – Học liệu, ôn tập và đánh giá kết quả:**
   Chia sẻ tài liệu (PDF, DOCX) trong phòng $\rightarrow$ Kho tài liệu chung $\rightarrow$ Trích xuất văn bản & gọi AI tạo Flashcard / Quiz $\rightarrow$ Mentor kiểm duyệt và phát hành $\rightarrow$ Thành viên tham gia ôn tập và làm bài $\rightarrow$ Thống kê từng bài $\rightarrow$ Thống kê tổng hợp theo phòng và cá nhân.

---

## 2. Mục tiêu đề tài

### 2.1. Mục tiêu tổng quát
Xây dựng ứng dụng di động hỗ trợ kết nối sinh viên có nhu cầu học tập với sinh viên có năng lực chuyên môn thông qua cơ chế gợi ý thông minh, tạo môi trường học tập cộng tác theo nhóm, quản lý minh chứng hoạt động hỗ trợ và ứng dụng trí tuệ nhân tạo để tự động tạo nội dung ôn tập từ tài liệu học tập được chia sẻ.

### 2.2. Mục tiêu cụ thể

| Mã | Mục tiêu cụ thể |
| :--- | :--- |
| **OBJ-01** | Xây dựng hệ thống xác thực tài khoản và phân quyền người dùng (Sinh viên, Admin); cho phép một sinh viên linh hoạt đảm nhận vai trò Mentor hoặc Mentee ở các học phần khác nhau. |
| **OBJ-02** | Xây dựng chức năng đăng ký tham gia chương trình theo học phần và cài đặt thuật toán gợi ý kết nối Mentor – Mentee phù hợp. |
| **OBJ-03** | Xây dựng chức năng tạo Phòng học tập (Study Room), gửi lời mời kết nối, chấp nhận tham gia và mời thêm thành viên mở rộng nhóm. |
| **OBJ-04** | Xây dựng kho học liệu chung trong từng phòng, hỗ trợ tải lên, phân loại và trích xuất văn bản trực tiếp trên ứng dụng từ tài liệu PDF, DOCX. |
| **OBJ-05** | Tích hợp AI (LLM API) tạo flashcard và câu hỏi trắc nghiệm từ tài liệu được lựa chọn, kèm cơ chế kiểm duyệt nội dung trước khi phát hành. |
| **OBJ-06** | Xây dựng chức năng học flashcard, làm bài trắc nghiệm trực tuyến, chấm điểm tự động và thống kê chi tiết theo từng bài ôn tập. |
| **OBJ-07** | Tổng hợp kết quả học tập và mức độ tham gia của các thành viên trong phòng học và toàn chương trình. |
| **OBJ-08** | Quản lý kế hoạch, lịch học, nội dung, điểm danh, xác nhận tham gia và lưu trữ minh chứng từng buổi hỗ trợ của Mentor. |
| **OBJ-09** | Cung cấp giao diện giám sát (Dashboard) tối giản trên di động để Admin theo dõi số liệu tổng quan và kiểm tra minh chứng hoạt động. |

---

## 3. Phạm vi đề tài và Giới hạn kỹ thuật

### 3.1. Phạm vi chức năng

**Trong phạm vi (In-Scope):**
* Quản lý tài khoản và hồ sơ sinh viên.
* Quản lý danh mục chương trình và học phần.
* Đăng ký tham gia vai trò Mentor/Mentee theo từng học phần.
* Thuật toán gợi ý kết nối Mentor – Mentee và cơ chế gửi/nhận lời mời tham gia Phòng học tập.
* Tạo phòng học tập, quản lý thành viên, mời thêm thành viên bằng mã phòng hoặc mã sinh viên/email.
* Chia sẻ, lưu trữ, quản lý và trích xuất văn bản từ tài liệu trong phòng.
* Sử dụng AI tạo flashcard và câu hỏi trắc nghiệm từ tài liệu được chọn; kiểm duyệt và chỉnh sửa trước khi công bố.
* Học flashcard, làm bài ôn tập trắc nghiệm, chấm điểm tự động và lưu kết quả.
* Thống kê kết quả từng bài và tổng hợp theo người học, phòng học.
* Quản lý lịch học, buổi học, nội dung hướng dẫn, điểm danh, xác nhận tham gia của Mentee và minh chứng của Mentor.
* Giao diện Admin tối giản trên mobile phục vụ theo dõi thống kê cơ bản và kiểm tra thông tin, minh chứng các buổi học.

**Ngoài phạm vi (Out-of-Scope):**
* AI chatbot giải đáp mọi câu hỏi tự do.
* AI tự động ghép nhóm áp đặt (không thông qua sự đồng ý của sinh viên) hoặc Admin ghép nhóm thủ công.
* AI tự động lập kế hoạch và viết báo cáo buổi học.
* Tính năng gửi đánh giá/chấm điểm chất lượng buổi học.
* Video call và livestream.
* OCR tài liệu scan, nhận diện chữ viết tay từ hình ảnh.
* Tự huấn luyện mô hình AI.
* Tích hợp trực tiếp cơ sở dữ liệu quản lý đào tạo của nhà trường.

### 3.2. Phạm vi ứng dụng AI
AI chỉ được sử dụng duy nhất trong module tạo nội dung ôn tập theo quy trình:

`Tài liệu trong phòng học tập` $\rightarrow$ `Trích xuất văn bản trên ứng dụng` $\rightarrow$ `Gửi yêu cầu đến LLM API qua Edge Function` $\rightarrow$ `Trả về JSON Flashcards & Quiz` $\rightarrow$ `Mentor kiểm duyệt & phát hành` $\rightarrow$ `Thành viên làm bài & Hệ thống thống kê`

AI **không** trực tiếp chấm điểm, **không** đánh giá tiến độ hay quyết định kết quả học tập. Toàn bộ các chỉ số thống kê đều do hệ thống xử lý bằng truy vấn dữ liệu thực tế từ kết quả làm bài.

### 3.3. Giới hạn kỹ thuật đối với tài liệu (Phục vụ kiểm thử và Demo)
Để đảm bảo tính ổn định trong phạm vi đồ án, tránh tràn bộ nhớ thiết bị khi trích xuất văn bản trên client và không vượt quá giới hạn ngữ cảnh (Context Window) của AI API, hệ thống áp dụng các ràng buộc kỹ thuật sau:

| Tiêu chí giới hạn | Quy định áp dụng |
| :--- | :--- |
| **Định dạng tệp hỗ trợ** | Chỉ hỗ trợ 2 định dạng văn bản phổ biến là `.pdf` (tệp PDF có lớp văn bản, không hỗ trợ tệp scan dạng ảnh) và `.docx`. |
| **Giới hạn dung lượng tệp** | Tối đa **5 MB / tệp**. |
| **Số lượng tệp mỗi lần tạo đề** | Tối đa **2 tệp** cho mỗi yêu cầu AI sinh nội dung ôn tập. |
| **Độ dài văn bản trích xuất** | Hệ thống chỉ trích xuất tối đa **15.000 ký tự đầu tiên** (tương đương khoảng 8–10 trang tài liệu chuẩn) để gửi tới AI API nhằm đảm bảo thời gian phản hồi nhanh và ổn định khi demo. |

---

## 4. Chức năng chính của hệ thống

Hệ thống được tổ chức thành **7 module** nghiệp vụ liên kết chặt chẽ để bao quát đầy đủ luồng hoạt động và tối ưu hóa việc triển khai trên thiết bị di động:

### Module 1. Quản lý tài khoản và Đăng ký chương trình (`ACC – Account Management`)

| Mã | Chức năng | Mô tả chi tiết |
| :--- | :--- | :--- |
| **ACC-01** | Đăng ký tài khoản | Tạo tài khoản sinh viên mới bằng email nhà trường hoặc email cá nhân. |
| **ACC-02** | Đăng nhập | Xác thực tài khoản và phân quyền truy cập (Sinh viên / Admin). |
| **ACC-03** | Quản lý hồ sơ | Cập nhật thông tin sinh viên: Họ tên, mã sinh viên, khoa, lớp, số điện thoại, ảnh đại diện. |
| **ACC-04** | Đăng ký vai trò Mentor | Chọn học phần muốn hỗ trợ, nhập điểm tổng kết học phần đó, mô tả thế mạnh kiến thức, số lượng Mentee tối đa có thể nhận và chọn khung lịch rảnh trong tuần. |
| **ACC-05** | Đăng ký vai trò Mentee | Chọn học phần cần hỗ trợ, mô tả chủ đề/kiến thức đang gặp khó khăn và chọn khung lịch rảnh trong tuần. |
| **ACC-06** | Quản lý đăng ký | Xem danh sách các học phần đã đăng ký, chỉnh sửa lịch rảnh hoặc hủy đăng ký khi chưa tham gia phòng. |

### Module 2. Gợi ý kết nối và Quản lý Phòng học tập (`ROM – Matching & Study Room`)

Hệ thống hợp nhất khái niệm *Nhóm hỗ trợ* và *Phòng học tập* thành một thực thể thống nhất là **Phòng học tập (Study Room)** để tránh chồng chéo dữ liệu và nghiệp vụ. Việc kết nối được thực hiện thông qua cơ chế gợi ý tự động kết hợp tương tác chủ động của người dùng:

* **2.1. Gợi ý kết nối tự động (Smart Recommendation):**
  * Dựa trên thông tin đăng ký ở Module 1, hệ thống chạy thuật toán tính điểm tương đồng để hiển thị danh sách **Mentor được gợi ý** cho Mentee (kèm mức độ phù hợp theo tỷ lệ `%` và số khung giờ trùng nhau), và ngược lại hiển thị danh sách **Mentee đang cần hỗ trợ** cho Mentor.
* **2.2. Tạo phòng học tập và Kết nối thành viên:**
  * **Tạo phòng học tập:** Mentor tạo phòng học tập gắn với một học phần cụ thể, đặt tên phòng, mô tả mục tiêu học tập và thiết lập trạng thái phòng (Mở nhận yêu cầu hoặc Riêng tư chỉ qua lời mời).
  * **Gửi lời mời kết nối (Mentor $\rightarrow$ Mentee):** Từ danh sách Mentee được hệ thống gợi ý hoặc tìm kiếm theo mã sinh viên/email, Mentor gửi lời mời tham gia phòng.
  * **Gửi yêu cầu tham gia (Mentee $\rightarrow$ Mentor/Phòng):** Từ danh sách Mentor được gợi ý hoặc danh sách phòng đang mở cùng học phần, Mentee gửi yêu cầu xin gia nhập phòng.
  * **Chấp nhận kết nối & Mở rộng nhóm:** Khi người nhận bấm **Chấp nhận (`Accepted`)**, người dùng chính thức trở thành thành viên của phòng. Trong suốt quá trình học tập, Mentor (và các thành viên nếu được cấp quyền) có thể tiếp tục mời thêm sinh viên khác tham gia phòng thông qua **Mã phòng (Room Code)** hoặc tìm kiếm tài khoản trên hệ thống.
* **2.3. Quản lý thành viên và Phân quyền trong phòng:**

| Vai trò trong phòng | Quyền hạn chi tiết |
| :--- | :--- |
| **Mentor (Chủ phòng)** | Quản lý thông tin phòng, duyệt/mời/xóa thành viên, quản lý tài liệu, tạo và kiểm duyệt nội dung ôn tập AI, lập kế hoạch buổi học, điểm danh và gửi minh chứng. |
| **Mentee (Thành viên)** | Xem và tải tài liệu, học Flashcard, làm bài Quiz, xem thống kê cá nhân/phòng, xem lịch học và tự xác nhận tham gia buổi học. |
| **Admin (Giám sát viên)** | Xem thông tin tổng quan phòng học, danh sách thành viên, kết quả ôn tập và nhật ký minh chứng các buổi học. |

  > *Lưu ý:* Một tài khoản sinh viên có thể tham gia nhiều phòng học khác nhau với các vai trò linh hoạt (ví dụ: làm Mentor trong phòng *Cơ sở dữ liệu* và đồng thời làm Mentee trong phòng *Lập trình Java*).
* **2.4. Không gian hoạt động trong phòng:**
  * Hiển thị danh sách thành viên, kho tài liệu chung, danh sách bộ Flashcard, danh sách bài Quiz đã phát hành, lịch buổi học sắp tới và dòng hoạt động gần đây của phòng.

### Module 3. Quản lý và Chia sẻ tài liệu (`DOC – Document Management`)

Mỗi phòng học sở hữu một kho tài liệu riêng biệt phục vụ cho việc lưu trữ học liệu và làm nguồn dữ liệu đầu vào cho AI:

* **3.1. Các chức năng chính:**
  * Tải lên tài liệu định dạng `.pdf` và `.docx` (dung lượng $\le 5\text{MB}$).
  * Xem danh sách tài liệu, thông tin người tải lên, thời gian tải lên và dung lượng tệp.
  * Tìm kiếm tài liệu theo tên tệp hoặc lọc theo chủ đề/chương học.
  * Tải tài liệu về thiết bị cá nhân để xem ngoại tuyến.
  * Xóa hoặc cập nhật mô tả tài liệu (theo quyền chủ phòng hoặc người tải lên).
  * Trích xuất văn bản trực tiếp trên ứng dụng di động khi người dùng chọn tài liệu để tạo nội dung ôn tập AI.
* **3.2. Cấu trúc thông tin tài liệu:**

| Trường dữ liệu | Mô tả |
| :--- | :--- |
| `document_id` | Mã định danh duy nhất của tài liệu. |
| `room_id` | Mã phòng học chứa tài liệu. |
| `file_name` | Tên hiển thị của tài liệu. |
| `file_url` | Đường dẫn lưu trữ tệp trên Supabase Storage. |
| `file_type` | Định dạng tệp (`pdf` hoặc `docx`). |
| `file_size` | Kích thước tệp (tính theo byte, kiểm tra giới hạn $\le 5\text{MB}$). |
| `topic` | Chủ đề hoặc chương kiến thức phân loại. |
| `uploaded_by` | ID người dùng tải tài liệu lên. |
| `uploaded_at` | Thời điểm tải lên. |

### Module 4. AI Tạo nội dung ôn tập (`AI – Learning Content Generation`)

Đây là module trọng tâm thể hiện việc ứng dụng trí tuệ nhân tạo có kiểm soát vào hỗ trợ học tập:

* **4.1. Tạo bộ Flashcard (`AI-01`):**
  * **Đầu vào:** Người dùng chọn 1 đến 2 tài liệu trong phòng, nhập chủ đề trọng tâm (tùy chọn), chọn số lượng thẻ (5–20 thẻ) và mức độ khó (Cơ bản / Trung bình / Nâng cao).
  * **Xử lý:** Ứng dụng trích xuất văn bản thô từ tài liệu đã chọn (giới hạn tối đa 15.000 ký tự), gửi qua Supabase Edge Function tới Gemini API với cấu trúc JSON Schema định sẵn.
  * **Đầu ra mỗi thẻ:** Mặt trước (Câu hỏi/Thuật ngữ), Mặt sau (Đáp án/Định nghĩa), Giải thích bổ sung, Chủ đề và Độ khó.
* **4.2. Tạo câu hỏi trắc nghiệm Quiz (`AI-02`):**
  * **Đầu vào:** Người dùng chọn 1 đến 2 tài liệu nguồn, số lượng câu hỏi (5–20 câu), mức độ khó và chủ đề muốn kiểm tra.
  * **Xử lý:** Edge Function gửi nội dung văn bản kèm prompt chuẩn hóa tới LLM API để sinh bộ câu hỏi trắc nghiệm 4 lựa chọn (`A, B, C, D`).
  * **Đầu ra mỗi câu hỏi:** Nội dung câu hỏi, danh sách 4 phương án lựa chọn, chỉ mục đáp án đúng, lời giải thích chi tiết tại sao đúng/sai, chủ đề và độ khó.
* **4.3. Kiểm duyệt và Quản lý nội dung AI tạo ra (`AI-03`):**
  * Toàn bộ nội dung do AI sinh ra mặc định ở trạng thái **Bản nháp (`Draft`)**, chỉ hiển thị với người tạo (Mentor).
  * Mentor xem trước toàn bộ danh sách thẻ/câu hỏi, có thể **chỉnh sửa** nội dung câu hỏi, sửa đáp án, sửa giải thích hoặc **xóa** các câu hỏi chưa chính xác.
  * Sau khi kiểm tra xong, Mentor nhấn **Phát hành (`Published`)** để công bố bộ Flashcard/Quiz cho tất cả thành viên trong phòng cùng ôn tập.
  * Hệ thống lưu lại liên kết tới các tài liệu nguồn đã dùng để tạo bộ đề.

### Module 5. Làm bài và Thống kê kết quả (`PRA – Practice & Analytics`)

* **5.1. Học Flashcard (`PRA-01`):**
  * Hiển thị giao diện thẻ lật 2 mặt trực quan (chạm để lật xem đáp án và giải thích).
  * Cho phép người học đánh dấu trạng thái từng thẻ: **"Đã nhớ"** hoặc **"Chưa nhớ / Cần ôn lại"**.
  * Hỗ trợ chế độ lọc chỉ ôn lại các thẻ *"Chưa nhớ"* và hiển thị thanh tiến độ số thẻ đã thuộc của cá nhân.
* **5.2. Làm bài trắc nghiệm Quiz (`PRA-02`):**
  * Người học bắt đầu làm bài, chọn đáp án cho từng câu hỏi và nhấn nộp bài.
  * Hệ thống tự động đối chiếu với đáp án đã lưu trong cơ sở dữ liệu để chấm điểm ngay lập tức.
  * Hiển thị chi tiết kết quả: Điểm số (thang điểm 10), số câu đúng/sai, đáp án đúng và phần giải thích cho từng câu; lưu toàn bộ lịch sử các lần làm bài.
* **5.3. Thống kê kết quả từng bài Quiz (`PRA-03`):**
  * Tổng số lượt làm bài của cả phòng, điểm trung bình và điểm cao nhất.
  * Danh sách kết quả làm bài của từng thành viên trong phòng.
  * **Tỷ lệ trả lời đúng theo từng câu hỏi:** Giúp Mentor nhận diện chính xác câu hỏi hoặc chủ đề kiến thức nào có nhiều Mentee trả lời sai nhất để tập trung giải đáp trong buổi học tiếp theo.
* **5.4. Thống kê tổng hợp (`PRA-04`):**
  * **Cấp độ cá nhân:** Tổng số bài Quiz đã làm, điểm trung bình tích lũy, số bộ Flashcard đã hoàn thành.
  * **Cấp độ phòng học:** Tiến độ hoàn thành các bài ôn tập của từng thành viên, điểm trung bình chung của phòng và thống kê các chủ đề kiến thức còn yếu.

### Module 6. Quản lý hoạt động hỗ trợ và Minh chứng buổi học (`SES – Tutoring Session Management`)

Module này quản lý hoạt động tương tác trực tiếp/trực tuyến giữa Mentor và Mentee, tách biệt với hoạt động tự ôn tập trên hệ thống:

* **6.1. Lập kế hoạch và Quản lý lịch học (`SES-01`):**
  * Mentor tạo kế hoạch dự kiến cho phòng học (số buổi dự kiến, nội dung từng buổi).
  * Mentor tạo lịch cho từng buổi học cụ thể: Tiêu đề buổi học, thời gian bắt đầu – kết thúc, hình thức (Trực tiếp tại thư viện/giảng đường hoặc Trực tuyến qua Google Meet/Zoom) và nội dung kiến thức dự kiến.
  * Thành viên trong phòng xem danh sách lịch học sắp tới và lịch sử các buổi đã diễn ra.
* **6.2. Ghi nhận nội dung, Điểm danh và Gửi minh chứng (`SES-02`):**
  * **Thông tin buổi học:** Ngày diễn ra, thời lượng thực tế (phút), nội dung kiến thức đã hướng dẫn, kết quả đạt được và các vấn đề còn tồn tại.
  * **Điểm danh thành viên:** Mentor đánh dấu trạng thái tham gia (`Có mặt` / `Vắng mặt`) cho từng Mentee trong phòng.
  * **Tải lên minh chứng:** Mentor đính kèm hình ảnh minh chứng thực tế của buổi học (ảnh chụp nhóm học tập, ảnh chụp màn hình buổi học online, ảnh bảng/tài liệu hướng dẫn) kèm mô tả ngắn.
* **6.3. Cơ chế xác nhận độc lập của Mentee (`SES-03`):**
  * Sau khi Mentor lưu thông tin buổi học, Mentee có thể truy cập vào chi tiết buổi học trên tài khoản cá nhân để bấm nút **"Xác nhận tham gia"** (hệ thống lưu lại dấu thời gian xác nhận).
  * **Quy tắc độc lập luồng dữ liệu:** Thao tác xác nhận của Mentee hoạt động hoàn toàn độc lập và **không chặn** việc hoàn tất báo cáo minh chứng của Mentor. Nếu Mentee quên hoặc chưa bấm xác nhận, báo cáo và minh chứng của Mentor vẫn được lưu trữ hợp lệ với trạng thái `Completed`; trạng thái xác nhận của từng Mentee sẽ được hiển thị minh bạch để Admin theo dõi.

### Module 7. Giám sát chương trình dành cho Admin (`ADM – Mobile Administration`)

Giao diện dành cho Admin được thiết kế tối giản, tối ưu hóa cho màn hình điện thoại di động, tập trung vào **theo dõi số liệu tổng quan và hậu kiểm minh chứng** mà không thực hiện các thao tác phê duyệt thủ công phức tạp:

* **7.1. Dashboard tổng quan trên Mobile (`ADM-01`):**
  * Tổng số sinh viên tham gia hệ thống (phân tách số lượng Mentor và Mentee).
  * Tổng số Phòng học tập đang hoạt động.
  * Tổng số buổi hỗ trợ đã được tổ chức (kèm minh chứng).
  * Tổng số bộ Flashcard/Quiz đã tạo và tổng lượt làm bài ôn tập.
* **7.2. Theo dõi danh sách Phòng học và Hoạt động (`ADM-02`):**
  * Xem danh sách tất cả các phòng học, lọc theo học phần hoặc tìm kiếm theo tên Mentor.
  * Xem nhanh tình hình hoạt động của từng phòng: Số thành viên, số tài liệu đã chia sẻ, số buổi học đã tổ chức và điểm trung bình làm bài của nhóm.
* **7.3. Kiểm tra nhật ký và Minh chứng buổi học (`ADM-03`):**
  * Admin truy cập danh sách các buổi học đã diễn ra (lọc theo học phần, Mentor hoặc thời gian).
  * Xem trực tiếp toàn bộ thông tin của một buổi học trên một màn hình: Thông tin Mentor phụ trách, thời gian/nội dung buổi học, danh sách Mentee tham gia (hiển thị rõ trạng thái Mentor điểm danh và trạng thái Mentee tự xác nhận: *Đã xác nhận* / *Chưa xác nhận*) cùng hình ảnh minh chứng Mentor đã tải lên.
  * Hệ thống không yêu cầu Admin bấm nút duyệt từng buổi; Admin chỉ theo dõi và chủ động liên hệ xử lý bên ngoài nếu phát hiện sai lệch hoặc thiếu minh chứng.

---

## 5. Thuật toán gợi ý kết nối Mentor – Mentee

Để giúp sinh viên nhanh chóng tìm được đối tác học tập phù hợp trước khi gửi lời mời kết nối, hệ thống sử dụng thuật toán **Tính điểm tương đồng có trọng số (Weighted Compatibility Scoring)** gồm 3 bước:

### Bước 1: Lọc điều kiện cứng (Hard Filtering)
Hệ thống loại bỏ ngay các ứng viên không thỏa mãn các điều kiện bắt buộc:
1. Không cùng mã học phần đăng ký ($Course_{Mentor} \neq Course_{Mentee}$).
2. Mentor đã đạt giới hạn số lượng Mentee tối đa có thể hỗ trợ ($CurrentMentees \ge MaxMentees$).
3. Hai tài khoản trùng nhau ($User_{Mentor} = User_{Mentee}$) hoặc đã ở chung một phòng học của học phần đó.

### Bước 2: Tính điểm phù hợp (Weighted Scoring – Thang điểm 100)
Với các cặp Mentor – Mentee vượt qua Bước 1, hệ thống tính điểm tương đồng tổng hợp $S$ dựa trên 3 tiêu chí (với bộ trọng số đề xuất $w_1 = 0.50$, $w_2 = 0.30$, $w_3 = 0.20$):

$$S = 0.50 \times S_{time} + 0.30 \times S_{academic} + 0.20 \times S_{capacity}$$

Trong đó:
1. **Điểm trùng lịch rảnh ($S_{time}$ – Trọng số 50%):**
   Lịch rảnh trong tuần được chia thành 21 khung giờ chuẩn (7 ngày từ Thứ 2 đến Chủ nhật $\times$ 3 buổi Sáng/Chiều/Tối). Điểm trùng lịch được tính bằng tỷ lệ khung giờ trùng nhau trên tổng số khung giờ Mentee đăng ký:
   $$S_{time} = \begin{cases} \dfrac{|Slots_{Mentor} \cap Slots_{Mentee}|}{|Slots_{Mentee}|} \times 100 & \text{nếu } |Slots_{Mentee}| > 0 \\ 50 & \text{nếu } |Slots_{Mentee}| = 0 \end{cases}$$

2. **Điểm năng lực học thuật của Mentor ($S_{academic}$ – Trọng số 30%):**
   Quy đổi từ điểm tổng kết học phần (thang điểm 10) mà Mentor đã đạt được sang thang điểm 100 để ưu tiên gợi ý các Mentor có nền tảng kiến thức vững vàng:
   $$S_{academic} = Grade_{course} \times 10$$

3. **Điểm độ sẵn sàng tiếp nhận ($S_{capacity}$ – Trọng số 20%):**
   Ưu tiên gợi ý các Mentor đang hỗ trợ ít Mentee để phân bổ đều nguồn lực hỗ trợ:
   $$S_{capacity} = \left(1 - \frac{CurrentMentees}{MaxMentees}\right) \times 100$$

### Bước 3: Xếp hạng và Hiển thị gợi ý
Hệ thống sắp xếp danh sách ứng viên theo điểm $S$ giảm dần và hiển thị kèm thông tin giải thích trực quan cho người dùng (ví dụ: *"Độ phù hợp: 86% • Trùng 4/5 buổi rảnh • Điểm môn: 9.0"*), từ đó người dùng quyết định bấm nút **Mời vào phòng** hoặc **Xin tham gia**.

---

## 6. Các quy tắc nghiệp vụ quan trọng (Business Rules)

| Mã | Quy tắc nghiệp vụ |
| :--- | :--- |
| **BR-01** | Một sinh viên có thể đăng ký làm Mentor hoặc Mentee ở nhiều học phần khác nhau, nhưng trong cùng một học phần chỉ được giữ một vai trò duy nhất. |
| **BR-02** | Mỗi Phòng học tập (`Study Room`) phải gắn với một học phần cụ thể và có ít nhất một Mentor làm chủ phòng. |
| **BR-03** | Người dùng chỉ được truy cập nội dung bên trong phòng học khi lời mời kết nối hoặc yêu cầu tham gia đã ở trạng thái `Accepted` (hoặc có quyền Admin). |
| **BR-04** | Chỉ cho phép tải lên tài liệu định dạng `.pdf` và `.docx` với dung lượng $\le 5\text{MB}$/tệp; mỗi lần tạo nội dung AI chỉ chọn tối đa 2 tệp và hệ thống chỉ trích xuất tối đa 15.000 ký tự đầu tiên. |
| **BR-05** | Tài liệu được sử dụng để tạo bài ôn tập phải thuộc phòng học mà người tạo có quyền truy cập. |
| **BR-06** | Nội dung Flashcard/Quiz do AI tạo ra bắt buộc phải qua bước kiểm duyệt và phát hành của Mentor trước khi hiển thị cho các thành viên khác. |
| **BR-07** | Hệ thống lưu trữ phiên bản câu hỏi tại thời điểm làm bài (hoặc khóa chỉnh sửa đề đã có lượt làm bài) để đảm bảo kết quả lịch sử của Mentee không bị sai lệch. |
| **BR-08** | Mỗi lượt làm Quiz được lưu thành một bản ghi độc lập; điểm số và các chỉ số thống kê được tính toán hoàn toàn từ dữ liệu làm bài thực tế bằng truy vấn cơ sở dữ liệu, không phụ thuộc AI. |
| **BR-09** | Mentor có quyền ghi nhận buổi học, điểm danh và tải lên minh chứng độc lập; trạng thái tự xác nhận của Mentee được lưu song song và không chặn việc hoàn tất báo cáo của Mentor. |
| **BR-10** | Mentee chỉ được phép tự xác nhận tham gia buổi học cho chính tài khoản của mình. |

---

## 7. Thiết kế dữ liệu và Công nghệ sử dụng

### 7.1. Cấu trúc cơ sở dữ liệu quan hệ (PostgreSQL)

| Nhóm nghiệp vụ | Các bảng dữ liệu chính | Mô tả vai trò |
| :--- | :--- | :--- |
| **Tài khoản & Học phần** | `profiles`, `programs`, `courses` | Lưu thông tin sinh viên, phân quyền hệ thống (`student`/`admin`), danh mục chương trình và học phần. |
| **Đăng ký tham gia** | `program_registrations` | Lưu thông tin đăng ký làm Mentor/Mentee theo học phần, điểm môn học, số lượng tối đa và mảng khung giờ rảnh. |
| **Phòng học & Kết nối** | `study_rooms`, `room_members`, `room_invitations` | Quản lý phòng học tập, mã mời, danh sách thành viên trong phòng và luồng gửi/nhận lời mời kết nối. |
| **Kho học liệu** | `documents` | Lưu metadata tài liệu (`.pdf`, `.docx`), kích thước tệp, chủ đề và đường dẫn Supabase Storage. |
| **Nội dung AI** | `generated_sets`, `generated_set_documents`, `flashcards`, `quizzes`, `questions` | Quản lý bộ học liệu AI, bảng trung gian liên kết nhiều tài liệu nguồn, trạng thái duyệt (`draft`/`published`), phiên bản đề và chi tiết thẻ/câu hỏi. |
| **Ôn tập & Thống kê** | `quiz_attempts`, `attempt_answers`, `flashcard_progress` | Lưu lịch sử từng lượt làm bài Quiz, đáp án đã chọn và trạng thái ghi nhớ từng Flashcard. |
| **Buổi học & Minh chứng** | `learning_plans`, `tutoring_sessions`, `session_attendances`, `session_evidences` | Lưu kế hoạch buổi học, nhật ký buổi học, trạng thái điểm danh của Mentor, cờ tự xác nhận của Mentee và danh sách ảnh minh chứng. |

**Lưu ý kỹ thuật khi hiện thực Database:**
* Bảng `generated_set_documents` đóng vai trò bảng trung gian (N–N) giữa `generated_sets` và `documents`, giúp truy xuất chính xác một bộ Quiz/Flashcard được tổng hợp từ 1 hay 2 tài liệu nào.
* Các chỉ số thống kê (Tỷ lệ chính xác `Accuracy`, Điểm trung bình `AverageScore`, Tỷ lệ hoàn thành `CompletionRate`) được tính trực tiếp thông qua các hàm tổng hợp của PostgreSQL (`COUNT`, `AVG`, `SUM`) hoặc Database Views để đảm bảo tốc độ truy vấn nhanh và chính xác.

### 7.2. Công nghệ sử dụng (Tech Stack)

| Thành phần | Công nghệ lựa chọn | Mục đích sử dụng |
| :--- | :--- | :--- |
| **Mobile App** | Flutter + Dart | Phát triển ứng dụng di động đa nền tảng Android/iOS. |
| **State Management** | Riverpod | Quản lý trạng thái ứng dụng chặt chẽ, dễ kiểm thử. |
| **Navigation** | GoRouter | Điều hướng màn hình và phân luồng giao diện Sinh viên / Admin. |
| **Trích xuất văn bản** | `syncfusion_flutter_pdf`, `archive` + `xml` | Trích xuất văn bản thô từ tệp `.pdf` và `.docx` trực tiếp trên thiết bị di động trước khi gửi lên server. |
| **Nén hình ảnh** | `flutter_image_compress` | Nén ảnh minh chứng buổi học xuống dưới 500KB trước khi tải lên Storage. |
| **Backend & Database** | Supabase (PostgreSQL) | Lưu trữ dữ liệu quan hệ và phân quyền truy cập bằng Row Level Security (RLS). |
| **Authentication** | Supabase Auth | Xác thực đăng nhập, đăng ký người dùng. |
| **File Storage** | Supabase Storage | Lưu trữ tệp tài liệu học tập (PDF/DOCX) và hình ảnh minh chứng buổi học. |
| **Realtime** | Supabase Realtime | Cập nhật tức thì lời mời kết nối, tài liệu mới và bài ôn tập mới trong phòng. |
| **Server-side & AI** | Supabase Edge Functions + Gemini API (`gemini-2.5-flash`) | Bảo mật API Key, gọi LLM API với chế độ *Structured Outputs (JSON Schema)* để sinh Flashcard và Quiz chuẩn định dạng. |

### 7.3. Luồng xử lý tích hợp AI (Client – Server – LLM API)
1. **Bước 1:** Mentor chọn 1–2 tài liệu trong phòng học trên ứng dụng Flutter, thiết lập số lượng câu hỏi/thẻ và độ khó.
2. **Bước 2:** Ứng dụng Flutter tải tệp (nếu chưa có trong cache) và dùng thư viện trích xuất văn bản tại Client, cắt lấy tối đa 15.000 ký tự đầu tiên.
3. **Bước 3:** Flutter gửi chuỗi văn bản cùng các tham số cấu hình lên **Supabase Edge Function**.
4. **Bước 4:** Edge Function kiểm tra quyền thành viên phòng của người gửi, đóng gói prompt kèm **JSON Schema** và gọi **Gemini API**.
5. **Bước 5:** Gemini API trả về dữ liệu JSON đúng cấu trúc mảng Flashcard hoặc Quiz.
6. **Bước 6:** Edge Function trả kết quả về ứng dụng Flutter ở chế độ xem trước (`Draft`). Mentor kiểm tra, chỉnh sửa nếu cần và nhấn lưu/phát hành vào cơ sở dữ liệu PostgreSQL.

---

## 8. Kế hoạch thực hiện (Chia theo giai đoạn)

Dự án được chia thành **5 giai đoạn** triển khai tuần tự, ưu tiên hoàn thiện thông suốt luồng nghiệp vụ cốt lõi (End-to-End) trước khi mở rộng các chức năng thống kê và giám sát:

| Giai đoạn | Nội dung công việc chính | Sản phẩm đầu ra |
| :--- | :--- | :--- |
| **Giai đoạn 1: Phân tích nghiệp vụ & Thiết kế hệ thống** | • Xác định Actor và đặc tả chi tiết Use Cases.<br>• Chuẩn hóa quy tắc nghiệp vụ (Business Rules) và luồng dữ liệu.<br>• Thiết kế sơ đồ ERD, khởi tạo bảng trên Supabase PostgreSQL và cấu hình RLS.<br>• Thiết kế UI/UX Prototype trên Figma cho luồng Sinh viên và Admin Mobile.<br>• Khởi tạo cấu trúc dự án Flutter theo kiến trúc phân lớp. | Tài liệu đặc tả yêu cầu, Sơ đồ ERD, Thiết kế Figma và khung dự án Flutter. |
| **Giai đoạn 2: Xây dựng nền tảng người dùng & Kết nối phòng học** | • Phát triển đăng ký, đăng nhập và quản lý hồ sơ cá nhân.<br>• Xây dựng màn hình đăng ký tham gia chương trình theo học phần.<br>• Cài đặt thuật toán gợi ý kết nối (Weighted Compatibility Scoring).<br>• Phát triển tạo Phòng học tập, gửi/nhận lời mời kết nối, chấp nhận/từ chối và mời thêm thành viên bằng mã phòng. | Module Tài khoản (`ACC`) và Module Kết nối & Phòng học (`ROM`) hoàn chỉnh. |
| **Giai đoạn 3: Xây dựng kho học liệu & Tích hợp AI** | • Phát triển tải lên, quản lý và tải về tài liệu `.pdf`, `.docx` (kiểm tra dung lượng $\le 5\text{MB}$).<br>• Tích hợp thư viện trích xuất văn bản PDF và DOCX trên Flutter Client (giới hạn 15.000 ký tự).<br>• Viết Supabase Edge Function kết nối Gemini API dùng JSON Schema sinh Flashcard và Quiz.<br>• Xây dựng màn hình xem trước, chỉnh sửa và phát hành bộ học liệu. | Kho tài liệu (`DOC`) và Module AI sinh nội dung ôn tập (`AI`) chạy ổn định. |
| **Giai đoạn 4: Ôn tập, Thống kê & Quản lý minh chứng** | • Xây dựng giao diện học Flashcard (lật thẻ, đánh dấu đã nhớ/chưa nhớ).<br>• Xây dựng giao diện làm bài Quiz, chấm điểm tự động và hiển thị giải thích.<br>• Xây dựng các truy vấn và màn hình thống kê theo bài Quiz và theo Phòng học.<br>• Phát triển lập kế hoạch buổi học, điểm danh, tải ảnh minh chứng của Mentor và tự xác nhận độc lập của Mentee. | Module Ôn tập & Thống kê (`PRA`) và Module Quản lý buổi học & Minh chứng (`SES`). |
| **Giai đoạn 5: Admin Mobile, Kiểm thử & Hoàn thiện** | • Phát triển Dashboard tối giản trên di động cho Admin (xem chỉ số tổng quan, danh sách phòng học và kiểm tra nhật ký, ảnh minh chứng buổi học).<br>• Kiểm thử toàn diện luồng nghiệp vụ và kiểm thử biên (file vượt dung lượng, file rỗng text, gọi AI nhiều lần).<br>• Tạo dữ liệu mẫu (Seed data) theo kịch bản demo và hoàn thiện báo cáo. | Ứng dụng hoàn chỉnh sẵn sàng demo và tài liệu báo cáo đồ án. |

---

## 9. Kịch bản demo sản phẩm (Phục vụ bảo vệ đồ án)

**Bối cảnh giả lập:** Phòng học học phần *Cơ sở dữ liệu* gồm 1 Mentor và 3 Mentee.

1. **Đăng ký chương trình:** Một sinh viên (điểm tổng kết CSDL 9.0) đăng ký làm Mentor môn Cơ sở dữ liệu; ba sinh viên khác đăng ký làm Mentee cần hỗ trợ môn này kèm khung lịch rảnh.
2. **Gợi ý kết nối & Tạo phòng học:** Hệ thống gợi ý danh sách Mentee phù hợp cho Mentor (hiển thị tỷ lệ `%` trùng lịch). Mentor tạo phòng *"CSDL – Nhóm 01"*, gửi lời mời tới 2 Mentee; Mentee thứ 3 chủ động tìm phòng/nhập mã phòng để xin tham gia và được Mentor chấp nhận.
3. **Chia sẻ học liệu:** Mentor tải lên phòng 1 tệp giáo trình `Chuong_3_SQL.pdf` (dung lượng 2.1 MB).
4. **AI tạo nội dung ôn tập:** Mentor chọn tệp `Chuong_3_SQL.pdf`, yêu cầu AI tạo 10 Flashcard và 10 câu hỏi trắc nghiệm mức độ Trung bình. Ứng dụng trích xuất văn bản và trả về bản nháp; Mentor chỉnh sửa lại câu chữ của 1 câu hỏi cho rõ nghĩa hơn rồi nhấn **Phát hành**.
5. **Thành viên ôn tập & Làm bài:** Các Mentee đăng nhập trên tài khoản riêng, lật thẻ Flashcard và hoàn thành bài Quiz, nhận điểm số cùng giải thích chi tiết ngay sau khi nộp bài.
6. **Xem thống kê học tập:** Mentor mở trang thống kê của bài Quiz, nhận thấy câu hỏi về phép nối `LEFT JOIN` có tỷ lệ trả lời đúng thấp nhất (chỉ 33%).
7. **Tổ chức buổi học & Gửi minh chứng:** Mentor tạo buổi học ôn tập chuyên sâu phần `JOIN`, thực hiện điểm danh, ghi nhận nội dung đã hướng dẫn và tải lên ảnh chụp buổi học làm minh chứng. Hai Mentee vào bấm xác nhận tham gia, một Mentee chưa bấm xác nhận nhưng báo cáo của Mentor vẫn hiển thị đầy đủ trạng thái.
8. **Admin giám sát trên Mobile:** Đăng nhập bằng tài khoản Admin trên điện thoại, xem Dashboard tổng quan số lượng phòng, số buổi học, mở chi tiết buổi học của *"CSDL – Nhóm 01"* để kiểm tra ảnh minh chứng và đối chiếu trạng thái xác nhận của các Mentee.

---

## 10. Kết luận

**TLU PeerLearn** giải quyết trọn vẹn bài toán tổ chức và quản lý hoạt động học tập cộng tác giữa sinh viên theo chương trình *"TLU Đồng hành học tập – Sinh viên hỗ trợ sinh viên"* với kiến trúc tinh gọn, thực tế và có tính khả thi cao. Việc phân định rạch ròi vai trò của AI trong khâu biên soạn học liệu từ tài liệu có sẵn kết hợp với cơ chế kiểm duyệt của con người và thống kê dựa trên dữ liệu thực tế giúp ứng dụng vừa tận dụng được sức mạnh của công nghệ hiện đại, vừa đảm bảo tính chính xác, minh bạch trong quá trình vận hành và đánh giá kết quả học tập.