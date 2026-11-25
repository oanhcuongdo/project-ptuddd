# Kế Hoạch Triển Khai Phân Hệ AI Sleep Assistant (DCSleep) - v1.5

> **Dành cho Agent/Kỹ sư triển khai:** BẮT BUỘC SỬ DỤNG SUB-SKILL: Sử dụng `superpowers:subagent-driven-development` (khuyên dùng) hoặc `superpowers:executing-plans` để thực thi kế hoạch này từng tác vụ một. Các bước sử dụng cú pháp checkbox (`- [ ]`) để theo dõi tiến độ.

**Mục tiêu:** Xây dựng hoàn chỉnh phân hệ Trợ lý AI Tư vấn Giấc ngủ (AI Sleep Assistant) theo bản đặc tả v1.3, tích hợp Gemini 2.5 Flash (hỗ trợ MockClient & khử trùng role tuyệt đối), quản lý khóa an toàn qua `flutter_secure_storage` (kèm dialog demo trực tiếp), bộ lọc an toàn 2 lớp hỗ trợ tiếng Việt không dấu, cơ chế tự phục hồi ngoại tuyến và lưu trữ SQLite bền vững (hỗ trợ in-memory test).

**Phạm vi triển khai (Scope Clarification):** Đợt triển khai này tập trung 100% vào việc hoàn thiện và tối ưu `GeminiAIService` (Gemini 2.5 Flash) cùng bộ dự phòng `OfflineSleepEngine`. Phân hệ `OpenAIService` (Mục 2.3 của spec) nằm ngoài phạm vi thực thi đợt này, đã được mở sẵn cổng chờ kết nối thông qua interface `AIService`.

**Kiến trúc:** Áp dụng Strategy Pattern và Dependency Injection (DI) cho Service Layer (`AIService`), tách biệt hoàn toàn khỏi `AIAssistantProvider`. Dữ liệu được bảo vệ 2 tầng qua `SafetyGuardrails` (chạy trên máy) và `OfflineSleepEngine` (khi mạng lỗi). Khóa API được quản lý tập trung bởi `ApiKeyManager`. Toàn bộ lịch sử chat được lưu trữ bền vững trong SQLite cục bộ (`database_helper.dart`).

**Công nghệ sử dụng:** Flutter 3.x, Dart 3.x, `provider`, `sqflite`, `sqflite_common_ffi` (dùng `inMemoryDatabasePath` cho unit test), `http` (kèm `MockClient` test), `flutter_secure_storage`.

