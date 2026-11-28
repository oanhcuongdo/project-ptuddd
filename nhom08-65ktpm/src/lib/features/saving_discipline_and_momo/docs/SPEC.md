# 📋 Tài liệu Đặc tả Kỹ thuật (SPEC.md)
## Phân hệ 2: Kỷ luật Tích góp & Quỹ nhóm MoMo (`saving_discipline_and_momo`)
### Đề tài: Travel Buddy - Ứng dụng lập kế hoạch chuyến đi, checklist chuẩn bị & tích góp quỹ nhóm
**Kỹ sư phụ trách:** Nguyễn Xuân Bình (MSV: 2251172252 - Lớp: 64KTPM5 - Thành viên số 2)  
**Môn học:** Phát triển ứng dụng trên thiết bị di động (PTUDDD) - Trường Đại học Thủy lợi (TLU)  
**Nhánh Git:** `nhom08-65ktpm` / `feat/saving-models-calculator`  
**Phạm vi file:** Giới hạn tuyệt đối trong `nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/` và `docs/`

---

## 🎯 Tổng quan các yêu cầu cốt lõi (Core Requirements)

1. **Thuật toán chia nhỏ kinh phí (Saving Calculator):** Tự động chia nhỏ tổng kinh phí chuyến đi thành các kỳ đóng quỹ định kỳ (ngày/tuần/tháng) dựa trên thời gian đếm ngược đến ngày khởi hành; làm tròn đến 1.000 VNĐ và dồn phần dư vào kỳ cuối.
2. **Quét mã QR Quỹ nhóm MoMo (`mobile_scanner`):** Tích hợp camera quét mã QR thanh toán hoặc mã QR Quỹ nhóm MoMo, có nút bật/tắt đèn flash và chuyển đổi camera trước/sau.
3. **Deeplink nộp quỹ 1 chạm (`url_launcher`):** Nút mở trực tiếp ứng dụng MoMo (`momo://`) kèm số điện thoại, số tiền và nội dung chuyển khoản tự động. Có phương án fallback sao chép nhanh 1 chạm khi máy chưa cài MoMo.
4. **Lịch chuỗi kỷ luật tích góp (Saving Streak Calendar kiểu DailyYou):** Hiển thị trực quan dạng lưới lịch tháng, đánh dấu ngày đóng quỹ đúng hạn với ngọn lửa streak 🔥 và huy hiệu hoàn thành.
5. **Tính toán chuỗi kỷ luật (Streak) & Nhật ký cảm xúc:** Tự động đếm chuỗi ngày tích góp liên tục (Current Streak, Longest Streak), cho phép chọn icon cảm xúc (😄 Hào hứng, 😎 Tự tin, 😤 Quyết tâm, ☕ Bỏ ly cà phê) và ghi chú nhật ký cá nhân mỗi lần đóng tiền.
6. **Tải ảnh biên lai lên Cloud Storage:** Cho phép thành viên chụp hoặc chọn ảnh chụp màn hình chuyển khoản MoMo từ máy, tải lên Firebase Storage (`trips/{tripId}/receipts/`) để tạo giao dịch ở trạng thái chờ duyệt (`PENDING`).
7. **Duyệt biên lai & Thanh tiến độ quỹ chung đạt mốc 100%:** Trưởng quỹ (Host) kiểm tra ảnh biên lai (zoom chi tiết) và bấm Duyệt/Từ chối. Khi duyệt, hệ thống dùng Firestore Transaction cập nhật số tiền đã thu và thanh tiến độ hoàn thành quỹ nhóm tiến tới mốc 100% với hiệu ứng chúc mừng.

---

## ⚠️ Giả định ban đầu (Assumptions)
1. **Tích hợp Quỹ MoMo:** Ứng dụng tích hợp qua Deeplink chuẩn của MoMo (`momo://...`) và mã QR nhóm bằng `mobile_scanner`, không gọi API core banking nội bộ nhằm đảm bảo an toàn và phù hợp phạm vi đồ án.
2. **Cơ chế xác thực giao dịch:** Dựa trên ảnh biên lai chuyển tiền tải lên Firebase Storage. Trưởng nhóm duyệt giao dịch trên Firestore để kích hoạt cộng tiền vào quỹ và nối dài chuỗi streak của thành viên.
3. **Môi trường lưu trữ:** Dữ liệu quỹ, kế hoạch thành viên, lịch sử nộp và streak được lưu trữ trong Cloud Firestore theo cấu trúc sub-collection của `tripId`.

