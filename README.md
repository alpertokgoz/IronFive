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
