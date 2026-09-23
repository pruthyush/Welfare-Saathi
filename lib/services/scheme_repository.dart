import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/akshaya_centre.dart';
import '../models/household_profile.dart';
import '../models/scheme.dart';

class SampleProfileItem {
  final String id;
  final String titleEn;
  final String titleMl;
  final String descriptionEn;
  final String descriptionMl;
  final HouseholdProfile profile;
  final List<String> expectedPotentialSchemeIds;
  final List<String> expectedIncompleteSchemeIds;

  const SampleProfileItem({
    required this.id,
    required this.titleEn,
    required this.titleMl,
    required this.descriptionEn,
    required this.descriptionMl,
    required this.profile,
    required this.expectedPotentialSchemeIds,
    this.expectedIncompleteSchemeIds = const [],
  });

  String getTitle(bool isMalayalam) => isMalayalam ? titleMl : titleEn;
  String getDescription(bool isMalayalam) => isMalayalam ? descriptionMl : descriptionEn;
}

class SchemeRepository {
  List<Scheme> _schemes = [];
  List<AkshayaCentre> _akshayaCentres = [];
  List<SampleProfileItem> _sampleProfiles = [];

  List<Scheme> get schemes => List.unmodifiable(_schemes);
  List<AkshayaCentre> get akshayaCentres => List.unmodifiable(_akshayaCentres);
  List<SampleProfileItem> get sampleProfiles => List.unmodifiable(_sampleProfiles);

  void initWithData({
    required List<Scheme> schemes,
    List<AkshayaCentre> akshayaCentres = const [],
    List<SampleProfileItem> sampleProfiles = const [],
  }) {
    _schemes = schemes;
    _akshayaCentres = akshayaCentres;
    _sampleProfiles = sampleProfiles;
  }

  /// Loads all verified scheme datasets and directories from local assets.
  Future<void> loadData() async {
    try {
      final schemesJsonString = await rootBundle.loadString('assets/data/schemes.json');
      final schemesList = json.decode(schemesJsonString) as List<dynamic>;
      _schemes = schemesList.map((e) => Scheme.fromJson(e as Map<String, dynamic>)).toList();

      final akshayaJsonString = await rootBundle.loadString('assets/data/akshaya_centres.json');
      final akshayaList = json.decode(akshayaJsonString) as List<dynamic>;
      _akshayaCentres = akshayaList.map((e) => AkshayaCentre.fromJson(e as Map<String, dynamic>)).toList();

      final profilesJsonString = await rootBundle.loadString('assets/data/sample_households.json');
      final profilesList = json.decode(profilesJsonString) as List<dynamic>;
      _sampleProfiles = profilesList.map((e) {
        final map = e as Map<String, dynamic>;
        return SampleProfileItem(
          id: map['id'] as String,
          titleEn: map['titleEn'] as String,
          titleMl: map['titleMl'] as String,
          descriptionEn: map['descriptionEn'] as String,
          descriptionMl: map['descriptionMl'] as String,
          profile: HouseholdProfile.fromMap(map['profile'] as Map<String, dynamic>),
          expectedPotentialSchemeIds: (map['expectedPotentialSchemeIds'] as List<dynamic>? ?? [])
              .map((id) => id.toString())
              .toList(),
          expectedIncompleteSchemeIds: (map['expectedIncompleteSchemeIds'] as List<dynamic>? ?? [])
              .map((id) => id.toString())
              .toList(),
        );
      }).toList();
    } catch (e) {
      // Graceful fallback for tests or empty bundle
    }
  }

  /// Finds Akshaya centres matching the household's district, or returns general hubs.
  List<AkshayaCentre> getCentresForDistrict(String? district) {
    if (district == null || district.isEmpty) {
      return _akshayaCentres.take(3).toList();
    }
    final matched = _akshayaCentres
        .where((c) => c.district.toLowerCase() == district.toLowerCase())
        .toList();
    if (matched.isNotEmpty) {
      return matched;
    }
    return _akshayaCentres.take(3).toList();
  }
}
