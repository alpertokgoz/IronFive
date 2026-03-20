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
   - **New PR Indicator**: A "NEW PR!" badge if the estimated 1RM is a personal best for that lift.
3. **Stat Row (Health & Effort)**: Three compact columns.
   - **KCAL**: Flame icon + active energy.
   - **AVG BPM**: Heart icon + heart rate.
   - **TIME**: Clock icon + total duration.
4. **Progress Card (Cycle Status)**: Dedicated card for program progress.
   - **Week/Cycle Info**: "CYCLE 2, WEEK 3 (5/3/1)".
   - **Progress Bar**: Sleek bar showing progress toward finishing the 4-workout week.
5. **Efficiency Footer**: Large, centered "TOTAL VOLUME" metric (e.g., "4,250 kg LIFTED") in bold.
6. **Primary Action**: "FINISH" button at the bottom, anchored to the edge.

### Interaction & Feedback
- **Celebration**: Trigger `ParticleBurstView` with the lift's color upon showing the summary.
- **Haptics**: `UINotificationFeedbackGenerator` for success pulses on the "Finish" button.
- **Animations**: Stats "count up" to their final values when the view appears.
- **Scroll-free**: The entire view must fit on a single page without scrolling.

### Implementation Details
- **View**: `WorkoutSummaryView` will be updated to accept `WorkoutStep` to extract the AMRAP data.
- **Logic**: Calculate total volume from completed sets and identify if a new PR was set by comparing with `WorkoutSession` history.
- **Theming**: Background `Color.black.gradient` with a top-down glow using the `lift.color`.
