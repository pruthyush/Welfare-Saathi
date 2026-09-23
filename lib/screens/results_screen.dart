import 'package:flutter/material.dart';
import '../controllers/alert_controller.dart';
import '../controllers/screening_controller.dart';
import '../models/eligibility_result.dart';
import '../models/scheme.dart';
import '../services/localization_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/language_selector.dart';

class ResultsScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final ValueChanged<Scheme> onSelectScheme;
  final VoidCallback onReviewAnswers;
  final VoidCallback onReset;
  final VoidCallback? onOpenDirectory;
  final AlertController? alertController;
  final VoidCallback? onOpenAlerts;

  const ResultsScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onSelectScheme,
    required this.onReviewAnswers,
    required this.onReset,
    this.onOpenDirectory,
    this.alertController,
    this.onOpenAlerts,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final potentialList = controller.potentiallyEligible;
    final incompleteList = controller.moreInformationNeeded;
    final notMatchedList = controller.notMatched;

    final matchingAlerts = widget.alertController?.repository.getAlertsFor(
      sector: controller.profile.occupation,
      district: controller.profile.district,
    ) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.tr('resultsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: loc.tr('exportAkshayaReport'),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _showExportDialog(context, potentialList, incompleteList),
          ),
          if (widget.onOpenDirectory != null)
            IconButton(
              tooltip: loc.tr('schemeDirectory'),
              icon: const Icon(Icons.menu_book_rounded),
              onPressed: widget.onOpenDirectory,
            ),
          TextButton.icon(
            onPressed: widget.onReviewAnswers,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(
              loc.tr('reviewAnswers'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          LanguageSelector(loc: loc),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
          indicatorWeight: 3,
          labelColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(
              text: isMl
                  ? 'സാധ്യതയുള്ളവ (${potentialList.length})'
                  : 'Potentially Eligible (${potentialList.length})',
            ),
            Tab(
              text: isMl
                  ? 'വിവരം വേണം (${incompleteList.length})'
                  : 'More Info Needed (${incompleteList.length})',
            ),
            Tab(
              text: isMl
                  ? 'ചേരാത്തവ (${notMatchedList.length})'
                  : 'Not Matched (${notMatchedList.length})',
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            children: [
              // Top Notice Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: DisclaimerBanner(loc: loc, compact: true),
              ),

              // Contextual Safety Advisories Banner if matching alerts exist for applicant's profile
              if (matchingAlerts.isNotEmpty && widget.onOpenAlerts != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: InkWell(
                    onTap: () {
                      widget.alertController?.syncWithProfile(
                        sector: controller.profile.occupation,
                        district: controller.profile.district,
                      );
                      widget.onOpenAlerts!();
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF261D12) : const Color(0xFFFFFBEB),
                        border: Border.all(
                          color: isDark ? const Color(0xFFD97706) : const Color(0xFFF59E0B),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isMl
                                  ? 'ജാഗ്രതാ നിർദ്ദേശം: ${controller.profile.district ?? ""} മേഖലയിൽ ${matchingAlerts.length} സുരക്ഷാ മുന്നറിയിപ്പുകൾ സജീവമാണ് (ഡെമോ വിവരങ്ങൾ)'
                                  : 'Safety Advisory: ${matchingAlerts.length} active alerts relevant to ${controller.profile.district ?? "your sector"} (Demo Feed)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFFD166) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isMl ? 'കാണുക' : 'View',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFFFD166) : const Color(0xFFD97706),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFD97706)),
                        ],
                      ),
                    ),
                  ),
                ),

              // Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSchemeList(potentialList, isMl, isDark),
                    _buildSchemeList(incompleteList, isMl, isDark),
                    _buildSchemeList(notMatchedList, isMl, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onReset,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(loc.tr('clearAll')),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPdf
                    ? null
                    : () => _showExportDialog(context, potentialList, incompleteList),
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded),
                label: Text(
                  isMl ? 'അക്ഷയ റിപ്പോർട്ട് (PDF)' : 'Export Akshaya PDF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    List<EligibilityResult> potentialList,
    List<EligibilityResult> incompleteList,
  ) {
    bool includeProfile = true;
    bool includePotential = potentialList.isNotEmpty;
    bool includeMoreInfo = incompleteList.isNotEmpty;

    final loc = widget.loc;
    final isMl = loc.isMalayalam;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF006D77)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMl ? 'അക്ഷയ റിപ്പോർട്ട് തയ്യാറാക്കുക' : 'Prepare Akshaya Report',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMl
                        ? 'അക്ഷയ കേന്ദ്രത്തിലോ ക്ഷേമനിധി ബോർഡ് ഓഫീസിലോ ഹാജരാക്കുന്നതിനായി വ്യക്തമായ സ്ക്രീനിംഗ് സമ്മറി പി.ഡി.എഫ് ഡൗൺലോഡ് ചെയ്യാം.'
                        : 'Generate a clean, print-ready screening summary to present at your local Akshaya e-Centre or Welfare Fund Board.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const Divider(),
                  const SizedBox(height: 8),

                  CheckboxListTile(
                    value: includeProfile,
                    title: Text(
                      isMl ? 'കുടുംബ സ്ക്രീനിംഗ് വിവരങ്ങൾ ഉൾപ്പെടുത്തുക' : 'Include Household Screening Profile',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isMl ? 'തൊഴിൽ, പ്രായം, റേഷൻ കാർഡ്, ക്ഷേമനിധി അംഗത്വം' : 'Sector, age, ration card, board tenure',
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => includeProfile = val ?? true),
                  ),

                  CheckboxListTile(
                    value: includePotential,
                    title: Text(
                      isMl
                          ? 'സാധ്യതയുള്ള പദ്ധതികൾ (${potentialList.length})'
                          : 'Potentially Eligible Schemes (${potentialList.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isMl ? 'നിബന്ധനകൾ, ആവശ്യമായ രേഖകൾ, അപേക്ഷാ മാർഗ്ഗം' : 'Criteria matched, required documents, next steps',
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => includePotential = val ?? true),
                  ),

                  CheckboxListTile(
                    value: includeMoreInfo,
                    title: Text(
                      isMl
                          ? 'വിവരം ആവശ്യമുള്ള പദ്ധതികൾ (${incompleteList.length})'
                          : 'More Information Needed (${incompleteList.length})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isMl ? 'പരിശോധിക്കേണ്ട രേഖകളും ഒഴിവാക്കിയ വിവരങ്ങളും' : 'Missing criteria and documents to clarify at Akshaya',
                      style: const TextStyle(fontSize: 12),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => includeMoreInfo = val ?? true),
                  ),

                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 18, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMl
                                ? 'സ്വകാര്യതാ സുരക്ഷ: ആധാർ നമ്പറോ ഫോൺ നമ്പറോ രേഖകളിൽ സൂക്ഷിക്കുന്നില്ല.'
                                : 'Privacy: No Aadhaar or phone numbers are included or stored.',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.tr('cancel')),
              ),
              ElevatedButton.icon(
                onPressed: (!includePotential && !includeMoreInfo && !includeProfile)
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final messenger = ScaffoldMessenger.of(context);
                        setState(() => _isGeneratingPdf = true);
                        try {
                          await PdfExportService.downloadScreeningReport(
                            profile: widget.controller.profile,
                            results: widget.controller.results,
                            loc: widget.loc,
                            includeHouseholdDetails: includeProfile,
                            includePotentiallyEligible: includePotential,
                            includeMoreInfoNeeded: includeMoreInfo,
                          );
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  isMl
                                      ? 'അക്ഷയ സ്ക്രീനിംഗ് റിപ്പോർട്ട് വിജയകരമായി തയ്യാറാക്കി ഡൗൺലോഡ് ചെയ്തു.'
                                      : 'Akshaya Screening Report downloaded successfully.',
                                ),
                                backgroundColor: const Color(0xFF006D77),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Export error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isGeneratingPdf = false);
                          }
                        }
                      },
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  isMl ? 'ഡൗൺലോഡ് ചെയ്യുക (PDF)' : 'Download PDF',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSchemeList(
    List<EligibilityResult> results,
    bool isMl,
    bool isDark,
  ) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                isMl ? 'ഈ വിഭാഗത്തിൽ പദ്ധതികളൊന്നും കണ്ടെത്താനായില്ല.' : 'No schemes in this category.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildSchemeCard(result, isMl, isDark);
      },
    );
  }

  Widget _buildSchemeCard(
    EligibilityResult result,
    bool isMl,
    bool isDark,
  ) {
    final scheme = result.scheme;
    final whyMatched = result.getWhyMatchedExplanations(isMl);
    final missingPrompts = result.getMissingPrompts(isMl);
    final unmetReasons = result.getUnmetReasons(isMl);
    final docs = scheme.getRequiredDocuments(isMl);
    final channels = scheme.getApplicationChannels(isMl);

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;

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

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge (STRICTLY "Potentially Eligible", never "You are eligible")
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 16, color: badgeText),
                  const SizedBox(width: 6),
                  Text(
                    result.getStatusLabel(isMl),
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scheme Name
            Text(
              scheme.getName(isMl),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scheme.getDepartment(isMl),
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const Divider(height: 24),

            // 1. Why Matched or Missing / Unmet Section
            if (result.isPotentiallyEligible) ...[
              Text(
                widget.loc.tr('whyMatched'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...whyMatched.take(3).map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
            ] else if (result.isMoreInformationRequired) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    widget.loc.tr('missingRequirement'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...missingPrompts.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $m',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  )),
            ] else ...[
              Text(
                widget.loc.tr('unmetRequirement'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
              const SizedBox(height: 8),
              ...unmetReasons.take(2).map((u) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      u,
                      style: const TextStyle(fontSize: 13, color: Colors.red),
                    ),
                  )),
            ],

            const SizedBox(height: 16),

            // 2. Documents Required Snapshot
            Text(
              '${widget.loc.tr('documentsRequired')}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...docs.take(2).map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          doc,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            if (docs.length > 2)
              Text(
                isMl ? '+ ${docs.length - 2} രേഖകൾ കൂടി...' : '+ ${docs.length - 2} more documents...',
                style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 12),

            // 3. Where to Apply Snapshot
            if (channels.isNotEmpty) ...[
              Text(
                '${widget.loc.tr('whereToApply')}:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pin_drop_outlined, size: 16, color: Colors.teal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      channels.first,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // Action: View Details
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => widget.onSelectScheme(scheme),
                icon: const Icon(Icons.description_outlined, size: 18),
                label: Text(widget.loc.tr('viewDetails')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
