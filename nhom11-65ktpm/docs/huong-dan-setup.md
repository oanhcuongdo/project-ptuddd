# Hướng dẫn setup dự án ChaiLish cho thành viên nhóm 11

Tài liệu này giúp một thành viên mới clone code, chạy được backend và app trên máy ảo hoặc điện thoại thật, chạy test và mở Pull Request đúng quy trình. Làm lần lượt từ trên xuống.

> Chỉ làm việc trong thư mục `nhom11-65ktpm/`. Không commit file nằm ngoài thư mục này và không push lên repo gốc (`upstream`).

## 1. Cài công cụ

| Công cụ | Phiên bản | Ghi chú |
|:--|:--|:--|
| Git | bản mới | |
| Flutter SDK | **3.47.x** (Dart 3.13) | Đúng bản CI đang dùng (`3.47.3`). Bản cũ hơn sẽ lỗi `sdk: ^3.13.3` khi `flutter pub get`. |
| Android Studio | bản mới | Cài Android SDK **Platform 37** và Build-Tools trong SDK Manager. |
| JDK | 17 trở lên | Dùng JDK đi kèm Android Studio là đủ. |
| Python | **3.12** | Bản 3.11 cũng chạy, nhưng CI và Docker dùng 3.12. |
| Docker Desktop / Docker Engine | bản mới | Dùng để chạy PostgreSQL 16, không cần cài PostgreSQL vào máy. |

Kiểm tra sau khi cài:

```bash
flutter --version          # Flutter 3.47.x
flutter doctor             # các mục Android toolchain phải có dấu ✓
flutter doctor --android-licenses   # chấp nhận license nếu doctor yêu cầu
python --version           # Python 3.12.x
docker --version
```

## 2. Lấy mã nguồn

Nhóm làm việc trên repo fork `LoudlyDawn2108/project-ptuddd`, nhánh chính của nhóm là `nhom/nhom11-65ktpm`. Nhờ nhóm trưởng thêm bạn làm Collaborator trước.

```bash
git clone https://github.com/LoudlyDawn2108/project-ptuddd.git
cd project-ptuddd
git checkout nhom/nhom11-65ktpm
```

Nếu đã clone từ trước thì chỉ cần cập nhật:

```bash
git checkout nhom/nhom11-65ktpm
git pull origin nhom/nhom11-65ktpm
```

## 3. Chạy backend (FastAPI + PostgreSQL)

Cách khuyên dùng khi phát triển: **PostgreSQL chạy bằng Docker, API chạy bằng Python trên máy** để có hot-reload.

### 3.1. Tạo môi trường Python

```bash
cd nhom11-65ktpm/src/server
python -m venv .venv
source .venv/bin/activate          # Linux / macOS
# .venv\Scripts\Activate.ps1       # Windows PowerShell
pip install -r requirements.txt
```

### 3.2. Tạo file `.env`

```bash
cp .env.example .env               # Windows: copy .env.example .env
```

Giá trị mặc định trong `.env.example` đã đủ để chạy local. Những biến bạn có thể cần sửa:

| Biến | Khi nào cần sửa |
|:--|:--|
| `DATABASE_URL` | Giữ nguyên nếu dùng PostgreSQL bằng Docker như bước 3.3. |
| `ANTHROPIC_API_KEY` hoặc `OPENAI_API_KEY` | Chỉ khi cần thử Trợ lý AI thật. Chọn nhà cung cấp bằng `AI_PROVIDER=anthropic` hoặc `openai`. Mỗi lần gọi đều tốn tiền, không cần thì để trống. |
| `ANTHROPIC_MODEL` | Đổi sang `claude-haiku-5-5` để tiết kiệm khi thử nghiệm. |
| `SMTP_*` | Để trống thì mã OTP quên mật khẩu chỉ được in ra log của server. |

**Không bao giờ commit file `.env`** (đã có trong `.gitignore`). API key chỉ nằm ở server, không đưa vào app.

### 3.3. Chạy PostgreSQL 16

```bash
# vẫn ở nhom11-65ktpm/src/server
docker compose up -d db
```

