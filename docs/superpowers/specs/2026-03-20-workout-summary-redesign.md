# Spec: Workout Summary View Redesign

## Goal
Redesign the post-workout summary on Apple Watch to provide a high-hierarchy, visually appealing layout that focuses on training volume and health metrics (KCAL, BPM).

## Success Criteria
- **Clarity**: Total volume lifted is the primary hero metric.
- **Density**: KCAL and Heart Rate are presented in a 2x2 or 2x1 grid without being cramped.
- **Accessibility**: The "FINISH" button is a large, easy-to-tap target at the bottom.
- **Consistency**: Matches the established design language of `IronFive`.

## Design

### 1. View Structure
The view will be renamed `WorkoutSummaryView` and will be part of the `TabView` in `WorkoutActiveView`.

### 2. Layout Hierarchy (Top to Bottom)
- **Header**:
  - Icon: `🏆` (trophy.fill)
  - Text: "WORKOUT SAVED" (system size 11, black, rounded)
  - Alignment: Center-top.
- **Hero Card (Volume)**:
  - Label: "TOTAL VOLUME" (accent color, font size 8, extra bold)
  - Value: Big, prominent display of `totalWeight` (system size 20, black, rounded)
  - Unit: e.g., "KG" (secondary color, font size 10)
  - Background: Gradient (0.2 opacity of Blue/Accent) with a left border accent.
- **Stats Grid**:
  - A horizontal row of two boxes.
  - Box 1: "🔥 KCAL" + `activeEnergy` value.
  - Box 2: "❤️ BPM" + `heartRate` value.
  - Style: Subtle dark background (`Color.white.opacity(0.08)`), rounded corners (10).
- **Action Button**:
  - Label: "FINISH" (font size 15, black, rounded)
  - Color: `.green` (borderedProminent style).
  - Height: ~40px.

### 3. PR/Celebration Logic
If `showCelebration` is `true`:
- The header text changes to "NEW PR!" (gold/yellow).
- An additional badge for the AMRAP result ("SESSION BEST") is shown above the Hero Card or as a small overlay on it.
- Confetti particles (from `CelebrationView`) will still spawn in the background.

## Technical Implementation
- **File**: `Sources/Views/WorkoutSummaryView.swift`
- **Component**: Update `CompactStatBox` to match the new design with smaller text and larger icons.
- **View**: Remove `ScrollView` to avoid double-scroll issues within `TabView` and ensure the layout is pixel-perfect for the 46mm (and below) watch screens.

## Verification Plan
- **Manual**: Verify that on Apple Watch Series 11 (46mm) the layout is not clipped and the "FINISH" button is easily tappable.
- **Build**: Ensure `xcodebuild` passes after the renaming.
