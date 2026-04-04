# Design Spec: Tactile Input Specialist (Approach 1)

**Date:** 2026-04-04
**Topic:** Digital Crown, AOD, and Haptic Feedback for IronFive

## 1. Overview
The goal of this design is to make IronFive the most tactile and glanceable strength training app on watchOS. By leveraging the Digital Crown for inputs, optimizing for Always-On Display (AOD), and refining haptic patterns, we minimize the friction of logging sets while under physical stress.

## 2. Digital Crown Integration
The Digital Crown will be the primary input method for weight and rep adjustments.

### 2.1 Contextual Weight/Rep Adjustment
- **Focus States:** Tapping a weight or rep label in `WorkoutStepView` or `AmrapInputView` will "focus" that field for crown input.
- **Visual Feedback:** A subtle glow or border around the active field.
- **Increments:**
    - **Weight:** Based on `WeightUnit` (5.0 lbs or 2.5 kg).
    - **Reps:** Single unit (1 rep).
- **Tactile Feedback:** Each "detent" or click of the crown will trigger a subtle haptic pulse to confirm the change.

### 2.2 Implementation Detail
- Use `digitalCrownRotation` modifier in SwiftUI.
- Map the rotation value to the `WorkoutSet.weight` or `WorkoutSet.actualReps`.

## 3. Always-On Display (AOD) Optimization
The app will transition to a "Glanceable Mode" when the wrist is lowered.

### 3.1 Content Filtering
- **Hidden Elements:** Heart rate animations, elapsed workout timer (seconds), and secondary navigation dots.
- **Prioritized Elements:**
    - Current Set Weight and Target Reps (large, high-contrast).
    - Active Rest Timer (if counting down).
- **Styling:** Use thinner font weights or dimmed colors to reduce power consumption while maintaining readability.

### 3.2 Implementation Detail
- Utilize the `@Environment(\.isLuminanceReduced)` property to detect AOD state.
- Conditionally hide/show views based on this environment value.

## 4. Refined Haptic Profiles
Haptic feedback will provide non-visual status updates for critical workout milestones.

### 4.1 Rest Timer "Count-in"
- **3-Second Pulse:** A rhythmic pulse at 3s, 2s, and 1s remaining in the rest timer.
- **Rest Over:** A distinct "Success" (double pulse) haptic when the timer reaches 0.

### 4.2 Logging & Progress
- **Set Completion:** A "Direction Up" haptic when a set is marked as complete.
- **Phase Completion:** A "Success" haptic when all sets in a phase (Warmup, Main, Supplemental) are finished.
- **Workout Complete:** A "Victory" (long, rhythmic pulse) when the entire session is saved.

### 4.3 Implementation Detail
- Use `WKInterfaceDevice.current().play(_:)` with specific `WKHapticType` values.
- Types: `.directionUp` for set completion, `.success` for rest over, and `.notification` or custom rhythmic calls for the "Count-in."

## 5. Testing & Validation
- **Unit Tests:** Verify `WorkoutCalculator` rounding logic for crown increments.
- **UI Tests:** Simulate crown rotation events and verify value updates in the focused field.
- **Manual Verification:** Test haptic timing during a live rest timer session on a physical device.
- **AOD Verification:** Use the "Luminance Reduced" toggle in the SwiftUI preview or a physical device to confirm the dimmed UI state.