---

## 1. Chi tiết User Stories & Tiêu chí nghiệm thu (Acceptance Criteria)

### US1: Thuật toán chia nhỏ tổng kinh phí thành các kỳ đóng định kỳ
- **Là:** Thành viên chuyến đi,
- **Tôi muốn:** Hệ thống tự động tính toán số tiền cần đóng theo từng kỳ (hàng ngày, hàng tuần, hàng tháng) dựa trên hạn mức chi tiêu cá nhân và số ngày đếm ngược đến ngày đi,
- **Để:** Tôi chủ động chuẩn bị tài chính và duy trì kỷ luật tích lũy.
- **Tiêu chuẩn nghiệm thu (AC):**
  - Hỗ trợ các chu kỳ: **Hàng ngày (Daily)**, **Hàng tuần (Weekly)**, **Hàng tháng (Monthly)**.
  - Công thức: `Số tiền mỗi kỳ = Tổng kinh phí / Số kỳ hạn cho tới ngày khởi hành`.
  - Tự động fallback: Nếu thời gian còn lại < 7 ngày, bắt buộc chọn chu kỳ ngày. Nếu < 30 ngày, chu kỳ tháng chuyển thành tuần.
  - Làm tròn tiền đến 1.000 VNĐ gần nhất (`(raw / 1000).round() * 1000`), toàn bộ sai số phần dư làm tròn được bù vào kỳ đóng cuối cùng để tổng chính xác 100%.

### US2: Quét mã QR Quỹ MoMo & Deeplink nộp quỹ 1 chạm
- **Là:** Thành viên chuyến đi,
- **Tôi muốn:** Quét mã QR MoMo của nhóm hoặc bấm nút để mở thẳng app MoMo,
- **Để:** Thanh toán tiền quỹ nhanh chóng mà không cần nhập tay số điện thoại hoặc nội dung chuyển khoản.
- **Tiêu chuẩn nghiệm thu (AC):**
  - Quét mã QR trực tiếp qua camera bằng thư viện `mobile_scanner`, tự động xin quyền camera qua `permission_handler`.
  - Hiển thị mã QR quỹ nhóm (tạo qua `qr_flutter`) kèm tên quỹ, tên thủ quỹ và số điện thoại.
  - Nút "Mở MoMo nộp quỹ" kích hoạt URL scheme `momo://` thông qua `url_launcher`.
  - Fallback: Nếu mở không thành công (chưa cài app MoMo), hiển thị popup hỗ trợ nút 1-tap "Sao chép số điện thoại" và "Sao chép nội dung chuyển khoản".

### US3: Lịch theo dõi chuỗi kỷ luật tích góp (DailyYou-style) & Icon cảm xúc
- **Là:** Thành viên chuyến đi,
- **Tôi muốn:** Theo dõi chuỗi ngày đóng tiền đúng hạn trên giao diện lịch trực quan và gắn thẻ cảm xúc,
- **Để:** Có động lực duy trì kỷ luật tài chính trước chuyến đi.
- **Tiêu chuẩn nghiệm thu (AC):**
  - Lưới lịch hiển thị theo tháng, ô ngày (`CalendarDayCell`) có màu sắc trực quan: Đã nộp (Xanh lá), Đến hạn hôm nay (Vàng hổ phách), Quá hạn (Xám/Đỏ).
  - Huy hiệu ngọn lửa (`StreakFireBadge`) hiển thị chuỗi hiện tại (`currentStreak`) và chuỗi kỷ lục (`longestStreak`).
  - Hộp thoại chọn cảm xúc (`emotionTag`) với các lựa chọn: 😄 Hào hứng, 😎 Tự tin, 😤 Quyết tâm, ☕ Nhịn một ly cà phê, kèm ô nhập ghi chú ngắn.

