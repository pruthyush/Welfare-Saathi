import '../models/eligibility_result.dart';
import '../models/household_profile.dart';

class SchemeBenefitData {
  final int monthlyAmount;
  final int annualAmount;
  final int oneTimeAmount;
  final int insuranceCover; // Contingent risk cover (not counted as cash grant)
  final String benefitType; // 'pension', 'relief', 'housing', 'education', 'grant', 'insurance'

  const SchemeBenefitData({
    this.monthlyAmount = 0,
    this.annualAmount = 0,
    this.oneTimeAmount = 0,
    this.insuranceCover = 0,
    required this.benefitType,
  });
}

class SchemeEntitlementItem {
  final String schemeId;
  final String schemeNameEn;
  final String schemeNameMl;
  final String category;
  final int monthlyAmount;
  final int annualAmount;
  final int oneTimeAmount;
  final int insuranceCover;
  final int firstYearTotal;
  final String benefitDescriptionEn;
  final String benefitDescriptionMl;

  const SchemeEntitlementItem({
    required this.schemeId,
    required this.schemeNameEn,
    required this.schemeNameMl,
    required this.category,
    required this.monthlyAmount,
    required this.annualAmount,
    required this.oneTimeAmount,
    this.insuranceCover = 0,
    required this.firstYearTotal,
    required this.benefitDescriptionEn,
    required this.benefitDescriptionMl,
  });
}

class EntitlementSummary {
  final int monthlyRecurring;
  final int annualRecurring;
  final int oneTimeGrants;
  final int totalFirstYearPotential;
  final int eligibleCount;
  final List<SchemeEntitlementItem> items;

  const EntitlementSummary({
    required this.monthlyRecurring,
    required this.annualRecurring,
    required this.oneTimeGrants,
    required this.totalFirstYearPotential,
    required this.eligibleCount,
    this.items = const [],
  });
}

class LeakageItem {
  final String titleEn;
  final String titleMl;
  final int annualAmount;
  final int threeYearLoss;

  const LeakageItem({
    required this.titleEn,
    required this.titleMl,
    required this.annualAmount,
    required this.threeYearLoss,
  });
}

class LeakageReport {
  final int unclaimedAmount;
  final int yearsMissed;
  final List<String> missedItemsEn;
  final List<String> missedItemsMl;
  final List<LeakageItem> items;
  final String urgencyMessageEn;
  final String urgencyMessageMl;

  const LeakageReport({
    required this.unclaimedAmount,
    required this.yearsMissed,
    required this.missedItemsEn,
    required this.missedItemsMl,
    this.items = const [],
    required this.urgencyMessageEn,
    required this.urgencyMessageMl,
  });
}

/// Service calculating total financial entitlements and auditing retroactive
/// entitlement leakage (unclaimed welfare benefits) for Kerala families.
class BenefitCalculatorService {
  static const Map<String, SchemeBenefitData> _schemeBenefits = {
    'SCHEME-01': SchemeBenefitData(monthlyAmount: 1600, annualAmount: 19200, benefitType: 'pension'),
    'SCHEME-02': SchemeBenefitData(annualAmount: 4500, benefitType: 'relief'),
    'SCHEME-03': SchemeBenefitData(oneTimeAmount: 400000, benefitType: 'housing'),
    'SCHEME-04': SchemeBenefitData(annualAmount: 8000, benefitType: 'education'),
    // SCHEME-05 is Group Accident Insurance. The state provides ₹2,000/yr premium subsidy.
    // The ₹5,00,000 accidental death/disability coverage is contingent risk cover and
    // is NOT counted as a one-time cash grant or missing benefit.
    'SCHEME-05': SchemeBenefitData(annualAmount: 2000, oneTimeAmount: 0, insuranceCover: 500000, benefitType: 'insurance'),
    'SCHEME-06': SchemeBenefitData(oneTimeAmount: 200000, benefitType: 'housing'),
    'SCHEME-07': SchemeBenefitData(annualAmount: 5000, benefitType: 'education'),
    'SCHEME-08': SchemeBenefitData(annualAmount: 15000, benefitType: 'medical'),
    'SCHEME-09': SchemeBenefitData(oneTimeAmount: 50000, benefitType: 'microfinance'),
    'SCHEME-10': SchemeBenefitData(monthlyAmount: 1600, annualAmount: 19200, benefitType: 'pension'),
    'SCHEME-11': SchemeBenefitData(oneTimeAmount: 15000, benefitType: 'grant'),
    'SCHEME-12': SchemeBenefitData(oneTimeAmount: 1000000, benefitType: 'housing'),
    'SCHEME-13': SchemeBenefitData(oneTimeAmount: 10000, benefitType: 'grant'),
    'SCHEME-14': SchemeBenefitData(oneTimeAmount: 15000, benefitType: 'maternity'),
    'SCHEME-15': SchemeBenefitData(oneTimeAmount: 10000, benefitType: 'grant'),
    'SCHEME-16': SchemeBenefitData(oneTimeAmount: 15000, benefitType: 'maternity'),
  };

