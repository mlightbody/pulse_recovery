# Pulse Recovery Decision Rules

This document explains how the Pulse Recovery decision engine turns raw assessment values into a user-facing recovery decision and message.

The overall pipeline is:

```text
Raw values
  ↓
Calculated metrics
  ↓
Classified labels
  ↓
Derived signals
  ↓
Final decision
  ↓
Messages
```

The main purpose of this document is to make the rules transparent, so that changes can be made in the correct place in the code.

---

## 1. Processing Pipeline

| Stage | What happens | Main file |
|---|---|---|
| Raw input | Peak HR, HR at 60s, HR at 120s, RPE, post-exercise feeling, activity type are collected | `recovery_decision_engine.dart` |
| Metrics | HRR60, HRR120, second-minute drop, second-minute ratio and HRR score are calculated | `recovery_metrics_calculator.dart` |
| Classifications | Numeric values are converted into labels such as `poor`, `good`, `hard`, `excellent` | `recovery_signal_classifier.dart` |
| Derived signals | Labels are combined into meaningful boolean signals such as `hiddenLoadSignal` or `highStrainSignal` | `recovery_signal_builder.dart` |
| Final decision | Signals are checked in priority order to produce `progress`, `maintain`, `caution` or `recover` | `recovery_decision_policy.dart` |
| Messages | Decision state and reason tag are converted into title, summary and recommendation text | `recovery_message_builder.dart` |

---

## 2. Input Classification Rules

These rules convert raw numbers into simple labels used by the rest of the decision engine.

### 2.1 HR Recovery Quality

| Raw metric | Rule | Classified label | File to edit |
|---|---:|---|---|
| `hrrScore` | `< 0.35` | `RecoveryQuality.poor` | `recovery_signal_classifier.dart` |
| `hrrScore` | `0.35 – < 0.55` | `RecoveryQuality.moderate` | `recovery_signal_classifier.dart` |
| `hrrScore` | `0.55 – < 0.75` | `RecoveryQuality.good` | `recovery_signal_classifier.dart` |
| `hrrScore` | `>= 0.75` | `RecoveryQuality.strong` | `recovery_signal_classifier.dart` |

### 2.2 Workout Demand

| Raw input | Rule | Classified label | File to edit |
|---|---:|---|---|
| `rpe` | `<= 4` | `WorkoutDemand.easy` | `recovery_signal_classifier.dart` |
| `rpe` | `5–6` | `WorkoutDemand.moderate` | `recovery_signal_classifier.dart` |
| `rpe` | `7–8` | `WorkoutDemand.hard` | `recovery_signal_classifier.dart` |
| `rpe` | `>= 9` | `WorkoutDemand.veryHard` | `recovery_signal_classifier.dart` |

### 2.3 Subjective Response

| Raw input | Rule | Classified label | File to edit |
|---|---:|---|---|
| `feelingAfter` | `<= 4` | `SubjectiveResponse.poor` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `5–6` | `SubjectiveResponse.okay` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `7–8` | `SubjectiveResponse.good` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `>= 9` | `SubjectiveResponse.excellent` | `recovery_signal_classifier.dart` |

---

## 3. Recovery Shape Classification Rules

These rules describe the shape of the heart-rate recovery curve, not just the total recovery amount.

| Raw condition | Classified label | Meaning | File to edit |
|---|---|---|---|
| `hrr60 <= 0` OR `secondMinuteDrop < 0` | `RecoveryShape.unclear` | HR did not fall cleanly, or rose again | `recovery_signal_classifier.dart` |
| `hrr60 < 8` AND `secondMinuteDrop < 5` | `RecoveryShape.weak` | Weak drop in both first and second minute | `recovery_signal_classifier.dart` |
| `secondMinuteRatio == null` | `RecoveryShape.unclear` | Not enough ratio information | `recovery_signal_classifier.dart` |
| `secondMinuteRatio < 0.5` | `RecoveryShape.fastStartThenStall` | Good initial fall, then weaker continuation | `recovery_signal_classifier.dart` |
| `secondMinuteRatio <= 1.2` | `RecoveryShape.sustained` | Recovery continues at a broadly steady rate | `recovery_signal_classifier.dart` |
| `secondMinuteRatio > 1.2` | `RecoveryShape.delayed` | Second-minute recovery is stronger than first-minute recovery | `recovery_signal_classifier.dart` |

---

## 4. Derived Signal Rules

