# Robust Icon and Layout Fixes

The goal is to solve the "invisible icons" issue by using SF Symbols that are highly compatible and ensuring they are rendered correctly on the top layer with sufficient contrast.

## User Review Required

> [!IMPORTANT]
> I will be switching to slightly more generic but highly compatible icons (SF Symbols 2.0/3.0) if the exercise-specific figures continue to fail. This ensures that users always see *something* rather than just empty colors.

## Proposed Changes

### [Models]
- Revert `MainLift.symbolName` to use more standard icons that are available in older SF Symbols versions (2.0/3.0).
- Squat: `dumbbell.fill` (or `figure.strengthtraining.functional` if confirmed)
- Bench: `figure.strengthtraining.traditional`
- Deadlift: `figure.strengthtraining.traditional`
- OHP: `figure.arms.up`

### [Views]
- **DashboardView**:
    - Add `.zIndex(1)` to the `Image` within the `ZStack` to ensure it's on top.
    - Increase icon font size to `15` and weight to `heavy`.
    - Ensure contrast: Use white for completed, and the lift's color for incomplete.
- **WorkoutActiveView**:
    - Update the header icon rendering with the same robust styles.

#### [MODIFY] [Models.swift](file:///Users/alper/github/antigravity/IronFive/Sources/Models/Models.swift)
- Provide a robust mapping of symbol names.

#### [MODIFY] [DashboardView.swift](file:///Users/alper/github/antigravity/IronFive/Sources/Views/DashboardView.swift)
- Improve the `ZStack` layering and icon styling.

#### [MODIFY] [WorkoutActiveView.swift](file:///Users/alper/github/antigravity/IronFive/Sources/Views/WorkoutActiveView.swift)
- Improve the header icon styling.

## Verification Plan

### Manual Verification
1. Run on simulator.
2. Verify icons are visible in BOTH completed and uncompleted rings.
3. Verify icons are visible in the workout header.
4. Verify icons are visible in the confirmation dialog.
