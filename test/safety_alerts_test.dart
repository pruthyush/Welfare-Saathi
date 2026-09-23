import 'package:flutter_test/flutter_test.dart';
import 'package:welfare_saathi/models/safety_alert.dart';
import 'package:welfare_saathi/services/alert_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleAlert1 = SafetyAlert(
    id: "alert-coastal-alappuzha-01",
    titleEn: "High Tide & Rough Sea Warning",
    titleMl: "ഉയർന്ന തിരമാലയും കടൽക്ഷോഭ മുന്നറിയിപ്പും",
    descriptionEn: "INCOIS has issued a high swell wave alert for Alappuzha coast.",
    descriptionMl: "ആലപ്പുഴ തീരത്ത് ഉയർന്ന തിരമാലകൾക്ക് സാധ്യതയുണ്ടെന്ന് ഐഎൻസിഒഐഎസ് മുന്നറിയിപ്പ്.",
    category: "coastal",
    hazardType: "high_tide",
    affectedSector: "fishing",
    affectedDistricts: ["Alappuzha", "Kollam", "Ernakulam"],
    severity: "warning",
    issuedAt: "2026-09-23T18:00:00Z",
    validUntil: "2026-09-25T18:00:00Z",
    source: "INCOIS / KSDMA",
    sourceUrl: "https://incois.gov.in",
    isDemo: true,
    recommendedActionsEn: [
      "Fisherfolk are advised not to venture into deep sea.",
      "Secure fishing crafts and nets at harbor shelters."
    ],
    recommendedActionsMl: [
      "മത്സ്യത്തൊഴിലാളികൾ കടലിൽ പോകരുതെന്ന് നിർദ്ദേശിക്കുന്നു.",
      "വള്ളങ്ങളും വലകളും സുരക്ഷിത സ്ഥാനങ്ങളിലേക്ക് മാറ്റുക."
    ],
  );

  final sampleAlert2 = SafetyAlert(
    id: "alert-plantation-idukki-01",
    titleEn: "Wild Elephant Herd Movement Advisory",
    titleMl: "കാട്ടാനക്കൂട്ടത്തിന്റെ സാന്നിധ്യം - ജാഗ്രതാ നിർദ്ദേശം",
    descriptionEn: "Forest department reports active wild elephant herd movement near tea division.",
    descriptionMl: "മുല്ലക്കാനം തേയില തോട്ടം ഭാഗത്ത് കാട്ടാനക്കൂട്ടം നിലയുറപ്പിച്ചതായി റിപ്പോർട്ട്.",
    category: "plantation",
    hazardType: "wildlife",
    affectedSector: "plantation",
    affectedDistricts: ["Idukki"],
    severity: "alert",
    issuedAt: "2026-09-23T19:30:00Z",
    validUntil: "2026-09-24T20:00:00Z",
    source: "Kerala Forest & Wildlife Department (Devikulam Range)",
    sourceUrl: "https://forest.kerala.gov.in",
    isDemo: true,
    recommendedActionsEn: [
      "Avoid early morning (before 7 AM) walking on foot along section 4.",
      "Do not provoke elephants; carry whistles and torchlights."
    ],
    recommendedActionsMl: [
      "സെക്ഷൻ 4 ലൂടെ പുലർച്ചെ 7 ന് മുമ്പുള്ള ഒറ്റയ്ക്കുള്ള നടത്തം ഒഴിവാക്കുക.",
      "ആനകളെ പ്രകോപിപ്പിക്കരുത്; ടോർച്ചും വിസിലും കരുതുക."
    ],
  );

  final sampleAlert3 = SafetyAlert(
    id: "alert-plantation-wayanad-01",
    titleEn: "Landslide Vulnerability Advisory",
    titleMl: "ഉരുൾപൊട്ടൽ സാധ്യത മുന്നറിയിപ്പ്",
    descriptionEn: "Heavy rainfall increases slope instability risk in Meppadi estate valleys.",
    descriptionMl: "മേപ്പാടി എസ്റ്റേറ്റ് താഴ്‌വരകളിൽ ഉരുൾപൊട്ടൽ സാധ്യത.",
    category: "plantation",
    hazardType: "landslide",
    affectedSector: "plantation",
    affectedDistricts: ["Wayanad"],
    severity: "warning",
    issuedAt: "2026-09-23T17:00:00Z",
    validUntil: "2026-09-25T12:00:00Z",
    source: "KSDMA & Geological Survey of India",
    isDemo: true,
    recommendedActionsEn: ["Evacuate labor line rooms situated under steep cuts."],
    recommendedActionsMl: ["കുത്തനെയുള്ള ചരിവുകളിലെ ലയങ്ങളിൽ നിന്ന് മാറിത്താമസിക്കുക."],
  );

  group('Community Safety Alerts Feature Tests', () {
    late AlertRepository repository;

    setUp(() {
      repository = AlertRepository();
      repository.initWithData([sampleAlert1, sampleAlert2, sampleAlert3]);
    });

    test('1. Alert model parsing from JSON preserves all fields and types', () {
      final json = sampleAlert1.toJson();
      final parsed = SafetyAlert.fromJson(json);

      expect(parsed.id, equals('alert-coastal-alappuzha-01'));
      expect(parsed.titleEn, contains('High Tide'));
      expect(parsed.category, equals('coastal'));
      expect(parsed.affectedSector, equals('fishing'));
      expect(parsed.affectedDistricts, contains('Alappuzha'));
      expect(parsed.severity, equals('warning'));
      expect(parsed.isDemo, isTrue);
      expect(parsed.recommendedActionsEn.length, equals(2));
      expect(parsed.sourceUrl, isNotNull);
    });

    test('2. Demo alerts are strictly identified as DEMO data', () {
      for (final alert in repository.alerts) {
        expect(alert.isDemo, isTrue,
            reason: 'All prototype alerts must have isDemo = true');
      }
    });

    test('3. Coastal alert filtering returns coastal alerts for fishing sector', () {
      final coastalAlerts = repository.getAlertsFor(sector: 'fishing');
      expect(coastalAlerts.isNotEmpty, isTrue);
      for (final alert in coastalAlerts) {
        expect(alert.isCoastal, isTrue);
      }
    });

    test('4. Hill/Plantation alert filtering returns plantation alerts', () {
      final plantationAlerts = repository.getAlertsFor(sector: 'plantation');
      expect(plantationAlerts.isNotEmpty, isTrue);
      for (final alert in plantationAlerts) {
        expect(alert.isPlantation, isTrue);
      }
    });

    test('5. District filtering returns only alerts relevant to that district', () {
      final alappuzhaAlerts = repository.getAlertsFor(district: 'Alappuzha');
      expect(alappuzhaAlerts.length, equals(1));
      expect(alappuzhaAlerts.first.id, equals('alert-coastal-alappuzha-01'));

      final idukkiAlerts = repository.getAlertsFor(district: 'Idukki');
      expect(idukkiAlerts.length, equals(1));
      expect(idukkiAlerts.first.titleEn, contains('Wild Elephant'));
    });

    test('6. No unrelated alert is shown to the wrong sector and district', () {
      // E.g., Fishing search in Idukki (hill district) should return zero coastal alerts
      final fishingInIdukki = repository.getAlertsFor(
        sector: 'fishing',
        district: 'Idukki',
      );
      expect(fishingInIdukki, isEmpty,
          reason: 'Idukki is a hill district; coastal alerts must not match');

      // E.g., Plantation search in Alappuzha (coastal district)
      final plantationInAlappuzha = repository.getAlertsFor(
        sector: 'plantation',
        district: 'Alappuzha',
      );
      expect(plantationInAlappuzha, isEmpty,
          reason: 'Alappuzha is coastal; plantation alerts must not match');
    });

    test('7. Bilingual title, description, and action resolution', () {
      final alert = sampleAlert1;
      expect(alert.getTitle(false), equals(alert.titleEn));
      expect(alert.getTitle(true), equals(alert.titleMl));
      expect(alert.getDescription(false), equals(alert.descriptionEn));
      expect(alert.getDescription(true), equals(alert.descriptionMl));
      expect(alert.getRecommendedActions(true).first, contains('മത്സ്യത്തൊഴിലാളികൾ'));
    });
  });
}
