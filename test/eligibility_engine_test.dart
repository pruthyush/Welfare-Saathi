import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/engine/eligibility_engine.dart';
import 'package:welfare_saathi/models/eligibility_result.dart';
import 'package:welfare_saathi/models/household_profile.dart';
import 'package:welfare_saathi/models/scheme.dart';

void main() {
  late List<Scheme> allSchemes;
  const engine = EligibilityEngine();

  setUpAll(() {
    // Load schemes directly from JSON file for standalone unit testing
    final file = File('assets/data/schemes.json');
    final jsonString = file.readAsStringSync();
    final jsonList = json.decode(jsonString) as List<dynamic>;
    allSchemes = jsonList.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();
  });

  group('Deterministic Eligibility Engine Tests', () {
    test('1. Verified dataset contains at least 10 schemes (Current: 16 verified schemes)', () {
      expect(allSchemes.length, equals(16));
    });

    test('2. Potentially eligible household matches expected scheme', () {
      // Senior fisherman profile
      const seniorFisherman = HouseholdProfile(
        occupation: 'fishing',
        age: 62,
        district: 'Ernakulam',
        monthlyIncome: 7500,
        isBoardMember: true,
        yearsOfMembership: 10,
        rationCardCategory: 'PHH',
        housingCondition: 'kutcha',
        hasStudentChild: false,
        specialStatus: 'none',
      );

      final results = engine.evaluateAll(
        schemes: allSchemes,
        profile: seniorFisherman,
      );

      final eligible = engine.getPotentiallyEligible(results);
      final eligibleIds = eligible.map((r) => r.scheme.id).toList();

      // SCHEME-01 is Matsyathozhilali Old Age Pension
      expect(eligibleIds, contains('SCHEME-01'));
      // SCHEME-02 is Lean Period / Monsoon Relief
      expect(eligibleIds, contains('SCHEME-02'));
      // SCHEME-05 is Group Accident Insurance
      expect(eligibleIds, contains('SCHEME-05'));
    });

    test('3. Not matched household (criteria unmet) is correctly disqualified', () {
      // General worker with high income and no board registration
      const generalWorker = HouseholdProfile(
        occupation: 'other',
        age: 35,
        district: 'Ernakulam',
        monthlyIncome: 45000,
        isBoardMember: false,
        yearsOfMembership: 0,
        rationCardCategory: 'Non-Priority',
        housingCondition: 'pucca',
        hasStudentChild: false,
        specialStatus: 'none',
      );

      final results = engine.evaluateAll(
        schemes: allSchemes,
        profile: generalWorker,
      );

      final eligible = engine.getPotentiallyEligible(results);
      // No scheme should qualify
      expect(eligible, isEmpty);

      final notMatched = engine.getNotMatched(results);
      expect(notMatched.length, equals(allSchemes.length));
    });

    test('4. Missing information triggers moreInformationRequired status without assuming answers', () {
      // Fisherman with age 62 and board registration, but skipped income
      const incompleteProfile = HouseholdProfile(
        occupation: 'fishing',
        age: 62,
        district: 'Alappuzha',
        monthlyIncome: null, // SKIPPED
        isBoardMember: true,
        yearsOfMembership: 10,
        rationCardCategory: 'PHH',
        housingCondition: null, // SKIPPED
      );

      final results = engine.evaluateAll(
        schemes: allSchemes,
        profile: incompleteProfile,
      );

      final incompleteResults = engine.getMoreInformationRequired(results);
      final incompleteIds = incompleteResults.map((r) => r.scheme.id).toList();

      // SCHEME-01 requires monthly income (< ₹8,333). Since it was skipped, it must require more info!
      expect(incompleteIds, contains('SCHEME-01'));

      final pensionResult = incompleteResults.firstWhere((r) => r.scheme.id == 'SCHEME-01');
      expect(pensionResult.status, equals(EligibilityStatus.moreInformationRequired));
      expect(pensionResult.missingRules.isNotEmpty, isTrue);
      expect(pensionResult.missingRules.first.rule.field, equals('monthlyIncome'));
    });

    test('5. Correcting an answer recalculates from incomplete to potentially eligible', () {
      // Step A: Initially incomplete (missing income)
      var profile = const HouseholdProfile(
        occupation: 'fishing',
        age: 65,
        district: 'Kochi',
        monthlyIncome: null,
        isBoardMember: true,
        yearsOfMembership: 8,
      );

      final initialResults = engine.evaluateAll(schemes: allSchemes, profile: profile);
      final initialPension = initialResults.firstWhere((r) => r.scheme.id == 'SCHEME-01');
      expect(initialPension.status, equals(EligibilityStatus.moreInformationRequired));

      // Step B: User edits and provides income = ₹7,000
      profile = profile.copyWith(monthlyIncome: 7000);
      final updatedResults = engine.evaluateAll(schemes: allSchemes, profile: profile);
      final updatedPension = updatedResults.firstWhere((r) => r.scheme.id == 'SCHEME-01');

      expect(updatedPension.status, equals(EligibilityStatus.potentiallyEligible));
      expect(updatedPension.isPotentiallyEligible, isTrue);
    });

    test('6. Boundary conditions in supplied rules evaluate with exact precision', () {
      // Pension age rule: Age >= 60
      // Exactly age 59 -> Unmet
      const profile59 = HouseholdProfile(
        occupation: 'fishing',
        age: 59,
        monthlyIncome: 6000,
        isBoardMember: true,
        yearsOfMembership: 6,
      );
      final res59 = engine.evaluateScheme(allSchemes.firstWhere((s) => s.id == 'SCHEME-01'), profile59);
      expect(res59.status, equals(EligibilityStatus.notMatched));

      // Exactly age 60 -> Satisfied
      const profile60 = HouseholdProfile(
        occupation: 'fishing',
        age: 60,
        monthlyIncome: 6000,
        isBoardMember: true,
        yearsOfMembership: 6,
      );
      final res60 = engine.evaluateScheme(allSchemes.firstWhere((s) => s.id == 'SCHEME-01'), profile60);
      expect(res60.status, equals(EligibilityStatus.potentiallyEligible));

      // Income limit rule: Monthly income <= 8333
      // Exactly ₹8,333 -> Satisfied
      const profileExactIncome = HouseholdProfile(
        occupation: 'fishing',
        age: 60,
        monthlyIncome: 8333,
        isBoardMember: true,
        yearsOfMembership: 6,
      );
      final resIncomeOk = engine.evaluateScheme(allSchemes.firstWhere((s) => s.id == 'SCHEME-01'), profileExactIncome);
      expect(resIncomeOk.status, equals(EligibilityStatus.potentiallyEligible));

      // ₹8,334 -> Unmet
      const profileExcessIncome = HouseholdProfile(
        occupation: 'fishing',
        age: 60,
        monthlyIncome: 8334,
        isBoardMember: true,
        yearsOfMembership: 6,
      );
      final resIncomeFail = engine.evaluateScheme(allSchemes.firstWhere((s) => s.id == 'SCHEME-01'), profileExcessIncome);
      expect(resIncomeFail.status, equals(EligibilityStatus.notMatched));
    });

    test('7. Strict compliance: Status label says "Potentially Eligible", NEVER "You are eligible"', () {
      const sample = HouseholdProfile(
        occupation: 'fishing',
        age: 61,
        monthlyIncome: 5000,
        isBoardMember: true,
        yearsOfMembership: 8,
      );

      final res = engine.evaluateScheme(allSchemes.firstWhere((s) => s.id == 'SCHEME-01'), sample);
      final englishLabel = res.getStatusLabel(false);
      final malayalamLabel = res.getStatusLabel(true);

      // Must state "Potentially Eligible"
      expect(englishLabel, equals('Potentially Eligible'));
      expect(malayalamLabel, contains('Potentially Eligible'));

      // Strict prohibition: NEVER "You are eligible"
      expect(englishLabel.toLowerCase(), isNot(contains('you are eligible')));
      expect(malayalamLabel.toLowerCase(), isNot(contains('you are eligible')));
    });

    test('8. Plantation schemes correctly identify plantation laborers and scholarship dependents', () {
      const plantationFamily = HouseholdProfile(
        occupation: 'plantation',
        age: 44,
        district: 'Idukki',
        monthlyIncome: 9000,
        isBoardMember: true,
        yearsOfMembership: 5,
        housingCondition: 'dilapidated',
        hasStudentChild: true,
      );

      final results = engine.evaluateAll(schemes: allSchemes, profile: plantationFamily);
      final eligible = engine.getPotentiallyEligible(results);
      final eligibleIds = eligible.map((r) => r.scheme.id).toList();

      // SCHEME-06: Housing Renovation
      expect(eligibleIds, contains('SCHEME-06'));
      // SCHEME-07: Merit Scholarship for children
      expect(eligibleIds, contains('SCHEME-07'));
      // SCHEME-08: Medical Assistance
      expect(eligibleIds, contains('SCHEME-08'));

      // Fishing schemes should NOT match
      expect(eligibleIds, isNot(contains('SCHEME-01')));
    });
  });
}
