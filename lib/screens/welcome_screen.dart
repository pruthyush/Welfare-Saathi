import 'package:flutter/material.dart';
import '../controllers/alert_controller.dart';
import '../controllers/screening_controller.dart';
import '../services/localization_service.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/language_selector.dart';

class WelcomeScreen extends StatelessWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onStartScreening;
  final VoidCallback onSampleLoaded;
  final VoidCallback onOpenDirectory;
  final AlertController? alertController;
  final VoidCallback? onOpenAlerts;

  const WelcomeScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onStartScreening,
    required this.onSampleLoaded,
    required this.onOpenDirectory,
    this.alertController,
    this.onOpenAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 620;
    final isMl = loc.currentLanguage == 'ml';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('appTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isMobile
            ? [
                IconButton(
                  tooltip: loc.tr('schemeDirectory'),
                  icon: const Icon(Icons.menu_book_rounded),
                  onPressed: onOpenDirectory,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'contrast') controller.toggleHighContrast();
                    if (val == 'font') controller.toggleLargeText();
                    if (val == 'alerts' && onOpenAlerts != null) onOpenAlerts!();
                  },
                  itemBuilder: (ctx) => [
                    if (onOpenAlerts != null)
                      PopupMenuItem(
                        value: 'alerts',
                        child: Row(
                          children: [
                            Badge(
                              isLabelVisible: (alertController?.unreadCount ?? 0) > 0,
                              label: Text('${alertController?.unreadCount ?? 0}'),
                              child: const Icon(Icons.shield_outlined, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(loc.tr('safetyAlerts')),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'contrast',
                      child: Row(
                        children: [
                          Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(loc.tr('highContrast')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'font',
                      child: Row(
                        children: [
                          Icon(controller.largeText ? Icons.text_fields : Icons.format_size, size: 20),
                          const SizedBox(width: 10),
                          Text(loc.tr('fontSize')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                LanguageSelector(loc: loc, compact: true),
                const SizedBox(width: 10),
              ]
            : [
                if (onOpenAlerts != null)
                  IconButton(
                    tooltip: loc.tr('safetyAlerts'),
                    icon: Badge(
                      isLabelVisible: (alertController?.unreadCount ?? 0) > 0,
                      label: Text('${alertController?.unreadCount ?? 0}'),
                      child: const Icon(Icons.shield_outlined),
                    ),
                    onPressed: onOpenAlerts,
                  ),
                IconButton(
                  tooltip: loc.tr('schemeDirectory'),
                  icon: const Icon(Icons.menu_book_rounded),
                  onPressed: onOpenDirectory,
                ),
                IconButton(
                  tooltip: loc.tr('highContrast'),
                  icon: Icon(controller.highContrast ? Icons.contrast : Icons.contrast_outlined),
                  onPressed: () => controller.toggleHighContrast(),
                ),
                IconButton(
                  tooltip: loc.tr('fontSize'),
                  icon: Icon(controller.largeText ? Icons.text_fields : Icons.format_size),
                  onPressed: () => controller.toggleLargeText(),
                ),
                const SizedBox(width: 8),
                LanguageSelector(loc: loc),
                const SizedBox(width: 16),
              ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Header Card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E1E1E), const Color(0xFF2A2A2A)]
                          : [const Color(0xFF006D77), const Color(0xFF0F4C5C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.tr('appTitle'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isMl ? 'തോട്ടം & മത്സ്യത്തൊഴിലാളി ക്ഷേമസഹായി' : 'Plantation & Fisherfolk Welfare Assistant',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFFFD166) : const Color(0xFFFFDDD2),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loc.tr('appSubtitle'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        loc.tr('welcomeBanner'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mandatory Official Disclaimer
                DisclaimerBanner(loc: loc),

                const SizedBox(height: 28),

                // Primary Action Button
                ElevatedButton.icon(
                  onPressed: onStartScreening,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                  label: Text(
                    loc.tr('startScreening'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: onOpenDirectory,
                  icon: const Icon(Icons.menu_book_rounded, size: 20),
                  label: Text(
                    isMl
                        ? 'എല്ലാ 16 ക്ഷേമപദ്ധതികളും കാണുക (Scheme Directory)'
                        : 'Browse All 16 Verified Schemes & Handbook',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 12),

                // Community Safety Alerts Banner
                if (onOpenAlerts != null)
                  InkWell(
                    onTap: onOpenAlerts,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB),
                        border: Border.all(
                          color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      loc.tr('safetyAlerts'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFF856404), width: 0.5),
                                      ),
                                      child: Text(
                                        isMl ? 'ഡെമോ' : 'DEMO',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF856404),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isMl
                                      ? 'തീരദേശ & മലയോര തോട്ടം സുരക്ഷാ ജാഗ്രതാ നിർദ്ദേശങ്ങൾ'
                                      : 'Coastal & Hill Plantation Safety Advisories (INCOIS / KSDMA)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Organiser / Benchmark Sample Profiles section
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        loc.tr('loadSampleProfile'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 16),

                ...controller.repository.sampleProfiles.map((sample) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE0F2F1),
                        child: Icon(
                          sample.profile.occupation == 'fishing'
                              ? Icons.phishing_rounded
                              : sample.profile.occupation == 'plantation'
                                  ? Icons.eco_rounded
                                  : Icons.work_outline_rounded,
                          color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                        ),
                      ),
                      title: Text(
                        sample.getTitle(isMl),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Text(
                        sample.getDescription(isMl),
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        controller.loadSampleProfile(sample);
                        onSampleLoaded();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