### US4: Tải ảnh biên lai & Thanh tiến độ quỹ chung đạt mốc 100%
- **Là:** Thành viên chuyến đi và Trưởng quỹ (Host),
- **Tôi muốn:** Thành viên upload ảnh chụp màn hình biên lai chuyển tiền lên Cloud Storage, và Trưởng quỹ có thể duyệt/từ chối biên lai,
- **Để:** Minh bạch tài chính và thanh tiến độ tích lũy quỹ nhóm đạt mốc 100%.
- **Tiêu chuẩn nghiệm thu (AC):**
  - Thành viên chọn ảnh biên lai -> Tải lên Firebase Storage tại đường dẫn `trips/{tripId}/receipts/`.
  - Tạo bản ghi `DepositRecord` với trạng thái `PENDING`.
  - Trưởng quỹ xem danh sách chờ duyệt, mở ảnh xem phóng to/thu nhỏ, chọn "Duyệt" (`APPROVED`) hoặc "Từ chối" (`REJECTED`).
  - Khi duyệt thành công: Dùng Firestore Transaction cộng tiền vào `currentCollectedAmount` của quỹ nhóm, tăng `paidAmount` của thành viên, nối dài `currentStreak`.
  - Thanh tiến độ quỹ nhóm (`FundProgressCard`) hiển thị tỷ lệ `%` tăng dần, hiển thị trạng thái hoàn thành nổi bật khi đạt 100%.

---

## 2. Công nghệ & Thư viện sử dụng

| Công nghệ / Gói | Phiên bản | Mục đích sử dụng |
| :--- | :--- | :--- |
| **Flutter / Dart** | SDK ^3.12.2 | Nền tảng xây dựng giao diện đa nền tảng |
| **flutter_riverpod** | ^3.5.0 | Quản lý trạng thái an toàn kiểu dữ liệu (AsyncNotifier / Notifier) |
| **cloud_firestore** | ^7.1.0 | Cơ sở dữ liệu thời gian thực lưu trữ quỹ, kế hoạch và streak |
| **firebase_storage** | ^14.0.1 | Lưu trữ ảnh chụp biên lai chuyển tiền MoMo |
| **mobile_scanner** | ^7.5.0 | Quét mã QR quỹ nhóm trực tiếp bằng camera |
| **qr_flutter** | ^4.1.0 | Tạo mã QR trực quan cho quỹ nhóm MoMo |
| **url_launcher** | ^6.3.0 | Mở deeplink ứng dụng MoMo (`momo://`) |
| **permission_handler** | ^13.0.2 | Kiểm tra và xin quyền sử dụng Camera an toàn |

---

## 3. Cấu trúc Thư mục Module (`saving_discipline_and_momo`)

```text
nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/
├── docs/                              # Tài liệu đặc tả kỹ thuật & kế hoạch
│   ├── SPEC.md
│   └── PLAN.md
├── models/                            # Data Models & Entities
│   ├── momo_fund_config.dart          # Cấu hình quỹ MoMo
│   ├── saving_plan.dart               # Kế hoạch tích góp từng thành viên
│   ├── deposit_record.dart            # Bản ghi nộp quỹ & biên lai
│   └── member_streak.dart             # Dữ liệu chuỗi ngày kỷ luật
├── presentation/                      # UI Presentation Layer
│   ├── screens/
│   │   ├── momo_fund_config_screen.dart       # Màn hình cài đặt quỹ MoMo (Trưởng quỹ)
│   │   ├── momo_deposit_screen.dart           # Màn hình nộp quỹ & mở MoMo 1 chạm
│   │   ├── qr_scanner_screen.dart             # Màn hình quét mã QR bằng camera
│   │   ├── saving_plan_screen.dart            # Màn hình tạo kế hoạch & xem kỳ đóng
│   │   ├── streak_calendar_screen.dart        # Màn hình lịch streak DailyYou
│   │   └── pending_receipts_screen.dart       # Màn hình duyệt biên lai (Trưởng quỹ)
│   └── widgets/
│       ├── streak_fire_badge.dart             # Widget huy hiệu lửa streak
│       ├── calendar_day_cell.dart             # Ô lịch hiển thị trạng thái đóng tiền
│       ├── fund_progress_card.dart            # Thẻ tiến độ quỹ nhóm đạt mốc 100%
│       └── emotion_selector_dialog.dart       # Hộp thoại chọn icon cảm xúc & ghi chú
├── providers/                         # Riverpod Notifiers Layer
│   ├── momo_fund_provider.dart
│   ├── saving_plan_provider.dart
│   ├── streak_calendar_provider.dart
│   └── receipt_approval_provider.dart
├── repository/                        # Data Layer (Firestore & Storage)
│   ├── saving_repository.dart
│   └── saving_repository_impl.dart
└── utils/                             # Domain Utilities
    ├── momo_deeplink_helper.dart      # Bộ hỗ trợ mở URL scheme MoMo & fallback
    └── saving_calculator.dart         # Thuật toán chia nhỏ kinh phí & làm tròn
```

