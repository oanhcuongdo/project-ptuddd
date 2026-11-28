# Thiết kế Cơ sở dữ liệu — Travel Buddy (Firebase + Supabase Storage)

Tài liệu đặc tả kiến trúc dữ liệu chuẩn cho dự án **Travel Buddy** (Nhóm 8 — Lớp K65 KTPM, Trường Đại học Thủy Lợi), tối ưu cho Flutter (`flutter_riverpod`, `freezed`, `json_serializable`) theo mô hình **Vertical Slices (4 Module độc lập)** và kiến trúc lưu trữ kết hợp **Firebase Auth + Cloud Firestore + Supabase Storage** (thay thế Firebase Cloud Storage).

---

## 1. Kiến trúc Hybrid Backend (Firebase + Supabase)

Việc tách lớp lưu trữ tệp sang Supabase Storage giúp tránh yêu cầu nâng cấp gói trả phí (Blaze Plan) của Firebase Cloud Storage, đồng thời vẫn giữ trọn vẹn khả năng đồng bộ thời gian thực (real-time stream) của Cloud Firestore.

| Thành phần | Dịch vụ sử dụng | Vai trò trong hệ thống |
| :--- | :--- | :--- |
| **Xác thực (Auth)** | Firebase Authentication | Đăng nhập Email/Password, Google Sign-In; sinh `uid` làm khóa định danh duy nhất toàn hệ thống. |
| **Cơ sở dữ liệu (DB)** | Cloud Firestore (`asia-southeast1`) | Lưu toàn bộ dữ liệu nghiệp vụ của 4 module; đồng bộ real-time qua Riverpod `StreamProvider`. |
| **Lưu trữ tệp (Media)** | Supabase Storage | Lưu ảnh đại diện, ảnh bìa chuyến đi, ảnh minh chứng Checklist, biên lai MoMo, hóa đơn OCR, ảnh Check-in. |

### Nguyên tắc thiết kế cốt lõi

- **Subcollection theo `tripId`**: Mọi dữ liệu của 4 module nằm dưới `trips/{tripId}/...` để tránh giới hạn 1 MB/document của Firestore, giảm xung đột code giữa 4 thành viên và tối ưu chi phí đọc.
- **Lưu cặp `Url` + `StoragePath` cho mọi ảnh Supabase**: Mỗi bản ghi có ảnh trên Firestore khuyến nghị lưu cả `imageUrl` (để hiển thị ngay) và `storagePath` (để xóa file rác trên Supabase khi người dùng xóa bản ghi).
- **Tiền tệ dùng kiểu số nguyên (`int`, đơn vị VND)** cho các module mới (Auth/Trip, Module 1, Module 4); riêng Module 2 & 3 giữ tương thích kiểu `double`/`num` đã có test.
- **Thời gian chuẩn hóa bằng `Timestamp`**: Mọi mốc thời gian trên Firestore dùng kiểu `Timestamp`, chuyển đổi qua `TimestampConverter` (`lib/core/utils/timestamp_converter.dart`) trong Freezed/JSON Serializable.
- **Denormalization có kiểm soát**: Các chỉ số tổng hợp trên Dashboard (tiến độ Checklist %, tiến độ Quỹ %, tổng thực chi) được lưu sẵn trên document `trips/{tripId}` và cập nhật nguyên tử bằng `WriteBatch` hoặc `runTransaction`.

---

## 2. Sơ đồ cây Collection trên Cloud Firestore