  /// Calculates total monetary assistance for a list of potentially eligible schemes.
  static EntitlementSummary calculateSummary(List<EligibilityResult> results) {
    int monthly = 0;
    int annual = 0;
    int oneTime = 0;
    int count = 0;
    final items = <SchemeEntitlementItem>[];

    for (final r in results) {
      if (!r.isPotentiallyEligible) continue;
      count++;
      final data = _schemeBenefits[r.scheme.id.toUpperCase()];
      final m = data?.monthlyAmount ?? 0;
      final a = data?.annualAmount ?? 0;
      final o = data?.oneTimeAmount ?? 0;
      final c = data?.insuranceCover ?? 0;

      monthly += m;
      annual += a;
      oneTime += o;

      items.add(SchemeEntitlementItem(
        schemeId: r.scheme.id,
        schemeNameEn: r.scheme.nameEn,
        schemeNameMl: r.scheme.nameMl,
        category: r.scheme.category,
        monthlyAmount: m,
        annualAmount: a,
        oneTimeAmount: o,
        insuranceCover: c,
        firstYearTotal: a + o,
        benefitDescriptionEn: r.scheme.descriptionEn,
        benefitDescriptionMl: r.scheme.descriptionMl,
      ));
    }

    final totalFirstYear = annual + oneTime;

    return EntitlementSummary(
      monthlyRecurring: monthly,
      annualRecurring: annual,
      oneTimeGrants: oneTime,
      totalFirstYearPotential: totalFirstYear,
      eligibleCount: count,
      items: items,
    );
  }

