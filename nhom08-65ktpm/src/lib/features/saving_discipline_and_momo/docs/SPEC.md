# 📋 Technical Specification (SPEC.md)
## Module 2: Saving Discipline & MoMo Group Fund (`saving_discipline_and_momo`)
### Project: Travel Buddy - Trip Planning, Preparation Checklist & Fund Saving Discipline
**Engineer:** Nguyen Xuan Binh (Student ID: 2251172252 - Class: 64KTPM5 - Member #2)  
**Course:** Mobile Application Development (PTUDDD) - Thuyloi University (TLU)  
**Git Branch:** `nhom08-65ktpm`  
**Execution Boundary:** Strictly limited to `nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/`

---

## ⚠️ Surfaced Assumptions (Upfront Assumptions)
1. **MoMo Fund Integration:** Integrates with MoMo Group Fund via standard MoMo Deeplinks (`momo://...` or official web redirect) and QR scanning (`mobile_scanner`). It does not invoke private core banking APIs, which matches the project scope.
2. **Transaction Verification:** The verification mechanism relies on transfer receipts (screenshots uploaded by trip members to Firebase Storage). The Fund Host manually approves transactions in Cloud Firestore to increment the fund progress toward 100%.
3. **Database Schema:** Fund configuration, member saving schedules, deposit histories, and streaks are stored in Cloud Firestore under sub-collections of each `tripId`.
4. **Third-Party Package Additions:** The module requires `url_launcher` (to trigger the native MoMo app deeplink) and `image_picker` (to select receipt screenshots from the device camera/gallery).

---

## 1. Objective & User Stories

### 1.1. Problem Statement
Group travel plans among students frequently fail due to **financial indiscipline**: members postpone saving, forget payment deadlines, or lack transparency in fund collection. **Module 2: Saving Discipline & MoMo Group Fund** solves this problem by automating periodic saving schedules based on a trip countdown, gamifying financial discipline through a DailyYou-style Streak Calendar, streamlining payments via MoMo Group Fund (QR & 1-tap Deeplink), and maintaining real-time fund transparency.

### 1.2. Target Personas
- **Fund Host (Trip Planner / Host):** Configures the MoMo Group Fund details (phone number, fund link, QR code) and reviews/approves transaction receipts submitted by members.
- **Trip Member:** Views their personal installment schedule, receives payment reminders, makes 1-tap deposits to MoMo, maintains saving streaks, and uploads transaction receipts for verification.

### 1.3. User Stories & Acceptance Criteria (AC)

#### US1: Automated Saving Plan Generator
- **As a** trip member,
- **I want** the system to automatically calculate my periodic saving installments (daily, weekly, or monthly) based on my budget share and the departure countdown,
- **So that** I know exactly how much to save and can maintain financial discipline.
- **Acceptance Criteria (AC):**
  - Allows selecting installment frequency: *Daily*, *Weekly*, or *Monthly*.
  - Formula: `Installment Amount = Total Member Budget / Number of Intervals until Departure`.
  - Rounds amounts to sensible increments (e.g., nearest 1,000 VND), with any fractional remainder adjusted in the final installment.
  - Generates clear due dates for each installment.

#### US2: MoMo Group Fund Integration & QR Scanner
- **As a** trip member,
- **I want** to scan the group fund's MoMo QR code or tap a button to open the MoMo app directly,
- **So that** I can transfer money quickly without typing phone numbers or transfer remarks manually.
- **Acceptance Criteria (AC):**
  - Scans QR codes using the device camera via `mobile_scanner`.
  - Displays the group fund's QR code (rendered via `qr_flutter`) along with fund title, host name, and phone number.
  - "Open MoMo" button initiates the `momo://` scheme via `url_launcher`.
  - Fallback: If MoMo is not installed or fails to launch, displays a polite fallback dialog with 1-tap "Copy Phone Number" and "Copy Transfer Note" buttons.

#### US3: Saving Streak Calendar (DailyYou-style)
- **As a** trip member,
- **I want** to track my on-time deposit streak on a visual calendar,
- **So that** I stay motivated to save regularly before the trip starts.
- **Acceptance Criteria (AC):**
  - Monthly calendar view marking successful deposit days with visual badges (green checkmarks or streak flame icons 🔥).
  - Displays metrics: *Current Streak*, *Longest Streak*, and *Total Completed Installments*.
  - Allows members to attach an Emotion Tag (😄 Excited, 😎 Confident, 😤 Determined, ☕ Sacrificed coffee) and a brief personal note to each deposit.

#### US4: Receipt Upload & Fund Progress Bar
- **As a** trip member,
- **I want** to upload my transfer receipt screenshot,
- **So that** the Host can verify my contribution.
- **As a** Fund Host,
- **I want** to inspect pending transaction receipts and approve/reject them,
- **So that** the group fund balance and progress bar update reliably.
- **Acceptance Criteria (AC):**
  - Member uploads screenshot -> image uploaded to Firebase Storage (`trips/{tripId}/receipts/...`).
  - Creates a transaction document in Firestore with status `PENDING`.
  - Host views thumbnail, inspects full image in zoom dialog, and taps `Approve` or `Reject`.
  - On approval: updates status to `APPROVED`, increments group fund collected amount, updates member's paid total, and extends their streak.
  - Fund progress bar visually reflects `currentAmount / targetAmount * 100%` in real time.

---

## 2. Tech Stack & Dependencies

| Layer / Role | Library / Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter / Dart | `>= 3.10.0` / `>= 3.0.0` | Cross-platform mobile development |
| **State Management** | `flutter_riverpod` | `^3.5.0` | Compile-safe reactive state (Notifier / AsyncNotifier) |
| **Routing** | `go_router` | `^18.1.4` | Declarative routing & parameter passing |
| **Database** | `cloud_firestore` | `^7.1.0` | Realtime NoSQL persistence for funds, plans, and streaks |
| **Storage** | `firebase_storage` | `^14.0.1` | Cloud image storage for transfer receipt screenshots |
| **QR Code Display** | `qr_flutter` | `^4.1.0` | Dynamic QR code generation for group funds |
| **QR Code Scanner** | `mobile_scanner` | `^7.5.0` | Live camera QR code barcode scanning |
| **URL & Deeplink** | `url_launcher` | `^6.3.0` *(To add)* | Launches MoMo app scheme (`momo://`) or web URLs |
| **Image Selection** | `image_picker` | `^1.1.2` *(To add)* | Captures or selects receipt images from device |
| **Code Generation** | `freezed` & `json_serializable` | `^3.2.5` / `^6.15.2` | Immutable data structures with JSON serialization |

---

## 3. Development & Verification Commands

All development commands are executed from the Flutter root:
```bash
# 1. Navigate to the source root
cd nhom08-65ktpm/src

# 2. Install dependencies
flutter pub get

# 3. Generate Freezed / JSON models
dart run build_runner build --delete-conflicting-outputs

# 4. Run static analysis (linter)
flutter analyze

# 5. Run unit & widget tests for Module 2
flutter test test/features/saving_discipline_and_momo/

# 6. Run application in debug mode
flutter run
```

---

## 4. Module Directory Structure

All source files for Module 2 are strictly encapsulated within:
```text
nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/
├── presentation/                      # UI Presentation Layer
│   ├── screens/
│   │   ├── momo_fund_config_screen.dart       # Host setup for MoMo fund
│   │   ├── momo_deposit_screen.dart           # Member deposit & QR display screen
│   │   ├── qr_scanner_screen.dart             # Live Camera QR scanner screen
│   │   ├── saving_plan_screen.dart            # Plan generator & installment overview
│   │   ├── streak_calendar_screen.dart        # DailyYou-style saving streak calendar
│   │   └── pending_receipts_screen.dart       # Host review & approval screen
│   └── widgets/
│       ├── streak_fire_badge.dart             # Animated flame badge widget
│       ├── calendar_day_cell.dart             # Custom day cell reflecting deposit status
│       ├── fund_progress_card.dart            # Material 3 fund progress overview card
│       └── emotion_selector_dialog.dart       # Mood & note dialog on saving
├── providers/                         # Riverpod State Management Layer
│   ├── momo_fund_provider.dart                # Fund configuration AsyncNotifier
│   ├── saving_plan_provider.dart              # Installment generator & member plan state
│   ├── streak_calendar_provider.dart          # Streak calculation & calendar history state
│   └── receipt_approval_provider.dart         # Receipt submission & approval state
├── repository/                        # Data Access Layer
│   ├── saving_repository.dart                 # Abstract repository interface
│   └── saving_repository_impl.dart            # Firestore & Firebase Storage implementation
└── utils/                             # Domain Helpers & Pure Utilities
    ├── momo_deeplink_helper.dart              # MoMo schema builder & launcher logic
    └── saving_calculator.dart                 # Pure calculation logic for installments
```

---

## 5. Data Models & Firestore Schema

### 5.1. Collection: `trips/{tripId}/momo_fund_config`
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

### 5.2. Collection: `trips/{tripId}/saving_plans/{memberId}`
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

### 5.3. Collection: `trips/{tripId}/deposit_records`
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

### 5.4. Collection: `trips/{tripId}/member_streaks/{memberId}`
```typescript
interface MemberStreak {
  memberId: string;
  tripId: string;
  currentStreak: number;
  longestStreak: number;
  lastDepositDate?: Timestamp;
  depositDates: string[]; // List of ISO date strings: ['2026-11-20', ...]
  totalDisciplinedDays: number;
}
```

---

## 6. Code Style & Riverpod Conventions

The module strictly implements clean separation of concerns using Riverpod `AsyncNotifier`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final Set<String> activeDates;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.activeDates = const {},
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    Set<String>? activeDates,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      activeDates: activeDates ?? this.activeDates,
    );
  }
}

