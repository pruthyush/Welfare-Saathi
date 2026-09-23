import 'eligibility_rule.dart';
import 'scheme.dart';

enum EligibilityStatus {
  potentiallyEligible,
  moreInformationRequired,
  notMatched,
}

class EligibilityResult {
  final Scheme scheme;
  final EligibilityStatus status;
  final List<RuleEvaluationResult> matchedRules;
  final List<RuleEvaluationResult> unmetRules;
  final List<RuleEvaluationResult> missingRules;

  const EligibilityResult({
    required this.scheme,
    required this.status,
    required this.matchedRules,
    required this.unmetRules,
    required this.missingRules,
  });

  bool get isPotentiallyEligible => status == EligibilityStatus.potentiallyEligible;
  bool get isMoreInformationRequired => status == EligibilityStatus.moreInformationRequired;
  bool get isNotMatched => status == EligibilityStatus.notMatched;

  String getStatusLabel(bool isMalayalam) {
    switch (status) {
      case EligibilityStatus.potentiallyEligible:
        return isMalayalam ? 'ലഭിക്കാൻ സാധ്യതയുണ്ട് (Potentially Eligible)' : 'Potentially Eligible';
      case EligibilityStatus.moreInformationRequired:
        return isMalayalam ? 'കൂടുതൽ വിവരങ്ങൾ ആവശ്യമാണ്' : 'More Information Needed';
      case EligibilityStatus.notMatched:
        return isMalayalam ? 'നിബന്ധനകൾ പൂർണ്ണമല്ല' : 'Criteria Not Met';
    }
  }

  List<String> getWhyMatchedExplanations(bool isMalayalam) {
    return matchedRules
        .map((r) => isMalayalam ? r.explanationMl : r.explanationEn)
        .toList();
  }

  List<String> getMissingPrompts(bool isMalayalam) {
    return missingRules
        .map((r) => isMalayalam ? r.explanationMl : r.explanationEn)
        .toList();
  }

  List<String> getUnmetReasons(bool isMalayalam) {
    return unmetRules
        .map((r) => isMalayalam ? r.explanationMl : r.explanationEn)
        .toList();
  }
}
