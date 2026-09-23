import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/controllers/alert_controller.dart';
import 'package:welfare_saathi/controllers/screening_controller.dart';
import 'package:welfare_saathi/main.dart';
import 'package:welfare_saathi/models/scheme.dart';
import 'package:welfare_saathi/services/alert_repository.dart';
import 'package:welfare_saathi/services/localization_service.dart';
import 'package:welfare_saathi/services/scheme_repository.dart';

void main() {
  late List<Scheme> schemes;
  late Map<String, String> enMap;
  late Map<String, String> mlMap;

  setUpAll(() {
    final schemesRaw = File('assets/data/schemes.json').readAsStringSync();
    final schemesList = json.decode(schemesRaw) as List<dynamic>;
    schemes = schemesList.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();

    final terminologyRaw = File('assets/data/terminology.json').readAsStringSync();
    final termData = json.decode(terminologyRaw) as Map<String, dynamic>;
    enMap = (termData['en'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
    mlMap = (termData['ml'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
  });

  Widget buildTestWidget({
    required SchemeRepository repo,
    required LocalizationService loc,
    required ScreeningController controller,
    AlertController? alertCtrl,
  }) {
    return MaterialApp(
      locale: Locale(loc.currentLanguage),
      home: WelfareSaathiApp(
        repository: repo,
        loc: loc,
        controller: controller,
        alertController: alertCtrl,
      ),
    );
  }

  group('Homepage Redesign Verification Tests', () {
    testWidgets('1. Desktop layout (1280x900): renders top nav, hero, disclaimer, quick access, and sample profiles', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = SchemeRepository();
      repo.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repo);
      final alertCtrl = AlertController(repository: AlertRepository());

      await tester.pumpWidget(buildTestWidget(
        repo: repo,
        loc: loc,
        controller: controller,
        alertCtrl: alertCtrl,
      ));
      await tester.pumpAndSettle();

      // Top Navigation
      expect(find.text('Welfare Saathi'), findsWidgets);
      expect(find.text('Kerala Social Security Discovery Portal'), findsWidgets);
      expect(find.text('Handbook'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);

      // Hero Section (Left & Right)
      expect(find.text('Plantation & Fisherfolk Welfare Assistant'), findsOneWidget);
      expect(find.text('Find welfare schemes that your household may potentially qualify for.'), findsOneWidget);
      expect(find.text('16 Scheme Definitions'), findsWidgets);
      expect(find.text('Deterministic Rule Evaluation'), findsOneWidget);
      expect(find.text('Privacy-Conscious Screening'), findsOneWidget);
      expect(find.text('Check Your Household'), findsOneWidget);
      expect(find.textContaining('Start Screening'), findsOneWidget);

      // Disclaimer Section
      expect(find.text('Potential Eligibility Only'), findsOneWidget);
      expect(find.textContaining('Final eligibility is determined by the relevant authority'), findsOneWidget);
      expect(find.text('You are eligible'), findsNothing);

      // Quick Access Hub Cards
      expect(find.text('Quick Access Hub'), findsOneWidget);
      expect(find.text('Browse Welfare Schemes'), findsOneWidget);
      expect(find.text('Community Safety Alerts'), findsOneWidget);
      expect(find.text('DEMO'), findsOneWidget);
      expect(find.text('Prepare Akshaya Report'), findsOneWidget);
      expect(find.text('My Household Profile'), findsOneWidget);

      // Sample Profiles Section
      expect(find.text('Try a Sample Profile'), findsOneWidget);
      expect(find.textContaining('Explore how Welfare Saathi evaluates different household situations'), findsOneWidget);
    });

    testWidgets('2. Mobile layout (390x844): compact top nav, vertically stacked hero, no back button', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = SchemeRepository();
      repo.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repo);

      await tester.pumpWidget(buildTestWidget(
        repo: repo,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Top Navigation
      expect(find.text('Welfare Saathi'), findsWidgets);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);

      // Mobile Start Screening button visible
      expect(find.textContaining('Start Screening'), findsOneWidget);
    });

    testWidgets('3. Malayalam Locale: verifies bilingual support across all sections', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = SchemeRepository();
      repo.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'ml');

      final controller = ScreeningController(repository: repo);

      await tester.pumpWidget(buildTestWidget(
        repo: repo,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Top Navigation
      expect(find.textContaining('വെൽഫെയർ സാഥി'), findsWidgets);
      expect(find.text('കേരള സാമൂഹിക സുരക്ഷാ പോർട്ടൽ'), findsWidgets);

      // Hero Malayalam
      expect(find.text('തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി'), findsOneWidget);
      expect(find.text('നിങ്ങളുടെ കുടുംബത്തിന് അർഹതയുണ്ടാകാൻ സാധ്യതയുള്ള ക്ഷേമപദ്ധതികൾ കണ്ടെത്തുക.'), findsOneWidget);
      expect(find.textContaining('സ്ക്രീനിംഗ് ആരംഭിക്കുക'), findsOneWidget);

      // Disclaimer Malayalam
      expect(find.textContaining('സാധ്യതയുള്ള അർഹത മാത്രം'), findsOneWidget);
      expect(find.textContaining('അന്തിമ അർഹത ബന്ധപ്പെട്ട സർക്കാർ ഉദ്യോഗസ്ഥർ നിശ്ചയിക്കുന്നതാണ്'), findsOneWidget);

      // Hub Malayalam
      expect(find.text('പ്രധാന സേവനങ്ങൾ'), findsOneWidget);
      expect(find.text('പദ്ധതി വിവരങ്ങൾ'), findsWidgets);
      expect(find.text('സുരക്ഷാ മുന്നറിയിപ്പുകൾ'), findsOneWidget);

      // Sample Profiles Malayalam
      expect(find.text('സാമ്പിൾ പ്രൊഫൈലുകൾ പരീക്ഷിക്കുക'), findsOneWidget);
    });
  });
}
