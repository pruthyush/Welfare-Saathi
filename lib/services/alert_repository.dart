import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/safety_alert.dart';

/// Repository for retrieving and querying community safety advisories.
///
/// Offline-first design: loads verified seed/demo alerts from local asset bundles.
/// In production Phase 5, [fetchLiveAlerts] can be wired to official government
/// API endpoints (KSDMA, INCOIS, IMD, Forest Dept) or browser Web Push feeds.
class AlertRepository {
  List<SafetyAlert> _alerts = [];

  List<SafetyAlert> get alerts => List.unmodifiable(_alerts);

  /// Synchronous initialization method for standalone unit testing without Flutter bindings.
  void initWithData(List<SafetyAlert> alerts) {
    _alerts = List.from(alerts);
  }

  /// Loads community safety alerts from the local asset bundle.
  Future<void> loadAlerts() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/safety_alerts.json');
      final list = json.decode(jsonString) as List<dynamic>;
      _alerts = list
          .map((e) => SafetyAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _alerts = [];
    }
  }

  /// Filters alerts deterministically by sector, district, and category.
  List<SafetyAlert> getAlertsFor({
    String? sector,
    String? district,
    String? category,
  }) {
    return _alerts.where((alert) {
      if (category != null && category != 'all' && alert.category != category) {
        return false;
      }
      if (sector != null && !alert.matchesSector(sector)) {
        return false;
      }
      if (district != null && !alert.matchesDistrict(district)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Extension point for future live authoritative push/REST integrations.
  Future<void> fetchLiveAlerts() async {
    // Production roadmap: Integrate KSDMA / INCOIS CAP (Common Alerting Protocol) RSS/REST feeds.
  }
}
