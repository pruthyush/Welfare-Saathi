import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/controllers/screening_controller.dart';
import 'package:welfare_saathi/models/household_profile.dart';
import 'package:welfare_saathi/models/scheme.dart';
import 'package:welfare_saathi/services/scheme_repository.dart';

void main() {
  late List<Scheme> schemes;
  late List<SampleProfileItem> sampleProfiles;

  setUpAll(() {
    final schemesRaw = File('assets/data/schemes.json').readAsStringSync();
    final schemesList = json.decode(schemesRaw) as List<dynamic>;
    schemes = schemesList.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();

    sampleProfiles = [
      SampleProfileItem(
        id: 'fisherfolk_elder',
        titleEn: 'Elderly Traditional Fisherman (Age 62)',
        titleMl: 'പ്രായമായ പരമ്പരാഗത മത്സ്യത്തൊഴിലാളി (62 വയസ്സ്)',
        descriptionEn: 'Alappuzha, 32 yrs board member, dilapidated housing',
        descriptionMl: 'ആലപ്പുഴ, 32 വർഷത്തെ ബോർഡ് അംഗം, ജീർണ്ണിച്ച വീട്',
        profile: const HouseholdProfile(
          occupation: 'fishing',
          age: 62,
          district: 'Alappuzha',
          monthlyIncome: 4500,
          isBoardMember: true,
          yearsOfMembership: 32,
          rationCardCategory: 'BPL',
          housingCondition: 'dilapidated',
          hasStudentChild: false,
          specialStatus: 'none',
        ),
        expectedPotentialSchemeIds: ['kerala_matsya_oldage_pension'],
      ),
    ];
  });

  group('Fresh Screening & Null Value Preservation Tests', () {
    test('Test 1: Start a new screening -> Profile demographic fields remain empty/null', () {
      final profile = HouseholdProfile.empty();
      expect(profile.age, isNull, reason: 'Age must start null');
      expect(profile.yearsOfMembership, isNull, reason: 'Years of membership must start null');
      expect(profile.isBoardMember, isNull, reason: 'Board membership must start null');
      expect(profile.housingCondition, isNull, reason: 'Housing condition must start null');
      expect(profile.monthlyIncome, isNull, reason: 'Monthly income must start null');
      expect(profile.occupation, isNull, reason: 'Occupation must start null');
      expect(profile.district, isNull, reason: 'District must start null');
      expect(profile.rationCardCategory, isNull, reason: 'Ration card category must start null');
      expect(profile.hasStudentChild, isNull, reason: 'hasStudentChild must start null');
    });

    test('Test 2: Do not answer board membership -> Board membership remains unanswered/null', () {
      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);
      final controller = ScreeningController(repository: repository);

      controller.reset();
      expect(controller.profile.isBoardMember, isNull);

      // Verify that evaluating an unanswered profile does not guess board membership
      controller.evaluateCurrentProfile();
      expect(controller.profile.isBoardMember, isNull);
    });

    test('Test 3: Skip income -> Income = null. Eligibility engine returns More Information Needed where income is required', () {
      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);
      final controller = ScreeningController(repository: repository);

      controller.reset();
      controller.updateProfile(controller.profile.copyWith(
        occupation: 'fishing',
        age: 62,
        district: 'Alappuzha',
        isBoardMember: true,
        yearsOfMembership: 30,
        // income intentionally omitted / null
        clearMonthlyIncome: true,
      ));

      expect(controller.profile.monthlyIncome, isNull);
      controller.evaluateCurrentProfile();

      // Check for any scheme requiring income criteria
      final needsInfo = controller.results.where((r) => r.isMoreInformationRequired).toList();
      expect(needsInfo, isNotEmpty, reason: 'Schemes with missing criteria must produce More Information Needed');
      for (final r in needsInfo) {
        expect(r.missingRules, isNotEmpty);
      }
    });

    test('Test 4: Enter age = 62 -> Age is updated to 62', () {
      final profile = HouseholdProfile.empty().copyWith(age: 62);
      expect(profile.age, equals(62));
    });

    test('Test 5: Enter age = 62, then clear it -> Age returns to null/empty, NOT 58 or any default', () {
      final profileWithAge = HouseholdProfile.empty().copyWith(age: 62);
      expect(profileWithAge.age, equals(62));

      // Clearing age using copyWith(clearAge: true)
      final clearedProfile = profileWithAge.copyWith(clearAge: true);
      expect(clearedProfile.age, isNull);
      expect(clearedProfile.age, isNot(equals(58)));

      // Also verify years of membership
      final profileWithYears = profileWithAge.copyWith(yearsOfMembership: 6);
      final clearedYears = profileWithYears.copyWith(clearYearsOfMembership: true);
      expect(clearedYears.yearsOfMembership, isNull);
      expect(clearedYears.yearsOfMembership, isNot(equals(6)));

      // Also verify board membership
      final profileWithBoard = profileWithAge.copyWith(isBoardMember: true);
      final clearedBoard = profileWithBoard.copyWith(clearIsBoardMember: true);
      expect(clearedBoard.isBoardMember, isNull);
      expect(clearedBoard.isBoardMember, isNot(isTrue));

      // Also verify housing condition
      final profileWithHousing = profileWithAge.copyWith(housingCondition: 'dilapidated');
      final clearedHousing = profileWithHousing.copyWith(clearHousingCondition: true);
      expect(clearedHousing.housingCondition, isNull);
      expect(clearedHousing.housingCondition, isNot(equals('dilapidated')));
    });

    test('Test 6: Load a benchmark profile -> Benchmark profile still loads intentional values correctly', () {
      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes, sampleProfiles: sampleProfiles);
      final controller = ScreeningController(repository: repository);

      controller.loadSampleProfile(sampleProfiles.first);

      expect(controller.profile.occupation, equals('fishing'));
      expect(controller.profile.age, equals(62));
      expect(controller.profile.district, equals('Alappuzha'));
      expect(controller.profile.monthlyIncome, equals(4500));
      expect(controller.profile.isBoardMember, isTrue);
      expect(controller.profile.yearsOfMembership, equals(32));
      expect(controller.profile.housingCondition, equals('dilapidated'));
      expect(controller.hasRunScreening, isTrue);
      expect(controller.results, isNotEmpty);
    });
  });
}
