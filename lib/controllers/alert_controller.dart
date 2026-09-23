import 'package:flutter/foundation.dart';
import '../models/safety_alert.dart';
import '../services/alert_repository.dart';

/// Manages community safety alert state, category/district filtering,
/// and read/unread status in memory.
class AlertController extends ChangeNotifier {
  final AlertRepository repository;

  String _selectedSector = 'all'; // 'all', 'fishing', 'plantation'
  String? _selectedDistrict; // null means 'All Districts'
  final Set<String> _readAlertIds = {};

  AlertController({required this.repository});

  String get selectedSector => _selectedSector;
  String? get selectedDistrict => _selectedDistrict;
  List<SafetyAlert> get allAlerts => repository.alerts;

  /// Returns active alerts matching current sector and district filters.
  List<SafetyAlert> get filteredAlerts {
    return repository.getAlertsFor(
      sector: _selectedSector == 'all' ? null : _selectedSector,
      district: _selectedDistrict,
    );
  }

  /// Calculates total unread alerts across the system.
  int get unreadCount {
    return repository.alerts
        .where((a) => !_readAlertIds.contains(a.id))
        .length;
  }

  /// Checks if a specific alert has been marked as read.
  bool isRead(String alertId) => _readAlertIds.contains(alertId);

  void setSector(String sector) {
    if (_selectedSector != sector) {
      _selectedSector = sector;
      notifyListeners();
    }
  }

  void setDistrict(String? district) {
    if (_selectedDistrict != district) {
      _selectedDistrict = district;
      notifyListeners();
    }
  }

  /// Pre-filters alerts to match a screened household's demographic location.
  void syncWithProfile({String? sector, String? district}) {
    if (sector != null && (sector == 'fishing' || sector == 'plantation')) {
      _selectedSector = sector;
    }
    if (district != null && district.isNotEmpty) {
      _selectedDistrict = district;
    }
    notifyListeners();
  }

  void markAsRead(String alertId) {
    if (_readAlertIds.add(alertId)) {
      notifyListeners();
    }
  }

  void toggleReadStatus(String alertId) {
    if (_readAlertIds.contains(alertId)) {
      _readAlertIds.remove(alertId);
    } else {
      _readAlertIds.add(alertId);
    }
    notifyListeners();
  }

  void markAllAsRead() {
    for (final alert in repository.alerts) {
      _readAlertIds.add(alert.id);
    }
    notifyListeners();
  }

  void resetFilters() {
    _selectedSector = 'all';
    _selectedDistrict = null;
    notifyListeners();
  }
}