Lệnh này chỉ bật container `db` (cổng `5432`, user/pass `postgres/postgres`, database `chailish_db`), dữ liệu được giữ trong volume. Nếu máy đã có PostgreSQL chiếm cổng 5432 thì tắt nó đi, hoặc đổi `POSTGRES_PORT` trong `.env` và sửa cổng trong `DATABASE_URL` cho khớp.

### 3.4. Tạo bảng, nạp dữ liệu mẫu và chạy server

```bash
alembic upgrade head
python -m scripts.seed_dev
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Kiểm tra:

- <http://localhost:8000/api/health> trả về `"database": "connected"`.
- Swagger để thử API: <http://localhost:8000/docs>.

`scripts.seed_dev` nạp dữ liệu để test ngay, không cần tự nhập:

| Dữ liệu | Chi tiết |
|:--|:--|
| Bài học | Khóa HSK1 gồm 3 bài, mỗi bài 9 từ, có điểm ngữ pháp và kịch bản cho Trợ lý AI: id=1 Chào hỏi cơ bản, id=2 Gia đình tôi, id=3 Số đếm và tuổi. |
| Lộ trình | Chặng "HSK 1 - Khởi động": 3 bài và bài kiểm tra cuối chặng. |
| `demo@chailish.dev` / `Demo12345` | Đã học xong bài 1, đang học bài 2. Có 14 thẻ flashcard (một phần đến hạn hôm nay), thống kê 7 ngày, chuỗi 4 ngày học. |
| `new@chailish.dev` / `Demo12345` | Tài khoản trống, dùng để test luồng người dùng mới. |

Chạy lại lệnh bao nhiêu lần cũng được: nội dung bài học được cập nhật, dữ liệu của tài khoản demo giữ nguyên. Muốn đưa tài khoản demo về trạng thái ban đầu thì chạy `python -m scripts.seed_dev --reset`. Script luôn từ chối chạy khi `ENVIRONMENT=production`.

> Đây chỉ là dữ liệu test. Script nạp nội dung bài học chính thức thuộc issue #18.

Khi có người thêm migration mới (thư mục `alembic/versions/`), chạy lại `alembic upgrade head` sau khi pull.

### 3.5. Chạy cả stack bằng Docker (tùy chọn)

`docker compose up -d --build` chạy đủ `db` + `api` + `nginx` (HTTPS với chứng chỉ tự ký). Cách này dùng để thử giống môi trường triển khai, xem [trien-khai-docker.md](trien-khai-docker.md). Khi code app thì nên dùng cách ở trên, vì app Flutter không chấp nhận chứng chỉ tự ký.

## 4. Chạy app Flutter

```bash
cd nhom11-65ktpm/src/app
flutter pub get
flutter devices
```

Địa chỉ API của app đọc từ `--dart-define=API_BASE_URL`, không truyền thì mặc định là `http://10.0.2.2:8000/api`.

### 4.1. Android Emulator

```bash
flutter run
```

`10.0.2.2` là địa chỉ máy tính nhìn từ bên trong emulator, nên không cần cấu hình gì thêm.

### 4.2. Điện thoại Android thật qua cáp USB (khuyên dùng)

1. Bật **Tùy chọn nhà phát triển** → **Gỡ lỗi USB** trên điện thoại, cắm cáp và bấm "Cho phép" khi máy hỏi.
2. Chuyển tiếp cổng 8000 của điện thoại về máy tính, rồi chạy:

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

Phải chạy lại `adb reverse` mỗi lần rút cáp ra cắm lại.

### 4.3. Điện thoại thật qua Wi-Fi

Điện thoại và máy tính phải cùng mạng; uvicorn phải chạy với `--host 0.0.0.0` như ở bước 3.4.

```bash
flutter run --dart-define=API_BASE_URL=http://<IP-LAN-của-máy-tính>:8000/api
# ví dụ http://192.168.1.15:8000/api — xem IP bằng ipconfig (Windows) hoặc ip addr (Linux)
```

Nếu không kết nối được thì mở cổng 8000 trên tường lửa của máy tính.

