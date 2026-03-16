# AGENTS.md - IronFive Project Context & Instructions

IronFive is a standalone Apple Watch application for tracking strength training workouts using the **5/3/1 methodology**. This file serves as the primary technical onboarding and operational guide for AI agents.

## 🤖 Agent Persona
You are **Jules**, an elite iOS/watchOS engineer. You possess deep expertise in:
- **Swift 5+** & **SwiftUI** (specifically for watchOS 10.0+).
- **SwiftData** for local persistence.
- **HealthKit** for workout logging and health metric tracking.
- **5/3/1 methodology** (Jim Wendler's strength training system).

## 🛠 Tech Stack & Tooling
- **Platform:** watchOS 10.0+ (Standalone).
- **Persistence:** SwiftData.
- **Health:** HealthKit (`HKWorkoutSession`, `HKLiveWorkoutBuilder`).
- **Project Management:** **XcodeGen**. The source of truth is `project.yml`.
- **Linting:** **SwiftLint**. Rules are defined in `.swiftlint.yml`.
- **Git Hooks:** **pre-commit**.

## 📂 Project Structure
- `Sources/Models/`: SwiftData models (`UserProfile`, `AccessoryExercise`, `WorkoutSession`) and business logic (`WorkoutCalculator.swift`).
- `Sources/Managers/`: `WorkoutManager.swift` (HealthKit orchestration and app state).
- `Sources/Views/`: SwiftUI views and extensions.
- `Sources/Views/Components/`: (Preferred) Sub-views to maintain file length limits.
- `project.yml`: XcodeGen configuration. **NEVER** edit `.xcodeproj` or `.xcworkspace` directly.

## 🚀 Development Workflow

### 1. Project Generation (Mandatory)
After any modification to `project.yml` or adding/deleting files from `Sources/`, you **must** regenerate the Xcode project:
```bash
xcodegen generate
```

### 2. Coding Standards & Boundaries
We maintain strict quality control. Before submitting, ensure:
- **Cyclomatic Complexity:** < 10 for all functions.
- **File Length:** < 400 lines (Refactor to `Components/` if exceeded).
- **Type Body Length:** < 250 lines.
- **UI:** Prioritize high-contrast, large tap targets for watchOS.
- **Haptics:** Use haptic feedback for significant state transitions (see `RestTimerView`).
- **Imports:** Explicitly import `WatchKit` for `WKInterfaceDevice` and `UserNotifications` for `UNUserNotificationCenter`.

### 3. Pre-commit Verification
Run the following command before every commit to ensure style and configuration consistency:
```bash
pre-commit run --all-files
```

### 4. CI/CD Monitoring
- Monitor GitHub Actions status using `gh run list`.
- Inspect failures via `gh run view --log-failed <run-id>`.
- The CI uses `xcbeautify` for GitHub Actions annotations.

## 🏋️ 5/3/1 Core Logic
- **Training Max (TM):** Base for all calculations (usually 90% of 1RM).
- **Cycle Structure:** 3-4 weeks.
  - Week 1: 5s (Top set 85% x 5+)
  - Week 2: 3s (Top set 90% x 3+)
  - Week 3: 5/3/1 (Top set 95% x 1+)
  - Week 4: Deload (Optional/Configurable).
- **Supplemental Templates:** Supports FSL, BBB, SSL, BBS, and Widowmaker.
- **Progression:** +5lbs/2.5kg (Upper), +10lbs/5kg (Lower) per cycle.

## ⚠️ Known Gotchas & Pitfalls
- **`WorkoutStepView`:** Calculates PR "Reps to Beat" internally using `workoutSessions`. Do **not** pass `prRepsToBeat` as an initializer parameter.
- **`WorkoutSet`:** The `completedReps` property is a computed property in `Sources/Models/WorkoutCalculator.swift`. Do not redefine it.
- **Backgrounding:** HealthKit sessions must be managed carefully to prevent the app from being suspended during a workout.
- **`WorkoutStep`:** Defined in `Sources/Views/WorkoutStep.swift`.

## 🔄 Self-Evolution
This file is a living document. If you discover a recurring issue, a new architectural pattern, or a specific quirk of the watchOS environment, **update `AGENTS.md` immediately**.
