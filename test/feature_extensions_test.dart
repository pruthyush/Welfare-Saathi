import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/engine/eligibility_engine.dart';
import 'package:welfare_saathi/models/household_profile.dart';
import 'package:welfare_saathi/models/scheme.dart';
import 'package:welfare_saathi/services/benefit_calculator_service.dart';
import 'package:welfare_saathi/services/localization_service.dart';
import 'package:welfare_saathi/services/qr_packet_service.dart';
import 'package:welfare_saathi/services/self_declaration_service.dart';

void main() {
  late List<Scheme> allSchemes;
  const engine = EligibilityEngine();

  setUpAll(() {
    final file = File('assets/data/schemes.json');
    final jsonString = file.readAsStringSync();
    final jsonList = json.decode(jsonString) as List<dynamic>;
    allSchemes = jsonList.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();
  });

  group('Benefit Calculator Service Tests', () {
    test('1. calculateSummary extracts monthly, annual & first year amounts from actual scheme results', () {
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

      final summary = BenefitCalculatorService.calculateSummary(results);
      expect(summary.eligibleCount, greaterThan(0));
      expect(summary.monthlyRecurring, greaterThan(0)); // Old age pension 1600
      expect(summary.totalFirstYearPotential, greaterThan(15000));
    });

    test('2. auditLeakage computes 3-year unclaimed retroactivity for unregistered profile', () {
      const profile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        monthlyIncome: 8000,
        isBoardMember: false,
        hasStudentChild: true,
      );

      final audit = BenefitCalculatorService.auditLeakage(profile);
      expect(audit, isNotNull);
      // Lean relief: 4500 * 3 = 13,500
      // Pension (age 62): 1600 * 12 * 3 = 57,600
      // Student aid: 5000 * 3 = 15,000
      // Total = 86,100
      expect(audit!.unclaimedAmount, 86100);
      expect(audit.yearsMissed, 3);
      expect(audit.missedItemsEn.length, 3);
      expect(audit.missedItemsMl.length, 3);
    });

    test('3. auditLeakage returns null for registered member with 3+ years tenure', () {
      const profile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        isBoardMember: true,
        yearsOfMembership: 5,
      );

      final audit = BenefitCalculatorService.auditLeakage(profile);
      expect(audit, isNull);
    });
  });

  group('QR Packet Service Tests', () {
    test('1. encodePacket generates clean Base64 string with WS: prefix and decodes correctly', () {
      const profile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        monthlyIncome: 8000,
        rationCardCategory: 'AAY',
        isBoardMember: true,
        yearsOfMembership: 4,
      );

      final qrData = QrPacketService.encodePacket(
        profile: profile,
        matchedSchemeIds: ['SCHEME-01', 'SCHEME-02'],
      );

      expect(qrData, startsWith('WS:'));

      final packet = QrPacketService.decodePacket(qrData);
      expect(packet, isNotNull);
      expect(packet!.profile.occupation, 'fishing');
      expect(packet.profile.district, 'Alappuzha');
      expect(packet.profile.age, 62);
      expect(packet.profile.monthlyIncome, 8000);
      expect(packet.profile.rationCardCategory, 'AAY');
      expect(packet.profile.isBoardMember, isTrue);
      expect(packet.profile.yearsOfMembership, 4);
      expect(packet.matchedSchemeIds, ['SCHEME-01', 'SCHEME-02']);
    });

    test('2. decodePacket handles invalid or malformed data gracefully', () {
      expect(QrPacketService.decodePacket(''), isNull);
      expect(QrPacketService.decodePacket('INVALID_STRING'), isNull);
      expect(QrPacketService.decodePacket('WS:invalid_base64!!!'), isNull);
    });
  });

  group('Self Declaration Affidavit Service Tests', () {
    test('1. generateAffidavitPdf returns valid PDF bytes', () async {
      final loc = LocalizationService();
      await loc.loadTranslations();

      const profile = HouseholdProfile(
        occupation: 'fishing',
        district: 'Kollam',
        age: 58,
        monthlyIncome: 7000,
        rationCardCategory: 'PHH',
        isBoardMember: true,
        yearsOfMembership: 3,
      );

      final pdfBytes = await SelfDeclarationService.generateAffidavitPdf(
        profile: profile,
        loc: loc,
      );

      expect(pdfBytes, isNotEmpty);
      // Valid PDF files start with %PDF- header
      final header = String.fromCharCodes(pdfBytes.take(5));
      expect(header, '%PDF-');
    });
  });
}