class StreakNotifier extends AutoDisposeFamilyAsyncNotifier<StreakState, String> {
  @override
  Future<StreakState> build(String tripId) async {
    final repo = ref.watch(savingRepositoryProvider);
    final streak = await repo.getMemberStreak(tripId);
    return StreakState(
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      activeDates: streak.depositDates.toSet(),
    );
  }

  Future<void> recordDeposit({
    required double amount,
    required String emotion,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(savingRepositoryProvider);
      await repo.submitDeposit(
        tripId: arg,
        amount: amount,
        emotion: emotion,
        note: note,
      );
      final updated = await repo.getMemberStreak(arg);
      return StreakState(
        currentStreak: updated.currentStreak,
        longestStreak: updated.longestStreak,
        activeDates: updated.depositDates.toSet(),
      );
    });
  }
}
```

---

## 7. Engineering Boundaries

- **ALWAYS:**
  - Validate monetary inputs (`amount > 0`).
  - Wrap asynchronous calls with `AsyncValue.guard()` or proper `try/catch` error states.
  - Request camera permissions using `permission_handler` prior to launching the QR scanner.
  - Confine all file modifications strictly to `nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/`.
- **ASK FIRST:**
  - Before modifying root dependencies in `pubspec.yaml` (e.g., adding `url_launcher` or `image_picker`).
  - Before modifying Firestore security rules affecting multi-module permissions.
- **NEVER:**
  - Never edit files outside `nhom08-65ktpm/` (e.g., root `.gitignore` or root `README.md`).
  - Never hardcode private API keys, secrets, or production credentials in Dart code.
  - Never use force unwrap operators (`!`) without prior null verification.

---

## 8. Definition of Done (DoD)
1. Clean static analysis: `flutter analyze` reports 0 errors and 0 warnings for the module.
2. Saving plan generator accurately partitions installment amounts across Daily, Weekly, and Monthly frequencies.
3. QR Scanner reads MoMo fund strings reliably and handles deeplink invocation with graceful fallbacks.
4. DailyYou Streak Calendar renders on-time milestones and updates reactively on deposit approval.
5. End-to-end receipt upload, Host approval, and real-time fund progress bar function smoothly.
