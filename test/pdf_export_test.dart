import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/models/household_profile.dart';
import 'package:welfare_saathi/models/scheme.dart';
import 'package:welfare_saathi/models/eligibility_rule.dart';
import 'package:welfare_saathi/models/eligibility_result.dart';
import 'package:welfare_saathi/services/pdf_export_service.dart';
import 'package:welfare_saathi/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalizationService loc;
  late Scheme dummyScheme1;
  late Scheme dummyScheme2;

  setUpAll(() async {
    loc = LocalizationService();
    loc.initWithMaps(
      enStrings: {
        'appTitle': 'Welfare Saathi',
        'potentiallyEligible': 'Potentially Eligible',
        'moreInfoNeeded': 'More Information Needed',
        'notEligible': 'Not Eligible',
        'disclaimer': 'This tool is an entitlement screener. Final determination is by the competent authority.',
        'safetyAlerts': 'Community Safety Alerts',
        'exportAkshayaPdf': 'Export Akshaya Report (PDF)',
      },
      mlStrings: {
        'appTitle': 'ക്ഷേമ സാഥി',
        'potentiallyEligible': 'സാധ്യതയുള്ളത്',
        'moreInfoNeeded': 'കൂടുതൽ വിവരങ്ങൾ ആവശ്യമാണ്',
        'notEligible': 'അർഹമല്ല',
        'disclaimer': 'ഇതൊരു പ്രാഥമിക പരിശോധന മാത്രമാണ്. അന്തിമ തീരുമാനം ബന്ധപ്പെട്ട അതോറിറ്റിയുടേതാണ്.',
        'safetyAlerts': 'സുരക്ഷാ മുന്നറിയിപ്പുകൾ',
        'exportAkshayaPdf': 'അക്ഷയ റിപ്പോർട്ട് ഡൗൺലോഡ് ചെയ്യുക (PDF)',
      },
    );

    dummyScheme1 = const Scheme(
      id: "KBWWB-PENSION-01",
      nameEn: "Old Age Pension Scheme (Fishermen Welfare Board)",
      nameMl: "വാർദ്ധക്യകാല പെൻഷൻ പദ്ധതി",
      departmentEn: "Kerala Fishermen's Welfare Fund Board (Matsyaboard)",
      departmentMl: "കേരള മത്സ്യത്തൊഴിലാളി ക്ഷേമനിധി ബോർഡ് (മത്സ്യബോർഡ്)",
      category: "fishing",
      descriptionEn: "Monthly pension for registered senior fisherfolk aged 60 and above.",
      descriptionMl: "60 വയസ്സ് തികഞ്ഞ രജിസ്റ്റർ ചെയ്ത മത്സ്യത്തൊഴിലാളികൾക്കുള്ള പ്രതിമാസ പെൻഷൻ.",
      rules: [],
      requiredDocumentsEn: [
        "Matsyaboard Membership Passbook",
        "Aadhaar Card",
        "Bank Passbook linked with Aadhaar",
      ],
      requiredDocumentsMl: [
        "മത്സ്യബോർഡ് അംഗത്വ പാസ്ബുക്ക്",
        "ആധാർ കാർഡ്",
        "ബാങ്ക് പാസ്ബുക്ക്",
      ],
      applicationChannelsEn: ["Matsyaboard Fisheries Office or Akshaya Centre"],
      applicationChannelsMl: ["മത്സ്യബോർഡ് ഓഫീസ് അല്ലെങ്കിൽ അക്ഷയ കേന്ദ്രം"],
      nextStepsEn: ["Submit physical verification documents at the regional Matsyaboard office."],
      nextStepsMl: ["മേഖലാ മത്സ്യബോർഡ് ഓഫീസിൽ രേഖകൾ ഹാജരാക്കുക."],
      sourceOfficial: "Kerala Fishermen Welfare Fund Board Act & Rules",
      disclaimer: "Subject to verification of subscription records.",
      officialUrl: "https://matsyaboard.kerala.gov.in",
    );

    dummyScheme2 = const Scheme(
      id: "PLANT-SCHOLAR-01",
      nameEn: "Higher Education Scholarship for Plantation Labor Wards",
      nameMl: "തോട്ടം തൊഴിലാളി മക്കൾക്കുള്ള ഉന്നത വിദ്യാഭ്യാസ സ്കോളർഷിപ്പ്",
      departmentEn: "Plantation Workers Welfare Board",
      departmentMl: "തോട്ടം തൊഴിലാളി ക്ഷേമനിധി ബോർഡ്",
      category: "plantation",
      descriptionEn: "Educational scholarship grant for children of registered plantation workers.",
      descriptionMl: "രജിസ്റ്റർ ചെയ്ത തോട്ടം തൊഴിലാളികളുടെ മക്കൾക്കുള്ള വിദ്യാഭ്യാസ സഹായം.",
      rules: [],
      requiredDocumentsEn: [
        "Board Membership Card",
        "College Admission & Fee Receipt",
        "Ration Card copy",
      ],
      requiredDocumentsMl: [
        "ബോർഡ് അംഗത്വ കാർഡ്",
        "കോളേജ് പ്രവേശന രസീത്",
        "റേഷൻ കാർഡ് കോപ്പി",
      ],
      applicationChannelsEn: ["Chief Inspector of Plantations or Akshaya e-Centre"],
      applicationChannelsMl: ["ചീഫ് ഇൻസ്പെക്ടർ ഓഫ് പ്ലാന്റേഷൻസ് ഓഫീസ് അല്ലെങ്കിൽ അക്ഷയ കേന്ദ്രം"],
      nextStepsEn: ["Submit application with college principal certification."],
      nextStepsMl: ["പ്രിൻസിപ്പലിന്റെ സാക്ഷ്യപത്രത്തോടൊപ്പം അപേക്ഷ സമർപ്പിക്കുക."],
      sourceOfficial: "Kerala Plantation Workers Welfare Fund Rules",
      disclaimer: "Subject to budget allocation.",
      officialUrl: "https://lc.kerala.gov.in",
    );
  });

  group('PDF Export Service Tests', () {
    test('1. Generates PDF with Potentially Eligible schemes', () async {
      final profile = const HouseholdProfile(
        occupation: 'fishing',
        district: 'Alappuzha',
        age: 62,
        yearsOfMembership: 8,
        isBoardMember: true,
      );

      final rule1 = const EligibilityRule(
        field: 'age',
        operator: RuleOperator.greaterEqual,
        value: 60,
        labelEn: 'Age >= 60',
        labelMl: 'പ്രായം 60 അല്ലെങ്കിൽ അതിൽ കൂടുതൽ',
        missingPromptEn: 'Please enter age',
        missingPromptMl: 'ദയവായി പ്രായം രേഖപ്പെടുത്തുക',
      );

      final matchedRuleEval = RuleEvaluationResult(
        rule: rule1,
        state: RuleEvaluationState.satisfied,
        actualValueFormatted: '62',
        explanationEn: 'Age is 62 (minimum requirement is 60)',
        explanationMl: 'പ്രായം 62 ആണ് (ആവശ്യമായ കുറഞ്ഞ പ്രായം 60)',
      );

      final result1 = EligibilityResult(
        scheme: dummyScheme1,
        status: EligibilityStatus.potentiallyEligible,
        matchedRules: [matchedRuleEval],
        unmetRules: [],
        missingRules: [],
      );

      final pdfBytes = await PdfExportService.generateScreeningReport(
        profile: profile,
        results: [result1],
        loc: loc,
        includeHouseholdDetails: true,
        includePotentiallyEligible: true,
        includeMoreInfoNeeded: true,
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF begins with %PDF- header magic bytes
      final header = ascii.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
      expect(pdfBytes.length, greaterThan(2000));
    });

    test('2. PDF contains mandatory legal disclaimer and strictly never says "You are eligible"', () {
      final disclaimer = PdfExportService.legalDisclaimer;

      // Verify exact regulatory disclaimer required by PS-07 specification
      expect(
        disclaimer.contains('This document is a screening summary based on the information provided by the applicant and the scheme rules available in Welfare Saathi.'),
        isTrue,
        reason: 'Mandatory disclaimer opening line must match specification',
      );
      expect(
        disclaimer.contains('It does not guarantee eligibility or approval.'),
        isTrue,
        reason: 'Must state non-guarantee explicitly',
      );
      expect(
        disclaimer.contains('Final verification and approval are performed by the relevant authority.'),
        isTrue,
        reason: 'Must state final authority determination',
      );

      // Verify that "You are eligible" is strictly absent
      expect(
        disclaimer.toLowerCase().contains('you are eligible'),
        isFalse,
        reason: 'Strict rule: Disclaimers and labels must never state "You are eligible"',
      );

      // Verify Potentially Eligible is used
      expect(
        disclaimer.contains('Potentially Eligible'),
        isTrue,
      );
    });

    test('3. Generates PDF with More Information Needed schemes without error', () async {
      final profile = const HouseholdProfile(
        occupation: 'plantation',
        district: 'Idukki',
      );

      final ruleMissing = const EligibilityRule(
        field: 'isBoardMember',
        operator: RuleOperator.booleanCheck,
        value: true,
        labelEn: 'Plantation Welfare Board Member',
        labelMl: 'തോട്ടം തൊഴിലാളി ക്ഷേമനിധി ബോർഡ് അംഗം',
        missingPromptEn: 'Board membership not specified',
        missingPromptMl: 'ബോർഡ് അംഗത്വം വ്യക്തമാക്കിയിട്ടില്ല',
      );

      final missingRuleEval = RuleEvaluationResult(
        rule: ruleMissing,
        state: RuleEvaluationState.missingInformation,
        actualValueFormatted: 'Not answered',
        explanationEn: 'Board membership is required to confirm eligibility.',
        explanationMl: 'അർഹത സ്ഥിരീകരിക്കുന്നതിന് ബോർഡ് അംഗത്വം ആവശ്യമാണ്.',
      );

      final result = EligibilityResult(
        scheme: dummyScheme2,
        status: EligibilityStatus.moreInformationRequired,
        matchedRules: [],
        unmetRules: [],
        missingRules: [missingRuleEval],
      );

      final bytes = await PdfExportService.generateScreeningReport(
        profile: profile,
        results: [result],
        loc: loc,
        includeHouseholdDetails: true,
        includePotentiallyEligible: true,
        includeMoreInfoNeeded: true,
      );

      expect(bytes.isNotEmpty, isTrue);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
      expect(bytes.length, greaterThan(1500));
    });

    test('4. Generates PDF cleanly even with empty/no-result list', () async {
      final profile = const HouseholdProfile(occupation: 'fishing', district: 'Kollam');

      final bytes = await PdfExportService.generateScreeningReport(
        profile: profile,
        results: [],
        loc: loc,
        includeHouseholdDetails: true,
        includePotentiallyEligible: true,
        includeMoreInfoNeeded: true,
      );

      expect(bytes.isNotEmpty, isTrue);
      final header = ascii.decode(bytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
      expect(bytes.length, greaterThan(1000));
    });
  });
}
