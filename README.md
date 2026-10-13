# IronFive

IronFive is a standalone Apple Watch application designed to track strength training workouts following the **5/3/1** methodology. It provides a streamlined experience for lifters to manage their cycles, track their sets, and log their progress directly from their wrist.

## Features

- **5/3/1 Methodology Support**: Tracks Warmup, Main (5s, 3s, 5/3/1), and Supplemental sets.
- **Supplemental Templates**: Supports popular variations including:
  - FSL (First Set Last)
  - BBB (Boring But Big)
  - SSL (Second Set Last)
  - BBS (Boring But Strong)
  - Widowmaker
- **Automatic Progression**: Calculates Training Max (TM) increases (+5lbs upper body, +10lbs lower body) after completing a cycle.
- **HealthKit Integration**: Synchronizes heart rate, active energy, and workout data with the Apple Health app.
- **SwiftData Persistence**: Efficiently manages user profiles, accessory exercises, and workout history.
- **Optimized for watchOS**: High-contrast UI with large tap targets and haptic feedback for a seamless workout experience.

## Tech Stack

- **Language**: Swift 5+
- **UI Framework**: SwiftUI (WatchOS)
- **Data Persistence**: SwiftData
- **Health Integration**: HealthKit
- **Project Management**: XcodeGen

## Project Structure

- `Sources/`
  - `Models/`: SwiftData models (`UserProfile`, `AccessoryExercise`, `WorkoutSession`) and `WorkoutCalculator` logic.
  - `Managers/`: `WorkoutManager` for HealthKit session management and state.
  - `Views/`: SwiftUI views including Dashboard, Active Workout, History, and Settings.
  - `IronFiveApp.swift`: App entry point and container setup.
- `project.yml`: Configuration file for XcodeGen.

## Getting Started

### Prerequisites

- macOS with Xcode installed.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed (`brew install xcodegen`).

### Setup

1. Clone the repository.
2. Run `xcodegen` in the root directory to generate the `IronFive.xcodeproj` file.
3. Open `IronFive.xcodeproj` in Xcode.
4. Build and run on a watchOS simulator or a physical Apple Watch.

## Development Guidelines

- **Project Refresh**: Always run `xcodegen` after modifying `project.yml` or adding new files.
- **Architecture**: Follows an MVVM-like pattern using `@Environment` for the `WorkoutManager` and SwiftData's `@Query`/`@Model`.
- **UI/UX**: Prioritize large, easy-to-tap elements and haptic feedback.
- **Coding Standards**: SwiftLint is used to maintain code quality. Refer to `.swiftlint.yml` for specific rules.

## Verification

Run `swift test` for countdown and saved-progress regression tests. These tests run on macOS without a watch simulator. For app validation, run `pre-commit run --all-files` and build the `IronFive` scheme for a watchOS simulator.

On an Apple Watch, verify that Autopilot off leaves a completed set on screen with an optional REST action; Autopilot on starts rest once for non-AMRAP sets. Skip must advance once, and ±30s must update both the countdown and notification. Background or terminate an active workout, then resume: logged sets, current page, and rest deadline should restore. When HealthKit provides an active session for recovery, it must be reattached rather than replaced. If HealthKit has no recoverable session, a new HealthKit recording starts when the saved workout is resumed.

## Design preview

Choose the `IronFiveDesign` scheme and a Watch simulator to browse the redesigned screens with sample data. This Debug-only mode uses an in-memory store and bypasses HealthKit and notifications. The normal `IronFive` scheme uses your actual program. An optional `--design-screen=dashboard` launch argument opens a screen directly; supported values are `dashboard`, `workout`, `rest`, `summary`, `history`, `settings`, `onboarding`, `weight`, and `amrap`.

The dashboard and rest layouts adapt to compact Watch displays. Start and resume open directly; the workout actions sheet provides Pause & Exit, Finish & Save, and Undo. Partial sessions stay in history without advancing the week. Changing units converts training maxes, assistance weights, and recorded AMRAP weights; program changes are restricted while a workout is saved.

Before release, verify HealthKit recovery, authorization, and haptics on a physical Watch, and exercise the full workout flow on 40mm and 46mm simulators.
