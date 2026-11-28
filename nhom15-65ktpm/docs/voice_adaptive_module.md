# Tài Liệu Đặc Tả Kỹ Thuật Module 4: AI Trợ Lý Giọng Nói & Gia Sư Thích Ứng

- **Tác giả phụ trách:** Nguyễn Thị Cẩm Ly (MSV: 2351170605 - Lớp 65KTPM)
- **Tên module:** Module 4 - AI Trợ Lý Giọng Nói & Động Cơ Gia Sư Thích Ứng (AI Voice Assistant & Adaptive Learning Engine)
- **Dự án:** Finger Math Kids App (Nhóm 15 - 65KTPM)

---

## 1. Giới Thiệu Tổng Quan

Module 4 đóng vai trò là "Trợ lý học tập thông minh" tương tác hai chiều với trẻ em 4–6 tuổi:
1. **Thu nhận và xử lý phát ngôn tự nhiên của trẻ (`VietnameseNumberExtractor`)**: Trẻ mầm non thường nói kèm các từ đệm, từ xưng hô lễ phép ("Dạ thưa cô", "con tính ra", "ạ") hoặc dùng từ ngữ địa phương ("hăm mốt", "nhăm", "lăm"). Thuật toán NLP trích xuất số chính xác từ chuỗi nhận dạng giọng nói của `speech_to_text`.
2. **Động cơ gia sư thích ứng (`AdaptiveTutorEngine`)**: Đánh giá kết quả làm bài của bé dựa trên cửa sổ trượt 5 bài gần nhất (Sliding Window), tự động nhận diện nếu bé tính nhanh/chính xác để tăng tốc độ flashcard hoặc thị phạm ngón tay và giảm tốc khi bé gặp khó khăn.
3. **Phát âm chuẩn hóa tiếng Việt cho trẻ em (`AudioService`)**: Tự động chuyển đổi các phép tính toán học và con số thành chữ tiếng Việt hoàn chỉnh trước khi chuyển qua Text-to-Speech (TTS), đảm bảo phát âm rõ ràng, chuẩn ngữ âm tiếng Việt và không bị đọc nhầm sang tiếng Anh.

---

## 2. Kiến Trúc & Thiết Kế Thành Phần

```
lib/features/4_ai_voice_tutor/
├── domain/
│   ├── engine/
│   │   └── adaptive_tutor_engine.dart       # Thuật toán gia sư thích ứng sliding window
│   └── usecases/
│       └── vietnamese_number_extractor.dart # Thuật toán NLP bóc tách số tiếng Việt
└── presentation/
    └── widgets/
        └── voice_answer_mic_button.dart     # Nút micro hoạt hình ghi âm & STT tương tác
```

---

## 3. Chi Tiết Thuật Toán

### 3.1. Thuật toán bóc tách số giọng nói tiếng Việt (`VietnameseNumberExtractor`)

- **Bước 1: Tiền xử lý (Cleaning & Normalization)**:
  - Chuyển toàn bộ về chữ thường (lowercase).
  - Loại bỏ các từ đệm, từ xưng hô của trẻ: `dạ`, `thưa cô`, `thưa thầy`, `con`, `em`, `bé`, `kết quả`, `đáp án`, `bằng`, `là`, `ạ`, `nhé`.
  - Loại bỏ dấu câu không cần thiết (`.`, `,`, `!`, `?`).
- **Bước 2: Chuẩn hóa phương ngữ & cách đọc đặc thù**:
  - `hăm` / `hăm mốt` $\rightarrow$ `hai mươi` / `hai mươi một`.
  - `nhăm` / `lăm` sau số hàng chục $\rightarrow$ số 5.
- **Bước 3: Nhận diện câu từ chối trả lời**:
  - Nếu câu nói chứa cụm: `không biết`, `chịu`, `khó quá`, `không làm được` $\rightarrow$ trả về `null` để hệ thống không chấm sai nhầm và kích hoạt động viên.
- **Bước 4: Trích xuất số**:
  - Kiểm tra số dạng chữ số (`0-99`) thông qua Regex `\b\d+\b`.
  - Nếu không có chữ số, đối chiếu từ điển số chữ tiếng Việt từ `không` đến `chín mươi chín`.

### 3.2. Động cơ gia sư thích ứng (`AdaptiveTutorEngine`)

