import '../models/eligibility_result.dart';
import '../models/eligibility_rule.dart';
import '../models/household_profile.dart';
import '../models/scheme.dart';

/// Reusable, 100% deterministic rule engine that evaluates welfare schemes
/// against a household profile.
///
/// Strictly operates without any external AI/LLM models, guaranteeing
/// complete auditability, explainability, and reproducibility.
class EligibilityEngine {
  const EligibilityEngine();

  /// Evaluates a single scheme deterministically.
  EligibilityResult evaluateScheme(Scheme scheme, HouseholdProfile profile) {
    final matchedRules = <RuleEvaluationResult>[];
    final unmetRules = <RuleEvaluationResult>[];
    final missingRules = <RuleEvaluationResult>[];

    for (final rule in scheme.rules) {
      final evaluation = rule.evaluate(profile);

      switch (evaluation.state) {
        case RuleEvaluationState.satisfied:
          matchedRules.add(evaluation);
          break;
        case RuleEvaluationState.unmet:
          unmetRules.add(evaluation);
          break;
        case RuleEvaluationState.missingInformation:
          missingRules.add(evaluation);
          break;
      }
    }

    // Deterministic status determination:
    // 1. If any requirement is explicitly unmet/disqualified, the household cannot match.
    // 2. If no requirement is unmet, but one or more required fields are unanswered/missing,
    //    we NEVER assume the answer; we strictly flag "moreInformationRequired".
    // 3. Only if ALL requirements are satisfied does the scheme qualify as "potentiallyEligible".
    EligibilityStatus status;
    if (unmetRules.isNotEmpty) {
      status = EligibilityStatus.notMatched;
    } else if (missingRules.isNotEmpty) {
      status = EligibilityStatus.moreInformationRequired;
    } else {
      status = EligibilityStatus.potentiallyEligible;
    }

    return EligibilityResult(
      scheme: scheme,
      status: status,
      matchedRules: matchedRules,
      unmetRules: unmetRules,
      missingRules: missingRules,
    );
  }

  /// Evaluates all provided schemes against the household profile.
  List<EligibilityResult> evaluateAll({
    required List<Scheme> schemes,
    required HouseholdProfile profile,
  }) {
    return schemes.map((s) => evaluateScheme(s, profile)).toList();
  }

  /// Filters for schemes where the household meets all verified criteria.
  List<EligibilityResult> getPotentiallyEligible(List<EligibilityResult> results) {
    return results.where((r) => r.isPotentiallyEligible).toList();
  }

  /// Filters for schemes where missing data prevents final determination.
  List<EligibilityResult> getMoreInformationRequired(List<EligibilityResult> results) {
    return results.where((r) => r.isMoreInformationRequired).toList();
  }

  /// Filters for schemes where criteria are not met.
  List<EligibilityResult> getNotMatched(List<EligibilityResult> results) {
    return results.where((r) => r.isNotMatched).toList();
  }
}
