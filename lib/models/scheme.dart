import 'eligibility_rule.dart';

class Scheme {
  final String id;
  final String nameEn;
  final String nameMl;
  final String departmentEn;
  final String departmentMl;
  final String category; // 'fishing', 'plantation', 'all'
  final String descriptionEn;
  final String descriptionMl;
  final List<EligibilityRule> rules;
  final List<String> requiredDocumentsEn;
  final List<String> requiredDocumentsMl;
  final List<String> applicationChannelsEn;
  final List<String> applicationChannelsMl;
  final List<String> nextStepsEn;
  final List<String> nextStepsMl;
  final String sourceOfficial;
  final String disclaimer;
  final String? officialUrl;

  const Scheme({
    required this.id,
    required this.nameEn,
    required this.nameMl,
    required this.departmentEn,
    required this.departmentMl,
    required this.category,
    required this.descriptionEn,
    required this.descriptionMl,
    required this.rules,
    required this.requiredDocumentsEn,
    required this.requiredDocumentsMl,
    required this.applicationChannelsEn,
    required this.applicationChannelsMl,
    required this.nextStepsEn,
    required this.nextStepsMl,
    required this.sourceOfficial,
    required this.disclaimer,
    this.officialUrl,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    final rawSource = json['sourceOfficial'] as String? ?? '';
    final explicitUrl = json['officialUrl'] as String?;
    
    // Extract url from sourceOfficial if present, or use explicit, or department fallback
    String resolvedUrl;
    if (explicitUrl != null && explicitUrl.isNotEmpty) {
      resolvedUrl = explicitUrl;
    } else {
      final urlMatch = RegExp(r'https?://[^\s/$.?#].[^\s]*').firstMatch(rawSource);
      if (urlMatch != null) {
        resolvedUrl = urlMatch.group(0)?.replaceAll(RegExp(r'[,;]$'), '') ?? '';
      } else {
        final cat = json['category'] as String? ?? 'all';
        if (cat == 'fishing') {
          resolvedUrl = 'https://fisheries.kerala.gov.in';
        } else if (cat == 'plantation') {
          resolvedUrl = 'https://lc.kerala.gov.in';
        } else {
          resolvedUrl = 'https://kerala.gov.in';
        }
      }
    }

    return Scheme(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameMl: json['nameMl'] as String,
      departmentEn: json['departmentEn'] as String? ?? '',
      departmentMl: json['departmentMl'] as String? ?? '',
      category: json['category'] as String? ?? 'all',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionMl: json['descriptionMl'] as String? ?? '',
      rules: (json['rules'] as List<dynamic>? ?? [])
          .map((r) => EligibilityRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      requiredDocumentsEn: (json['requiredDocumentsEn'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      requiredDocumentsMl: (json['requiredDocumentsMl'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      applicationChannelsEn: (json['applicationChannelsEn'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      applicationChannelsMl: (json['applicationChannelsMl'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      nextStepsEn: (json['nextStepsEn'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      nextStepsMl: (json['nextStepsMl'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      sourceOfficial: rawSource,
      disclaimer: json['disclaimer'] as String? ?? '',
      officialUrl: resolvedUrl,
    );
  }

  String getName(bool isMalayalam) => isMalayalam ? nameMl : nameEn;
  String getDepartment(bool isMalayalam) => isMalayalam ? departmentMl : departmentEn;
  String getDescription(bool isMalayalam) => isMalayalam ? descriptionMl : descriptionEn;
  List<String> getRequiredDocuments(bool isMalayalam) =>
      isMalayalam ? requiredDocumentsMl : requiredDocumentsEn;
  List<String> getApplicationChannels(bool isMalayalam) =>
      isMalayalam ? applicationChannelsMl : applicationChannelsEn;
  List<String> getNextSteps(bool isMalayalam) =>
      isMalayalam ? nextStepsMl : nextStepsEn;

  /// Returns the legal order / Act reference text without the URL prefix
  String get officialReferenceClean {
    if (sourceOfficial.contains(' / ')) {
      final parts = sourceOfficial.split(' / ');
      if (parts.length > 1) {
        return parts.sublist(1).join(' / ').trim();
      }
    }
    return sourceOfficial;
  }
}
