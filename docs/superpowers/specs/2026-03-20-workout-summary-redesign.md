# Workout Summary Redesign

## Goal
Redesign the `WorkoutSummaryView` to provide a high-impact, single-page summary of a completed 5/3/1 workout, emphasizing the user's AMRAP (As Many Reps As Possible) performance, overall cycle progress, and health data.

## Design: "The Hero Accomplishment"
Focus on the "win" of the workout—the AMRAP set—while grouping supporting data and celebrating the completion with visual and haptic feedback.

### Layout & Components
1. **Header**: Minimalist title like "SESSION COMPLETE" with the lift's theme color (e.g., Orange for Squat).
2. **Hero Section (AMRAP)**: High-contrast card.
   - **Performance**: "SQUAT 100 kg × 8" (or lbs) in bold typography.
   - **Est. 1RM Badge**: Small accented badge showing calculated 1RM (e.g., "126 kg EST. 1RM").
   - **New PR Indicator**: A "NEW PR!" badge if the estimated 1RM is a personal best for that lift (compare current estimated 1RM with the maximum `estimated1RM` from historical `WorkoutSession` objects for the same `MainLift`).
3. **Stat Row (Health & Effort)**: Three compact columns.
   - **KCAL**: Flame icon + active energy from `WorkoutManager`.
   - **AVG BPM**: Heart icon + heart rate from `WorkoutManager`.
   - **TIME**: Clock icon + total duration from `WorkoutManager.elapsedTime`.
4. **Progress Card (Cycle Status)**: Dedicated card for program progress.
   - **Week/Cycle Info**: "CYCLE 2, WEEK 3 (5/3/1)".
   - **Progress Bar**: Sleek bar showing progress toward finishing the 4-workout week (Squat, Bench, Deadlift, OHP).
5. **Efficiency Footer**: Large, centered "TOTAL VOLUME" metric (e.g., "4,250 kg LIFTED") in bold.
   - **Calculation**: Sum of `weight * completedReps` for all completed `WorkoutSet`s in the session.
6. **Primary Action**: "FINISH" button at the bottom, anchored to the edge.

### Interaction & Feedback
- **Celebration**: Trigger `ParticleBurstView` with the lift's color upon showing the summary.
- **Haptics**: `UINotificationFeedbackGenerator` for success pulses on the "Finish" button.
- **Animations**: Stats "count up" to their final values when the view appears.
- **Scroll-free Strategy**: The design targets a single-page view. However, to ensure compatibility with smaller Apple Watch sizes (38mm/40mm), the view should be wrapped in a `ScrollView` with indicators hidden, allowing overflow if absolutely necessary while keeping the main hero elements visible on larger screens (44mm/45mm/Ultra).

### Implementation Details
- **View**: `WorkoutSummaryView` will be updated to accept a `WorkoutSession` object and the list of completed `WorkoutSet`s.
- **Logic**:
  - Identify the AMRAP set by filtering `WorkoutSet`s for `isAMRAP == true` or checking for "+" in the reps string.
  - Calculate total volume: `completedSets.reduce(0) { $0 + ($1.weight * Double($1.completedReps)) }`.
  - PR Logic: Query `WorkoutSession` for the highest `estimated1RM` for the current `MainLift`. If current `estimated1RM > historicalMax`, show "NEW PR!".
- **Theming**: Background `Color.black.gradient` with a top-down glow using the `lift.color`. Ensure the "FINISH" button uses the lift's theme color for consistency.
- **Integration**: This view is for weekly workout completion. At the end of a cycle (Week 4 deload or Week 3 finish depending on settings), the app may still transition to `CycleSummaryView` for TM increases.