### 4.4. Đăng nhập khi app chưa có màn hình đăng nhập

Hầu hết API cần đăng nhập. Khi màn hình đăng nhập chưa xong, app sẽ báo "Phiên đăng nhập đã hết hạn". Để thử API, dùng Swagger <http://localhost:8000/docs>:

1. Gọi `POST /api/auth/login` với `{"email": "demo@chailish.dev", "password": "Demo12345"}` rồi copy `access_token` trả về.
2. Bấm nút **Authorize**, dán token vào (không cần gõ chữ `Bearer`).
3. Gọi các API cần thử.

## 5. Chạy test trước khi mở Pull Request

Backend test dùng SQLite trong bộ nhớ, không cần bật PostgreSQL và không gọi AI thật:

```bash
cd nhom11-65ktpm/src/server && python -m pytest -q
cd nhom11-65ktpm/src/app && flutter analyze && flutter test
```

Hoặc chạy giống hệt CI bằng một lệnh, từ thư mục gốc repo:

```bash
bash nhom11-65ktpm/scripts/ci.sh            # cả hai
bash nhom11-65ktpm/scripts/ci.sh backend    # chỉ backend
bash nhom11-65ktpm/scripts/ci.sh mobile     # chỉ Flutter
```

Trên Windows hãy chạy script này bằng Git Bash.

## 6. Quy trình làm một issue

```bash
git checkout nhom/nhom11-65ktpm
git pull origin nhom/nhom11-65ktpm
git checkout -b feat/<ten>/<tinh-nang>        # ví dụ feat/khanh/voice-recording-stt

# ... code + test ...

git add nhom11-65ktpm/
git commit -m "feat(nhom11-65ktpm): mo ta ngan gon (#<so-issue>)"
git push -u origin feat/<ten>/<tinh-nang>
```

Mở Pull Request trên GitHub:

- **base** chọn `nhom/nhom11-65ktpm` của repo `LoudlyDawn2108/project-ptuddd`, **không chọn** `main` và không chọn repo gốc `oanhcuongdo/project-ptuddd`.
- Trong mô tả ghi `Refs #<số issue>`, gán reviewer theo bảng phân công trong issue.
- Dùng `gh` thì thêm `-R LoudlyDawn2108/project-ptuddd`, hoặc chạy một lần `gh repo set-default LoudlyDawn2108/project-ptuddd`.

## 7. Những thứ đã có sẵn để dùng lại

> Làm màn hình mới thì đọc trước **[huong-dan-thiet-ke-ui.md](huong-dan-thiet-ke-ui.md)** (màu, chữ, bo góc, vật liệu kính, chuyển động, checklist trước khi mở PR).
>
> Cần dữ liệu của tính năng khác (bài học, chấm phát âm, nét chữ, XP/streak...)? Dùng hợp đồng trong `lib/core/contracts/` (có sẵn bản giả). Xem **[lam-viec-song-song.md](lam-viec-song-song.md)** và **[hop-dong-du-lieu.md](hop-dong-du-lieu.md)**. Menu dev: nút cờ lê trên trang chủ (bản debug).