These are the missing middle layer between simple classifications and the final decision.

A derived signal is not a raw input. It is a boolean flag created from one or more classified labels.

For example:

```text
hrrScore < 0.35
  → recoveryQuality = poor

feelingAfter <= 4
  → subjectiveResponse = poor

recoveryQuality = poor AND subjectiveResponse = poor
  → highStrainSignal = true
```

In the code:

```dart
final feelsGood =
    subjectiveResponse == SubjectiveResponse.good ||
    subjectiveResponse == SubjectiveResponse.excellent;

final feelsPoor = subjectiveResponse == SubjectiveResponse.poor;
```

| Derived signal | Actual condition behind it | Plain-English meaning | File to edit |
|---|---|---|---|
| `easySessionHandledWell` | `workoutDemand == easy` AND `feelsGood` AND `recoveryQuality != poor` | Easy session, user felt good afterwards, and recovery was not poor | `recovery_signal_builder.dart` |
| `strongRecoveryHandledWell` | `recoveryQuality == strong` AND `feelsGood` | Strong HR recovery and positive post-workout feeling | `recovery_signal_builder.dart` |
| `hiddenLoadSignal` | `recoveryQuality == poor` AND `feelsGood` | User feels good, but HR recovery says caution | `recovery_signal_builder.dart` |
| `fatigueMismatch` | `recoveryQuality == good/strong` AND `feelsPoor` AND workout was `hard/veryHard` | HR recovery looks okay, but user feels poor after a hard session | `recovery_signal_builder.dart` |
| `highStrainSignal` | `recoveryQuality == poor` AND `feelsPoor` | Both HR recovery and post-workout feeling are poor | `recovery_signal_builder.dart` |
| `weakRecoverySignal` | `recoveryQuality == poor` OR `recoveryShape == weak` | Recovery is weak by score or by curve shape | `recovery_signal_builder.dart` |

---

## 5. Final Decision Priority Table

The final decision rules are checked from top to bottom.

The first matching rule wins.

This is important because more than one derived signal may be true at the same time. For example, `hiddenLoadSignal` and `weakRecoverySignal` can both be true, but `hiddenLoadSignal` wins because it is checked first.

| Priority | Decision rule checked | Actual condition behind it | Decision state | Reason tag | Title shown |
|---:|---|---|---|---|---|
| 1 | `highStrainSignal == true` | `recoveryQuality == poor` AND `subjectiveResponse == poor` | `recover` | `highStrain` | “Prioritise recovery” |
| 2 | `hiddenLoadSignal == true` | `recoveryQuality == poor` AND `subjectiveResponse == good/excellent` | `caution` | `hiddenLoad` | “Use caution” |
| 3 | `fatigueMismatch == true` | `recoveryQuality == good/strong` AND `subjectiveResponse == poor` AND `workoutDemand == hard/veryHard` | `caution` | `fatigueMismatch` | “Use caution” |
| 4 | `easySessionHandledWell == true` | `workoutDemand == easy` AND `subjectiveResponse == good/excellent` AND `recoveryQuality != poor` | `progress` | `easySessionHandledWell` | “Ready to progress” |
| 5 | `strongRecoveryHandledWell == true` | `recoveryQuality == strong` AND `subjectiveResponse == good/excellent` | `progress` | `strongRecovery` | “Ready to progress” |
| 6 | `weakRecoverySignal == true` | `recoveryQuality == poor` OR `recoveryShape == weak` | `caution` | `weakRecovery` | “Use caution” |
| 7 | No rule matched | Default case | `maintain` | `normalResponse` | “Maintain current level” |

---

## 6. Raw-to-Decision Examples

These examples show how a raw input pattern becomes a final decision.