```text
firestore-root/
├── users/{userId}
├── invite_codes/{inviteCode}
├── checklist_templates/{templateId}
└── trips/{tripId}
    ├── members/{userId}                   # Thành viên & phân quyền (Host / Member)
    ├── checklists/{itemId}                # Module 1: Checklist công việc & hành lý
    ├── momo_fund_config/default           # Module 2 (đã triển khai): Cấu hình quỹ nhóm MoMo
    ├── saving_plans/{memberId}            # Module 2 (đã triển khai): Kế hoạch tích góp định kỳ
    ├── deposit_records/{depositId}        # Module 2 (đã triển khai): Biên lai nạp quỹ & duyệt
    ├── member_streaks/{memberId}          # Module 2 (đã triển khai): Lịch sử Streak & Journal DailyYou
    ├── place_plans/{placeId}              # Module 3 (đã triển khai): Lịch trình địa điểm & GPS Check-in
    ├── budget_envelopes/{envelopeId}      # Module 4: Hũ ngân sách dự kiến (kiểu Cashew)
    ├── expenses/{expenseId}               # Module 4: Ghi chép thực chi & dữ liệu Camera OCR
    └── settlements/{settlementId}         # Module 4: Kết quả tối giản hóa công nợ cuối chuyến
```

---

## 3. Đặc tả chi tiết từng Collection

### 3.1. `users/{userId}` (Root Collection — Auth & Hồ sơ)

Khóa tài liệu (`userId`) trùng khớp 100% với `FirebaseAuth.instance.currentUser!.uid`.

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `uid` | `string` | Có | UID từ Firebase Authentication. |
| `email` | `string` | Có | Email đăng nhập. |
| `displayName` | `string` | Có | Tên hiển thị trong nhóm. |
| `avatarUrl` | `string?` | Không | Public URL ảnh đại diện (Google hoặc Supabase). |
| `avatarStoragePath` | `string?` | Không | Đường dẫn file trên Supabase Storage (nếu tự tải lên). |
| `phoneNumber` | `string?` | Không | Số điện thoại (hỗ trợ đối chiếu tài khoản MoMo). |
| `tripIds` | `array<string>` | Có | Danh sách `tripId` người dùng đang tham gia (phục vụ query nhanh danh sách chuyến đi). |
| `createdAt` | `Timestamp` | Có | Thời điểm tạo tài khoản. |
| `updatedAt` | `Timestamp` | Có | Thời điểm cập nhật hồ sơ gần nhất. |

---

### 3.2. `invite_codes/{inviteCode}` (Root Collection — Tra cứu QR tham gia nhóm)

Tách riêng bảng tra cứu mã mời để người dùng chưa thuộc chuyến đi có thể quét QR lấy `tripId` trong `O(1)` mà không cần mở quyền đọc toàn bộ collection `trips`.

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `code` | `string` | Có | Mã mời viết hoa 6–8 ký tự (trùng Document ID, VD: `TB8K4M`). |
| `tripId` | `string` | Có | ID của chuyến đi đích. |
| `tripTitle` | `string` | Có | Tên chuyến đi hiển thị xem trước khi xác nhận tham gia. |
| `createdBy` | `string` | Có | `uid` của Trưởng nhóm (Host). |
| `isActive` | `bool` | Có | Cho phép Host vô hiệu hóa mã mời cũ nếu cần. |
| `expiresAt` | `Timestamp?` | Không | Thời điểm hết hạn mã mời (tùy chọn). |
| `createdAt` | `Timestamp` | Có | Thời điểm tạo mã. |

---

### 3.3. `checklist_templates/{templateId}` (Root Collection — Thư viện mẫu Checklist)

Dữ liệu mẫu (seed data) chỉ đọc cho Module 1, tương ứng các loại hình: `beach` (Du lịch biển), `trekking` (Leo núi/Cắm trại), `motorbike` (Phượt xe máy), `backpacking` (Du lịch tự túc dài ngày).

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID (VD: `tpl_beach`). |
| `tripType` | `string` | Có | Enum: `beach`, `trekking`, `motorbike`, `backpacking`. |
| `name` | `string` | Có | Tên hiển thị tiếng Việt (VD: "Du lịch biển"). |
| `items` | `array<map>` | Có | Mảng đầu việc mẫu: `{ title, phase, scope, category, daysBeforeDeparture }`. |

---

