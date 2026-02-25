# IronFive - Agent Context

IronFive is a standalone Apple Watch application designed to track strength training workouts following the **5/3/1** methodology.

## Tech Stack
- **Language:** Swift 5+
- **UI Framework:** SwiftUI (optimized for watchOS)
- **Data Persistence:** SwiftData
- **Health Integration:** HealthKit (for heart rate, active energy, and workout logging)
- **Project Management:** XcodeGen (generates `.xcodeproj` from `project.yml`)

## Project Structure
- `Sources/`
  - `Models/`: SwiftData models (`UserProfile`, `AccessoryExercise`, `WorkoutSession`) and business logic (`WorkoutCalculator`).
  - `Managers/`: `WorkoutManager` handles HealthKit sessions and state.
  - `Views/`: SwiftUI views for Dashboard, Active Workout (Warmup, Main, FSL, Accessories), and Settings.
  - `IronFiveApp.swift`: Main entry point and SwiftData container setup.
- `project.yml`: Configuration file for XcodeGen.
- `.github/workflows/`: CI/CD pipeline configurations.

## Development Guidelines
- **Project Refresh:** After modifying `project.yml` or adding many files, run `xcodegen` to update the Xcode project.
- **Architecture:** MVVM-like pattern using `@Environment` for `WorkoutManager` and SwiftData's `@Query`/`@Model`.
- **UI/UX:** Focus on high-contrast, large-tap targets suitable for Apple Watch. Use Haptic feedback for transitions (implemented in `RestTimerView`).
- **HealthKit:** Always ensure `HKWorkoutSession` is managed correctly to prevent app suspension during active workouts.
- **Coding Standards:** SwiftLint is used to maintain code quality. Avoid iOS-specific modifiers that are unavailable on watchOS.

## Core Logic (5/3/1)
- Progression is based on Training Max (typically 90% of 1RM).
- Cycles consist of 4 weeks (3 weeks of increasing intensity + 1 deload week).
- Automatic progression (+5lbs upper body, +10lbs lower body) occurs after completing a full cycle.