| Raw-ish input pattern | Classification | Derived signal | Final result |
|---|---|---|---|
| `hrrScore < 0.35` AND `feelingAfter <= 4` | `recoveryQuality = poor`, `subjectiveResponse = poor` | `highStrainSignal = true` | `recover / highStrain` |
| `hrrScore < 0.35` AND `feelingAfter >= 7` | `recoveryQuality = poor`, `subjectiveResponse = good/excellent` | `hiddenLoadSignal = true` | `caution / hiddenLoad` |
| `hrrScore >= 0.55` AND `feelingAfter <= 4` AND `rpe >= 7` | `recoveryQuality = good/strong`, `subjectiveResponse = poor`, `workoutDemand = hard/veryHard` | `fatigueMismatch = true` | `caution / fatigueMismatch` |
| `rpe <= 4` AND `feelingAfter >= 7` AND `hrrScore >= 0.35` | `workoutDemand = easy`, `subjectiveResponse = good/excellent`, `recoveryQuality != poor` | `easySessionHandledWell = true` | `progress / easySessionHandledWell` |
| `hrrScore >= 0.75` AND `feelingAfter >= 7` | `recoveryQuality = strong`, `subjectiveResponse = good/excellent` | `strongRecoveryHandledWell = true` | `progress / strongRecovery` |
| `hrrScore < 0.35` OR recovery shape is weak | `recoveryQuality = poor` OR `recoveryShape = weak` | `weakRecoverySignal = true` | `caution / weakRecovery`, unless a higher-priority rule already fired |
| None of the above | Mixed or normal signals | No special signal wins | `maintain / normalResponse` |

---

## 7. Message Rules Table

The title is selected from the final decision state.

The summary and recommendation are selected from the `reasonTag`.

| Reason tag | Title | Summary meaning | Recommendation meaning | File to edit |
|---|---|---|---|---|
| `easySessionHandledWell` | “Ready to progress” | Session looked comfortably manageable | Consider a small progression next time | `recovery_message_builder.dart` |
| `strongRecovery` | “Ready to progress” | HR recovery was strong and post-workout feeling was positive | Consider a modest increase, but avoid increasing intensity and duration together | `recovery_message_builder.dart` |
| `hiddenLoad` | “Use caution” | User felt good, but HR recovery was slower than expected | Keep next session controlled and watch whether the pattern repeats | `recovery_message_builder.dart` |
| `fatigueMismatch` | “Use caution” | HR recovery looked reasonable, but post-workout feeling was low for a hard session | Prioritise sleep, hydration, nutrition and easier aerobic work | `recovery_message_builder.dart` |
| `highStrain` | “Prioritise recovery” | HR recovery and post-workout feeling both suggest strain | Avoid another hard session immediately | `recovery_message_builder.dart` |
| `weakRecovery` | “Use caution” | HR recovery was weaker than expected | Reduce intensity, extend warm-down, or allow more recovery | `recovery_message_builder.dart` |
| `normalResponse` | “Maintain current level” | Recovery response is broadly in line with the session | Keep next session similar and look for steady improvement | `recovery_message_builder.dart` |

---

## 8. Where to Change Things

| You want to change… | Edit this file |
|---|---|
| HRR scoring formula | `recovery_metrics_calculator.dart` |
| Poor / moderate / good / strong thresholds | `recovery_signal_classifier.dart` |
| RPE bands | `recovery_signal_classifier.dart` |
| Feeling-after bands | `recovery_signal_classifier.dart` |
| Recovery-shape rules | `recovery_signal_classifier.dart` |
| What counts as hidden load, high strain, fatigue mismatch, etc. | `recovery_signal_builder.dart` |
| Which signal wins when several are true | `recovery_decision_policy.dart` |
| Title, summary, and recommendation text | `recovery_message_builder.dart` |
| Add a new decision state | `models/recovery_decision.dart`, then policy and message builder |
| Add a new signal | `models/recovery_signals.dart`, then builder, policy, and message builder |

---

## 9. Suggested Developer Trace

A useful future improvement would be to store a `decisionTrace` with each assessment.

This would make the system much easier to debug when a user says the advice feels wrong.

Example:

```json
{
  "recoveryQuality": "poor",
  "workoutDemand": "hard",
  "subjectiveResponse": "good",
  "recoveryShape": "weak",
  "signalsTrue": ["hiddenLoadSignal", "weakRecoverySignal"],
  "winningRule": "hiddenLoadSignal",
  "decision": "caution",
  "reasonTag": "hiddenLoad"
}
```

This would show whether the problem is caused by:

- the numeric thresholds,
- the derived signal logic,
- the decision priority order, or
- the message wording.

---

## 10. Summary

The decision engine is best understood as a layered rule system:

```text
Raw values
  ↓
Metrics
  ↓
Classifications
  ↓
Derived signals
  ↓
Priority-based decision
  ↓
User-facing message
```

The most important part to understand is that the final decision table does not directly use raw inputs.

It uses derived signals such as `highStrainSignal`, `hiddenLoadSignal`, and `fatigueMismatch`.

Those signals are created earlier by combining recovery quality, workout demand, subjective response and recovery shape.
# Pulse Recovery Decision Rules

