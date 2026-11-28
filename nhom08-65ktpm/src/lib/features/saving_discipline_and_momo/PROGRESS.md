# 📊 Module 2 Progress Tracker (`saving_discipline_and_momo`)
**Project:** Travel Buddy (PTUDDD - Group 08 - 65KTPM)  
**Lead Engineer:** Nguyen Xuan Binh (Member #2 - 64KTPM5)  
**Branch:** `feat/nhom08-65ktpm/routing-and-quality-polish`  

---

## 🟢 Phase 1: Data Foundations & Saving Plan Generator

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 1.1** | Define Data Models & Entities (`MoMoFundConfig`, `SavingPlan`, `DepositRecord`, `MemberStreak`) | **COMPLETED** | Models created with Firestore serialization, deserialization, and null safety: <br>- `models/momo_fund_config.dart`<br>- `models/saving_plan.dart`<br>- `models/deposit_record.dart`<br>- `models/member_streak.dart` |
| **Task 1.2** | Implement Saving Plan Calculator (`SavingCalculator`) | **COMPLETED** | Domain calculation logic implemented in `utils/saving_calculator.dart` with 100% boundary test coverage. All 6 unit tests passed in `test/features/saving_discipline_and_momo/saving_calculator_test.dart`. |
| **Task 1.3** | Build Saving Repository Layer (`SavingRepository` & `SavingRepositoryImpl`) | **COMPLETED** | Abstract contract & Firestore + Firebase Storage implementation created with atomic transactions: <br>- `repository/saving_repository.dart`<br>- `repository/saving_repository_impl.dart` |
| **Task 1.4 (Phase 1 Vertical Slice Completion)** | Riverpod Saving Plan State Management & UI Screen | **COMPLETED** | End-to-end slice connecting Models + Calculator + Repository to UI: <br>- `providers/saving_plan_provider.dart` (`AsyncNotifierProvider`)<br>- `presentation/screens/saving_plan_screen.dart` (Live breakdown, installment schedule preview, form validation & progress tracking) |

### 🎯 Checkpoint 1 Status: Passed ✅
- [x] Data models compile with null safety.
- [x] Unit tests for `SavingCalculator` pass with 100% boundary coverage (6/6 tests passing).
- [x] Repository layer implemented with atomic Firestore transaction and Riverpod provider.
- [x] Riverpod `savingPlanProvider` (`AsyncNotifierProvider.autoDispose.family`) implemented with `AsyncValue.guard()`.
- [x] `SavingPlanScreen` UI widget built for periodic saving plan generation and review.
- [x] Static analysis: `flutter analyze` reports 0 issues (0 errors, 0 warnings).

---

## 🟢 Phase 2: MoMo Group Fund & Camera QR Scanner

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 2.1** | Host MoMo Fund Setup Screen | **COMPLETED** | `ConsumerStatefulWidget` setup sheet with Riverpod state & gallery QR upload: <br>- `providers/momo_fund_provider.dart`<br>- `presentation/setup_momo_sheet.dart`<br>- `repository/in_memory_saving_repository.dart` |
| **Task 2.2** | Live Camera QR Scanner via `mobile_scanner` | **COMPLETED** | Camera QR scanner with `permission_handler` & MoMo/VietQR payload parser: <br>- `presentation/screens/momo_qr_scanner_screen.dart`<br>- `utils/momo_deeplink_helper.dart` |
| **Task 2.3** | 1-Tap MoMo Deeplink & Payment View | **COMPLETED** | Scannable QR display (`qr_flutter`), 1-tap copy, and native MoMo app launcher: <br>- `presentation/screens/momo_payment_screen.dart`<br>- `utils/momo_launcher.dart`<br>- `presentation/momo_fund_screen.dart` |

### 🎯 Checkpoint 2 Status: Passed ✅
- [x] `MoMoFundNotifier` & `momoFundStreamProvider` implemented with `ref.keepAlive()`, `ref.mounted`, and `AsyncValue.guard()`.
- [x] Live camera QR scanner (`mobile_scanner`) and gallery QR image decoding (`image_picker`) parse MoMo & VietQR payloads.
- [x] Payment view (`MomoPaymentScreen`) and `MoMoLauncher` launch MoMo with clipboard + QR fallbacks.
- [x] Static analysis: `flutter analyze` reports 0 issues (0 errors, 0 warnings).
- [x] Unit tests: `flutter test test/features/saving_discipline_and_momo/` passes 12/12 tests.

## 🟢 Phase 3: DailyYou-Style Saving Streak Calendar

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 3.1** | Saving Streak Calculation Logic | **COMPLETED** | Pure streak calculation, calendar grid mapping & Riverpod state: <br>- `utils/saving_streak_calculator.dart`<br>- `providers/saving_streak_provider.dart` |
| **Task 3.2** | DailyYou Streak Calendar UI Widget | **COMPLETED** | Interactive monthly calendar with month navigation, legend & live streak badge: <br>- `presentation/widgets/daily_you_streak_calendar.dart`<br>- `presentation/momo_fund_screen.dart` |
| **Task 3.3** | Emotion Tags & Saving Journal Dialog | **COMPLETED** | DailyYou emotion chip picker & saving reflection dialog: <br>- `presentation/widgets/saving_journal_dialog.dart` |

### 🎯 Checkpoint 3 Status: Passed ✅
- [x] `SavingStreakCalculator` computes current/longest streaks, idempotent check-ins, and monthly status cells.
- [x] `SavingStreakNotifier` & `savingJournalProvider` persist check-ins and emotion journal notes.
- [x] `DailyYouStreakCalendar` & `SavingJournalDialog` wired into `MomoFundScreen`.
- [x] Static analysis & unit tests verified (`saving_streak_calculator_test.dart`).

## 🟢 Phase 4: Receipt Upload, Host Approval & Fund Progress

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 4.1** | Transfer Receipt Upload to Firebase Storage | **COMPLETED** | `DepositReceiptSheet` wired with `image_picker` (camera/gallery), Storage upload & `PENDING` `DepositRecord` submission via `receiptApprovalProvider`: <br>- `presentation/deposit_receipt_sheet.dart`<br>- `providers/receipt_approval_provider.dart` |
| **Task 4.2** | Host Receipt Review & Verification Screen | **COMPLETED** | `ApproveReceiptScreen` wired with `tripDepositsStreamProvider`, full-screen `InteractiveViewer` receipt zoom, atomic Firestore approval (fund + plan + streak) & rejection reason dialog: <br>- `presentation/approve_receipt_screen.dart`<br>- `models/deposit_record.dart`<br>- `repository/saving_repository_impl.dart` |
| **Task 4.3** | Realtime Fund Progress Bar & Leaderboard Card | **COMPLETED** | Extracted `FundProgressCard` with 100% completion celebration state and wired `MomoFundScreen` to realtime streams with sorted member leaderboard (zero `MockTripData` dependencies): <br>- `presentation/widgets/fund_progress_card.dart`<br>- `presentation/momo_fund_screen.dart` |

### 🎯 Checkpoint 4 Status: Passed ✅
- [x] `DepositReceiptSheet` uploads receipt photos to Firebase Storage (`trips/{tripId}/receipts/`) and submits `PENDING` `DepositRecord`s.
- [x] `ApproveReceiptScreen` displays realtime pending/approved/rejected tabs, full-screen receipt zoom, and atomic approve/reject actions.
- [x] `SavingRepositoryImpl.updateDepositStatus` atomically increments fund `currentCollectedAmount`, member `paidAmount`, and updates `MemberStreak`.
- [x] `FundProgressCard` and `MomoFundScreen` render realtime progress, 100% celebration banner, and member leaderboard without `MockTripData`.
- [x] Static analysis & unit/widget tests verified (`receipt_approval_provider_test.dart`, `phase4_widgets_test.dart`).

## 🟢 Phase 5: Routing Integration & Quality Polish

| Task | Description | Status | Verification / Artifacts |
| :--- | :--- | :---: | :--- |
| **Task 5.1** | Encapsulate Module Routing Contract | **COMPLETED** | Encapsulated `GoRouter` route constants, argument parser (`SavingRouteArgs`), and `savingModuleRoutes()` for all Module 2 screens/sheets without modifying restricted `app_router.dart`: <br>- `presentation/routes.dart`<br>- `test/features/saving_discipline_and_momo/saving_routes_test.dart` |
| **Task 5.2** | Static Analysis & Code Quality Verification | **COMPLETED** | Fixed all review findings (journal guard on failed deposit upload, Firestore plan completion status, live `memberPlan` stream, inline deposit error banner, non-default `tripId` routing, shared `MoMoDeeplinkHelper.formatInitials`, and `SavingPlanScreen` entry button from `MomoFundScreen`) and verified static analysis + full test suite. |

### 🎯 Checkpoint 5 Status: Passed ✅
- [x] `SavingRoutes` & `savingModuleRoutes()` expose `/trip/momo`, `/saving-plan`, `/momo-deposit`, `/streak-calendar`, `/momo-config`, `/pending-receipts`, and `/trip/momo/approve`.
- [x] `MomoFundScreen` uses live stream state, preserves dynamic `tripId`/`memberId` navigation, and links to `SavingPlanScreen`.
- [x] Static analysis (`flutter analyze`) reports 0 errors and 0 warnings across `lib/features/saving_discipline_and_momo` and `test/features/saving_discipline_and_momo`.
- [x] Full Module 2 test suite passes (`flutter test test/features/saving_discipline_and_momo/`).