**Tài liệu đặc tả (Spec):** [spec_ai_sleep_assistant.md](file:///d:/Nhom_mobile/project-ptuddd/nhom07-65ktpm/docs/spec/spec_ai_sleep_assistant.md)

---

## Ràng Buộc Toàn Cục (Global Constraints)

- **Mô hình AI:** Bắt buộc sử dụng `gemini-2.5-flash` (không dùng dòng 1.5 đã ngừng phục vụ).
- **Cấu hình Payload:** `thinkingBudget: 0`, `temperature: 0.7`, `maxOutputTokens: 1024`.
- **Thời gian chờ (Timeout):** Gắn cứng `.timeout(const Duration(seconds: 10))` cho mọi request HTTP gọi API trực tuyến.
- **Bảo mật Header & Mockability:** Truyền khóa API qua Header `x-goog-api-key`, tuyệt đối không truyền `?key=...` trên URL. `GeminiAIService` nhận `http.Client?` qua constructor để test bằng `MockClient`.
- **Khử trùng Role an toàn:** Nối `currentPrompt` trước khi chuẩn hóa; đảm bảo mảng `contents` cuối cùng luôn bắt đầu bằng `user`, kết thúc bằng `user` và xen kẽ nghiêm ngặt `user` $\leftrightarrow$ `model`.
- **Chống gửi trùng (Debounce):** Chặn sớm `if (_isThinking || prompt.trim().isEmpty) return;` ở đầu `sendMessage()`.
- **Ngữ cảnh giấc ngủ:** `[DỮ LIỆU THỰC TẾ TỪ DCSLEEP]` chỉ ghép động vào `system_instruction` của HTTP payload, tuyệt đối không lưu vào bảng `ai_chat_messages` trong SQLite. Đọc đúng các thuộc tính thực tế của `SleepProvider` (`goal.targetDurationHours`, `complianceRate`, `averageDurationHours`, `latestRecord`).
- **Chuẩn hóa Màu sắc Flutter 3.x:** Sử dụng `.withValues(alpha: 0.3)` thay vì phương thức đã deprecated `.withOpacity(0.3)`.
- **Cô lập kiểm thử CSDL:** `DatabaseHelper` hỗ trợ `inMemoryDatabasePath` cho unit test để không sinh file `dcsleep.db` rác và tránh ô nhiễm dữ liệu giữa các test cases.
- **Tiêu chuẩn mã nguồn:** Không có cảnh báo/lỗi trên `flutter analyze`, toàn bộ code nằm trọn vẹn trong `nhom07-65ktpm/src/`.

---

## Trọng Tâm Rà Soát (Review Focus)

1. **Thứ tự khử trùng role trong `buildContentsPayload`:** Nếu lọc history trước rồi mới nối `currentPrompt`, gặp history kết thúc bằng `user` sẽ gây lỗi 2 tin `user` liên tiếp $\rightarrow$ API bắn lỗi `400 Bad Request`. Khắc phục: Nối `currentPrompt` trước, sau đó chạy một lượt khử trùng lặp các role đứng liền nhau.
2. **Crash `MissingPluginException` và file DB rác khi chạy test trên máy tính:** Khi chạy `flutter test`, `sqflite` thiếu platform channel. Khắc phục: Sử dụng `sqflite_common_ffi` kết hợp `inMemoryDatabasePath` (`sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;`) trong `setUpAll`.
3. **Bấm gửi liên tục (Double-tap spam):** Người dùng bấm gửi 2 lần nhanh $\rightarrow$ phát sinh 2 lời gọi bất đồng bộ đè nhau. Khắc phục: `if (_isThinking || prompt.trim().isEmpty) return;` ở đầu hàm `sendMessage`.
4. **Gắn nhầm nhãn `[Ngoại tuyến]` cho cảnh báo y tế:** Phản hồi từ `SafetyGuardrails` là cơ chế an toàn chủ động, điện thoại vẫn có mạng bình thường. Khắc phục: Chỉ gán `isOffline: true` khi câu trả lời thực sự do `OfflineSleepEngine` sinh ra.
5. **Cảnh báo Deprecated trên Flutter mới:** Dùng `.withOpacity(...)` gây warning khi chạy `flutter analyze`. Khắc phục: Thay bằng `.withValues(alpha: ...)`.

---

## Danh Sách Tác Vụ Triển Khai (Tasks)

### Tác Vụ 1: Bổ Sung Dependencies, Nâng Cấp Model & CSDL Hỗ Trợ In-Memory Test

**Tệp tin:**
- Sửa đổi: `nhom07-65ktpm/src/pubspec.yaml`
- Sửa đổi: `nhom07-65ktpm/src/lib/data/models/ai_message_model.dart`
- Sửa đổi: `nhom07-65ktpm/src/lib/data/database/database_helper.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/ai_message_model_test.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/database_helper_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: `sqflite`, `sqflite_common_ffi`, `flutter_secure_storage`.
- Cung cấp: `AIMessageModel` có thuộc tính `isOffline: bool`; `DatabaseHelper` hỗ trợ lưu/truy vấn `is_offline`, hàm `@visibleForTesting initCustomDatabase({String? path})` và `closeDatabase()`.

- [ ] **Bước 1: Bổ sung dependencies vào `pubspec.yaml`**
  - Thêm `flutter_secure_storage: ^9.2.2` vào mục `dependencies:`.
  - Thêm `sqflite_common_ffi: ^2.3.4+4` vào mục `dev_dependencies:`.
  - Chạy: `flutter pub get`.

- [ ] **Bước 2: Viết test kiểm tra serialization của `AIMessageModel` & CSDL In-Memory**
  ```dart
  // nhom07-65ktpm/src/test/ai_message_model_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:dcsleep/data/models/ai_message_model.dart';

  void main() {
    test('AIMessageModel serialization includes isOffline flag', () {
      final msg = AIMessageModel(
        id: 1,
        text: 'Thở 4-7-8',
        isUser: false,
        isOffline: true,
        timestamp: DateTime.parse('2026-11-21T08:00:00'),
      );
      final map = msg.toMap();
      expect(map['is_offline'], 1);
      final fromMap = AIMessageModel.fromMap(map);
      expect(fromMap.isOffline, true);
    });
  }
  ```
  ```dart
  // nhom07-65ktpm/src/test/database_helper_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:sqflite_common_ffi/sqflite_ffi.dart';
  import 'package:dcsleep/data/database/database_helper.dart';
  import 'package:dcsleep/data/models/ai_message_model.dart';

  void main() {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    tearDown(() async {
      await DatabaseHelper.instance.closeDatabase();
    });

    test('DatabaseHelper saves and retrieves is_offline flag using in-memory db', () async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
      final msg = AIMessageModel(
        text: 'Offline test',
        isUser: false,
        isOffline: true,
        timestamp: DateTime.now(),
      );
      final id = await DatabaseHelper.instance.insertAIMessage(msg);
      final messages = await DatabaseHelper.instance.getAllAIMessages();
      expect(messages.any((m) => m.id == id && m.isOffline == true), true);
    });
  }
  ```

- [ ] **Bước 3: Cập nhật `AIMessageModel`**
  - Thêm thuộc tính `final bool isOffline;` với giá trị mặc định `false`.
  - Cập nhật hàm `toMap()` ghi `is_offline: isOffline ? 1 : 0`.
  - Cập nhật hàm `fromMap()` đọc `isOffline: (map['is_offline'] as int?) == 1`.

- [ ] **Bước 4: Cập nhật `DatabaseHelper` với Migration an toàn và hỗ trợ In-Memory Path**
  - Nâng `_databaseVersion` lên `2`.
  - Thêm hỗ trợ biến `String? _customPath;`.
  - Cung cấp hàm:
    ```dart
    @visibleForTesting
    Future<Database> initCustomDatabase({String? path}) async {
      _customPath = path;
      _database = await _initDatabase();
      return _database!;
    }

    @visibleForTesting
    Future<void> closeDatabase() async {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
      }
      _database = null;
      _customPath = null;
    }
    ```
  - Trong `_initDatabase()`: nếu `_customPath != null`, mở trực tiếp `openDatabase(_customPath!, ...)`; nếu không thì dùng `getDatabasesPath()`.
  - Bổ sung `is_offline INTEGER NOT NULL DEFAULT 0` vào câu lệnh `CREATE TABLE ai_chat_messages`.
  - Trong `_onUpgrade(db, oldVersion, newVersion)`, thêm lệnh `ALTER TABLE ai_chat_messages ADD COLUMN is_offline INTEGER NOT NULL DEFAULT 0;` khi `oldVersion < 2`.
  - Cập nhật `insertAIMessage`, `getAllAIMessages` và thêm `clearAllAIMessages()`.

- [ ] **Bước 5: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/ai_message_model_test.dart test/database_helper_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 6: Commit**
  ```bash
  git add nhom07-65ktpm/src/pubspec.yaml nhom07-65ktpm/src/pubspec.lock nhom07-65ktpm/src/lib/data/models/ai_message_model.dart nhom07-65ktpm/src/lib/data/database/database_helper.dart nhom07-65ktpm/src/test/ai_message_model_test.dart nhom07-65ktpm/src/test/database_helper_test.dart
  git commit -m "feat(nhom07-65ktpm): nang cap ai_message_model, migration sqlite ho tro in-memory test"
  ```

---

### Tác Vụ 2: Xây Dựng Bộ Lọc An Toàn Tiền Xử Lý (Safety Guardrails)

**Tệp tin:**
- Tạo mới: `nhom07-65ktpm/src/lib/data/services/safety_guardrails.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/safety_guardrails_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: Chuỗi văn bản prompt của người dùng.
- Cung cấp: Hàm `SafetyGuardrails.evaluate(String prompt) -> SafetyCheckResult` trả về cảnh báo nếu phát hiện dược lý / red flags.