This document explains how the Pulse Recovery decision engine turns raw assessment values into a user-facing recovery decision and message.

The overall pipeline is:

```text
Raw values
  ↓
Calculated metrics
  ↓
Classified labels
  ↓
Derived signals
  ↓
Final decision
  ↓
Messages
```

The main purpose of this document is to make the rules transparent, so that changes can be made in the correct place in the code.

---

## 1. Processing Pipeline

| Stage | What happens | Main file |
|---|---|---|
| Raw input | Peak HR, HR at 60s, HR at 120s, RPE, post-exercise feeling, activity type are collected | `recovery_decision_engine.dart` |
| Metrics | HRR60, HRR120, second-minute drop, second-minute ratio and HRR score are calculated | `recovery_metrics_calculator.dart` |
| Classifications | Numeric values are converted into labels such as `poor`, `good`, `hard`, `excellent` | `recovery_signal_classifier.dart` |
| Derived signals | Labels are combined into meaningful boolean signals such as `hiddenLoadSignal` or `highStrainSignal` | `recovery_signal_builder.dart` |
| Final decision | Signals are checked in priority order to produce `progress`, `maintain`, `caution` or `recover` | `recovery_decision_policy.dart` |
| Messages | Decision state and reason tag are converted into title, summary and recommendation text | `recovery_message_builder.dart` |

---

## 2. Input Classification Rules

These rules convert raw numbers into simple labels used by the rest of the decision engine.

### 2.1 HR Recovery Quality

| Raw metric | Rule | Classified label | File to edit |
|---|---:|---|---|
| `hrrScore` | `< 0.35` | `RecoveryQuality.poor` | `recovery_signal_classifier.dart` |
| `hrrScore` | `0.35 – < 0.55` | `RecoveryQuality.moderate` | `recovery_signal_classifier.dart` |
| `hrrScore` | `0.55 – < 0.75` | `RecoveryQuality.good` | `recovery_signal_classifier.dart` |
| `hrrScore` | `>= 0.75` | `RecoveryQuality.strong` | `recovery_signal_classifier.dart` |

### 2.2 Workout Demand

| Raw input | Rule | Classified label | File to edit |
|---|---:|---|---|
| `rpe` | `<= 4` | `WorkoutDemand.easy` | `recovery_signal_classifier.dart` |
| `rpe` | `5–6` | `WorkoutDemand.moderate` | `recovery_signal_classifier.dart` |
| `rpe` | `7–8` | `WorkoutDemand.hard` | `recovery_signal_classifier.dart` |
| `rpe` | `>= 9` | `WorkoutDemand.veryHard` | `recovery_signal_classifier.dart` |

### 2.3 Subjective Response

| Raw input | Rule | Classified label | File to edit |
|---|---:|---|---|
| `feelingAfter` | `<= 4` | `SubjectiveResponse.poor` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `5–6` | `SubjectiveResponse.okay` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `7–8` | `SubjectiveResponse.good` | `recovery_signal_classifier.dart` |
| `feelingAfter` | `>= 9` | `SubjectiveResponse.excellent` | `recovery_signal_classifier.dart` |

---

## 3. Recovery Shape Classification Rules

These rules describe the shape of the heart-rate recovery curve, not just the total recovery amount.

| Raw condition | Classified label | Meaning | File to edit |
|---|---|---|---|
| `hrr60 <= 0` OR `secondMinuteDrop < 0` | `RecoveryShape.unclear` | HR did not fall cleanly, or rose again | `recovery_signal_classifier.dart` |
| `hrr60 < 8` AND `secondMinuteDrop < 5` | `RecoveryShape.weak` | Weak drop in both first and second minute | `recovery_signal_classifier.dart` |
| `secondMinuteRatio == null` | `RecoveryShape.unclear` | Not enough ratio information | `recovery_signal_classifier.dart` |
| `secondMinuteRatio < 0.5` | `RecoveryShape.fastStartThenStall` | Good initial fall, then weaker continuation | `recovery_signal_classifier.dart` |
| `secondMinuteRatio <= 1.2` | `RecoveryShape.sustained` | Recovery continues at a broadly steady rate | `recovery_signal_classifier.dart` |
| `secondMinuteRatio > 1.2` | `RecoveryShape.delayed` | Second-minute recovery is stronger than first-minute recovery | `recovery_signal_classifier.dart` |

---

## 4. Derived Signal Rules

