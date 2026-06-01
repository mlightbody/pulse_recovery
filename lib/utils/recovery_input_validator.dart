import '../models/recovery_input.dart';

class RecoveryInputValidator {
  static ValidationResult validate(RecoveryInput input) {
    if (input.peakHr <= 0) {
      return const ValidationResult.invalid(
        'Please enter valid heart rate and subjective values.',
      );
    }

    if (input.rpe < 1 ||
        input.rpe > 10 ||
        input.feelingAfter < 1 ||
        input.feelingAfter > 10) {
      return const ValidationResult.invalid(
        'RPE and feeling after must be between 1 and 10.',
      );
    }

    if (input.hr60 >= input.peakHr || input.hr120 >= input.peakHr) {
      return const ValidationResult.invalid(
        'Recovery heart rates should be lower than peak HR.',
      );
    }

    if (input.hr120 > input.hr60) {
      return const ValidationResult.invalid(
        '120-second HR should usually be lower than 60-second HR.',
      );
    }

    return const ValidationResult.valid();
  }
}