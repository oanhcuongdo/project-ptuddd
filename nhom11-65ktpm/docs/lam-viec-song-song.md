# Làm việc song song: không ai phải chờ ai

Cả nhóm cùng code một app. Nếu chia việc theo tầng (người làm dữ liệu → người làm API → người làm màn hình), người đứng sau phải chờ người đứng trước mới chạy được app. Nhóm 11 chia theo **lát dọc**: mỗi người làm trọn một tính năng (dữ liệu + API + màn hình), và nói chuyện với tính năng của người khác qua **hợp đồng có sẵn bản giả**.

Định dạng dữ liệu và interface: [hop-dong-du-lieu.md](hop-dong-du-lieu.md).

## 1. Ai làm gì

| Người | Lát dọc | Issue |
|---|---|---|
| Phúc | Khung app, backend nền, trợ lý AI, khung hợp đồng + sự kiện học tập | #4–#10 |
| Hoa | Nội dung bài học, từ vựng, flashcard SM-2, dữ liệu mẹo phát âm | #17 #18 #19 #20 #22 |
| Khánh | Toàn bộ phát âm: ghi âm, nhận dạng, TTS, pinyin, chấm offline/online, màn hình, test | #11–#16 |
| Đệ | Viết chữ Hán, tài khoản, lưu trữ offline + đồng bộ, thông báo + bảng xếp hạng | #23–#28 |
| Bảo | Lộ trình, kiểm tra đầu vào, kiểm tra cuối chặng, trang chủ, thống kê, huy hiệu, kiểm thử E2E | #21 #29–#34 |

## 2. Sáu quy tắc

1. **Chỉ phụ thuộc vào hợp đồng.** Cần dữ liệu của người khác thì dùng provider trong `core/contracts/`. Không import file trong `features/<tính năng của người khác>/`.
2. **Bản giả trước, bản thật sau.** Mỗi hợp đồng có sẵn bản giả chạy được. Làm màn hình trên bản giả, làm xong bản thật thì chỉ đổi provider của mình.
3. **Mỗi PR chạy được trên app.** Không merge thứ làm hỏng bản giả mà người khác đang dùng. `flutter analyze`, `flutter test`, `pytest` phải xanh (`bash scripts/ci.sh`).
4. **Ghi sự kiện, đừng gọi chéo.** Học xong một thứ thì `progressService.record(...)`. Trang chủ, thống kê, huy hiệu, bảng xếp hạng đọc sự kiện, không gọi vào module của bạn.
5. **Đổi hợp đồng phải báo nhóm.** Sửa tài liệu, model, bản giả và test trong cùng một PR, tag những người đang dùng hợp đồng đó.
6. **Không có ảnh QA thì không merge.** PR phải kèm ảnh / video app thật đang chạy tính năng, chụp từ commit cuối (xem mục 8). Test xanh chưa đủ: code biên dịch được vẫn có thể là code chết.

## 3. Bắt đầu làm một issue

```bash
git checkout nhom/nhom11-65ktpm && git pull
git checkout -b feat/<tên>/<việc>

# Server (một lần, hoặc sau khi có migration mới):
cd nhom11-65ktpm/src/server
alembic upgrade head
python -m scripts.seed_dev --reset     # 3 bài mẫu + tài khoản demo có 30 ngày học
uvicorn app.main:app --reload

# App:
cd ../app
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api   # máy thật: adb reverse tcp:8000 tcp:8000
# Không có server? Vẫn chạy được: mọi hợp đồng có bản giả.
# Ép dùng bản giả kể cả khi đã có bản thật:  --dart-define=FAKE_DATA=true
```

Trong app, bấm nút **cờ lê** trên trang chủ (chỉ có ở bản debug) để mở **menu dev**:
- **Đăng nhập nhanh** `demo@` (có tiến độ) hoặc `new@` (người dùng mới).
- **Tạo 30 ngày học giả** (chỉ trên máy) hoặc **Kéo từ server** để có dữ liệu cho trang chủ / thống kê / huy hiệu.
- **Ghi 1 sự kiện thử**, xem **Outbox** còn bao nhiêu mục chờ gửi.
- Bảng **hợp đồng**: cái nào đang **GIẢ**, cái nào đã **THẬT**.

## 4. Thêm bản thật cho hợp đồng của mình