- [ ] **Bước 1: Viết test cho bộ lọc an toàn với cả tiếng Việt có dấu và không dấu**
  ```dart
  // nhom07-65ktpm/src/test/safety_guardrails_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:dcsleep/data/services/safety_guardrails.dart';

  void main() {
    test('SafetyGuardrails blocks medication keywords with and without accents', () {
      expect(SafetyGuardrails.evaluate('Tôi muốn mua thuốc ngủ').isBlocked, true);
      expect(SafetyGuardrails.evaluate('uong thuoc ngu lieu luong the nao').isBlocked, true);
      expect(SafetyGuardrails.evaluate('seduxen 5mg uong sao').isBlocked, true);
      expect(SafetyGuardrails.evaluate('uong stilnox hay diazepam').isBlocked, true);
    });
    test('SafetyGuardrails detects red flags', () {
      expect(SafetyGuardrails.evaluate('ngung tho khi ngu co sao khong').isBlocked, true);
      expect(SafetyGuardrails.evaluate('Ngưng thở khi ngủ có nguy hiểm không').isBlocked, true);
    });
    test('SafetyGuardrails allows normal sleep hygiene questions', () {
      expect(SafetyGuardrails.evaluate('Nên ngủ trưa bao nhiêu phút?').isBlocked, false);
      expect(SafetyGuardrails.evaluate('uong ca phe sau may gio').isBlocked, false);
    });
  }
  ```

- [ ] **Bước 2: Triển khai lớp `SafetyGuardrails`**
  - Tạo hàm tiện ích `removeDiacritics(String text)` loại bỏ toàn bộ dấu tiếng Việt.
  - Danh sách từ khóa cấm: `thuốc ngủ`, `thuoc ngu`, `thuốc an thần`, `thuoc an than`, `seduxen`, `stilnox`, `zolpidem`, `diazepam`, `rotunda`, `uống thuốc gì`, `uong thuoc gi`, `liều lượng thuốc`, `lieu luong thuoc`.
  - Danh sách Red Flags: `ngưng thở khi ngủ`, `ngung tho khi ngu`, `co giật`, `co giat`, `ảo giác`, `ao giac`, `suy nhược cấp`, `suy nhuoc cap`, `mất ngủ kinh niên`, `mat ngu kinh nien`.
  - Trả về `SafetyCheckResult(isBlocked: true, warningMessage: '...')` khi vi phạm.

- [ ] **Bước 3: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/safety_guardrails_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 4: Commit**
  ```bash
  git add nhom07-65ktpm/src/lib/data/services/safety_guardrails.dart nhom07-65ktpm/src/test/safety_guardrails_test.dart
  git commit -m "feat(nhom07-65ktpm): trien khai bo loc an toan 2 lop safety guardrails ho tro tieng viet khong dau"
  ```

---