### 3.4. `trips/{tripId}` (Root Collection — Mục tiêu Chuyến đi & Dashboard)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID (Auto ID). |
| `title` | `string` | Có | Tên chuyến đi (VD: "Phá đảo Đà Lạt 4N3Đ"). |
| `destination` | `string` | Có | Tên địa điểm mục tiêu. |
| `destinationLat` | `double?` | Không | Vĩ độ tâm điểm đến (dùng khởi tạo camera Google Maps). |
| `destinationLng` | `double?` | Không | Kinh độ tâm điểm đến. |
| `tripType` | `string` | Có | Enum: `beach`, `trekking`, `motorbike`, `backpacking`, `other`. |
| `coverImageUrl` | `string?` | Không | URL ảnh bìa chuyến đi trên Supabase. |
| `coverStoragePath` | `string?` | Không | Đường dẫn file ảnh bìa trên Supabase. |
| `startDate` | `Timestamp` | Có | Ngày khởi hành (dùng cho bộ đếm ngược Countdown). |
| `endDate` | `Timestamp` | Có | Ngày kết thúc chuyến đi. |
| `hostId` | `string` | Có | `uid` của Trưởng nhóm (Trip Planner & Fund Host). |
| `memberIds` | `array<string>` | Có | Mảng `uid` thành viên (phục vụ truy vấn `array-contains` và Security Rules). |
| `inviteCode` | `string` | Có | Mã mời QR hiện hành (tham chiếu sang `invite_codes`). |
| `status` | `string` | Có | Enum: `planning`, `ongoing`, `completed`, `cancelled`. |
| `targetBudget` | `int` | Có | Tổng kinh phí mục tiêu của cả nhóm (VND). |
| `perMemberTarget` | `int` | Có | Mục tiêu đóng góp mỗi thành viên (VND). |
| `savingFrequency` | `string` | Có | Chu kỳ đóng quỹ mặc định của nhóm: `daily`, `weekly`, `monthly`. |
| `checklistTotal` | `int` | Có | *(Denormalized)* Tổng số đầu việc Checklist chung. |
| `checklistCompleted` | `int` | Có | *(Denormalized)* Số đầu việc Checklist chung đã hoàn thành. |
| `totalSavedAmount` | `int` | Có | *(Denormalized)* Tổng tiền đã xác nhận nạp vào Quỹ nhóm (VND). |
| `totalPlannedItineraryCost` | `int` | Có | *(Denormalized)* Tổng chi phí ước tính từ lịch trình Module 3 (VND). |
| `totalSpentAmount` | `int` | Có | *(Denormalized)* Tổng thực chi đã ghi nhận ở Module 4 (VND). |
| `createdAt` | `Timestamp` | Có | Thời điểm khởi tạo chuyến đi. |
| `updatedAt` | `Timestamp` | Có | Thời điểm cập nhật gần nhất. |

---

### 3.5. `trips/{tripId}/members/{userId}` (Subcollection — Thành viên & Phân quyền)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `userId` | `string` | Có | `uid` thành viên (trùng Document ID). |
| `displayName` | `string` | Có | Bản sao tên hiển thị (giảm số lần join bảng `users`). |
| `avatarUrl` | `string?` | Không | Bản sao ảnh đại diện. |
| `role` | `string` | Có | Enum: `host` (Trưởng nhóm) hoặc `member` (Thành viên). |
| `targetContribution` | `int` | Có | Mức quỹ mục tiêu riêng của thành viên này (VND). |
| `contributedAmount` | `int` | Có | *(Denormalized)* Tổng tiền đã được Host xác nhận nạp quỹ (VND). |
| `personalAdvancedAmount` | `int` | Có | *(Denormalized)* Tổng tiền thành viên đã ứng trước cho nhóm ở Module 4 (VND). |
| `currentStreak` | `int` | Có | *(Denormalized)* Chuỗi kỳ đóng quỹ đúng hạn liên tiếp hiện tại. |
| `joinedAt` | `Timestamp` | Có | Thời điểm tham gia chuyến đi. |

---