These are the missing middle layer between simple classifications and the final decision.

A derived signal is not a raw input. It is a boolean flag created from one or more classified labels.

For example:

```text
hrrScore < 0.35
  → recoveryQuality = poor

feelingAfter <= 4
  → subjectiveResponse = poor

recoveryQuality = poor AND subjectiveResponse = poor
  → highStrainSignal = true
```

In the code:

```dart
final feelsGood =
    subjectiveResponse == SubjectiveResponse.good ||
    subjectiveResponse == SubjectiveResponse.excellent;

final feelsPoor = subjectiveResponse == SubjectiveResponse.poor;
```

| Derived signal | Actual condition behind it | Plain-English meaning | File to edit |
|---|---|---|---|
| `easySessionHandledWell` | `workoutDemand == easy` AND `feelsGood` AND `recoveryQuality != poor` | Easy session, user felt good afterwards, and recovery was not poor | `recovery_signal_builder.dart` |
| `strongRecoveryHandledWell` | `recoveryQuality == strong` AND `feelsGood` | Strong HR recovery and positive post-workout feeling | `recovery_signal_builder.dart` |
| `hiddenLoadSignal` | `recoveryQuality == poor` AND `feelsGood` | User feels good, but HR recovery says caution | `recovery_signal_builder.dart` |
| `fatigueMismatch` | `recoveryQuality == good/strong` AND `feelsPoor` AND workout was `hard/veryHard` | HR recovery looks okay, but user feels poor after a hard session | `recovery_signal_builder.dart` |
| `highStrainSignal` | `recoveryQuality == poor` AND `feelsPoor` | Both HR recovery and post-workout feeling are poor | `recovery_signal_builder.dart` |
| `weakRecoverySignal` | `recoveryQuality == poor` OR `recoveryShape == weak` | Recovery is weak by score or by curve shape | `recovery_signal_builder.dart` |

---

## 5. Final Decision Priority Table

The final decision rules are checked from top to bottom.

The first matching rule wins.

This is important because more than one derived signal may be true at the same time. For example, `hiddenLoadSignal` and `weakRecoverySignal` can both be true, but `hiddenLoadSignal` wins because it is checked first.

| Priority | Decision rule checked | Actual condition behind it | Decision state | Reason tag | Title shown |
|---:|---|---|---|---|---|
| 1 | `highStrainSignal == true` | `recoveryQuality == poor` AND `subjectiveResponse == poor` | `recover` | `highStrain` | “Prioritise recovery” |
| 2 | `hiddenLoadSignal == true` | `recoveryQuality == poor` AND `subjectiveResponse == good/excellent` | `caution` | `hiddenLoad` | “Use caution” |
| 3 | `fatigueMismatch == true` | `recoveryQuality == good/strong` AND `subjectiveResponse == poor` AND `workoutDemand == hard/veryHard` | `caution` | `fatigueMismatch` | “Use caution” |
| 4 | `easySessionHandledWell == true` | `workoutDemand == easy` AND `subjectiveResponse == good/excellent` AND `recoveryQuality != poor` | `progress` | `easySessionHandledWell` | “Ready to progress” |
| 5 | `strongRecoveryHandledWell == true` | `recoveryQuality == strong` AND `subjectiveResponse == good/excellent` | `progress` | `strongRecovery` | “Ready to progress” |
| 6 | `weakRecoverySignal == true` | `recoveryQuality == poor` OR `recoveryShape == weak` | `caution` | `weakRecovery` | “Use caution” |
| 7 | No rule matched | Default case | `maintain` | `normalResponse` | “Maintain current level” |

---

## 6. Raw-to-Decision Examples

These examples show how a raw input pattern becomes a final decision.

