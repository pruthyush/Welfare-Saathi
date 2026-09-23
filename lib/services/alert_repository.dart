import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Loads community safety alerts from Firestore if available, with offline asset fallback.
  Future<void> loadAlerts() async {
    // 1. First load local seed/demo alerts to guarantee immediate offline usability
    try {
      final jsonString = await rootBundle.loadString('assets/data/safety_alerts.json');
      final list = json.decode(jsonString) as List<dynamic>;
      _alerts = list
          .map((e) => SafetyAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _alerts = [];
    }

    // 2. Attempt to synchronize with Cloud Firestore if online
    try {
      await fetchLiveAlerts();
    } catch (_) {
      // Offline fallback preserved
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

  /// Extension point: queries live or cloud-synchronized alerts from Firestore if available.
  Future<void> fetchLiveAlerts() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('alerts').get();
      if (snapshot.docs.isNotEmpty) {
        final firestoreAlerts = snapshot.docs
            .map((doc) => SafetyAlert.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
        if (firestoreAlerts.isNotEmpty) {
          _alerts = firestoreAlerts;
        }
      }
    } catch (_) {
      // Offline fallback preserved
    }
  }
}