### 3.6. `trips/{tripId}/checklists/{itemId}` (Subcollection — Module 1: `goal_and_checklist`)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID. |
| `title` | `string` | Có | Nội dung đầu việc / vật dụng (VD: "Đặt vé xe giường nằm"). |
| `description` | `string?` | Không | Ghi chú chi tiết. |
| `phase` | `string` | Có | Mốc thời gian: `before_30d`, `before_14d`, `before_3d`, `packing`. |
| `scope` | `string` | Có | Enum: `group` (Việc chung cả nhóm) hoặc `personal` (Hành lý cá nhân). |
| `ownerId` | `string?` | Không | Nếu `scope == 'personal'`, lưu `uid` chủ sở hữu để chỉ hiện cho người đó. |
| `assigneeId` | `string?` | Không | `uid` người được phân công phụ trách (với việc `group`). |
| `assigneeName` | `string?` | Không | Tên hiển thị người phụ trách (denormalized). |
| `dueDate` | `Timestamp?` | Không | Hạn chót hoàn thành (dùng lập lịch Local Notification nhắc việc). |
| `isCompleted` | `bool` | Có | Trạng thái hoàn thành (`false` mặc định). |
| `completedAt` | `Timestamp?` | Không | Thời điểm đánh dấu hoàn thành. |
| `completedBy` | `string?` | Không | `uid` người xác nhận hoàn thành. |
| `proofImageUrl` | `string?` | Không | URL ảnh chụp Camera xác nhận hoàn thành trên Supabase. |
| `proofStoragePath` | `string?` | Không | Đường dẫn file ảnh minh chứng trên Supabase. |
| `sortOrder` | `int` | Có | Thứ tự hiển thị trong giai đoạn. |
| `createdBy` | `string` | Có | `uid` người tạo. |
| `createdAt` | `Timestamp` | Có | Thời điểm tạo. |

---

### 3.7. Module 2 (`saving_discipline_and_momo`) — Đồng bộ theo code đã triển khai

