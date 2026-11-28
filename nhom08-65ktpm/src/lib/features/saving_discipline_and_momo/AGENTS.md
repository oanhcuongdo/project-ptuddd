# 🤖 AI Agent Operating Guidelines (AGENTS.md)
## Project: Travel Buddy (PTUDDD - Group 08 - 65KTPM)
### Target Module: Module 2 - Saving Discipline & MoMo Group Fund (`saving_discipline_and_momo`)
**Lead Engineer:** Nguyen Xuan Binh (Student ID: 2251172252 - Class: 64KTPM5 - Member #2)

---

## 1. Role & Purpose
This document governs the operational rules, architectural guidelines, and safety boundaries for any AI Agent reading, generating, or refactoring code for **Module 2: Saving Discipline & MoMo Group Fund**.
Every agent must adhere strictly to the boundaries defined below to ensure clean integration, avoid git conflicts, and maintain academic compliance.

---

## 2. Strict Scope & Safety Boundaries

### 2.1. File System Boundary
- **ALLOWED DIRECTORY (Strict Sandbox):**
  - `C:\project-ptuddd\nhom08-65ktpm\src\lib\features\saving_discipline_and_momo/**`
  - `C:\docs/**` (for specifications and documentation export)
- **STRICTLY PROHIBITED / DO-NOT-MODIFY DIRECTORIES:**
  - Root project files: `c:\project-ptuddd\.gitignore`, `c:\project-ptuddd\README.md`.
  - Shared core & app entrypoints (managed by Team Lead):
    - `nhom08-65ktpm/src/lib/core/theme/` & `nhom08-65ktpm/src/lib/core/widgets/` — **Do not modify.** Reuse `AppColors`, `AppTheme`, `AppInsetCard`, `AppStatusBadge`, etc.
    - `nhom08-65ktpm/src/lib/main.dart` & `nhom08-65ktpm/src/lib/firebase_options.dart` — **Do not modify.**
    - `nhom08-65ktpm/src/lib/router/app_router.dart` — **Restricted.** Notify Team Lead or note in PR if new routes are needed.
  - Other feature modules:
    - `nhom08-65ktpm/src/lib/features/auth_and_group/` & `goal_and_checklist/` (Module 1)
    - `nhom08-65ktpm/src/lib/features/place_and_itinerary_planner/` (Module 3)
    - `nhom08-65ktpm/src/lib/features/budget_and_expense_cashew/` (Module 4)
  - Root documentation of other groups.

### 2.2. Git Workflow & Commit Rules
- **Official Team Branch:** `nhom08-65ktpm`.
- **Module Feature Branch:** Must follow `[feat/docs/fix]/nhom08-65ktpm/<branch_name>` (e.g., `feat/nhom08-65ktpm/module2-momo`). Pull latest `git pull origin nhom08-65ktpm` before branching, then open a PR for Team Lead review.
- **Absolute Rule:** Never commit or push directly to `main` or `upstream/main`.
- **Safe Staging Command:** Always stage only the module/group directory:
  ```bash
  git add nhom08-65ktpm/
  ```
  *Never execute `git add .` from the root workspace.*
- **Commit Message Format:**
  ```text
  <type>(nhom08-65ktpm): <concise-description>
  ```
  *Examples:*
  - `feat(nhom08-65ktpm): add momo group fund qr scanner`
  - `feat(nhom08-65ktpm): implement dailyyou saving streak calendar`
  - `fix(nhom08-65ktpm): handle momo deeplink fallback on missing app`

---

## 3. Architecture & Coding Conventions

Module 2 follows **Feature-First Clean Architecture**:

```
saving_discipline_and_momo/
 ├── models/                # Existing models: saving_plan.dart, momo_fund_config.dart, deposit_record.dart, member_streak.dart
 ├── presentation/          # UI Layer (setup_momo_sheet.dart, deposit_receipt_sheet.dart, approve_receipt_screen.dart, momo_fund_screen.dart). No direct Firestore calls.
 ├── providers/             # Riverpod Notifiers (saving_plan_provider.dart). Bridges UI & Repository.
 ├── repository/            # Data Layer (saving_repository_impl.dart: Firestore, Firebase Storage, External hardware SDKs).
 └── utils/                 # Pure domain helper functions (saving_calculator.dart, Deeplink builders).
```

### Key Engineering Rules:
1. **Riverpod State Management (v3.5.0):**
   - Use `AsyncNotifierProvider` or `NotifierProvider`. Avoid unmanaged mutable state or raw `StateProvider` for complex workflows.
   - Always wrap asynchronous repository invocations with `AsyncValue.guard()` in Notifiers to ensure robust error capturing.
   - Never inject `BuildContext` into Repositories or Notifiers.
2. **Asynchronous & Error Handling:**
   - Every I/O operation (Firestore, Storage, Camera) must be guarded against network failure and exceptions.
   - Provide user-friendly feedback (Snackbars / Dialogs) rather than unhandled crashes.
3. **MoMo Deeplink & Hardware Safety:**
   - Prior to calling `launchUrl()`, verify with `canLaunchUrl()`.
   - Always implement a fallback UI providing 1-tap copy buttons for phone number and transfer note if the native MoMo app is unavailable.
   - When launching the camera via `mobile_scanner`, always verify `Permission.camera` using `permission_handler`.

---

## 4. Agent Command Palette

Execute all build and verification commands inside `nhom08-65ktpm/src`:

```powershell
# Navigate to source
cd nhom08-65ktpm/src

# Fetch packages
flutter pub get

# Preview full UI without backend
flutter run -t lib/main_ui_preview.dart

# Code generation (Freezed & JSON)
dart run build_runner build --delete-conflicting-outputs

# Static analysis
flutter analyze

# Execute tests for Module 2
flutter test test/features/saving_discipline_and_momo/

# Inspect Git status
git status

# Update knowledge graph after Module 2 code/doc changes (from saving_discipline_and_momo/)
/graphify . --update
```

---

## 5. Standard Agent Execution Flow

When tasked with wiring logic or implementing a feature slice:
1. **Consult the Spec & Plan:** Review the corresponding section in [SPEC.md](file:///C:/docs/SPEC.md), [PLAN.md](file:///C:/docs/PLAN.md), and [huong_dan_code_logic_nhom8.md](file:///c:/project-ptuddd/nhom08-65ktpm/src/lib/features/saving_discipline_and_momo/docs/huong_dan_code_logic_nhom8.md).
2. **State Assumptions Upfront:** Surface any ambiguity before writing code.
3. **4-Step Mock-to-Real-Logic Workflow:**
   - **Repository (`repository/`):** Complete Firestore, Storage, or SDK calls, isolated from UI.
   - **Providers (`providers/`):** Wrap repository calls with `StreamProvider` (realtime Firestore) or `AsyncNotifierProvider` (mutations).
   - **Presentation (`presentation/`):** Convert `StatefulWidget` -> `ConsumerStatefulWidget` (or `StatelessWidget` -> `ConsumerWidget`), replace `MockTripData.*` with `ref.watch(...)` using `.when(loading: ..., error: ..., data: ...)`, and preserve existing widget trees and `core/widgets/`.
   - **Replace `// TODO(Module 2):` Markers:** Wire `ref.read(...notifier)...` calls with loading states to prevent double-taps.
4. **Pre-PR Verification Checklist:**
   - All `MockTripData` dependencies removed from completed screens.
   - No edits outside `saving_discipline_and_momo/` and no hardcoded colors (use `AppColors`).
   - `flutter analyze` in `src/` reports **0 errors** and 0 warnings.
   - Tested on Android emulator / physical device with real Firestore data (no crashes on empty lists or slow network).
5. **Auto-Update Knowledge Graph (`graphify`):**
   - After completing any code or documentation changes inside `saving_discipline_and_momo/`, automatically run an incremental graphify update (`/graphify . --update` or `graphify update` using `graphify-out/.graphify_python`) so `graphify-out/` stays in sync with the latest codebase.
   - Keep `graphify-out/` unstaged in feature commits unless the engineer explicitly asks to commit graph outputs.
6. **Report Clearly:** Provide file links and verification instructions to the engineer.