1. Tạo lớp mới **implements** interface (vd. `HybridPronunciationScorer implements PronunciationScorer`), đặt trong `features/<tính năng>/data/` hoặc ngay `core/contracts/` nếu nhiều nơi dùng.
2. Đổi provider: `AppConfig.fakeData ? FakeX() : RealX(...)`. Giữ nguyên bản giả.
3. Viết test cho bản thật. Test của người khác vẫn dùng bản giả và phải xanh.
4. Mở menu dev kiểm tra nhãn chuyển từ GIẢ sang THẬT.

## 5. Dùng hợp đồng của người khác trong test

```dart
await tester.pumpWidget(ProviderScope(
  overrides: [
    pronunciationScorerProvider.overrideWithValue(FakePronunciationScorer()),
    progressServiceProvider.overrideWithValue(myRecordingProgress),
  ],
  child: const MaterialApp(home: PronunciationScreen()),
));
```

## 6. Thêm dữ liệu dùng chung

- **Bài học:** thêm / sửa `data/lessons/<cấp>/lesson-XX.json`, chạy `bash scripts/sync_dev_data.sh`, rồi `python -m scripts.seed_dev`. Cấp độ mới (vd. `hsk2/`) thì khai báo thêm thư mục trong `src/app/pubspec.yaml`.
- **Mẹo phát âm:** `src/app/assets/data/pronunciation_tips.json`.
- **Loại sự kiện mới:** `EventType` (server) + `LearningEventType` (app) + bảng ở hop-dong-du-lieu.md, trong cùng một PR.

## 7. Gặp vướng

- Bản giả thiếu thứ bạn cần (vd. cần thêm một hàm trong interface): mở PR nhỏ sửa hợp đồng trước (interface + bản giả + tài liệu), tag chủ sở hữu, merge rồi mới làm tiếp.
- Bản thật của người khác có lỗi: tạm chạy với `--dart-define=FAKE_DATA=true`, báo trên issue của họ.

## 8. Mở PR: bằng chứng QA

Mỗi PR vào `nhom/nhom11-65ktpm` phải chứng minh tính năng **thật sự chạy trên app**, để người review đối chiếu được, không chỉ đọc code.

**Mở PR bằng mẫu** [mau-pull-request.md](mau-pull-request.md):

```bash
gh pr create -B nhom/nhom11-65ktpm --body-file nhom11-65ktpm/docs/mau-pull-request.md
# rồi mở PR trên GitHub, bấm Edit, điền và kéo thả ảnh vào mục "Bằng chứng QA"
```

**Ảnh hợp lệ:**
- Chụp **app thật đang chạy** (máy thật, máy ảo hoặc web). Không dùng ảnh thiết kế, ảnh Figma, ảnh golden test.
- Chụp từ **commit cuối** của PR và ghi mã commit. Push thêm thay đổi luồng hoặc giao diện thì chụp lại.
- Đủ **từng bước của luồng chính**: mở màn hình → thao tác → kết quả. Luồng nhiều bước, có ghi âm hoặc hoạt ảnh thì quay video ngắn / GIF.
- Ít nhất **một trường hợp lỗi hoặc trống** (mất mạng, từ chối quyền mic, danh sách rỗng...).
- Làm **bản thật** của hợp đồng: thêm ảnh menu dev cho thấy hợp đồng chuyển sang **THẬT**, và ảnh kết quả đến từ bản thật (vd. điểm phát âm thay đổi theo giọng đọc, không phải số cố định).
- PR **chỉ server**: ảnh Swagger `/docs` hoặc output `curl` gọi endpoint thật, có cả request và response.
- Dán ảnh trực tiếp vào mô tả PR. **Không commit ảnh** vào repo.

**Được miễn:** PR chỉ sửa tài liệu, chỉ thêm test, chỉ sửa CI / script. Ghi rõ `Không cần QA: <lý do>`.

**Người review:**
- Mở từng ảnh, đối chiếu với code: đúng màn hình, đúng luồng, đúng commit.
- Nghi ngờ thì checkout nhánh về chạy thử (`gh pr checkout <số>`).
- **Không Approve** khi thiếu ảnh hoặc ảnh không khớp; chọn *Request changes* và ghi thiếu gì.

**Trưởng nhóm:** không merge (kể cả merge bằng quyền admin) PR thiếu bằng chứng QA hợp lệ.