Các subcollection đang được [SavingRepositoryImpl](file:///D:/DinhAn/BTL_Mobile/project-ptuddd/nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/repository/saving_repository_impl.dart) sử dụng thực tế dưới `trips/{tripId}/`:

1. **`momo_fund_config/default`** (`MoMoFundConfig`): Cấu hình Quỹ nhóm MoMo (`momoPhone`, `momoName`, `momoLink`, `qrImageUrl`, `targetAmount`, `currentCollectedAmount`, `createdAt`, `updatedAt`).
2. **`saving_plans/{memberId}`** (`SavingPlan`): Kế hoạch tích lũy của từng thành viên (`tripId`, `memberId`, `memberName`, `targetAmount`, `paidAmount`, `frequency`, `amountPerInstallment`, `totalInstallments`, `completedInstallments`, `startDate`, `deadlineDate`, `status`, `createdAt`).
3. **`deposit_records/{depositId}`** (`DepositRecord`): Lịch sử nộp quỹ & ảnh biên lai từ Supabase (`tripId`, `memberId`, `memberName`, `amount`, `depositDate`, `receiptImageUrl`, `status`: `'PENDING' | 'APPROVED' | 'REJECTED'`, `emotionTag`, `journalNote`, `approvedBy`, `approvedAt`, `rejectionReason`, `createdAt`).
4. **`member_streaks/{memberId}`** (`MemberStreak`): Chuỗi kỷ luật DailyYou (`memberId`, `tripId`, `currentStreak`, `longestStreak`, `lastCheckInDate`, `checkInDates`, `dailyNotes`).

---

### 3.8. `trips/{tripId}/place_plans/{placeId}` (Subcollection — Module 3: `place_and_itinerary_planner`)

Đồng bộ theo [PlacePlan](file:///D:/DinhAn/BTL_Mobile/project-ptuddd/nhom08-65ktpm/src/lib/features/place_and_itinerary_planner/models/place_plan.dart) và [FirestoreItineraryRepository](file:///D:/DinhAn/BTL_Mobile/project-ptuddd/nhom08-65ktpm/src/lib/features/place_and_itinerary_planner/repository/itinerary_repository.dart):

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID. |
| `tripId` | `string` | Có | ID chuyến đi. |
| `dayNumber` | `int` | Có | Ngày thứ mấy trong chuyến đi (1, 2, 3...). |
| `sortOrder` | `int` | Có | Thứ tự ghé thăm trong ngày (dùng cho `.orderBy('sortOrder')`). |
| `placeName` | `string` | Có | Tên địa điểm. |
| `category` | `string` | Có | Enum: `attraction`, `food`, `hotel`. |
| `latitude` | `double` | Có | Vĩ độ. |
| `longitude` | `double` | Có | Kinh độ. |
| `address` | `string` | Không | Địa chỉ hiển thị. |
| `startTime` | `Timestamp` | Có | Giờ bắt đầu dự kiến. |
| `durationMinutes` | `int` | Có | Thời lượng dự kiến (phút). |
| `ticketCost` | `double` | Có | Chi phí vé tham quan dự kiến. |
| `foodCost` | `double` | Có | Chi phí ăn uống dự kiến. |
| `isCheckedIn` | `bool` | Có | Đã check-in GPS/Camera thực tế hay chưa. |
| `checkedInAt` | `Timestamp?` | Không | Thời điểm check-in. |
| `checkInPhotoUrl` | `string?` | Không | URL ảnh chụp Camera check-in trên Supabase (`trips/{tripId}/checkins/{planId}.jpg`). |

---

### 3.9. `trips/{tripId}/budget_envelopes/{envelopeId}` (Subcollection — Module 4: Hũ Ngân sách Cashew)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID (trùng `category`, VD: `food`, `transport`). |
| `category` | `string` | Có | Enum: `transport`, `accommodation`, `food`, `tickets`, `shopping`, `contingency`. |
| `name` | `string` | Có | Tên hiển thị tiếng Việt (VD: "Ăn uống", "Di chuyển"). |
| `iconCode` | `string` | Có | Mã icon hiển thị trên UI kiểu Cashew. |
| `colorHex` | `string` | Có | Mã màu hex của hũ (VD: `#FF7043`). |
| `allocatedAmount` | `int` | Có | Hạn mức ngân sách phân bổ cho hũ (VND). |
| `plannedFromItinerary` | `int` | Có | *(Denormalized)* Tổng chi phí dự kiến từ Module 3 thuộc hạng mục này (VND). |
| `spentAmount` | `int` | Có | *(Denormalized)* Tổng thực chi đã ghi nhận thuộc hũ này (VND). |
| `updatedAt` | `Timestamp` | Có | Thời điểm cập nhật gần nhất. |

---

### 3.10. `trips/{tripId}/expenses/{expenseId}` (Subcollection — Module 4: Thực chi & Camera OCR)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID. |
| `title` | `string` | Có | Tên khoản chi (VD: "Bữa tối lẩu gà lá é"). |
| `amount` | `int` | Có | Số tiền thực chi (VND). |
| `envelopeId` | `string` | Có | Tham chiếu tới `budget_envelopes/{envelopeId}`. |
| `category` | `string` | Có | Hạng mục chi tiêu (trùng `envelope.category`). |
| `placePlanId` | `string?` | Không | Gắn với điểm đến trong lịch trình (nếu có). |
| `paymentSource` | `string` | Có | Nguồn tiền: `group_fund` hoặc `personal_advance`. |
| `paidBy` | `string` | Có | `uid` người chi trả. |
| `splitType` | `string` | Có | Enum: `equal`, `exact`, `personal`. |
| `splitBetween` | `array<string>` | Có | Danh sách `uid` những người cùng chịu khoản chi này. |
| `splitDetails` | `map<string, int>` | Có | Map `uid -> số tiền phải chịu (VND)`. |
| `isOcrScanned` | `bool` | Có | Có quét từ Camera ML Kit OCR hay không. |
| `ocrDetectedAmount` | `int?` | Không | Số tiền gốc ML Kit nhận diện. |
| `ocrRawText` | `string?` | Không | Văn bản thô bóc tách từ hóa đơn (tùy chọn). |
| `receiptImageUrl` | `string?` | Không | URL ảnh chụp hóa đơn trên Supabase. |
| `receiptStoragePath` | `string?` | Không | Đường dẫn file ảnh hóa đơn trên Supabase. |
| `spentAt` | `Timestamp` | Có | Thời điểm phát sinh giao dịch. |
| `note` | `string?` | Không | Ghi chú bổ sung. |
| `createdBy` | `string` | Có | `uid` người nhập khoản chi. |
| `createdAt` | `Timestamp` | Có | Thời điểm ghi nhận lên hệ thống. |

---

### 3.11. `trips/{tripId}/settlements/{settlementId}` (Subcollection — Module 4: Tối giản hóa Công nợ)

| Trường (Field) | Kiểu dữ liệu | Bắt buộc | Mô tả |
| :--- | :--- | :--- | :--- |
| `id` | `string` | Có | Document ID. |
| `fromUserId` | `string` | Có | `uid` người cần chuyển tiền (hoặc `"GROUP_FUND"`). |
| `toUserId` | `string` | Có | `uid` người nhận tiền. |
| `amount` | `int` | Có | Số tiền cần thanh toán (VND). |
| `status` | `string` | Có | Enum: `pending` hoặc `paid`. |
| `proofImageUrl` | `string?` | Không | URL ảnh biên lai chuyển khoản tất toán trên Supabase. |
| `proofStoragePath` | `string?` | Không | Đường dẫn file biên lai trên Supabase. |
| `settledAt` | `Timestamp?` | Không | Thời điểm xác nhận hoàn tất. |
| `createdAt` | `Timestamp` | Có | Thời điểm Host bấm chốt quyết toán. |

---

## 4. Thiết kế Supabase Storage (Thay thế Firebase Cloud Storage)

### 4.1. Cấu trúc Bucket & Thư mục

Bucket mặc định trong `lib/core/services/supabase_storage_service.dart` là **`travel-buddy`** (có thể đổi bằng `--dart-define=SUPABASE_BUCKET=...`):

```text
travel-buddy/
├── avatars/{userId}/avatar_{timestamp}.jpg
└── trips/{tripId}/
    ├── cover/cover_{timestamp}.jpg
    ├── momo_qr/qr_{timestamp}.jpg
    ├── checklists/{itemId}/{uuid}.jpg      # Module 1: Ảnh xác thực Checklist
    ├── receipts/{timestamp}_{depositId}.jpg # Module 2: Biên lai nạp quỹ MoMo
    ├── checkins/{planId}.jpg               # Module 3: Ảnh GPS/Camera Check-in
    ├── expenses/{expenseId}/{uuid}.jpg     # Module 4: Ảnh hóa đơn OCR
    └── settlements/{settlementId}/{uuid}.jpg # Module 4: Ảnh chuyển khoản tất toán
```

### 4.2. SQL khởi tạo Bucket & Policy (Chạy trong Supabase SQL Editor)

> Lưu ý: Vì ứng dụng dùng **Firebase Auth** (không dùng Supabase Auth), mọi request từ app dùng `publishableKey` đi dưới vai trò **`anon`**.

```sql
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'travel-buddy',
  'travel-buddy',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Public Read Travel Buddy"
ON storage.objects FOR SELECT
TO anon, authenticated
USING (bucket_id = 'travel-buddy');

CREATE POLICY "Allow Upload Travel Buddy"
ON storage.objects FOR INSERT
TO anon, authenticated
WITH CHECK (bucket_id = 'travel-buddy');

CREATE POLICY "Allow Update Travel Buddy"
ON storage.objects FOR UPDATE
TO anon, authenticated
USING (bucket_id = 'travel-buddy');

CREATE POLICY "Allow Delete Travel Buddy"
ON storage.objects FOR DELETE
TO anon, authenticated
USING (bucket_id = 'travel-buddy');
```

---

## 5. Tệp cấu hình triển khai Firebase đi kèm
- Firestore Security Rules: `nhom08-65ktpm/src/firestore.rules`
- Firestore Composite Indexes: `nhom08-65ktpm/src/firestore.indexes.json`
- Shared Timestamp Converter: `nhom08-65ktpm/src/lib/core/utils/timestamp_converter.dart`
- Shared Supabase Storage Service: `nhom08-65ktpm/src/lib/core/services/supabase_storage_service.dart`