---

## 4. Cấu trúc Dữ liệu Firestore

### 4.1. `trips/{tripId}/momo_fund_config/default`
```typescript
interface MoMoFundConfig {
  tripId: string;
  fundName: string;
  hostUserId: string;
  hostName: string;
  momoPhoneNumber: string;
  momoFundDeeplink?: string;
  qrCodeUrl?: string;
  targetTotalAmount: number;
  currentCollectedAmount: number;
  currency: string; // 'VND'
  updatedAt: Timestamp;
}
```

### 4.2. `trips/{tripId}/saving_plans/{memberId}`
```typescript
interface SavingPlan {
  id: string;
  tripId: string;
  memberId: string;
  memberName: string;
  targetAmount: number;
  paidAmount: number;
  frequency: 'daily' | 'weekly' | 'monthly';
  installmentAmount: number;
  totalInstallments: number;
  completedInstallments: number;
  startDate: Timestamp;
  deadlineDate: Timestamp;
  status: 'active' | 'completed';
}
```

### 4.3. `trips/{tripId}/deposit_records/{recordId}`
```typescript
interface DepositRecord {
  id: string;
  tripId: string;
  memberId: string;
  memberName: string;
  amount: number;
  installmentIndex: number;
  depositDate: Timestamp;
  receiptImageUrl?: string;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  approvedBy?: string;
  approvedAt?: Timestamp;
  note?: string;
  emotionTag?: string; // 'happy', 'excited', 'disciplined', 'coffee_cut'
}
```

### 4.4. `trips/{tripId}/member_streaks/{memberId}`
```typescript
interface MemberStreak {
  memberId: string;
  tripId: string;
  currentStreak: number;
  longestStreak: number;
  lastDepositDate?: Timestamp;
  depositDates: string[]; // ['2026-11-20', '2026-11-21', ...]
  totalDisciplinedDays: number;
}
```

---

## 5. Tiêu chuẩn Hoàn thành (Definition of Done)
1. Thuật toán `SavingCalculator` chia chính xác số tiền theo ngày/tuần, có kiểm thử đơn vị đạt 100% boundary test.
2. Quét mã QR MoMo bằng `mobile_scanner` ổn định, xin quyền máy ảnh rõ ràng.
3. Nút deeplink mở được ứng dụng MoMo và có phương án fallback sao chép thông tin tiện lợi.
4. Lịch kỷ luật DailyYou hiển thị trực quan các ngày đóng tiền kèm ngọn lửa streak.
5. Cho phép chọn icon cảm xúc, viết nhật ký đóng quỹ.
6. Tải ảnh chụp biên lai lên Firebase Storage thành công, trưởng quỹ duyệt giao dịch bằng Firestore Transaction.
7. Thanh tiến độ quỹ hiển thị mượt mà và chuyển trạng thái chúc mừng khi quỹ đạt 100%.
8. Phân tích tĩnh (`flutter analyze`) đạt 0 lỗi và 0 cảnh báo.
