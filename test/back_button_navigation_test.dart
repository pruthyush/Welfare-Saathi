import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/controllers/screening_controller.dart';
import 'package:welfare_saathi/main.dart';
import 'package:welfare_saathi/models/scheme.dart';
import 'package:welfare_saathi/services/localization_service.dart';
import 'package:welfare_saathi/services/scheme_repository.dart';
import 'package:welfare_saathi/widgets/app_back_button.dart';

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

  group('Back Button Navigation Tests', () {
    testWidgets('1. Homepage (WelcomeScreen) explicitly has NO Back button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Verify on WelcomeScreen
      expect(find.text('Start Screening'), findsOneWidget);

      // Verify that NO AppBackButton or arrow_back icon exists on Homepage
      expect(find.byType(AppBackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('2. Screening screen has Back button; tapping on Step 1 returns to Homepage', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Navigate to Screening
      await tester.tap(find.text('Start Screening'));
      await tester.pumpAndSettle();

      // Verify on Screening step 1
      expect(find.textContaining('Step 1 of 3'), findsOneWidget);

      // Verify Back button exists
      final backBtn = find.byType(AppBackButton);
      expect(backBtn, findsOneWidget);

      // Tap Back button -> returns to Welcome screen
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Start Screening'), findsOneWidget);
      expect(find.byType(AppBackButton), findsNothing);
    });

    testWidgets('3. Scheme Directory has Back button; tapping returns to Homepage', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Navigate to Scheme Directory
      final browseBtn = find.textContaining('Browse All 16 Verified Schemes');
      await tester.ensureVisible(browseBtn);
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      // Verify on Scheme Directory
      expect(find.textContaining('Scheme Handbook & Directory'), findsOneWidget);

      // Verify Back button exists
      final backBtn = find.byType(AppBackButton);
      expect(backBtn, findsOneWidget);

      // Tap Back button -> returns to Homepage
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.text('Start Screening'), findsOneWidget);
      expect(find.byType(AppBackButton), findsNothing);
    });

    testWidgets('4. Scheme Detail opened from Directory has Back button returning to Directory', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Go to Directory
      final browseBtn = find.textContaining('Browse All 16 Verified Schemes');
      await tester.ensureVisible(browseBtn);
      await tester.tap(browseBtn);
      await tester.pumpAndSettle();

      // Open Scheme Detail
      final detailsIcon = find.byIcon(Icons.description_outlined).first;
      await tester.ensureVisible(detailsIcon);
      await tester.tap(detailsIcon);
      await tester.pumpAndSettle();

      // Verify on Detail page
      expect(find.textContaining('Complete Scheme Information'), findsOneWidget);

      // Verify Back button exists
      final backBtn = find.byType(AppBackButton);
      expect(backBtn, findsOneWidget);

      // Tap Back -> returns to Scheme Directory
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Scheme Handbook & Directory'), findsOneWidget);
    });

    testWidgets('5. Results screen has Back button returning to Screening', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Navigate to Screening
      await tester.tap(find.text('Start Screening'));
      await tester.pumpAndSettle();

      // Step 1: tap Next
      final nextBtn1 = find.byIcon(Icons.arrow_forward);
      await tester.tap(nextBtn1);
      await tester.pumpAndSettle();

      // Step 2: tap Next
      final nextBtn2 = find.byIcon(Icons.arrow_forward);
      await tester.tap(nextBtn2);
      await tester.pumpAndSettle();

      // Step 3: tap Check Eligibility / Submit
      final submitBtn = find.byIcon(Icons.check_circle_outline);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify on Screening Results page
      expect(find.textContaining('Screening Results'), findsOneWidget);

      // Verify Back button exists on Results screen
      final backBtn = find.byType(AppBackButton);
      expect(backBtn, findsOneWidget);

      // Tap Back on Results -> returns to Screening
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Step 3 of 3'), findsOneWidget);
    });

    testWidgets('6. Review screen opened from Results has Back button returning to Results', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'en');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Go to Screening -> Step 1 -> Step 2 -> Step 3 -> Results
      await tester.tap(find.text('Start Screening'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pumpAndSettle();

      expect(find.textContaining('Screening Results'), findsOneWidget);

      // Tap Review / Edit Answers
      final reviewBtn = find.textContaining('Review / Edit Answers').first;
      await tester.tap(reviewBtn);
      await tester.pumpAndSettle();

      // Verify on Review screen
      expect(find.textContaining('Review / Edit Answers'), findsOneWidget);
      final backBtn = find.byType(AppBackButton);
      expect(backBtn, findsOneWidget);

      // Tap Back on Review -> returns to Results
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Screening Results'), findsOneWidget);
    });

    testWidgets('7. Malayalam locale provides proper localized tooltip "പുറകിലേക്ക്"', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repository = SchemeRepository();
      repository.initWithData(schemes: schemes);

      final loc = LocalizationService();
      loc.initWithMaps(enStrings: enMap, mlStrings: mlMap, defaultLanguage: 'ml');

      final controller = ScreeningController(repository: repository);

      await tester.pumpWidget(WelfareSaathiApp(
        repository: repository,
        loc: loc,
        controller: controller,
      ));
      await tester.pumpAndSettle();

      // Navigate to Screening (Malayalam)
      final startBtn = find.textContaining('സ്ക്രീനിംഗ് ആരംഭിക്കുക');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Verify Back button tooltip in Malayalam is 'പുറകിലേക്ക്'
      final backBtnFinder = find.byType(AppBackButton);
      expect(backBtnFinder, findsOneWidget);
      final backBtnWidget = tester.widget<AppBackButton>(backBtnFinder);
      expect(backBtnWidget.tooltip, equals('പുറകിലേക്ക്'));
    });
  });
}