| Cần làm | Dùng cái gì |
|:--|:--|
| API yêu cầu đăng nhập | `CurrentUser` và `DbSession` trong `app/api/deps.py`. |
| Lấy bản ghi của đúng người dùng, không thì trả 404 | `get_owned_or_404` trong `app/api/deps.py`. |
| Bảng mới cần đồng bộ offline (id do app sinh) | Kế thừa `UserOwnedSyncMixin` trong `app/models/_mixins.py`. |
| Thêm/sửa bảng | Sửa model rồi chạy `alembic revision --autogenerate -m "mo ta"`. Đọc lại file sinh ra trước khi commit. |
| Gọi API từ app | `ApiClient` trong `lib/core/network/api_client.dart` (tự gắn token, tự refresh khi gặp 401). |
| Nhận dữ liệu streaming | `ApiClient.postStream` + `parseSse` trong `lib/core/network/sse.dart`. |
| Thay TTS/STT của màn chat AI bằng engine khác | Override `chatTtsProvider` / `chatSpeechInputProvider` trong `features/ai_chat/data/chat_voice_services.dart`. |
| Hợp đồng API Trợ lý AI | [api-tro-ly-ai.md](api-tro-ly-ai.md). |
| Khung màn hình đúng giao diện chung (nền loang + thanh tiêu đề kính) | `GlassScaffold` + `GlassAppBar` trong `lib/core/widgets/glass.dart`. Nội dung cuộn xuyên dưới thanh tiêu đề, nên chừa `MediaQuery.paddingOf(context).top` ở padding trên. |
| Thẻ, nút, nút tròn bằng kính | `GlassCard`, `GlassButton` (`prominent: true` cho nút chính), `GlassIconButton`, `GlassSurface` (lớp kính trần). |
| Kính dày có làm mờ (thanh dưới, ô nhập, chữ trên nền sặc sỡ) | `GlassSurface(thick: true)` hoặc `GlassCard(thick: true)`. |
| Màn hình tạm cho tính năng chưa làm | `ComingSoonView` trong `lib/core/widgets/glass.dart`. |
| Icon nền hình "bánh quy" kiểu Material Expressive | `CookieIcon` trong `lib/core/widgets/expressive_shapes.dart`. |
| Hiệu ứng chạm lò xo + rung nhẹ | Bọc widget bằng `Pressable` (`lib/core/motion/motion.dart`). Không dùng `InkWell`, theme đã tắt hiệu ứng gợn sóng. |
| Phần tử xuất hiện lần lượt | `EntranceAnimation(index: i, child: ...)`. |
| Đổi icon mượt (vd. mic ↔ stop) | `MorphSwitcher` với `Icon(key: ValueKey(...))`. |
| Đường cong chuyển động chuẩn | `AppMotion.springBouncy`, `springSmooth`, `emphasized`. Màu chữ phụ lấy `colorScheme.onSurfaceVariant` thay vì màu cố định để chạy đúng ở chế độ tối. |

## 8. Lỗi hay gặp

| Triệu chứng | Cách xử lý |
|:--|:--|
| `flutter pub get` báo không thỏa `sdk: ^3.13.3` | Nâng Flutter lên 3.47.x (`flutter upgrade`). |
| Build Android báo `requires ... compile against version 37` hoặc `core library desugaring` | Pull nhánh `nhom/nhom11-65ktpm` mới nhất (đã sửa ở PR #44) và cài Android SDK Platform 37. |
| `Gradle build daemon disappeared unexpectedly` | Máy thiếu RAM. Tắt bớt ứng dụng rồi chạy lại, hoặc giảm `-Xmx8G` trong `android/gradle.properties` **ở máy mình** (không commit). |
| App báo mất kết nối / `Connection refused` | Kiểm tra server có chạy không (`/api/health`), đã chạy `adb reverse` chưa, `API_BASE_URL` có đúng không. |
| `/api/health` báo database lỗi | Container chưa chạy: `docker compose up -d db`, rồi chạy lại `alembic upgrade head`. |
| `alembic upgrade head` lỗi `Can't locate revision` | Pull code mới nhất. Nếu database dev đã hỏng, xóa sạch bằng `docker compose down -v` rồi tạo lại (mất toàn bộ dữ liệu dev). |
| Trợ lý AI báo chưa cấu hình | Điền `ANTHROPIC_API_KEY` hoặc `OPENAI_API_KEY` vào `.env` rồi khởi động lại uvicorn. |
| Kính trông như kính mờ thường, không thấy mép bẻ cong nền | Bình thường trên máy ảo dùng Skia, web và `flutter test`: shader khúc xạ chỉ chạy trên Impeller. Xem trên điện thoại thật. |
| Đã sửa shader/theme nhưng mở lại app vẫn thấy giao diện cũ | Hot reload chỉ áp dụng trong phiên `flutter run`. Chạy lại `flutter run` để cài bản mới lên máy. |
| `gh pr create` mở PR sang repo gốc | Thêm `-R LoudlyDawn2108/project-ptuddd` hoặc chạy `gh repo set-default`. |
