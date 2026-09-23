import 'household_profile.dart';

enum RuleOperator {
  equals,
  greaterEqual,
  lessEqual,
  inList,
  booleanCheck,
}

enum RuleEvaluationState {
  satisfied,
  unmet,
  missingInformation,
}

class RuleEvaluationResult {
  final EligibilityRule rule;
  final RuleEvaluationState state;
  final String actualValueFormatted;
  final String explanationEn;
  final String explanationMl;

  const RuleEvaluationResult({
    required this.rule,
    required this.state,
    required this.actualValueFormatted,
    required this.explanationEn,
    required this.explanationMl,
  });
}

class EligibilityRule {
  final String field;
  final RuleOperator operator;
  final dynamic value;
  final String labelEn;
  final String labelMl;
  final String missingPromptEn;
  final String missingPromptMl;

  const EligibilityRule({
    required this.field,
    required this.operator,
    required this.value,
    required this.labelEn,
    required this.labelMl,
    required this.missingPromptEn,
    required this.missingPromptMl,
  });

  factory EligibilityRule.fromJson(Map<String, dynamic> json) {
    RuleOperator op;
    final opString = (json['operator'] as String? ?? '').toUpperCase();
    switch (opString) {
      case 'GREATER_EQUAL':
        op = RuleOperator.greaterEqual;
        break;
      case 'LESS_EQUAL':
        op = RuleOperator.lessEqual;
      case 'IN_LIST':
        op = RuleOperator.inList;
        break;
      case 'BOOLEAN':
        op = RuleOperator.booleanCheck;
        break;
      case 'EQUALS':
      default:
        op = RuleOperator.equals;
        break;
    }

    return EligibilityRule(
      field: json['field'] as String,
      operator: op,
      value: json['value'],
      labelEn: json['labelEn'] as String? ?? '',
      labelMl: json['labelMl'] as String? ?? '',
      missingPromptEn: json['missingPromptEn'] as String? ?? 'Missing information',
      missingPromptMl: json['missingPromptMl'] as String? ?? 'വിവരങ്ങൾ അപൂർണ്ണമാണ്',
    );
  }

  /// Pure deterministic evaluation of a single rule condition against the profile.
  RuleEvaluationResult evaluate(HouseholdProfile profile) {
    final actual = profile.getFieldValue(field);

    // If the required field is null/unanswered, mark as missingInformation
    if (actual == null) {
      return RuleEvaluationResult(
        rule: this,
        state: RuleEvaluationState.missingInformation,
        actualValueFormatted: 'Not provided',
        explanationEn: missingPromptEn,
        explanationMl: missingPromptMl,
      );
    }

    bool isSatisfied = false;
    switch (operator) {
      case RuleOperator.equals:
        isSatisfied = actual.toString().toLowerCase() == value.toString().toLowerCase();
        break;

      case RuleOperator.greaterEqual:
        if (actual is num && value is num) {
          isSatisfied = actual >= value;
        }
        break;

      case RuleOperator.lessEqual:
        if (actual is num && value is num) {
          isSatisfied = actual <= value;
        }
        break;

      case RuleOperator.inList:
        if (value is List) {
          final list = value.map((e) => e.toString().toLowerCase()).toList();
          isSatisfied = list.contains(actual.toString().toLowerCase());
        }
        break;

      case RuleOperator.booleanCheck:
        if (actual is bool && value is bool) {
          isSatisfied = actual == value;
        } else {
          isSatisfied = actual.toString().toLowerCase() == value.toString().toLowerCase();
        }
        break;
    }

    if (isSatisfied) {
      return RuleEvaluationResult(
        rule: this,
        state: RuleEvaluationState.satisfied,
        actualValueFormatted: actual.toString(),
        explanationEn: '✓ $labelEn (Provided: $actual)',
        explanationMl: '✓ $labelMl (നൽകിയത്: $actual)',
      );
    } else {
      return RuleEvaluationResult(
        rule: this,
        state: RuleEvaluationState.unmet,
        actualValueFormatted: actual.toString(),
        explanationEn: '✗ Requires: $labelEn (Provided: $actual)',
        explanationMl: '✗ ആവശ്യപ്പെടുന്നത്: $labelMl (നൽകിയത്: $actual)',
      );
    }
  }
}
