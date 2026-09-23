/// Represents the non-sensitive demographic and occupational characteristics
/// of a household being screened for welfare entitlements.
///
/// Designed to strictly preserve privacy: no names, no Aadhaar numbers,
/// no full phone numbers, and no street addresses are collected.
class HouseholdProfile {
  final String? occupation; // 'fishing', 'plantation', 'other'
  final int? age;
  final String? district;
  final int? monthlyIncome; // In INR; null indicates skipped/unanswered
  final bool? isBoardMember; // Registered with Fishermen or Plantation Board
  final int? yearsOfMembership;
  final String? rationCardCategory; // 'AAY', 'PHH', 'NPHH', 'Non-Priority'
  final String? housingCondition; // 'homeless', 'dilapidated', 'kutcha', 'pucca'
  final bool? hasStudentChild; // Dependent in College / Higher Secondary
  final String? specialStatus; // 'none', 'widowed', 'destitute', 'disabled'

  const HouseholdProfile({
    this.occupation,
    this.age,
    this.district,
    this.monthlyIncome,
    this.isBoardMember,
    this.yearsOfMembership,
    this.rationCardCategory,
    this.housingCondition,
    this.hasStudentChild,
    this.specialStatus = 'none',
  });

  /// Factory for an empty profile ready for screening.
  factory HouseholdProfile.empty() {
    return const HouseholdProfile(specialStatus: 'none');
  }

  HouseholdProfile copyWith({
    String? occupation,
    int? age,
    String? district,
    int? monthlyIncome,
    bool? isBoardMember,
    int? yearsOfMembership,
    String? rationCardCategory,
    String? housingCondition,
    bool? hasStudentChild,
    String? specialStatus,
    bool clearOccupation = false,
    bool clearAge = false,
    bool clearDistrict = false,
    bool clearMonthlyIncome = false,
    bool clearIsBoardMember = false,
    bool clearYearsOfMembership = false,
    bool clearRationCardCategory = false,
    bool clearHousingCondition = false,
    bool clearHasStudentChild = false,
    bool clearSpecialStatus = false,
  }) {
    return HouseholdProfile(
      occupation: clearOccupation ? null : (occupation ?? this.occupation),
      age: clearAge ? null : (age ?? this.age),
      district: clearDistrict ? null : (district ?? this.district),
      monthlyIncome: clearMonthlyIncome ? null : (monthlyIncome ?? this.monthlyIncome),
      isBoardMember: clearIsBoardMember ? null : (isBoardMember ?? this.isBoardMember),
      yearsOfMembership: clearYearsOfMembership ? null : (yearsOfMembership ?? this.yearsOfMembership),
      rationCardCategory: clearRationCardCategory ? null : (rationCardCategory ?? this.rationCardCategory),
      housingCondition: clearHousingCondition ? null : (housingCondition ?? this.housingCondition),
      hasStudentChild: clearHasStudentChild ? null : (hasStudentChild ?? this.hasStudentChild),
      specialStatus: clearSpecialStatus ? 'none' : (specialStatus ?? this.specialStatus),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'occupation': occupation,
      'age': age,
      'district': district,
      'monthlyIncome': monthlyIncome,
      'isBoardMember': isBoardMember,
      'yearsOfMembership': yearsOfMembership,
      'rationCardCategory': rationCardCategory,
      'housingCondition': housingCondition,
      'hasStudentChild': hasStudentChild,
      'specialStatus': specialStatus,
    };
  }

  factory HouseholdProfile.fromMap(Map<String, dynamic> map) {
    return HouseholdProfile(
      occupation: map['occupation'] as String?,
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      district: map['district'] as String?,
      monthlyIncome: map['monthlyIncome'] != null ? (map['monthlyIncome'] as num).toInt() : null,
      isBoardMember: map['isBoardMember'] as bool?,
      yearsOfMembership: map['yearsOfMembership'] != null ? (map['yearsOfMembership'] as num).toInt() : null,
      rationCardCategory: map['rationCardCategory'] as String?,
      housingCondition: map['housingCondition'] as String?,
      hasStudentChild: map['hasStudentChild'] as bool?,
      specialStatus: map['specialStatus'] as String? ?? 'none',
    );
  }

  /// Helper to retrieve field value dynamically for deterministic rule checks.
  dynamic getFieldValue(String fieldName) {
    switch (fieldName) {
      case 'occupation':
        return occupation;
      case 'age':
        return age;
      case 'district':
        return district;
      case 'monthlyIncome':
        return monthlyIncome;
      case 'isBoardMember':
        return isBoardMember;
      case 'yearsOfMembership':
        return yearsOfMembership;
      case 'rationCardCategory':
        return rationCardCategory;
      case 'housingCondition':
        return housingCondition;
      case 'hasStudentChild':
        return hasStudentChild;
      case 'specialStatus':
        return specialStatus;
      default:
        return null;
    }
  }
}
