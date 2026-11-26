# Hợp đồng dữ liệu giữa các tính năng

Tài liệu này chốt **định dạng dữ liệu** và **interface** mà các tính năng dùng để nói chuyện với nhau. Nhờ vậy mỗi người code và test trên app ngay bằng bản giả, không phải chờ người khác làm xong. Quy trình làm việc xem [lam-viec-song-song.md](lam-viec-song-song.md).

> **Quy tắc vàng:** muốn đổi một định dạng hay chữ ký hàm trong tài liệu này thì báo cả nhóm trước, rồi sửa trong cùng một PR: tài liệu, model Dart, bản giả và test.

## Mục lục

1. [Bản đồ hợp đồng](#1-bản-đồ-hợp-đồng)
2. [Bài học và từ vựng](#2-bài-học-và-từ-vựng-json)
3. [Sự kiện học tập](#3-sự-kiện-học-tập)
4. [Kết quả chấm phát âm](#4-kết-quả-chấm-phát-âm)
5. [Mẹo phát âm](#5-mẹo-phát-âm)
6. [Nét chữ Hán](#6-nét-chữ-hán)
7. [Outbox (đồng bộ offline)](#7-outbox-đồng-bộ-offline)
8. [Người dùng và đăng nhập](#8-người-dùng-và-đăng-nhập)

---

## 1. Bản đồ hợp đồng

Toàn bộ nằm trong `src/app/lib/core/contracts/`. Chỉ cần `import 'package:chailish/core/contracts/contracts.dart';`.

| Hợp đồng | Provider | Bản giả hiện tại | Chủ bản thật | Ai dùng |
|---|---|---|---|---|
| `LessonRepository` | `lessonRepositoryProvider` | `AssetLessonRepository` đọc `assets/dev/lessons/` | Hoa #18 #19 | Bài học, Flashcard, Lộ trình, Kiểm tra, AI |
| `SrsService` | `srsServiceProvider` | `FakeSrsService` (từ của 2 bài đầu) | Hoa #20 | Trang chủ, Bài học |
| `TtsService` | `ttsServiceProvider` | *(đã thật)* `FlutterTtsService` | Khánh #12 | Phát âm, Từ vựng, Flashcard, Kiểm tra, AI |
| `PinyinService` | `pinyinServiceProvider` | `FakePinyinService` (tra từ bài mẫu) | Khánh #12 | Phát âm, Viết chữ |
| `SpeechRecognizer` | `speechRecognizerProvider` | *(đã thật)* `SpeechToTextRecognizer` | Khánh #11 | Phát âm, AI |
| `VoiceRecorder` | `voiceRecorderProvider` | `FakeVoiceRecorder` (sóng âm hình sin) | Khánh #11 | Phát âm |
| `PronunciationScorer` | `pronunciationScorerProvider` | `FakePronunciationScorer` | Khánh #13 #14 | Phát âm |
| `scoringModeProvider` | (Notifier) | *(thật, chưa lưu xuống máy)* mặc định ưu tiên online | Đệ #24 (màn Cài đặt + lưu) | Khánh #14 |
| `pronunciationTipsProvider` | (FutureProvider) | file mẫu 3 mẹo | Hoa #22 (dữ liệu) | Phát âm #15 |
| `HanziRepository` | `hanziRepositoryProvider` | `FakeHanziRepository` (一二三十人大口) | Đệ #26 | Viết chữ, Trang chủ |
| `Outbox` | `outboxProvider` | `MemoryOutbox` (RAM, chưa retry) | Đệ #23 #25 | ProgressService và mọi dữ liệu cần đồng bộ |
| `ProgressService` | `progressServiceProvider`, `learningEventsProvider` | *(thật)* `LocalProgressService` | Phúc | Mọi tính năng ghi; Bảo, Hoa (#21), Đệ (#28) đọc |
| `AuthRepository` | `authRepositoryProvider`, `currentUserProvider` | *(thật, gọi API #6)* | Phúc / Đệ #24 (UI) | Đăng nhập, Hồ sơ, Trang chủ |

Menu dev trong app (nút cờ lê trên trang chủ, chỉ có ở bản debug) liệt kê bảng này kèm nhãn **GIẢ / THẬT**.

**Cách thay bản giả bằng bản thật:** chỉ sửa provider của mình, không sửa nơi dùng:

```dart
final pronunciationScorerProvider = Provider<PronunciationScorer>((ref) {
  if (AppConfig.fakeData) return FakePronunciationScorer();      // --dart-define=FAKE_DATA=true
  return HybridPronunciationScorer(ref.watch(apiClientProvider)); // bản thật của Khánh
});
```

Giữ lại bản giả: test của người khác và chế độ `FAKE_DATA=true` còn dùng.

---

## 2. Bài học và từ vựng (JSON)

**Nguồn duy nhất:** `nhom11-65ktpm/data/lessons/<cấp>/lesson-XX.json` (hiện có 3 bài HSK1 mẫu).
- Server nạp bằng `scripts/seed_dev.py` (dev). Script nạp chính thức là việc của Hoa ở #18.
- App đọc bản sao trong `src/app/assets/dev/lessons/`. Sau khi sửa `data/` chạy `bash scripts/sync_dev_data.sh`; test `contracts_test.dart` sẽ báo lỗi nếu hai nơi lệch nhau.

```json
{
  "schemaVersion": 1,
  "contentVersion": 1,
  "id": "hsk1-greetings-01",          // mã ổn định, không đổi khi đã phát hành
  "level": "HSK1",                    // PINYIN | HSK1 | HSK2
  "order": 1,
  "title": "Chào hỏi cơ bản",
  "topic": "chào hỏi",
  "description": "…",
  "vocabulary": [
    {
      "id": "ni-hao",                 // mã từ, duy nhất trong bài
      "hanzi": "你好",
      "pinyin": "nǐ hǎo",             // có dấu, cách nhau theo âm tiết
      "hanViet": "nhĩ hảo",
      "meaningVi": "xin chào",
      "example": { "hanzi": "你好！", "pinyin": "Nǐ hǎo!", "meaningVi": "Xin chào!" }
    }
  ],
  "grammarPoints": [
    { "id": "gp-shi", "pattern": "A 是 B", "explanationVi": "…", "examples": ["我是学生。"] }
  ],
  "aiScenario": {                     // cho trợ lý AI (#8)
    "aiRole": "…", "learnerRole": "…", "situation": "…", "openingLine": "你好！你是学生吗？"
  }
}
```

Trong app: `Lesson` / `Word` / `GrammarPoint` (`models/lesson.dart`).
- `Lesson.id` là id số trên server. Với dữ liệu mẫu, id = thứ tự (1, 2, 3...), giống id mà `seed_dev.py` tạo trên CSDL mới.
- `Word.key` = `"<mã bài>/<mã từ>"` (vd. `hsk1-greetings-01/ni-hao`) là khoá duy nhất của một từ, dùng cho thẻ SRS và `refId` của sự kiện.

---

## 3. Sự kiện học tập

Mỗi hoạt động học xong sinh **một sự kiện**. Server tự cộng XP, tính `daily_stats`, `streaks` từ sự kiện, nên các màn tổng hợp không phải gọi vào module của người khác.

**Ghi từ app:**

```dart
await ref.read(progressServiceProvider).record(LearningEvent(
  type: LearningEventType.characterWritten,
  xp: 2, durationSec: 55, score: 88, refId: '好',
  data: {'mode': 'free', 'wrong_strokes': 1},
));
```

`record()` lưu trên máy ngay, rồi đưa vào Outbox để gửi `POST /api/events` (chưa đăng nhập / mất mạng thì chờ gửi sau).

**Ghi trên server** (vd. bài kiểm tra chấm ở server):

```python
from app.models import EventType
from app.services.progress import NewEvent, record_events

record_events(db, user, [NewEvent(type=EventType.QUIZ_COMPLETED, xp=50, score=85, ref_id="node-4")])
db.commit()
```

**Đọc:**
- App: `ref.watch(learningEventsProvider)` → `ProgressSummary.from(events)` (XP, streak, phút học theo ngày, số lượng theo loại).
- Server: bảng `daily_stats`, `streaks`, `users.xp_total`, hoặc `GET /api/events?since=…&type=…`.

### API

`POST /api/events` (Bearer token):

```json
{ "events": [ {
    "id": "6f1c…-uuid-v4",            // app sinh; gửi lại cùng id sẽ bị bỏ qua
    "type": "pronunciation_scored",
    "occurred_at": "2026-11-21T12:30:00Z",
    "xp": 5, "duration_sec": 40, "score": 92,
    "ref_id": "你好",
    "data": { "tones": { "1": 90, "2": 70, "3": 85, "4": 95 } }
} ] }
```

→ `{ "accepted": 1, "duplicates": 0, "xp_total": 664, "current_streak": 16, "longest_streak": 16 }`

Giới hạn: tối đa 200 sự kiện/lô, `xp` 0–500, `duration_sec` ≤ 4 giờ, `score` 0–100, `occurred_at` không ở tương lai.

`GET /api/events?since=<ISO>&type=<loại>&type=<loại>&limit=200` → danh sách, mới nhất trước.

### Các loại sự kiện và XP gợi ý

| `type` | Ai ghi | `ref_id` | `score` | `data` | XP gợi ý |
|---|---|---|---|---|---|
| `lesson_completed` | Hoa #19 / Bảo #29 | mã bài | điểm bài | – | 20 |
| `srs_review` | Hoa #20 | `Word.key` | – | `{"quality": 0..5, "card_type": "…"}` | 1 |
| `pronunciation_scored` | Khánh #15 | câu / từ mẫu (chữ Hán) | `overall` | `{"tones": {"1":…,"4":…}, "source": "online"}` | 2, ≥ 90 điểm: 5 |
| `character_written` | Đệ #27 | chữ Hán | điểm chữ | `{"mode": "watch/trace/free", "wrong_strokes": n, "hints": n}` | 2 |
| `ai_session_finished` | **server tự ghi** khi kết thúc phiên AI | id phiên | điểm tổng kết | `{"lesson_id": n}` | 10 |
| `quiz_completed` | Bảo #32 | id node lộ trình | % điểm | `{"passed": true}` | đạt: 50, không đạt: 10 |
| `placement_completed` | Bảo #30 | – | điểm | `{"level": "HSK1"}` | 0 |
| `study_session` | bất kỳ | – | – | – | 0 (chỉ cộng phút học) |

`duration_sec` cộng vào số phút học trong ngày (mục tiêu học mỗi ngày, biểu đồ cột #33). Cần loại sự kiện mới thì thêm vào `EventType` (server) + `LearningEventType` (app) + bảng này trong cùng một PR.

---

## 4. Kết quả chấm phát âm

Dùng **chung** cho engine offline (#13) và API online (#14). Màn phản hồi (#15) chỉ đọc định dạng này. API `POST /api/pronunciation/assess` trả đúng JSON sau:

```json
{
  "overall": 84, "accuracy": 86, "tone": 78, "fluency": 90, "completeness": 100,
  "source": "online",                       // online | offline
  "recognized_text": "你好",
  "syllables": [
    {
      "hanzi": "你",
      "expected": { "initial": "n", "final": "i", "tone": 3 },
      "actual":   { "initial": "n", "final": "i", "tone": 2 },   // null = bỏ sót âm tiết
      "score": 72,
      "status": "warn",                    // ok (xanh) | warn (vàng) | error (đỏ)
      "errors": ["tone"]                   // initial | final | tone | missing | extra
    }
  ]
}
```

- `PinyinService.toPinyin(hanzi)` trả thanh điệu gốc (hiển thị); `toPinyin(hanzi, applySandhi: true)` trả cách đọc sau biến điệu, nên dùng làm `expected` khi chấm.
- Thanh điệu: 1–4, **5 = thanh nhẹ**. Tách âm tiết bằng `splitPinyin()` (trong `pronunciation_scorer.dart`). Khánh có thể thay bằng bản đầy đủ hơn ở #13.
- Ghi âm (`VoiceRecorder.stop()`) trả `Recording(path, duration)`: file WAV 16 kHz mono. Bản giả trả `path = null`.

---

## 5. Mẹo phát âm

File `src/app/assets/data/pronunciation_tips.json` (Hoa #22). Màn phản hồi tra mẹo theo **âm bị sai** (`expected.initial`, `expected.final`, hoặc `tone<N>`):

```json
{ "schemaVersion": 1, "tips": [ {
    "sound": "zh",                 // khoá tra: thanh mẫu, vận mẫu ("ü", "ian"…) hoặc "tone1".."tone4"
    "title": "Âm zh (uốn lưỡi)",
    "mouthVi": "…", "tongueVi": "…", "compareVi": "so sánh với âm tiếng Việt…",
    "examples": ["中 zhōng", "这 zhè"]
} ] }
```

Bộ **test case chấm điểm** (#22 → #16): `nhom11-65ktpm/data/pronunciation/test_cases.json`, mỗi phần tử gồm `{ "id", "reference": {"hanzi","pinyin"}, "spoken_pinyin": "zi4 ji3", "expected": {"min_overall","max_overall","error_syllables":[0]}, "note": "nhầm zh → z" }`.

---

## 6. Nét chữ Hán

Cùng định dạng `graphics.txt` của [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) (giấy phép Arphic Public License, ghi nguồn trong màn Giới thiệu):

```json
{ "character": "口",
  "strokes": ["M 230 640 L … Z", "…"],          // SVG path từng nét, theo thứ tự viết
  "medians": [[[230,640],[260,40]], …] }        // đường trung tâm từng nét
```

Hệ toạ độ 1024 × 1024, **trục y hướng lên**; đổi sang màn hình bằng `Offset(x, 900 - y)` rồi scale theo ô vẽ. Model: `HanziStrokes`.

---

## 7. Outbox (đồng bộ offline)

Dữ liệu học tập **không gọi thẳng API ghi**, mà đưa vào hàng đợi:

```dart
await ref.read(outboxProvider).enqueue(OutboxItem(kind: 'srs_card', payload: card.toJson()));
```

| `kind` | Gửi tới | Chủ |
|---|---|---|
| `event` | `POST /api/events` (theo lô) | có sẵn |
| `srs_card` | `POST /api/sync/push` | Hoa #20 + Đệ #25 |
| `writing_attempt` | `POST /api/sync/push` | Đệ #27 #25 |
| `pronunciation_attempt` | `POST /api/sync/push` | Khánh #14 + Đệ #25 |

`id` của item (UUID) cũng là id bản ghi trên server, nhờ đó gửi lại không bị ghi trùng. `MemoryOutbox` hiện chỉ gửi `event`; bản SQLite + retry + ánh xạ các `kind` khác là việc của Đệ (#23, #25).

---

## 8. Người dùng và đăng nhập

- API có sẵn (#6): `POST /api/auth/register | login | refresh | logout | forgot-password | reset-password`, `GET /api/me`.
- App: `authRepositoryProvider` có `login`, `register`, `logout`, `currentUser`; `currentUserProvider` trả `UserProfile?`. Sau khi đăng nhập/đăng xuất gọi `ref.invalidate(currentUserProvider)`.
- Tài khoản dev (`python -m scripts.seed_dev`): `demo@chailish.dev` (có 30 ngày học, tiến độ lộ trình, thẻ SRS) và `new@chailish.dev` (mới tinh), mật khẩu `Demo12345`. Đăng nhập nhanh bằng menu dev.