  /// USP 2: Calculates retroactive unclaimed welfare (Entitlement Leakage Audit)
  /// for households who have not registered with the Welfare Board.
  /// 
  /// STRICT RULE:
  /// Accidental insurance, death compensation, and casualty-contingent schemes
  /// are strictly EXCLUDED from missing schemes / leakage audit.
  /// Rationale: Accidental cover is contingent on an unfortunate casualty occurring;
  /// an uninjured worker did not "miss" or "leak" accident money simply by being unregistered.
  static LeakageReport? auditLeakage(HouseholdProfile profile) {
    // If applicant is already registered and has tenure, leakage is minimal
    if (profile.isBoardMember == true && (profile.yearsOfMembership ?? 0) >= 3) {
      return null;
    }

    int lostTotal = 0;
    const years = 3;
    final missedEn = <String>[];
    final missedMl = <String>[];
    final leakageItems = <LeakageItem>[];

    final occ = profile.occupation;
    final age = profile.age ?? 45;

    // 1. Missed Monsoon / Lean Relief (Fishing)
    if (occ == 'fishing') {
      const annualRelief = 4500;
      lostTotal += annualRelief * years;
      missedEn.add('Monsoon & Lean Period Relief (3 years): ₹${annualRelief * years}');
      missedMl.add('മൺസൂൺ / ട്രോളിംഗ് നിരോധന ആശ്വാസം (3 വർഷം): ₹${annualRelief * years}');
      leakageItems.add(const LeakageItem(
        titleEn: 'Monsoon & Lean Period Trawling Ban Relief',
        titleMl: 'മൺസൂൺ / ട്രോളിംഗ് നിരോധന ആശ്വാസ ധനസഹായം',
        annualAmount: annualRelief,
        threeYearLoss: annualRelief * years,
      ));
    }

    // 2. Missed Pension if age >= 60
    if (age >= 60 && (occ == 'fishing' || occ == 'plantation')) {
      const monthlyPension = 1600;
      final lostPension = monthlyPension * 12 * years;
      lostTotal += lostPension;
      missedEn.add('Welfare Old Age Pension (3 years): ₹$lostPension');
      missedMl.add('ക്ഷേമനിധി വാർദ്ധക്യകാല പെൻഷൻ (3 വർഷം): ₹$lostPension');
      leakageItems.add(LeakageItem(
        titleEn: 'Welfare Board Old Age Pension (₹1,600/month)',
        titleMl: 'ക്ഷേമനിധി വാർദ്ധക്യകാല പെൻഷൻ (പ്രതിമാസം ₹1,600)',
        annualAmount: monthlyPension * 12,
        threeYearLoss: lostPension,
      ));
    }

    // 3. Missed Student Scholarship if student child present
    if (profile.hasStudentChild == true && (occ == 'fishing' || occ == 'plantation')) {
      const studentAid = 5000;
      lostTotal += studentAid * years;
      missedEn.add('Children Merit Scholarship (3 years): ₹${studentAid * years}');
      missedMl.add('മക്കൾക്കുള്ള വിദ്യാഭ്യാസ സ്കോളർഷിപ്പ് (3 വർഷം): ₹${studentAid * years}');
      leakageItems.add(const LeakageItem(
        titleEn: 'Children Higher Education Merit Scholarship',
        titleMl: 'കുട്ടികൾക്കുള്ള ഉന്നതവിദ്യാഭ്യാസ മെറിറ്റ് സ്കോളർഷിപ്പ്',
        annualAmount: studentAid,
        threeYearLoss: studentAid * years,
      ));
    }

    // Baseline minimum leakage if working in unorganized sector
    if (lostTotal == 0 && (occ == 'fishing' || occ == 'plantation')) {
      lostTotal = 15000;
      missedEn.add('Annual Welfare Board Festival & Lean Doles: ₹15,000');
      missedMl.add('ക്ഷേമനിധി ബോർഡ് ആശ്വാസ ധനസഹായങ്ങൾ: ₹15,000');
      leakageItems.add(const LeakageItem(
        titleEn: 'Annual Festival & Seasonal Lean Assistance',
        titleMl: 'ഉത്സവകാല / സീസണൽ ആശ്വാസ സഹായങ്ങൾ',
        annualAmount: 5000,
        threeYearLoss: 15000,
      ));
    }

    if (lostTotal == 0) return null;

    final formattedLost = formatCurrency(lostTotal);

    final isRecentMember = profile.isBoardMember == true;

    return LeakageReport(
      unclaimedAmount: lostTotal,
      yearsMissed: years,
      missedItemsEn: missedEn,
      missedItemsMl: missedMl,
      items: leakageItems,
      urgencyMessageEn: isRecentMember
          ? 'Before your recent Welfare Board registration, you missed approximately '
              '₹$formattedLost over the last $years years. Maintaining continuous renewal will secure your future entitlements!'
          : 'Because your household was not registered with the Welfare Board, you missed approximately '
              '₹$formattedLost over the last $years years. Completing registration this month will prevent further entitlement leakage!',
      urgencyMessageMl: isRecentMember
          ? 'ക്ഷേമനിധി ബോർഡിൽ മുൻപ് ചേരാതിരുന്നതിനാൽ കഴിഞ്ഞ $years വർഷങ്ങളിലായി ഏകദേശം '
              '₹$formattedLost രൂപയുടെ ആനുകൂല്യങ്ങൾ നഷ്ടപ്പെട്ടിരുന്നു. തുടർച്ചയായ അംഗത്വം നിലനിർത്തുക!'
          : 'ക്ഷേമനിധി ബോർഡിൽ രജിസ്റ്റർ ചെയ്യാതിരുന്നതിനാൽ കഴിഞ്ഞ $years വർഷങ്ങളിലായി ഏകദേശം '
              '₹$formattedLost രൂപയുടെ ആനുകൂല്യങ്ങൾ നിങ്ങളുടെ കുടുംബത്തിന് നഷ്ടപ്പെട്ടു. ഉടൻ അക്ഷയ വഴി രജിസ്റ്റർ ചെയ്യുക!',
    );
  }

  static String formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
          RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))(\.\d+)?'),
          (Match m) => '${m[1]},',
        );
  }
}
