# Design Spec: Elite Performance Features

**Date:** 2026-04-04
**Topic:** Visual Plate Guide, Workout Autopilot, Biometric Intensity, and Haptic Textures for IronFive

## 1. Overview
This design aims to elevate IronFive into a premium Apple Watch lifting experience by adding visual aids for plate loading, an automated workout "Autopilot" mode, heart rate intensity visualization, and tactile feedback refinement.

## 2. Visual Plate Guide (UX)
A compact visualization of the plates required for the current weight will be shown directly in the `SetRowView`.

### 2.1 Plate Math Logic
- Extract `platesNeeded(for:targetWeight:unit:)` from `PlateCalculatorView` into a static helper in `WorkoutCalculator`.
- Return an array of plate objects (weight, count, color).

### 2.2 UI Implementation
- Create a `CompactPlateStackView` that displays plates as a row of colored circles with their weights.
- Integrate this view into `SetRowView`, visible only when the set is "focused" or the active set in the session.

## 3. Workout Autopilot (Intelligence)
An optional mode to automate the transition between sets and rest timers.

### 3.1 Autopilot Logic
- **Trigger:** Logging a non-AMRAP set in `SetRowView`.
- **Action:**
    1.  Mark set as complete.
    2.  Immediately start the rest timer.
    3.  When rest timer hits 0, automatically advance the tab to the next `WorkoutStep`.
- **Configuration:** Add a "Workout Autopilot" toggle in `SettingsView`.

## 4. Biometric Intensity (Biometrics)
A color-coded heart rate ring to visualize physical strain.

### 4.1 Zone Calculation
- Define 5 HR zones based on a default Max HR (220 - Age, default Age = 30 if not set in `UserProfile`).
- **Zones:**
    - Zone 1 (<60%): Blue
    - Zone 2 (60-70%): Green
    - Zone 3 (70-80%): Yellow
    - Zone 4 (80-90%): Orange
    - Zone 5 (>90%): Red

### 4.2 UI Implementation
- Update the heart rate stat in the `WorkoutActiveView` footer.
- Add a circular stroke (intensity ring) around the heart icon that changes color based on the current HR zone.

## 5. Haptic Textures (Interaction)
Refined haptic feedback for Digital Crown inputs.

### 5.1 Input-Specific Haptics
- **Weight Adjustment:** Use `WKHapticType.click` for a "heavier," mechanical detent feel.
- **Rep Adjustment:** Use `WKHapticType.selection` for a "lighter," softer feel.

## 6. Testing & Validation
- **Unit Tests:** Verify plate calculation logic for both lbs and kg units.
- **UI Tests:** Confirm autopilot transitions work correctly (Set -> Rest -> Next Tab).
- **Manual Verification:** Test HR intensity color changes using the HealthKit simulator (or real device) and feel the distinct haptics for weight/rep adjustments.
