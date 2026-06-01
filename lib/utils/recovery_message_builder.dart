import '../models/recovery_decision.dart';

class RecoveryMessageBuilder {
  static String titleFor(RecoveryDecision decision) {
    switch (decision.state) {
      case RecoveryDecisionState.progress:
        return 'Ready to progress';
      case RecoveryDecisionState.maintain:
        return 'Maintain current level';
      case RecoveryDecisionState.caution:
        return 'Use caution';
      case RecoveryDecisionState.recover:
        return 'Prioritise recovery';
    }
  }

  static String summaryFor(RecoveryDecision decision) {
    switch (decision.reasonTag) {
      case RecoveryReasonTag.easySessionHandledWell:
        return 'This session looked comfortably manageable: the effort felt easy, you felt good afterwards, and your recovery was not poor.';

      case RecoveryReasonTag.strongRecovery:
        return 'Your heart-rate recovery was strong and your post-workout feeling was positive.';

      case RecoveryReasonTag.hiddenLoad:
        return 'You felt good, but your heart-rate recovery was slower than expected. This can sometimes reveal load before you notice it subjectively.';

      case RecoveryReasonTag.fatigueMismatch:
        return 'Your heart-rate recovery looked reasonable, but how you felt afterwards was low for a hard session.';

      case RecoveryReasonTag.highStrain:
        return 'Both your heart-rate recovery and how you felt afterwards suggest your body was under strain.';

      case RecoveryReasonTag.weakRecovery:
        return 'Your heart-rate recovery was weaker than expected, even if other signals were not clearly negative.';

      case RecoveryReasonTag.normalResponse:
        return 'Your recovery response is broadly in line with the session you completed.';
    }
  }

  static String recommendationFor(RecoveryDecision decision) {
    switch (decision.reasonTag) {
      case RecoveryReasonTag.easySessionHandledWell:
        return 'Consider a small progression next time: either a little longer, slightly harder, or slightly less rest. Change only one thing at a time.';

      case RecoveryReasonTag.strongRecovery:
        return 'You appear to be coping well. Consider a modest increase next time, but avoid increasing both intensity and duration together.';

      case RecoveryReasonTag.hiddenLoad:
        return 'Keep the next session controlled and watch whether this pattern repeats. If it does, treat it as an early caution signal.';

      case RecoveryReasonTag.fatigueMismatch:
        return 'Prioritise sleep, hydration, nutrition and an easier aerobic session before adding more intensity.';

      case RecoveryReasonTag.highStrain:
        return 'Avoid another hard session immediately. Choose rest, walking, mobility work, or a very easy recovery session.';

      case RecoveryReasonTag.weakRecovery:
        return 'Consider reducing intensity next time, extending your warm-down, or allowing more recovery before another hard session.';

      case RecoveryReasonTag.normalResponse:
        return 'Keep the next session similar and look for steady improvement over time.';
    }
  }
}