| Raw-ish input pattern | Classification | Derived signal | Final result |
|---|---|---|---|
| `hrrScore < 0.35` AND `feelingAfter <= 4` | `recoveryQuality = poor`, `subjectiveResponse = poor` | `highStrainSignal = true` | `recover / highStrain` |
| `hrrScore < 0.35` AND `feelingAfter >= 7` | `recoveryQuality = poor`, `subjectiveResponse = good/excellent` | `hiddenLoadSignal = true` | `caution / hiddenLoad` |
| `hrrScore >= 0.55` AND `feelingAfter <= 4` AND `rpe >= 7` | `recoveryQuality = good/strong`, `subjectiveResponse = poor`, `workoutDemand = hard/veryHard` | `fatigueMismatch = true` | `caution / fatigueMismatch` |
| `rpe <= 4` AND `feelingAfter >= 7` AND `hrrScore >= 0.35` | `workoutDemand = easy`, `subjectiveResponse = good/excellent`, `recoveryQuality != poor` | `easySessionHandledWell = true` | `progress / easySessionHandledWell` |
| `hrrScore >= 0.75` AND `feelingAfter >= 7` | `recoveryQuality = strong`, `subjectiveResponse = good/excellent` | `strongRecoveryHandledWell = true` | `progress / strongRecovery` |
| `hrrScore < 0.35` OR recovery shape is weak | `recoveryQuality = poor` OR `recoveryShape = weak` | `weakRecoverySignal = true` | `caution / weakRecovery`, unless a higher-priority rule already fired |
| None of the above | Mixed or normal signals | No special signal wins | `maintain / normalResponse` |

---

## 7. Message Rules Table

The title is selected from the final decision state.

The summary and recommendation are selected from the `reasonTag`.

| Reason tag | Title | Summary meaning | Recommendation meaning | File to edit |
|---|---|---|---|---|
| `easySessionHandledWell` | “Ready to progress” | Session looked comfortably manageable | Consider a small progression next time | `recovery_message_builder.dart` |
| `strongRecovery` | “Ready to progress” | HR recovery was strong and post-workout feeling was positive | Consider a modest increase, but avoid increasing intensity and duration together | `recovery_message_builder.dart` |
| `hiddenLoad` | “Use caution” | User felt good, but HR recovery was slower than expected | Keep next session controlled and watch whether the pattern repeats | `recovery_message_builder.dart` |
| `fatigueMismatch` | “Use caution” | HR recovery looked reasonable, but post-workout feeling was low for a hard session | Prioritise sleep, hydration, nutrition and easier aerobic work | `recovery_message_builder.dart` |
| `highStrain` | “Prioritise recovery” | HR recovery and post-workout feeling both suggest strain | Avoid another hard session immediately | `recovery_message_builder.dart` |
| `weakRecovery` | “Use caution” | HR recovery was weaker than expected | Reduce intensity, extend warm-down, or allow more recovery | `recovery_message_builder.dart` |
| `normalResponse` | “Maintain current level” | Recovery response is broadly in line with the session | Keep next session similar and look for steady improvement | `recovery_message_builder.dart` |

---

## 8. Where to Change Things

| You want to change… | Edit this file |
|---|---|
| HRR scoring formula | `recovery_metrics_calculator.dart` |
| Poor / moderate / good / strong thresholds | `recovery_signal_classifier.dart` |
| RPE bands | `recovery_signal_classifier.dart` |
| Feeling-after bands | `recovery_signal_classifier.dart` |
| Recovery-shape rules | `recovery_signal_classifier.dart` |
| What counts as hidden load, high strain, fatigue mismatch, etc. | `recovery_signal_builder.dart` |
| Which signal wins when several are true | `recovery_decision_policy.dart` |
| Title, summary, and recommendation text | `recovery_message_builder.dart` |
| Add a new decision state | `models/recovery_decision.dart`, then policy and message builder |
| Add a new signal | `models/recovery_signals.dart`, then builder, policy, and message builder |

---

## 9. Suggested Developer Trace

A useful future improvement would be to store a `decisionTrace` with each assessment.

This would make the system much easier to debug when a user says the advice feels wrong.

Example:

```json
{
  "recoveryQuality": "poor",
  "workoutDemand": "hard",
  "subjectiveResponse": "good",
  "recoveryShape": "weak",
  "signalsTrue": ["hiddenLoadSignal", "weakRecoverySignal"],
  "winningRule": "hiddenLoadSignal",
  "decision": "caution",
  "reasonTag": "hiddenLoad"
}
```

This would show whether the problem is caused by:

- the numeric thresholds,
- the derived signal logic,
- the decision priority order, or
- the message wording.

---

## 10. Summary

The decision engine is best understood as a layered rule system:

```text
Raw values
  ↓
Metrics
  ↓
Classifications
  ↓
Derived signals
  ↓
Priority-based decision
  ↓
User-facing message
```

The most important part to understand is that the final decision table does not directly use raw inputs.

It uses derived signals such as `highStrainSignal`, `hiddenLoadSignal`, and `fatigueMismatch`.

Those signals are created earlier by combining recovery quality, workout demand, subjective response and recovery shape.