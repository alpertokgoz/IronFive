# Design Spec: Reliability & Logic Decoupling (Priority 1 & 2)

**Date:** 2026-04-04
**Topic:** Service Layer, Active Session Persistence, and Decoupled Logic for IronFive

## 1. Overview
This design aims to improve the architecture and reliability of IronFive by decoupling 5/3/1 training logic from the View layer and ensuring that active workout progress is persisted across app restarts or backgrounding.

## 2. Logic Decoupling: `WorkoutSessionService`
We will introduce a dedicated service to handle all 5/3/1 calculations, progression, and session management.

### 2.1 Responsibilities
- **Next Lift Determination:** Logic to find the next lift based on user profile and workout history.
- **Cycle Advancement:** Logic to increment cycle/week and apply Training Max (TM) increases.
- **Workout Generation:** Calculating sets (Warmup, Main, Supplemental, Accessory) for a given lift and week.

### 2.2 Implementation Detail
- Create `@Observable class WorkoutSessionService`.
- Move `determineNextLift()` and `advanceCycle()` from `DashboardView`.
- Move `generateWorkoutSteps()` and related helper methods from `WorkoutActiveView+Logic`.

## 3. Reliability: `ActiveWorkoutSession` Persistence
We will implement a SwiftData model to store the state of a workout currently in progress.

### 3.1 `ActiveWorkoutSession` Model
- **Properties:**
    - `id: UUID`
    - `startTime: Date`
    - `mainLiftValue: Int` (enum raw value)
    - `currentStepIndex: Int`
    - `stepsData: Data` (JSON-encoded `[WorkoutStep]` array for easy persistence)
- **Auto-Save:** The session will be updated whenever a set is marked as complete or the user advances the tab.

### 3.2 Resume Logic
- In `WorkoutActiveView.onAppear`, check if an `ActiveWorkoutSession` exists for the current `mainLift`.
- If a session is found, decode `stepsData` and set `selectedTab = currentStepIndex`.
- If no session is found, generate new steps and create a new `ActiveWorkoutSession`.

## 4. Data Flow Refinement
- **DashboardView:** Uses `WorkoutSessionService` to show the "Next Lift" and advance cycles.
- **WorkoutActiveView:** Interacts with `WorkoutSessionService` to generate steps and manages `ActiveWorkoutSession` for persistence.
- **Completion:** Upon finishing a workout, the `ActiveWorkoutSession` is deleted, and a permanent `WorkoutSession` is added to the history.

## 5. Testing & Validation
- **Unit Tests:** Verify `WorkoutSessionService` correctly calculates sets for all templates and weeks.
- **Integration Tests:** Confirm that `ActiveWorkoutSession` is correctly saved and restored after simulating an app termination.
- **Manual Verification:** Start a workout, log a set, force-quit the app, and verify it resumes at the correct step with the set still marked as complete.
