import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/controllers/screening_controller.dart';
import 'package:welfare_saathi/main.dart';
import 'package:welfare_saathi/models/scheme.dart';
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

  testWidgets('Welfare Saathi smoke test: Renders Welcome, switches language, and verifies disclaimer', (WidgetTester tester) async {
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

    // Verify Malayalam Title exists on Welcome Screen
    expect(find.textContaining('വെൽഫെയർ സാഥി'), findsWidgets);

    // Verify Disclaimer is visible on Welcome Screen
    expect(
      find.textContaining('അന്തിമ അർഹത ബന്ധപ്പെട്ട സർക്കാർ ഉദ്യോഗസ്ഥർ നിശ്ചയിക്കുന്നതാണ്'),
      findsOneWidget,
    );

    // Verify strict safety: NEVER displays "You are eligible"
    expect(find.text('You are eligible'), findsNothing);
    expect(find.text('You are eligible.'), findsNothing);
    expect(find.text('നിങ്ങൾ അർഹനാണ്'), findsNothing);

    // Test Language switch to English
    loc.setLanguage('en');
    await tester.pumpAndSettle();

    expect(find.text('Welfare Saathi'), findsWidgets);
    expect(find.text('Start Screening'), findsOneWidget);
    expect(
      find.textContaining('Final eligibility is determined by the relevant authority'),
      findsOneWidget,
    );
  });

  testWidgets('Scheme Directory test: Navigates to directory and lists 16 verified schemes with details', (WidgetTester tester) async {
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

    // Scroll to and tap on "Browse All 16 Verified Schemes"
    final browseBtn = find.textContaining('Browse All 16 Verified Schemes');
    expect(browseBtn, findsOneWidget);
    await tester.ensureVisible(browseBtn);
    await tester.tap(browseBtn);
    await tester.pumpAndSettle();

    // Verify Scheme Directory is opened
    expect(find.textContaining('Scheme Handbook & Directory'), findsOneWidget);
    expect(find.textContaining('Showing 16 of 16 schemes'), findsOneWidget);

    // Verify sample schemes from both sectors appear
    expect(find.textContaining('Matsyathozhilali Old Age Pension'), findsOneWidget);

    // Tap into scheme complete details
    final detailsIcon = find.byIcon(Icons.description_outlined).first;
    await tester.ensureVisible(detailsIcon);
    await tester.tap(detailsIcon);
    await tester.pumpAndSettle();

    // Verify Full Scheme Information page is opened
    expect(find.textContaining('Complete Scheme Information'), findsOneWidget);
    expect(find.textContaining('ELIGIBILITY RULES & CRITERIA'), findsOneWidget);
    expect(find.textContaining('DOCUMENTS REQUIRED'), findsOneWidget);
    expect(find.textContaining('WHERE TO APPLY'), findsOneWidget);
    expect(find.textContaining('OFFICIAL GOVERNMENT REFERENCE'), findsOneWidget);
  });
}