### Tác Vụ 3: Bộ Tri Thức Chuyên Gia Ngoại Tuyến Nâng Cao (OfflineSleepEngine)

**Tệp tin:**
- Sửa đổi: `nhom07-65ktpm/src/lib/data/services/offline_sleep_engine.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/offline_sleep_engine_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: `prompt` (chuỗi người dùng nhập), `sleepContext` (tùy chọn), `SafetyGuardrails.removeDiacritics`.
- Cung cấp:
  - `OfflineSleepEngine.getAdvice(String prompt, {String? sleepContext}) -> String`
  - `OfflineSleepEngine.supportedTopicCount` (hằng số hoặc getter = 8).

- [ ] **Bước 1: Kiểm tra tên package trong `pubspec.yaml`**
  - Mở `pubspec.yaml` xác nhận chính xác trường `name: dcsleep` dùng cho import trong unit test.

- [ ] **Bước 2: Viết bộ Unit Test toàn diện trước khi code (TDD - Red)**
  - Kiểm thử 4 chủ đề cốt lõi (có dấu, không dấu, viết hoa, dính dấu câu):
    - Power Nap: `"Ngủ trưa bao nhiêu phút?"`, `"NGU TRUA 45 phut??"` → chứa `Power Nap`, `10 – 20 phút` (hoặc `15 - 20`), `Sleep Inertia`.
    - Thở 4-7-8 & Giãn cơ (PMR): `"Huong dan tho 478"`, `"kỹ thuật thở 4-7-8 giãn cơ"` → chứa `4 giây`, `7 giây`, `8 giây`, `phó giao cảm`.
    - Caffeine & Dinh dưỡng: `"Chiều uống cà phê sau mấy giờ?"`, `"uong tra sua buoi toi"` → chứa `5 – 7`, `14:00`, `2 tiếng`.
    - Khó ngủ / Trằn trọc: `"Nằm trằn trọc mãi không ngủ được"`, `"tran troc luc nua dem"` → chứa `20 phút`, `đèn vàng`.
  - Kiểm thử 4 chủ đề mở rộng chuẩn Sleep Hygiene:
    - Ánh sáng xanh & Thiết bị điện tử: `"Lướt điện thoại trước khi ngủ"` → chứa `Melatonin`, `30`.
    - Chu kỳ 90 phút & Nhịp sinh học: `"Chu kỳ giấc ngủ 90 phút và ngủ bù cuối tuần"` → chứa `90 phút`, `Social Jetlag`.
    - Stress / Overthinking: `"Áp lực deadline bị overthinking khó vào giấc"` → chứa `Brain Dump`.
    - Môi trường phòng ngủ & Đánh giá nhật ký: `"Phòng ngủ bao nhiêu độ?"` → chứa `20 – 24°C`; `"Đánh giá tiến độ giấc ngủ của tôi"` kèm `sleepContext: 'Mục tiêu: 8.0h. Tỷ lệ tuân thủ: 72%.'` → phản hồi có nhắc lại dữ liệu `72%`.
  - Kiểm thử độ chính xác của Weighted Scoring:
    - Câu pha trộn: `"Tôi ăn tối bình thường nhưng nằm trằn trọc không ngủ được"` → phải khớp Khó ngủ / Trằn trọc (20 phút), không khớp nhầm sang Caffeine/Ăn uống.
  - Kiểm thử Default Fallback & Medical Disclaimer:
    - Câu ngoài chủ đề (`"Hôm nay thời tiết thế nào?"`) và chuỗi rỗng (`"   "`) → chứa `chế độ ngoại tuyến`, nhắc `4-7-8`, hướng dẫn dùng Quick Chips.
    - Mọi câu trả lời ở tất cả các nhánh đều chứa câu miễn trừ y tế (*không thay thế chỉ định y tế* hoặc *không thay thế chẩn đoán*).

- [ ] **Bước 3: Chạy test xác nhận thất bại (Red)**
  - Chạy: `flutter test test/offline_sleep_engine_test.dart`
  - Kết quả mong đợi: FAIL do chưa hỗ trợ đầy đủ 8 chủ đề và weighted scoring.

- [ ] **Bước 4: Triển khai `OfflineSleepEngine` tại `lib/data/services/offline_sleep_engine.dart`**
  - `_WeightedKeyword` & `_SleepTopic` mô hình hóa từ khóa với trọng số (từ khóa đặc trưng 3-4, cụm phụ 2, từ chung 1).
  - Hàm `_normalizeInput(String raw)`: loại bỏ dấu tiếng Việt, làm sạch dấu câu (`?`, `!`, `,`, `.`, `;`, `:`, `(`, `)`), chuẩn hóa khoảng trắng thừa.
  - Kho 8 chủ đề chuyên sâu (Power Nap, 4-7-8 & PMR, Caffeine & Dinh dưỡng, Khó ngủ & Trằn trọc, Ánh sáng xanh & Màn hình, Nhịp sinh học & 90 phút, Stress & Overthinking, Môi trường ngủ & Tiến độ nhật ký kèm `sleepContext`).
  - Thuật toán chấm điểm tổng trọng số (Weighted Keyword Scoring), chọn chủ đề có điểm cao nhất, fallback về Default Fallback khi `bestScore == 0` hoặc prompt rỗng.
  - Luôn đính kèm `_disclaimer` vào chân mọi câu trả lời.

- [ ] **Bước 5: Chạy lại Unit Test & Phân tích tĩnh (Green)**
  - Chạy: `flutter test test/offline_sleep_engine_test.dart`
  - Chạy: `flutter analyze lib/data/services/offline_sleep_engine.dart test/offline_sleep_engine_test.dart`
  - Kết quả mong đợi: 100% PASS và No issues found!.

- [ ] **Bước 6: Commit riêng Tác vụ 3**
  ```bash
  git add nhom07-65ktpm/src/lib/data/services/offline_sleep_engine.dart nhom07-65ktpm/src/test/offline_sleep_engine_test.dart
  git commit -m "feat(nhom07-65ktpm): nang cap offline sleep engine 8 chu de, weighted scoring va sleep context"
  ```

---

### Tác Vụ 4: Quản Lý Khóa API An Toàn (ApiKeyManager)

**Tệp tin:**
- Tạo mới: `nhom07-65ktpm/src/lib/data/services/api_key_manager.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/api_key_manager_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: `flutter_secure_storage`.
- Cung cấp: Lớp `ApiKeyManager` với các hàm `getApiKey()`, `saveCustomApiKey()`, `clearCustomApiKey()`.

