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
- **STRICTLY PROHIBITED DIRECTORIES:**
  - Root project files: `c:\project-ptuddd\.gitignore`, `c:\project-ptuddd\README.md`.
  - Other feature modules:
    - `nhom08-65ktpm/src/lib/features/goal_and_checklist/` (Module 1)
    - `nhom08-65ktpm/src/lib/features/place_and_itinerary_planner/` (Module 3)
    - `nhom08-65ktpm/src/lib/features/budget_and_expense_cashew/` (Module 4)
  - Root documentation of other groups.

### 2.2. Git Workflow & Commit Rules
- **Official Team Branch:** `nhom08-65ktpm`.
- **Absolute Rule:** Never commit or push directly to `main` or `upstream/main`.
- **Safe Staging Command:** Always stage only the group directory:
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
 ├── presentation/          # UI Layer (Screens & Reusable Widgets). No direct Firestore calls.
 ├── providers/             # Riverpod Notifiers (AsyncNotifier / Notifier). Bridges UI & Repository.
 ├── repository/            # Data Layer (Firestore, Firebase Storage, External hardware SDKs).
 └── utils/                 # Pure domain helper functions (Calculator, Deeplink builders).
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

# Code generation (Freezed & JSON)
dart run build_runner build --delete-conflicting-outputs

# Static analysis
flutter analyze

# Execute tests for Module 2
flutter test test/features/saving_discipline_and_momo/

# Inspect Git status
git status
```

---

## 5. Standard Agent Execution Flow

When tasked with implementing a feature slice:
1. **Consult the Spec & Plan:** Review the corresponding section in [SPEC.md](file:///C:/docs/SPEC.md) and [PLAN.md](file:///C:/docs/PLAN.md).
2. **State Assumptions Upfront:** Surface any ambiguity before writing code.
3. **Execute Vertical Slice:** Implement Model ➔ Repository ➔ Notifier ➔ UI Widget strictly within `features/saving_discipline_and_momo/`.
4. **Verify Quality:** Run `flutter analyze` to ensure 0 errors and 0 warnings.
5. **Report Clearly:** Provide file links and verification instructions to the engineer.
