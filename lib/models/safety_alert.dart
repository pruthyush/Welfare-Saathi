/// Represents an officially issued (or prototype demo) community safety warning
/// for vulnerable coastal fisherfolk and high-range hill plantation labor communities.
///
/// Designed to strictly prevent fabricated emergencies: all demo alerts are
/// visibly labeled as demo data, and the data schema is directly extensible for
/// authoritative government feeds (INCOIS, IMD, KSDMA, Kerala Forest Dept).
class SafetyAlert {
  final String id;
  final String titleEn;
  final String titleMl;
  final String descriptionEn;
  final String descriptionMl;
  final String category; // 'coastal', 'plantation', 'general'
  final String hazardType; // 'high_tide', 'cyclone', 'landslide', 'wildlife', 'rough_sea'
  final String affectedSector; // 'fishing', 'plantation', 'both'
  final List<String> affectedDistricts;
  final String severity; // 'warning', 'alert', 'advisory'
  final String issuedAt;
  final String validUntil;
  final String source;
  final String? sourceUrl;
  final List<String> recommendedActionsEn;
  final List<String> recommendedActionsMl;
  final bool isDemo;

  const SafetyAlert({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.descriptionEn,
    required this.descriptionMl,
    required this.category,
    required this.hazardType,
    required this.affectedSector,
    required this.affectedDistricts,
    required this.severity,
    required this.issuedAt,
    required this.validUntil,
    required this.source,
    this.sourceUrl,
    required this.recommendedActionsEn,
    required this.recommendedActionsMl,
    this.isDemo = true,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) {
    return SafetyAlert(
      id: json['id'] as String,
      titleEn: json['titleEn'] as String,
      titleMl: json['titleMl'] as String,
      descriptionEn: json['descriptionEn'] as String,
      descriptionMl: json['descriptionMl'] as String,
      category: json['category'] as String? ?? 'general',
      hazardType: json['hazardType'] as String? ?? 'general',
      affectedSector: json['affectedSector'] as String? ?? 'both',
      affectedDistricts: (json['affectedDistricts'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      severity: json['severity'] as String? ?? 'advisory',
      issuedAt: json['issuedAt'] as String? ?? '',
      validUntil: json['validUntil'] as String? ?? '',
      source: json['source'] as String? ?? 'Official Agency',
      sourceUrl: json['sourceUrl'] as String?,
      recommendedActionsEn: (json['recommendedActionsEn'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      recommendedActionsMl: (json['recommendedActionsMl'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isDemo: json['isDemo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleMl': titleMl,
      'descriptionEn': descriptionEn,
      'descriptionMl': descriptionMl,
      'category': category,
      'hazardType': hazardType,
      'affectedSector': affectedSector,
      'affectedDistricts': affectedDistricts,
      'severity': severity,
      'issuedAt': issuedAt,
      'validUntil': validUntil,
      'source': source,
      'sourceUrl': sourceUrl,
      'recommendedActionsEn': recommendedActionsEn,
      'recommendedActionsMl': recommendedActionsMl,
      'isDemo': isDemo,
    };
  }

  String getTitle(bool isMalayalam) => isMalayalam ? titleMl : titleEn;
  String getDescription(bool isMalayalam) => isMalayalam ? descriptionMl : descriptionEn;
  List<String> getRecommendedActions(bool isMalayalam) =>
      isMalayalam ? recommendedActionsMl : recommendedActionsEn;

  bool get isCoastal => category == 'coastal' || affectedSector == 'fishing';
  bool get isPlantation => category == 'plantation' || affectedSector == 'plantation';

  /// Evaluates whether this alert is relevant to a given occupation sector.
  bool matchesSector(String? sector) {
    if (sector == null || sector.isEmpty || sector == 'all') return true;
    if (affectedSector == 'both' || affectedSector == 'all') return true;
    if (sector == 'fishing' && isCoastal) return true;
    if (sector == 'plantation' && isPlantation) return true;
    return false;
  }

  /// Evaluates whether this alert applies to a given district.
  bool matchesDistrict(String? district) {
    if (district == null || district.isEmpty || district == 'all') return true;
    return affectedDistricts.any(
      (d) => d.toLowerCase().trim() == district.toLowerCase().trim(),
    );
  }
}
