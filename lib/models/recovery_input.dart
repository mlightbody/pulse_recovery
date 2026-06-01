class RecoveryInput {
  final int peakHr;
  final int hr60;
  final int hr120;
  final int rpe;
  final int feelingAfter;
  final String? activityType;

  const RecoveryInput({
    required this.peakHr,
    required this.hr60,
    required this.hr120,
    required this.rpe,
    required this.feelingAfter,
    this.activityType,
  });
}

class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult._({
    required this.isValid,
    this.message,
  });

  const ValidationResult.valid() : this._(isValid: true);

  const ValidationResult.invalid(String message)
      : this._(
          isValid: false,
          message: message,
        );
}