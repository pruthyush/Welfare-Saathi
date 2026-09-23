import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/screening_controller.dart';
import '../models/eligibility_rule.dart';
import '../models/scheme.dart';
import '../services/localization_service.dart';
import '../widgets/app_back_button.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/language_selector.dart';

class SchemeDetailScreen extends StatelessWidget {
  final Scheme scheme;
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onBack;
  final VoidCallback? onStartScreening;

  const SchemeDetailScreen({
    super.key,
    required this.scheme,
    required this.controller,
    required this.loc,
    required this.onBack,
    this.onStartScreening,
  });

  Future<void> _openUrl(BuildContext context, String rawUrl) async {
    final cleanUrl = rawUrl.trim();
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await Clipboard.setData(ClipboardData(text: cleanUrl));
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                loc.isMalayalam
                    ? 'ലിങ്ക് പകർത്തി: $cleanUrl'
                    : 'Link copied to clipboard: $cleanUrl',
              ),
              backgroundColor: const Color(0xFF006D77),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: cleanUrl));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              loc.isMalayalam
                  ? 'ലിങ്ക് പകർത്തി: $cleanUrl'
                  : 'Link copied to clipboard: $cleanUrl',
            ),
            backgroundColor: const Color(0xFF006D77),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    final messenger = ScaffoldMessenger.of(context);
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        await Clipboard.setData(ClipboardData(text: phone));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              loc.isMalayalam
                  ? 'ഫോൺ നമ്പർ പകർത്തി: $phone'
                  : 'Phone number copied: $phone',
            ),
            backgroundColor: const Color(0xFF006D77),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.isMalayalam
                ? 'ഫോൺ നമ്പർ പകർത്തി: $phone'
                : 'Phone number copied: $phone',
          ),
          backgroundColor: const Color(0xFF006D77),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFishing = scheme.category == 'fishing';

    // Find the specific result for this scheme if screening was run
    final hasRun = controller.hasRunScreening;
    final result = controller.results.firstWhere(
      (r) => r.scheme.id == scheme.id,
      orElse: () => controller.engine.evaluateScheme(scheme, controller.profile),
    );

    final akshayaCentres = controller.repository.getCentresForDistrict(
      controller.profile.district,
    );

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (hasRun) {
      if (result.isPotentiallyEligible) {
        badgeBg = isDark ? const Color(0xFF1B4D3E) : const Color(0xFFD1FAE5);
        badgeText = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
        badgeIcon = Icons.check_circle_rounded;
      } else if (result.isMoreInformationRequired) {
        badgeBg = isDark ? const Color(0xFF5A3A00) : const Color(0xFFFEF3C7);
        badgeText = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
        badgeIcon = Icons.help_outline_rounded;
      } else {
        badgeBg = isDark ? const Color(0xFF4C1D1D) : const Color(0xFFFEE2E2);
        badgeText = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        badgeIcon = Icons.cancel_outlined;
      }
      badgeLabel = result.getStatusLabel(isMl);
    } else {
      badgeBg = isDark ? const Color(0xFF0F3A42) : const Color(0xFFE0F7FA);
      badgeText = isDark ? const Color(0xFF4DD0E1) : const Color(0xFF006D77);
      badgeIcon = Icons.verified_user_rounded;
      badgeLabel = isMl ? 'സ്ഥിരീകരിച്ച ഔദ്യോഗിക പദ്ധതി' : 'Verified Welfare Scheme';
    }

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          tooltip: loc.tr('back'),
          onPressed: onBack,
        ),
        title: Text(
          isMl ? 'സമ്പൂർണ്ണ പദ്ധതി വിവരങ്ങൾ' : 'Complete Scheme Information',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (onStartScreening != null)
            TextButton.icon(
              onPressed: onStartScreening,
              icon: const Icon(Icons.how_to_reg_rounded),
              label: Text(
                loc.tr('startScreening'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          LanguageSelector(loc: loc),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Scheme Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status / Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon, size: 16, color: badgeText),
                                const SizedBox(width: 8),
                                Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    color: badgeText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sector Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isFishing
                                  ? (isDark ? const Color(0xFF0F3A42) : const Color(0xFFE0F7FA))
                                  : (isDark ? const Color(0xFF283618) : const Color(0xFFF1F8E9)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFishing ? Icons.phishing_rounded : Icons.eco_rounded,
                                  size: 14,
                                  color: isFishing ? const Color(0xFF00838F) : const Color(0xFF558B2F),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFishing
                                      ? (isMl ? 'മത്സ്യബന്ധന മേഖല' : 'Fishing Sector')
                                      : (isMl ? 'തോട്ടം മേഖല' : 'Plantation Sector'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isFishing ? const Color(0xFF00838F) : const Color(0xFF558B2F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        scheme.getName(isMl),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scheme.getDepartment(isMl),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        scheme.getDescription(isMl),
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 1: ELIGIBILITY CRITERIA & RULES BREAKDOWN
                _buildSectionCard(
                  title: hasRun
                      ? (isMl ? 'എന്തുകൊണ്ട് ഈ ഫലം? (Why this result?)' : 'WHY THIS RESULT?')
                      : (isMl ? 'അർഹതാ മാനദണ്ഡങ്ങളും ചട്ടങ്ങളും' : 'ELIGIBILITY RULES & CRITERIA'),
                  icon: Icons.rule_rounded,
                  isDark: isDark,
                  child: Column(
                    children: scheme.rules.map((rule) {
                      final eval = rule.evaluate(controller.profile);
                      final isSatisfied = eval.state == RuleEvaluationState.satisfied;
                      final isMissing = eval.state == RuleEvaluationState.missingInformation;

                      Color stateColor;
                      IconData stateIcon;

                      if (hasRun) {
                        stateColor = isSatisfied
                            ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                            : isMissing
                                ? Colors.orange
                                : Colors.red;

                        stateIcon = isSatisfied
                            ? Icons.check_circle_rounded
                            : isMissing
                                ? Icons.help_outline_rounded
                                : Icons.cancel_rounded;
                      } else {
                        stateColor = isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77);
                        stateIcon = Icons.check_circle_outline_rounded;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: stateColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(stateIcon, color: stateColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMl ? rule.labelMl : rule.labelEn,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (hasRun) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      isMl
                                          ? 'കുടുംബത്തിന്റെ ഉത്തരം: ${eval.actualValueFormatted}'
                                          : 'Your household answer: ${eval.actualValueFormatted}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: stateColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (isMissing)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          isMl ? rule.missingPromptMl : rule.missingPromptEn,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${isMl ? 'നിർബന്ധിത ഘടകം' : 'Required parameter'}: ${rule.field.toUpperCase()} (${rule.operator.name})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 2: DOCUMENTS REQUIRED
                _buildSectionCard(
                  title: isMl ? 'ആവശ്യമായ രേഖകൾ' : 'DOCUMENTS REQUIRED',
                  icon: Icons.folder_shared_outlined,
                  isDark: isDark,
                  child: Column(
                    children: scheme.getRequiredDocuments(isMl).map((doc) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_box_outlined,
                              color: Color(0xFF006D77),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                doc,
                                style: const TextStyle(fontSize: 14, height: 1.35),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 3: WHERE TO APPLY & AKSHAYA CENTRES
                _buildSectionCard(
                  title: isMl ? 'എവിടെ അപേക്ഷിക്കണം?' : 'WHERE TO APPLY',
                  icon: Icons.store_mall_directory_outlined,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...scheme.getApplicationChannels(isMl).map((channel) {
                        final onlineUrl = channel.contains('sevana.gov.in')
                            ? 'https://sevana.gov.in'
                            : channel.contains('edistrict.kerala.gov.in')
                                ? 'https://edistrict.kerala.gov.in'
                                : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.pin_drop_rounded, color: Colors.teal, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  channel,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (onlineUrl != null)
                                TextButton.icon(
                                  onPressed: () => _openUrl(context, onlineUrl),
                                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                  label: Text(
                                    isMl ? 'തുറക്കുക' : 'Open',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),
                      Text(
                        '${loc.tr('nearestAkshaya')} (${controller.profile.district ?? 'Kerala'}):',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 10),

                      ...akshayaCentres.map((centre) {
                        return Card(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F7F8),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  centre.getName(isMl),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  centre.getLocation(isMl),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _callPhone(context, centre.phone),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_rounded, size: 15, color: Colors.teal),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${centre.contactPerson} (${centre.phone})',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.touch_app_rounded, size: 14, color: Colors.teal),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 4: ACTIONABLE NEXT STEPS
                _buildSectionCard(
                  title: isMl ? 'തുടർനടപടികൾ' : 'NEXT STEPS',
                  icon: Icons.alt_route_rounded,
                  isDark: isDark,
                  child: Column(
                    children: scheme.getNextSteps(isMl).map((step) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF006D77),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step,
                                style: const TextStyle(fontSize: 14, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 20),

                // SECTION 5: OFFICIAL LEGAL ORDER REFERENCE
                _buildSectionCard(
                  title: isMl ? 'ഔദ്യോഗിക ചട്ട റഫറൻസ്' : 'OFFICIAL GOVERNMENT REFERENCE',
                  icon: Icons.gavel_rounded,
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Clickable Official Government Website Link Card
                      if (scheme.officialUrl != null && scheme.officialUrl!.isNotEmpty) ...[
                        InkWell(
                          onTap: () => _openUrl(context, scheme.officialUrl!),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262626) : const Color(0xFFE8F4F8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF444444) : const Color(0xFFBEE3DB),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006D77).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 20,
                                    color: Color(0xFF006D77),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMl
                                            ? 'ഔദ്യോഗിക വെബ്സൈറ്റ് സന്ദർശിക്കുക (ക്ലിക്ക് ചെയ്യുക)'
                                            : 'Click to Visit Official Government Portal',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        scheme.officialUrl!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  tooltip: isMl ? 'ലിങ്ക് പകർത്തുക' : 'Copy Link',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: scheme.officialUrl!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isMl
                                              ? 'ലിങ്ക് പകർത്തി: ${scheme.officialUrl!}'
                                              : 'Link copied to clipboard: ${scheme.officialUrl!}',
                                        ),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xFF006D77),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Statutory Government Order Reference
                      if (scheme.officialReferenceClean.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF222222) : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.article_outlined, size: 18, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${isMl ? 'സർക്കാർ ഉത്തരവ് / ചട്ടം:' : 'G.O. / Statutory Reference:'} ${scheme.officialReferenceClean}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                tooltip: isMl ? 'റഫറൻസ് പകർത്തുക' : 'Copy Reference',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: scheme.officialReferenceClean));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isMl
                                            ? 'റഫറൻസ് പകർത്തി: ${scheme.officialReferenceClean}'
                                            : 'Reference copied: ${scheme.officialReferenceClean}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      Text(
                        scheme.disclaimer,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Official Legal Disclaimer Banner
                DisclaimerBanner(loc: loc),

                const SizedBox(height: 28),

                // Screen Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: Text(
                        isMl ? 'പുറകിലേക്ക്' : 'Back',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                    if (onStartScreening != null) ...[
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: onStartScreening,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          isMl ? 'അർഹത പരിശോധിക്കുക' : 'Check Eligibility',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77), size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}