- [ ] **Bước 1: Viết test cho luồng ưu tiên đọc API Key**
  ```dart
  // nhom07-65ktpm/src/test/api_key_manager_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import 'package:dcsleep/data/services/api_key_manager.dart';

  void main() {
    test('ApiKeyManager fallback to environment key when storage is empty', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final manager = ApiKeyManager();
      final key = await manager.getApiKey();
      expect(key, isA<String>());
    });
  }
  ```

- [ ] **Bước 2: Triển khai `ApiKeyManager`**
  - Sử dụng `FlutterSecureStorage` để lưu trữ key của người dùng với khóa `'user_gemini_api_key'`.
  - Luồng `getApiKey()`:
    1. Kiểm tra key trong `FlutterSecureStorage`.
    2. Nếu có và không rỗng $\rightarrow$ trả về key này.
    3. Nếu không có $\rightarrow$ fallback về `const String.fromEnvironment('GEMINI_API_KEY')`.
  - Cung cấp `saveCustomApiKey(String key)` và `clearCustomApiKey()`.

- [ ] **Bước 3: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/api_key_manager_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 4: Commit**
  ```bash
  git add nhom07-65ktpm/src/lib/data/services/api_key_manager.dart nhom07-65ktpm/src/test/api_key_manager_test.dart
  git commit -m "feat(nhom07-65ktpm): trien khai api key manager voi flutter_secure_storage va environment fallback"
  ```

---

### Tác Vụ 5: Tầng Dịch Vụ AI Trực Tuyến, MockClient & Khử Trùng Role An Toàn

