import 'package:flutter/material.dart';
import '../controllers/alert_controller.dart';
import '../models/safety_alert.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

/// Community Safety Alerts Screen.
///
/// Delivers area-specific coastal and hill/plantation hazard advisories.
/// All prototype demonstration alerts are visibly identified with the mandatory
/// "Demo Alert — Sample Data" indicator to ensure ethical safety compliance.
class AlertsScreen extends StatefulWidget {
  final AlertController alertController;
  final LocalizationService loc;
  final VoidCallback onBack;

  const AlertsScreen({
    super.key,
    required this.alertController,
    required this.loc,
    required this.onBack,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final List<String> _districts = const [
    'All Districts',
    'Alappuzha',
    'Ernakulam',
    'Idukki',
    'Wayanad',
    'Kollam',
    'Thiruvananthapuram',
    'Kozhikode',
    'Thrissur',
    'Malappuram',
    'Kannur',
    'Kasaragod',
    'Kottayam',
    'Palakkad',
    'Pathanamthitta',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = widget.alertController;
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final alerts = controller.filteredAlerts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          loc.tr('safetyAlerts'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (controller.unreadCount > 0)
            TextButton.icon(
              onPressed: () => controller.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(
                isMl ? 'എല്ലാം വായിച്ചു' : 'Mark All Read',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          const SizedBox(width: 4),
          LanguageSelector(loc: loc),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Mandatory Safety Disclaimer Banner
              _buildDemoDisclaimer(isMl, isDark),
              const SizedBox(height: 16),

              // Filter Controls (Sector Chips & District Dropdown)
              _buildFilterCard(controller, loc, isMl, isDark),
              const SizedBox(height: 16),

              // Results Count / Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMl
                        ? '${alerts.length} സജീവ മുന്നറിയിപ്പുകൾ'
                        : 'Active Advisories (${alerts.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (controller.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE63946),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Alerts Feed
              if (alerts.isEmpty)
                _buildEmptyState(loc, isMl, isDark)
              else
                ...alerts.map((alert) => _buildAlertCard(alert, controller, isMl, isDark)),

              const SizedBox(height: 24),

              // Phase 5 Push Notification Roadmap Information
              _buildNotificationRoadmapCard(isMl, isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  int get unreadCount => widget.alertController.unreadCount;

  Widget _buildDemoDisclaimer(bool isMl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E1C0C) : const Color(0xFFFFF7ED),
        border: Border.all(
          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFFB923C),
          width: 1.2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMl
                      ? 'ഡെമോ മുന്നറിയിപ്പ് — മാതൃകാ വിവരം (Demo Alert — Sample Data)'
                      : 'DEMO ALERT — SAMPLE DATA (Prototype Warning Feed)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMl
                      ? 'ഹാക്കത്തോൺ മാതൃകയ്ക്കായി തയ്യാറാക്കിയ സാമ്പിൾ മുന്നറിയിപ്പുകളാണിത്. യഥാർത്ഥ അടിയന്തിര ഒഴിപ്പിക്കലുകൾക്ക് ഇത് ഉപയോഗിക്കരുത്. ഔദ്യോഗിക ദുരന്തനിവാരണ അതോറിറ്റി (KSDMA) നിർദ്ദേശങ്ങൾ മാത്രം പിന്തുടരുക.'
                      : 'These advisories are representative sample data for hackathon demonstration. Do not use for real emergency evacuations. In production, this module will consume verified live feeds from INCOIS, IMD, KSDMA, and Kerala Forest Dept.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: isDark ? Colors.white70 : const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(
    AlertController controller,
    LocalizationService loc,
    bool isMl,
    bool isDark,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sector Selector Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSectorChip(
                  label: loc.tr('allAlerts'),
                  icon: Icons.notifications_active_outlined,
                  isSelected: controller.selectedSector == 'all',
                  onSelected: () => controller.setSector('all'),
                  isDark: isDark,
                ),
                _buildSectorChip(
                  label: loc.tr('coastalAlerts'),
                  icon: Icons.waves_rounded,
                  isSelected: controller.selectedSector == 'fishing',
                  onSelected: () => controller.setSector('fishing'),
                  isDark: isDark,
                ),
                _buildSectorChip(
                  label: loc.tr('plantationAlerts'),
                  icon: Icons.terrain_rounded,
                  isSelected: controller.selectedSector == 'plantation',
                  onSelected: () => controller.setSector('plantation'),
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // District Filter Dropdown
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF006D77)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.selectedDistrict ?? 'All Districts',
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _districts.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(
                          d == 'All Districts' ? (isMl ? 'എല്ലാ ജില്ലകളും' : 'All Districts') : d,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null || val == 'All Districts') {
                        controller.setDistrict(null);
                      } else {
                        controller.setDistrict(val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    final activeColor = isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77);
    final activeFg = isDark ? Colors.black : Colors.white;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? activeFg : (isDark ? Colors.white70 : Colors.black87),
      ),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: activeColor,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
        color: isSelected ? activeFg : null,
      ),
    );
  }

  Widget _buildAlertCard(
    SafetyAlert alert,
    AlertController controller,
    bool isMl,
    bool isDark,
  ) {
    final isRead = controller.isRead(alert.id);
    final severityColor = _getSeverityColor(alert.severity);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isRead ? 0.5 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isRead
              ? (isDark ? Colors.white12 : Colors.black12)
              : severityColor.withValues(alpha: 0.6),
          width: isRead ? 0.8 : 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity + Category + Demo Badge Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: severityColor, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getHazardIcon(alert.hazardType), size: 14, color: severityColor),
                      const SizedBox(width: 4),
                      Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: severityColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    alert.category == 'coastal'
                        ? (isMl ? 'തീരദേശം' : 'Coastal')
                        : alert.category == 'plantation'
                            ? (isMl ? 'മലയോരം / തോട്ടം' : 'Hill / Plantation')
                            : (isMl ? 'പൊതു ജാഗ്രത' : 'General'),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),

                // Demo Notice Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    border: Border.all(color: const Color(0xFF856404), width: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEMO DATA',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF856404),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Alert Title
            Text(
              alert.getTitle(isMl),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),

            // Affected Districts & Timing
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: Color(0xFF006D77)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    alert.affectedDistricts.join(', '),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF006D77),
                    ),
                  ),
                ),
                Text(
                  alert.issuedAt,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              alert.getDescription(isMl),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),

            // Recommended Actions Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: Color(0xFF006D77)),
                      const SizedBox(width: 6),
                      Text(
                        isMl ? 'ശ്രദ്ധിക്കേണ്ട കാര്യങ്ങൾ:' : 'What to do:',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006D77),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...alert.getRecommendedActions(isMl).map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(
                                  action,
                                  style: const TextStyle(fontSize: 12.5, height: 1.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Source & Read status toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${isMl ? "ഉറവിടം:" : "Source:"} ${alert.source}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => controller.toggleReadStatus(alert.id),
                  icon: Icon(
                    isRead ? Icons.mark_email_unread_outlined : Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: Text(
                    isRead
                        ? (isMl ? 'വായിക്കാത്തത്' : 'Mark unread')
                        : (isMl ? 'വായിച്ചു' : 'Mark as read'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LocalizationService loc, bool isMl, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 14),
            Text(
              loc.tr('noAlertsFound'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isMl
                  ? 'തിരഞ്ഞെടുത്ത മേഖലയിൽ അടിയന്തര ജാഗ്രതാനിർദ്ദേശങ്ങൾ ഒന്നും റിപ്പോർട്ട് ചെയ്തിട്ടില്ല.'
                  : 'No active safety warnings match your selected sector and district filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationRoadmapCard(bool isMl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cell_tower_rounded, color: Color(0xFF006D77), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMl
                      ? 'വെബ് പുഷ് നോട്ടിഫിക്കേഷൻ സൗകര്യം (Phase 5 Roadmap)'
                      : 'Browser Web Push Notification Architecture (Phase 5 Roadmap)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF006D77),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMl
                      ? 'യഥാർത്ഥ ഉൽപ്പാദന ഘട്ടത്തിൽ KSDMA, INCOIS, ഫോറസ്റ്റ് ഡിപ്പാർട്ട്മെന്റ് എന്നിവയുടെ തത്സമയ വെബ്‌ഹൂക്കുകൾ വഴി മത്സ്യത്തൊഴിലാളികൾക്കും തോട്ടം തൊഴിലാളികൾക്കും ബ്രൗസർ വഴിയും മൊബൈൽ വഴിയും തത്സമയ മുന്നറിയിപ്പുകൾ ലഭ്യമാകും.'
                      : 'Designed with a decoupled AlertRepository architecture to seamlessly plug in official KSDMA, INCOIS, and Forest Department CAP (Common Alerting Protocol) Web Push notifications for zero-latency community safety.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'warning':
        return const Color(0xFFE63946);
      case 'alert':
        return const Color(0xFFD97706);
      case 'advisory':
      default:
        return const Color(0xFF006D77);
    }
  }

  IconData _getHazardIcon(String hazard) {
    switch (hazard.toLowerCase()) {
      case 'high_tide':
      case 'rough_sea':
        return Icons.waves_rounded;
      case 'cyclone':
        return Icons.cyclone_rounded;
      case 'landslide':
        return Icons.terrain_rounded;
      case 'wildlife':
        return Icons.pets_rounded;
      case 'heavy_rain':
        return Icons.thunderstorm_rounded;
      default:
        return Icons.warning_rounded;
    }
  }
}
