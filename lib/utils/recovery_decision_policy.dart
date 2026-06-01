import '../models/recovery_decision.dart';
import '../models/recovery_signals.dart';

class RecoveryDecisionPolicy {
  static RecoveryDecision decide(RecoverySignals signals) {
    if (signals.highStrainSignal) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.recover,
        reasonTag: RecoveryReasonTag.highStrain,
      );
    }

    if (signals.hiddenLoadSignal) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.caution,
        reasonTag: RecoveryReasonTag.hiddenLoad,
      );
    }

    if (signals.fatigueMismatch) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.caution,
        reasonTag: RecoveryReasonTag.fatigueMismatch,
      );
    }

    if (signals.easySessionHandledWell) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.progress,
        reasonTag: RecoveryReasonTag.easySessionHandledWell,
      );
    }

    if (signals.strongRecoveryHandledWell) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.progress,
        reasonTag: RecoveryReasonTag.strongRecovery,
      );
    }

    if (signals.weakRecoverySignal) {
      return const RecoveryDecision(
        state: RecoveryDecisionState.caution,
        reasonTag: RecoveryReasonTag.weakRecovery,
      );
    }

    return const RecoveryDecision(
      state: RecoveryDecisionState.maintain,
      reasonTag: RecoveryReasonTag.normalResponse,
    );
  }
}