**Tệp tin:**
- Tạo mới: `nhom07-65ktpm/src/lib/data/services/ai_service.dart`
- Sửa đổi: `nhom07-65ktpm/src/lib/data/services/gemini_ai_service.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/gemini_ai_service_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: Model Gemini 2.5 Flash, API Key, lịch sử tin nhắn gần nhất (`history`), `http.Client?`.
- Cung cấp: Interface `AIService`, ngoại lệ `AIServiceException`, và lớp `GeminiAIService` có khả năng inject `MockClient`.

- [ ] **Bước 1: Viết test cho MockClient HTTP Header `x-goog-api-key` và Khử trùng lặp Role**
  ```dart
  // nhom07-65ktpm/src/test/gemini_ai_service_test.dart
  import 'dart:convert';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:http/http.dart' as http;
  import 'package:http/testing.dart';
  import 'package:dcsleep/data/services/gemini_ai_service.dart';
  import 'package:dcsleep/data/services/ai_service.dart';
  import 'package:dcsleep/data/models/ai_message_model.dart';

  void main() {
    test('GeminiAIService transmits API key in x-goog-api-key header and NOT in URL query', () async {
      late Uri capturedUri;
      late Map<String, String> capturedHeaders;

      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        capturedHeaders = request.headers;
        return http.Response(jsonEncode({
          'candidates': [
            {'content': {'parts': [{'text': 'Test response'}]}}
          ]
        }), 200);
      });

      final service = GeminiAIService(client: mockClient);
      service.setApiKey('test_secret_key');
      final res = await service.askAssistant(prompt: 'Hello');

      expect(res, 'Test response');
      expect(capturedUri.queryParameters.containsKey('key'), false); // Không lộ trên URL!
      expect(capturedHeaders['x-goog-api-key'], 'test_secret_key');
    });

    test('GeminiAIService buildContentsPayload ensures strict user-model-user alternation even with trailing user in history', () {
      final service = GeminiAIService();
      final history = [
        AIMessageModel(id: 1, text: 'Hi', isUser: false, timestamp: DateTime.now()), // bot chào
        AIMessageModel(id: 2, text: 'Tôi mệt', isUser: true, timestamp: DateTime.now()),
        AIMessageModel(id: 3, text: 'Lại gửi tiếp', isUser: true, timestamp: DateTime.now()), // 2 user liền nhau!
      ];
      final contents = service.buildContentsPayload(
        history: history,
        currentPrompt: 'Câu hỏi mới của tôi',
      );
      expect(contents.first['role'], 'user');
      expect(contents.last['role'], 'user');
      for (int i = 0; i < contents.length - 1; i++) {
        expect(contents[i]['role'], isNot(equals(contents[i + 1]['role'])));
      }
    });
  }
  ```

- [ ] **Bước 2: Định nghĩa `ai_service.dart`**
  - Khai báo class `AIServiceException` (message, statusCode).
  - Khai báo abstract class `AIService` với hàm `askAssistant({prompt, sleepContext, history}) -> Future<String>`.

- [ ] **Bước 3: Cập nhật `GeminiAIService`**
  - Nhận `http.Client? client` qua constructor:
    ```dart
    class GeminiAIService implements AIService {
      static final GeminiAIService instance = GeminiAIService();
      final http.Client _client;
      String _apiKey = '';

      GeminiAIService({http.Client? client}) : _client = client ?? http.Client();
    ```
  - Kiểm tra sớm: `if (!hasApiKey) throw AIServiceException('Chưa cấu hình API Key');`.
  - Header: `headers: {'Content-Type': 'application/json', 'x-goog-api-key': _apiKey}`.
  - Cấu hình `"generationConfig": {"temperature": 0.7, "maxOutputTokens": 1024, "thinkingConfig": {"thinkingBudget": 0}}`.
  - Cấu hình trường `"system_instruction"` tách biệt (ghép kèm ngữ cảnh `sleepContext` nếu có).
  - Cài đặt `buildContentsPayload`:
    1. Nạp các tin nhắn cũ từ `history` vào danh sách tạm.
    2. Nối câu hỏi hiện tại `{"role": "user", "parts": [{"text": currentPrompt}]}` vào cuối danh sách trước.
    3. Cắt lấy tối đa 7 tin nhắn gần nhất.
    4. Bỏ qua tin mở đầu nếu có `role: "model"`.
    5. Khử trùng lặp role liền nhau: duyệt mảng, nếu `contents[i]['role'] == contents[i+1]['role']`, loại bỏ phần tử cũ hơn để đảm bảo xen kẽ nghiêm ngặt `user` $\leftrightarrow$ `model`.
  - Sử dụng `_client.post(...).timeout(const Duration(seconds: 10))`.
  - Nếu mã phản hồi $\neq 200$, ném `AIServiceException(response.body, statusCode: response.statusCode)`.

- [ ] **Bước 4: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/gemini_ai_service_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 5: Commit**
  ```bash
  git add nhom07-65ktpm/src/lib/data/services/ai_service.dart nhom07-65ktpm/src/lib/data/services/gemini_ai_service.dart nhom07-65ktpm/src/test/gemini_ai_service_test.dart
  git commit -m "feat(nhom07-65ktpm): hoan thien gemini_ai_service voi mock client, timeout 10s va role deduplication"
  ```

---

### Tác Vụ 6: Nâng Cấp State Provider, Chống Spam Gửi Trùng & Tự Phục Hồi Online

**Tệp tin:**
- Sửa đổi: `nhom07-65ktpm/src/lib/providers/ai_assistant_provider.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/ai_assistant_provider_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: `SafetyGuardrails`, `GeminiAIService`, `OfflineSleepEngine`, `DatabaseHelper` (nhận qua constructor).
- Cung cấp: State `messages`, `isThinking`, `isOfflineMode`, `offlineReason`, hàm `sendMessage()`, hàm `clearHistory()`.

- [ ] **Bước 1: Viết test cho Provider với Constructor Injection, Debounce và Auto-recovery**
  ```dart
  // nhom07-65ktpm/src/test/ai_assistant_provider_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:dcsleep/providers/ai_assistant_provider.dart';

  void main() {
    test('AIAssistantProvider ignores duplicate send when isThinking is true', () async {
      final provider = AIAssistantProvider(databaseHelper: mockDb, aiService: mockService);
      provider.setThinkingForTest(true);
      await provider.sendMessage('Test prompt');
      expect(provider.messages.isEmpty, true); // Bị chặn sớm
    });
    test('AIAssistantProvider sets isOffline = false for SafetyGuardrails warning', () async {
      final provider = AIAssistantProvider(databaseHelper: mockDb, aiService: mockService);
      await provider.sendMessage('Uong thuoc ngu');
      expect(provider.messages.last.isOffline, false);
    });
    test('AIAssistantProvider resets isOfflineMode on successful online response', () async {
      final provider = AIAssistantProvider(databaseHelper: mockDb, aiService: mockService);
      provider.setOfflineModeForTest(true, reason: 'Mất mạng');
      await provider.sendMessage('Nên ngủ mấy giờ');
      expect(provider.isOfflineMode, false);
      expect(provider.offlineReason, isNull);
    });
  }
  ```

- [ ] **Bước 2: Cập nhật `AIAssistantProvider`**
  - Chuyển sang sử dụng Constructor Injection:
    ```dart
    AIAssistantProvider({
      DatabaseHelper? databaseHelper,
      AIService? aiService,
      ApiKeyManager? apiKeyManager,
    }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
         _aiService = aiService ?? GeminiAIService.instance,
         _apiKeyManager = apiKeyManager ?? ApiKeyManager();
    ```
  - State:
    - `bool _isOfflineMode = false; bool get isOfflineMode => _isOfflineMode;`
    - `String? _offlineReason; String? get offlineReason => _offlineReason;`
  - Hàm `sendMessage(prompt, {sleepSummary})`:
    1. **Chống spam gửi trùng:**
       ```dart
       if (_isThinking || prompt.trim().isEmpty) return;
       ```
    2. Chụp snapshot lịch sử trước khi thêm tin mới:
       `final previousHistory = List<AIMessageModel>.from(_messages);`
    3. Thêm tin nhắn người dùng vào danh sách và lưu vào SQLite (`is_offline = 0`).
    4. Kiểm tra `SafetyGuardrails.evaluate(prompt)`:
       - Nếu vi phạm: Thêm tin nhắn cảnh báo bot vào danh sách, lưu SQLite với **`is_offline = 0`** (vì không phải lỗi mạng), notifyListeners và return.
    5. Cập nhật `_isThinking = true; notifyListeners();`.
    6. Nạp API Key qua `_apiKeyManager.getApiKey()` và set vào `_aiService`.
    7. Khối `try / catch`:
       - **Thử gọi Online:**
         ```dart
         final response = await _aiService.askAssistant(
           prompt: prompt,
           sleepContext: sleepSummary,
           history: previousHistory,
         );
         _isOfflineMode = false;
         _offlineReason = null;
         // Lưu tin nhắn bot với is_offline = 0
         ```
       - **Bắt ngoại lệ (`AIServiceException` / Exception):**
         ```dart
         _isOfflineMode = true;
         if (e is AIServiceException && e.statusCode == 429) {
           _offlineReason = 'Dịch vụ AI trực tuyến quá tải (HTTP 429)';
         } else if (e is AIServiceException && (e.statusCode == 401 || e.statusCode == 403)) {
           _offlineReason = 'Khóa API không hợp lệ hoặc hết hạn';
         } else if (e.toString().contains('TimeoutException')) {
           _offlineReason = 'Quá thời gian phản hồi (> 10s)';
         } else {
           _offlineReason = 'Mất kết nối Internet hoặc chưa có API Key';
         }
         final offlineReply = OfflineSleepEngine.getAdvice(prompt);
         // Lưu tin nhắn bot với is_offline = 1
         ```
    8. `_isThinking = false; notifyListeners();`.
  - Triển khai `clearHistory()`: gọi `_databaseHelper.clearAllAIMessages()` (sử dụng biến đã inject) và làm mới danh sách `_messages`.

- [ ] **Bước 3: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/ai_assistant_provider_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 4: Commit**
  ```bash
  git add nhom07-65ktpm/src/lib/providers/ai_assistant_provider.dart nhom07-65ktpm/src/test/ai_assistant_provider_test.dart
  git commit -m "feat(nhom07-65ktpm): nang cap ai_assistant_provider voi debounce, di, va offline reason"
  ```

---

### Tác Vụ 7: Hoàn Thiện Giao Diện Chat UI (AIAssistantScreen), SleepContext & Dialog Cấu Hình Key

**Tệp tin:**
- Sửa đổi: `nhom07-65ktpm/src/lib/screens/ai_assistant/ai_assistant_screen.dart`
- Kiểm thử: `nhom07-65ktpm/src/test/ai_assistant_screen_test.dart`

**Giao diện kết nối:**
- Tiêu thụ: Trạng thái từ `AIAssistantProvider` và `SleepProvider`.
- Cung cấp: Màn hình Chat UI hoàn chỉnh với AppBar có nút Cấu hình Key (hỗ trợ Demo), nút Xóa lịch sử (kèm Confirm Dialog), Banner ngoại tuyến hiển thị đúng nguyên nhân `_offlineReason` bằng `.withValues(alpha: 0.3)`, Tag `[Ngoại tuyến]` trên tin nhắn, Medical Disclaimer cố định ở chân màn hình, và kích hoạt gửi câu hỏi khi bấm Quick Chips.

- [ ] **Bước 1: Viết widget test kiểm tra hiển thị Banner Ngoại tuyến, Reason, Disclaimer và Key Dialog**
  ```dart
  // nhom07-65ktpm/src/test/ai_assistant_screen_test.dart
  import 'package:flutter_test/flutter_test.dart';

  void main() {
    testWidgets('AIAssistantScreen displays offline banner with specific reason using withValues', (tester) async {
      // Bơm widget với mock provider isOfflineMode = true, offlineReason = 'Mất kết nối Internet'
      // Kiểm tra tìm thấy text banner
    });
    testWidgets('AIAssistantScreen displays fixed Medical Disclaimer', (tester) async {
      // Kiểm tra tìm thấy dòng khuyến cáo y tế ở chân màn hình
    });
  }
  ```

- [ ] **Bước 2: Cập nhật `ai_assistant_screen.dart`**
  - Nút Action trên AppBar:
    1. **Nút Cấu hình API Key (Icon `Icons.vpn_key_outlined`):** Mở `showDialog` cho phép nhập/dán Gemini API Key trực tiếp, có nút Lưu (gọi `ApiKeyManager().saveCustomApiKey(key)`) và Xóa key để dễ dàng demo trực tiếp trước giảng viên.
    2. **Nút Xóa lịch sử (Icon `Icons.delete_outline`):** Hiển thị `AlertDialog` xác nhận trước khi gọi `provider.clearHistory()`.
  - Dải Banner Ngoại tuyến dưới AppBar (Sử dụng chuẩn `.withValues` của Flutter 3.x):
    ```dart
    if (aiProv.isOfflineMode)
      Container(
        color: Colors.amber.shade900.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '⚠️ Chế độ ngoại tuyến: ${aiProv.offlineReason ?? "Tri thức cục bộ"}',
                style: const TextStyle(fontSize: 12, color: Colors.amber),
              ),
            ),
          ],
        ),
      ),
    ```
  - Xử lý Quick Chips: Khi bấm vào chip, tự động gọi `_handleSend(chipText)`.
  - Hàm `_handleSend([String? presetText])`:
    - Đọc đối chiếu chính xác từ `SleepProvider`:
      ```dart
      final sleepProv = context.read<SleepProvider>();
      final goalHours = sleepProv.goal.targetDurationHours;
      final compliance = sleepProv.complianceRate.round();
      final avgHours = sleepProv.averageDurationHours.toStringAsFixed(1);
      final summary = 'Mục tiêu: ${goalHours}h. Tỷ lệ tuân thủ 7 ngày: $compliance%. Thời lượng ngủ TB: ${avgHours}h.';
      ```
    - Gọi `aiProv.sendMessage(text, sleepSummary: summary)`.
  - Bong bóng tin nhắn:
    - Nếu `message.isOffline == true`: hiển thị nhãn chip nhỏ `[Ngoại tuyến]` màu xám trên đầu bong bóng bot.
  - Chân trang màn hình (dưới ô nhập chat): Thêm dòng Medical Disclaimer cố định:  
    *“DCSleep AI cung cấp kiến thức vệ sinh giấc ngủ nhằm xây dựng thói quen khoa học, không thay thế chẩn đoán y tế.”*

- [ ] **Bước 3: Chạy test xác nhận vượt qua**
  - Chạy: `flutter test test/ai_assistant_screen_test.dart`
  - Kết quả mong đợi: PASS.

- [ ] **Bước 4: Commit**
  ```bash
  git add nhom07-65ktpm/src/lib/screens/ai_assistant/ai_assistant_screen.dart nhom07-65ktpm/src/test/ai_assistant_screen_test.dart
  git commit -m "feat(nhom07-65ktpm): hoan thien ai_assistant_screen voi key dialog demo, withValues va disclaimer"
  ```

---

### Tác Vụ 8: Tích Hợp Kiểm Thử Toàn Diện & Nghiệm Thu Tiêu Chí

**Tệp tin:**
- Kiểm thử tích hợp: `nhom07-65ktpm/src/test/ai_assistant_integration_test.dart`

**Giao diện kết nối:**
- Kiểm thử toàn diện 8 tiêu chí nghiệm thu từ Mục 8 của bản đặc tả kỹ thuật với `sqflite_common_ffi` và `inMemoryDatabasePath`.

- [ ] **Bước 1: Viết test tích hợp end-to-end với SQLite In-Memory**
  ```dart
  // nhom07-65ktpm/src/test/ai_assistant_integration_test.dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:sqflite_common_ffi/sqflite_ffi.dart';
  import 'package:dcsleep/data/database/database_helper.dart';

  void main() {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      await DatabaseHelper.instance.initCustomDatabase(path: inMemoryDatabasePath);
    });

    tearDown(() async {
      await DatabaseHelper.instance.closeDatabase();
    });

    test('End-to-end flow: safe prompt, medication block, and offline fallback', () async {
      // Kiểm thử toàn bộ 8 tiêu chí nghiệm thu không để lại file database rác
    });
  }
  ```

- [ ] **Bước 2: Chạy toàn bộ test suite của dự án**
  - Chạy: `cd nhom07-65ktpm/src && flutter test`
  - Kết quả mong đợi: 100% tests PASS.

- [ ] **Bước 3: Chạy phân tích tĩnh mã nguồn**
  - Chạy: `cd nhom07-65ktpm/src && flutter analyze`
  - Kết quả mong đợi: No issues found (0 errors, 0 warnings).

- [ ] **Bước 4: Commit hoàn tất toàn bộ phân hệ**
  ```bash
  git add nhom07-65ktpm/src/
  git commit -m "test(nhom07-65ktpm): hoan tat kiem thu toan dien phan he ai sleep assistant dat chuan nghiem thu"
  ```