- **Đầu vào**:
  - Danh sách nhật ký làm bài gần nhất (`recentAttempts`: Sliding Window $N = 3 \to 5$ bài).
  - Tốc độ hiển thị thẻ bài hiện tại (`currentFlashSpeedMs`).
- **Quy tắc điều chỉnh thích ứng**:
  1. **Tăng tốc & Nâng độ khó (`AdaptiveAction.speedUp`)**:
     - *Điều kiện:* Tỷ lệ đúng đạt 100% và thời gian phản hồi trung bình $< 2.500\,\text{ms}$ (hoặc đúng $\ge 80\%$ với thời gian $< 2.000\,\text{ms}$).
     - *Hành động:* Giảm thời gian chớp số $200\,\text{ms}$ (tối thiểu $600\,\text{ms}$) để tăng phản xạ tính nhẩm siêu tốc.
  2. **Thị phạm ngón tay & Giảm tốc (`AdaptiveAction.guideHighlight`)**:
     - *Điều kiện:* Tỷ lệ đúng $< 60\%$ hoặc thời gian suy nghĩ kéo dài $> 6.000\,\text{ms}$.
     - *Hành động:* Tăng thời gian chớp số thêm $+200\,\text{ms}$ (tối đa $2.500\,\text{ms}$) và tự động hiển thị mô hình bàn tay gợi ý gảy ngón (Anh Bạn Nhỏ / Anh Bạn Lớn).
  3. **Duy trì nhịp độ ổn định (`AdaptiveAction.stayCurrent`)**:
     - *Điều kiện:* Bé làm bài với độ chính xác từ $60\% \to 80\%$ ở ngưỡng thời gian bình thường.
     - *Hành động:* Giữ nguyên tốc độ và độ khó để bé củng cố kiến thức.

---

## 4. Danh Sách 7 Ca Kiểm Thử Unit Tests (Module 4)

| Mã Test | Tệp Kiểm Thử | Tên Kịch Bản | Kết Quả Mong Đợi | Trạng Thái |
| :---: | :--- | :--- | :--- | :---: |
| **TC_NLP_01** | `number_extractor_test.dart` | Trích xuất số đơn lẻ và dạng chữ số ("năm", "số 7", "15", "bằng 8") | Trả về chính xác các giá trị số nguyên: `5`, `7`, `15`, `8` | **Pass (100%)** |
| **TC_NLP_02** | `number_extractor_test.dart` | Trích xuất câu nói tự nhiên kèm từ đệm dạ thưa ("dạ thưa cô kết quả bằng mười lăm ạ") | Loại bỏ toàn bộ từ đệm, trích xuất chính xác `15`, `10`, `9` | **Pass (100%)** |
| **TC_NLP_03** | `number_extractor_test.dart` | Trích xuất các số hàng chục và phương ngữ ("hai mươi mốt", "ba mươi lăm") | Chuẩn hóa phương ngữ và trả về giá trị `21`, `35`, `11`, `20` | **Pass (100%)** |
| **TC_NLP_04** | `number_extractor_test.dart` | Trả về null khi câu nói không chứa số hoặc câu từ chối ("con không biết") | Trả về `null`, kích hoạt gợi ý làm lại | **Pass (100%)** |
| **TC_AI_01** | `adaptive_tutor_test.dart` | Tăng tốc độ khi bé làm đúng 100% và rất nhanh (< 2s) | Quyết định `speedUp`, giảm `recommendedSpeedMs` từ 1200ms xuống 1000ms | **Pass (100%)** |
| **TC_AI_02** | `adaptive_tutor_test.dart` | Chuyển sang hướng dẫn thị phạm ngón tay khi bé làm sai nhiều | Quyết định `guideHighlight`, tăng `recommendedSpeedMs` lên 1400ms | **Pass (100%)** |
| **TC_AI_03** | `adaptive_tutor_test.dart` | Duy trì độ khó khi bé làm bài ổn định (tỷ lệ 80%) | Quyết định `stayCurrent`, giữ nguyên 1200ms | **Pass (100%)** |

---

## 5. Kết Quả Kiểm Thử & Phân Tích Mã Nguồn

```bash
cd nhom15-65ktpm/src
flutter test
# Kết quả: 28/28 tests passed (100%)

dart analyze lib test
# Kết quả: Analyzing lib, test... No issues found!
```
