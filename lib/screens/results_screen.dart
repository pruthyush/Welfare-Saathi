import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../controllers/alert_controller.dart';
import '../controllers/screening_controller.dart';
import '../models/eligibility_result.dart';
import '../models/scheme.dart';
import '../services/benefit_calculator_service.dart';
import '../services/localization_service.dart';
import '../services/pdf_export_service.dart';
import '../services/qr_packet_service.dart';
import '../services/self_declaration_service.dart';
import '../widgets/app_back_button.dart';
import '../widgets/language_selector.dart';
import 'fast_track_operator_screen.dart';

class ResultsScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final ValueChanged<Scheme> onSelectScheme;
  final VoidCallback onReviewAnswers;
  final VoidCallback onReset;
  final VoidCallback? onBack;
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
    this.onBack,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final isMobile = !isDesktop;

    final potentialList = controller.potentiallyEligible;
    final incompleteList = controller.moreInformationNeeded;
    final notMatchedList = controller.notMatched;

    final entitlementSummary = BenefitCalculatorService.calculateSummary(potentialList);
    final leakageReport = BenefitCalculatorService.auditLeakage(controller.profile);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          tooltip: loc.tr('back'),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              widget.onReset();
            }
          },
        ),
        title: Text(
          loc.tr('resultsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: isMobile
            ? [
                IconButton(
                  tooltip: loc.tr('exportAkshayaReport'),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  onPressed: () => _showExportDialog(context, potentialList, incompleteList),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (val) {
                    if (val == 'review') widget.onReviewAnswers();
                    if (val == 'directory' && widget.onOpenDirectory != null) widget.onOpenDirectory!();
                    if (val == 'operator') _openOperatorTerminal();
                    if (val == 'affidavit') _exportSelfDeclaration();
                    if (val == 'qr') _showFastTrackQrDialog(context, potentialList.map((r) => r.scheme.id).toList());
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'review',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(loc.tr('reviewAnswers')),
                        ],
                      ),
                    ),

                    PopupMenuItem(
                      value: 'affidavit',
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(isMl ? 'സത്യപ്രസ്താവന (Affidavit)' : 'Self-Declaration Form'),
                        ],
                      ),
                    ),
                    if (widget.onOpenDirectory != null)
                      PopupMenuItem(
                        value: 'directory',
                        child: Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(loc.tr('schemeDirectory')),
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
      body: isDesktop
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Scheme Cards TabBarView (expands across available screen)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSchemeList(potentialList, isMl, isDark),
                          _buildSchemeList(incompleteList, isMl, isDark),
                          _buildSchemeList(notMatchedList, isMl, isDark),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Summary, Leakage Audit, and Action Panel
                  SizedBox(
                    width: 420,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 12, right: 4, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildValueSummaryCard(entitlementSummary, isMl, isDark),
                          if (leakageReport != null) ...[
                            const SizedBox(height: 12),
                            _buildLeakageAuditCard(leakageReport, isMl, isDark),
                          ],
                          const SizedBox(height: 14),
                          _buildDesktopActionPanel(
                            context,
                            potentialList,
                            incompleteList,
                            isMl,
                            isDark,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Entitlement Value Summary Card
                    _buildValueSummaryCard(entitlementSummary, isMl, isDark),

                    // Entitlement Leakage Audit Warning Card (USP 2)
                    if (leakageReport != null)
                      _buildLeakageAuditCard(leakageReport, isMl, isDark),

                    // Fast-Track QR & Affidavit Action Chips Row
                    _buildActionChipsRow(context, potentialList, isMl, isDark),
                    const SizedBox(height: 8),

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
      bottomNavigationBar: isDesktop
          ? null
          : Container(
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

  Future<void> _executeExport({
    required bool isPrint,
    required bool isShare,
    required bool profile,
    required bool potential,
    required bool moreInfo,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final isMl = widget.loc.isMalayalam;
    setState(() => _isGeneratingPdf = true);

    try {
      if (isPrint) {
        await PdfExportService.printScreeningReport(
          profile: widget.controller.profile,
          results: widget.controller.results,
          loc: widget.loc,
          includeHouseholdDetails: profile,
          includePotentiallyEligible: potential,
          includeMoreInfoNeeded: moreInfo,
        );
      } else if (isShare) {
        await PdfExportService.shareScreeningReport(
          profile: widget.controller.profile,
          results: widget.controller.results,
          loc: widget.loc,
          includeHouseholdDetails: profile,
          includePotentiallyEligible: potential,
          includeMoreInfoNeeded: moreInfo,
        );
      } else {
        await PdfExportService.downloadScreeningReport(
          profile: widget.controller.profile,
          results: widget.controller.results,
          loc: widget.loc,
          includeHouseholdDetails: profile,
          includePotentiallyEligible: potential,
          includeMoreInfoNeeded: moreInfo,
        );
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isMl
                  ? 'അക്ഷയ സ്ക്രീനിംഗ് റിപ്പോർട്ട് വിജയകരമായി തയ്യാറാക്കി.'
                  : 'Akshaya Screening Report prepared successfully.',
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isAndroidOrMobile = !kIsWeb || screenWidth < 620;

    if (isAndroidOrMobile) {
      // Android / Mobile Outlay: Modal Bottom Sheet with WhatsApp Sharing & Print
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF006D77), size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isMl ? 'അക്ഷയ റിപ്പോർട്ട് തയ്യാറാക്കുക' : 'Prepare Akshaya Report',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMl
                        ? 'അക്ഷയ കേന്ദ്രത്തിൽ ഹാജരാക്കുന്നതിനുള്ള സ്ക്രീനിംഗ് സംഗ്രഹം.'
                        : 'Print-ready screening summary for Akshaya / Welfare Board.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(height: 20),

                  CheckboxListTile(
                    value: includeProfile,
                    title: Text(
                      isMl ? 'കുടുംബ വിവരങ്ങൾ' : 'Household Profile',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      isMl ? 'തൊഴിൽ, പ്രായം, റേഷൻ കാർഡ്, ക്ഷേമനിധി' : 'Sector, age, ration card, board tenure',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setSheetState(() => includeProfile = val ?? true),
                  ),
                  CheckboxListTile(
                    value: includePotential,
                    title: Text(
                      isMl
                          ? 'സാധ്യതയുള്ള പദ്ധതികൾ (${potentialList.length})'
                          : 'Potentially Eligible (${potentialList.length})',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setSheetState(() => includePotential = val ?? true),
                  ),
                  CheckboxListTile(
                    value: includeMoreInfo,
                    title: Text(
                      isMl
                          ? 'വിവരം ആവശ്യമുള്ളവ (${incompleteList.length})'
                          : 'More Info Needed (${incompleteList.length})',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setSheetState(() => includeMoreInfo = val ?? true),
                  ),

                  const SizedBox(height: 16),

                  // Mobile Action Buttons: Share to WhatsApp / Files & Print
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (!includePotential && !includeMoreInfo && !includeProfile)
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _executeExport(
                                    isPrint: true,
                                    isShare: false,
                                    profile: includeProfile,
                                    potential: includePotential,
                                    moreInfo: includeMoreInfo,
                                  );
                                },
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: Text(isMl ? 'പ്രിന്റ്' : 'Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: (!includePotential && !includeMoreInfo && !includeProfile)
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _executeExport(
                                    isPrint: false,
                                    isShare: true,
                                    profile: includeProfile,
                                    potential: includePotential,
                                    moreInfo: includeMoreInfo,
                                  );
                                },
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            isMl ? 'പങ്കിടുക (WhatsApp)' : 'Share (WhatsApp/Files)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006D77),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
      return;
    }

    // Web & Windows Desktop Outlay: Centered Dialog with direct download and print
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
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => includeMoreInfo = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(loc.tr('cancel')),
              ),
              OutlinedButton.icon(
                onPressed: (!includePotential && !includeMoreInfo && !includeProfile)
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _executeExport(
                          isPrint: true,
                          isShare: false,
                          profile: includeProfile,
                          potential: includePotential,
                          moreInfo: includeMoreInfo,
                        );
                      },
                icon: const Icon(Icons.print_rounded),
                label: Text(isMl ? 'പ്രിന്റ്' : 'Print'),
              ),
              ElevatedButton.icon(
                onPressed: (!includePotential && !includeMoreInfo && !includeProfile)
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _executeExport(
                          isPrint: false,
                          isShare: false,
                          profile: includeProfile,
                          potential: includePotential,
                          moreInfo: includeMoreInfo,
                        );
                      },
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  isMl ? 'ഡൗൺലോഡ് (PDF)' : 'Download PDF',
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

  void _openOperatorTerminal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => FastTrackOperatorScreen(
          profile: widget.controller.profile,
          results: widget.controller.results,
          loc: widget.loc,
          onBack: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _exportSelfDeclaration({bool share = false}) async {
    try {
      await SelfDeclarationService.exportAffidavit(
        profile: widget.controller.profile,
        loc: widget.loc,
        share: share,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.loc.isMalayalam
                  ? 'സത്യപ്രസ്താവന (Affidavit) വിജയകരമായി തയ്യാറാക്കി.'
                  : 'Self-Declaration Affidavit generated successfully.',
            ),
            backgroundColor: const Color(0xFF006D77),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFastTrackQrDialog(BuildContext context, List<String> matchedIds) {
    final payload = QrPacketService.encodePacket(
      profile: widget.controller.profile,
      matchedSchemeIds: matchedIds,
    );
    final isMl = widget.loc.isMalayalam;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF006D77), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isMl ? 'അക്ഷയ ഫാസ്റ്റ് ട്രാക്ക് QR' : 'Akshaya Fast-Track QR Packet',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMl
                  ? 'ഈ QR കോഡ് അക്ഷയ ഓപ്പറേറ്റർക്കോ വാർഡ് മെമ്പർക്കോ സ്കാൻ ചെയ്യാവുന്നതാണ്. സ്വകാര്യ രേഖകൾ സുരക്ഷിതമായി കൈമാറാം.'
                  : 'Show this offline QR packet to the Akshaya operator to eliminate manual data entry.',
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF006D77), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.qr_code_rounded, size: 140, color: Color(0xFF006D77)),
                  const SizedBox(height: 6),
                  Text(
                    '${matchedIds.length} Schemes Verified Offline',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006D77)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Zero-PII Encrypted Packet | Offline Portable',
              style: TextStyle(fontSize: 10.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Token: ${payload.length > 16 ? "${payload.substring(0, 16)}..." : payload}',
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey[700]),
                ),
                IconButton(
                  tooltip: 'Copy Payload',
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: payload));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isMl ? 'കോഡ് കോപ്പി ചെയ്തു' : 'Payload token copied'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.loc.tr('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openOperatorTerminal();
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(isMl ? 'ഓപ്പറേറ്റർ വ്യൂ കാണുക' : 'Open Operator View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueSummaryCard(EntitlementSummary summary, bool isMl, bool isDark) {
    if (summary.eligibleCount == 0) return const SizedBox.shrink();

    final formattedTotal = BenefitCalculatorService.formatCurrency(summary.totalFirstYearPotential);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F3D3E), const Color(0xFF164E63)]
              : [const Color(0xFF006D77), const Color(0xFF0F4C5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showValueBreakdownSheet(context, summary, isMl, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.currency_rupee_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isMl ? 'പ്രതീക്ഷിക്കുന്ന ഒന്നാം വർഷ ആനുകൂല്യം' : 'Estimated 1st Year Benefit Value',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹$formattedTotal /-',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (summary.monthlyRecurring > 0)
                            Text(
                              isMl
                                  ? '+ പ്രതിമാസം ₹${summary.monthlyRecurring} പെൻഷൻ'
                                  : '+ Monthly ₹${summary.monthlyRecurring} recurring pension',
                              style: const TextStyle(color: Color(0xFFFFD166), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD166),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${summary.eligibleCount} ${isMl ? "പദ്ധതികൾ" : "Schemes"}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isMl ? 'വിശദാംശങ്ങൾ കാണുക' : 'View Itemized Breakdown',
                      style: const TextStyle(color: Color(0xFFFFD166), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFD166), size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showValueBreakdownSheet(BuildContext context, EntitlementSummary summary, bool isMl, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder: (ctx, scrollController) => Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calculate_rounded, color: Color(0xFF006D77), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMl ? 'ഒന്നാം വർഷ ആനുകൂല്യങ്ങളുടെ കണക്കുകൂട്ടൽ' : '1st Year Entitlement Breakdown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            Text(
                              isMl
                                  ? '${summary.eligibleCount} അർഹതയുള്ള പദ്ധതികളുടെ ആകെ തുക'
                                  : 'Exact breakdown across ${summary.eligibleCount} matched schemes',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006D77),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          isMl ? 'ആകെ തുക' : 'Total Value',
                          '₹${BenefitCalculatorService.formatCurrency(summary.totalFirstYearPotential)}',
                          Colors.white,
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        _buildStatColumn(
                          isMl ? 'ഒറ്റത്തവണ' : 'One-Time',
                          '₹${BenefitCalculatorService.formatCurrency(summary.oneTimeGrants)}',
                          const Color(0xFFFFD166),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        _buildStatColumn(
                          isMl ? 'വാർഷികം' : 'Annual Relief',
                          '₹${BenefitCalculatorService.formatCurrency(summary.annualRecurring)}',
                          Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMl ? 'പദ്ധതി തിരിച്ചുള്ള ആനുകൂല്യങ്ങൾ:' : 'Scheme-by-Scheme Itemized Calculation:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: summary.items.length,
                      itemBuilder: (ctx, i) {
                        final item = summary.items[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.25)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF006D77).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.schemeId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                          color: Color(0xFF006D77),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isMl ? item.schemeNameMl : item.schemeNameEn,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '₹${BenefitCalculatorService.formatCurrency(item.firstYearTotal)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFF006D77),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isMl ? item.benefitDescriptionMl : item.benefitDescriptionEn,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (item.oneTimeAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006D77).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${isMl ? "ഒറ്റത്തവണ ഗ്രാന്റ്:" : "One-Time:"} ₹${BenefitCalculatorService.formatCurrency(item.oneTimeAmount)}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F4C5C),
                                          ),
                                        ),
                                      ),
                                    if (item.annualAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006D77).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${isMl ? "വാർഷിക ധനസഹായം:" : "Annual Aid:"} ₹${BenefitCalculatorService.formatCurrency(item.annualAmount)}',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F4C5C),
                                          ),
                                        ),
                                      ),
                                    if (item.monthlyAmount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD97706).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${isMl ? "പ്രതിമാസം:" : "Monthly:"} ₹${item.monthlyAmount} (₹${item.monthlyAmount * 12}/yr)',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFD97706),
                                          ),
                                        ),
                                      ),
                                    if (item.insuranceCover > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${isMl ? "പരിരക്ഷ:" : "Risk Cover:"} ₹${BenefitCalculatorService.formatCurrency(item.insuranceCover)} (${isMl ? "അപകട പരിരക്ഷ" : "Accidental Cover"})',
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0369A1),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isMl
                          ? '* ആകെ തുക കണക്കാക്കിയത് ലഭിക്കാൻ സാധ്യതയുള്ള ഒറ്റത്തവണ ഗ്രാന്റുകളും ആദ്യ 12 മാസത്തെ ആവർത്തന ആനുകൂല്യങ്ങളും ചേർത്താണ്. അന്തിമ തുക അധികാരികളുടെ പരിശോധനക്ക് വിധേയമാണ്.'
                          : '* Total 1st year value aggregates one-time grants plus 12 months of recurring benefits for all potentially eligible schemes. Final sanction is subject to department verification.',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeakageAuditCard(LeakageReport leakage, bool isMl, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF331D12) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showLeakageBreakdownSheet(context, leakage, isMl, isDark),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.trending_down_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMl
                            ? 'അവകാശ നഷ്ട ഓഡിറ്റ് (Entitlement Leakage Audit)'
                            : 'Entitlement Leakage Audit (Unclaimed Benefits)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isMl ? 'നഷ്ടം' : 'MISSED',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isMl ? leakage.urgencyMessageMl : leakage.urgencyMessageEn,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.grey[200] : const Color(0xFF78350F),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isMl ? 'നഷ്ടക്കണക്കുകൾ പരിശോധിക്കുക' : 'View Missed Breakdown',
                      style: const TextStyle(color: Color(0xFFB45309), fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFFB45309), size: 14),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLeakageBreakdownSheet(BuildContext context, LeakageReport leakage, bool isMl, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.90,
            minChildSize: 0.45,
            builder: (ctx, scrollController) => Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.trending_down_rounded, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMl ? 'നഷ്ടപ്പെട്ട ആനുകൂല്യങ്ങളുടെ ഓഡിറ്റ്' : 'Entitlement Leakage Audit Breakdown',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            Text(
                              isMl ? 'കഴിഞ്ഞ 3 വർഷത്തെ നഷ്ടക്കണക്ക്' : '3-Year Retroactive Unclaimed Loss Analysis',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMl ? 'ആകെ നഷ്ടപ്പെട്ട തുക (3 വർഷം)' : 'Total Retroactive 3-Yr Loss',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${BenefitCalculatorService.formatCurrency(leakage.unclaimedAmount)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMl ? '3 വർഷ നഷ്ടം' : '3 Years Missed',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isMl
                                ? 'ശ്രദ്ധിക്കുക: അപകട ഇൻഷുറൻസ് തുടങ്ങിയ ആകസ്മിക ആനുകൂല്യങ്ങൾ നഷ്ടക്കണക്കിൽ ഉൾപ്പെടുത്തിയിട്ടില്ല.'
                                : 'Note: Accidental insurance and casualty schemes are strictly excluded from missing schemes audit.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isMl ? 'നഷ്ടപ്പെട്ട പദ്ധതികളുടെ വിവരങ്ങൾ:' : 'Unclaimed Entitlement Items Breakdown:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: leakage.items.isNotEmpty ? leakage.items.length : leakage.missedItemsEn.length,
                      itemBuilder: (ctx, i) {
                        if (leakage.items.isNotEmpty) {
                          final item = leakage.items[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove_circle_outline_rounded,
                                      color: Color(0xFFD97706),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMl ? item.titleMl : item.titleEn,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${isMl ? "വാർഷിക നഷ്ടം:" : "Annual rate:"} ₹${BenefitCalculatorService.formatCurrency(item.annualAmount)} / yr × 3 yrs',
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${BenefitCalculatorService.formatCurrency(item.threeYearLoss)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return ListTile(
                            leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                            title: Text(isMl ? leakage.missedItemsMl[i] : leakage.missedItemsEn[i]),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openOperatorTerminal();
                    },
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: Text(
                      isMl
                          ? 'അക്ഷയ ഓപ്പറേറ്റർ ടെർമിനൽ തുറക്കുക (രജിസ്ട്രേഷൻ ഗൈഡ്)'
                          : 'Open Akshaya Operator View (Registration Guide)',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006D77),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildActionChipsRow(
    BuildContext context,
    List<EligibilityResult> potentialList,
    bool isMl,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showFastTrackQrDialog(
                context,
                potentialList.map((r) => r.scheme.id).toList(),
              ),
              icon: const Icon(Icons.qr_code_2_rounded, size: 16),
              label: Text(
                isMl ? 'ഫാസ്റ്റ് ട്രാക്ക് QR' : 'Fast-Track QR',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _exportSelfDeclaration(share: false),
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
              label: Text(
                isMl ? 'സത്യപ്രസ്താവന' : 'Self-Declaration',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopActionPanel(
    BuildContext context,
    List<EligibilityResult> potentialList,
    List<EligibilityResult> incompleteList,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.handyman_rounded,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl ? 'അക്ഷയ സേവന ടൂളുകൾ' : 'Akshaya Verification Tools',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      isMl ? 'ഔദ്യോഗിക രേഖകളും വേഗത്തിലുള്ള പ്രക്രിയയും' : 'Fast-Track Facilitation & Exports',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),

          // 1. Primary Action: Export Akshaya PDF Report
          ElevatedButton.icon(
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
              isMl ? 'അക്ഷയ റിപ്പോർട്ട് (PDF)' : 'Export Akshaya PDF Report',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Self-Declaration Affidavit Form (PDF)
          OutlinedButton.icon(
            onPressed: () => _exportSelfDeclaration(share: false),
            icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
            label: Text(
              isMl ? 'സത്യപ്രസ്താവന ഫോം (Affidavit PDF)' : 'Self-Declaration Affidavit (PDF)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),

          // 5. Review / Edit Answers
          TextButton.icon(
            onPressed: widget.onReviewAnswers,
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: Text(
              isMl ? 'വിവരങ്ങൾ തിരുത്തുക / മാറ്റുക' : 'Review / Edit Answers',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),

          // 6. Reset & Start Fresh Screening
          TextButton.icon(
            onPressed: widget.onReset,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.grey),
            label: Text(
              widget.loc.tr('clearAll'),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
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
