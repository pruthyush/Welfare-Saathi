import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/eligibility_result.dart';
import '../models/household_profile.dart';
import '../services/localization_service.dart';
import '../services/self_declaration_service.dart';
import '../widgets/app_back_button.dart';

/// Akshaya e-Centre Fast-Track Operator Terminal (USP 1)
///
/// Designed specifically for Akshaya operators and village desk officers to
/// review the applicant's pre-screened entitlements, verify physical documents,
/// and fast-track online portal uploads without manual data re-entry.
class FastTrackOperatorScreen extends StatefulWidget {
  final HouseholdProfile profile;
  final List<EligibilityResult> results;
  final LocalizationService loc;
  final VoidCallback onBack;

  const FastTrackOperatorScreen({
    super.key,
    required this.profile,
    required this.results,
    required this.loc,
    required this.onBack,
  });

  @override
  State<FastTrackOperatorScreen> createState() => _FastTrackOperatorScreenState();
}

class _FastTrackOperatorScreenState extends State<FastTrackOperatorScreen> {
  final Set<String> _verifiedDocs = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMl = widget.loc.isMalayalam;

    final potentialSchemes = widget.results.where((r) => r.isPotentiallyEligible).toList();
    final p = widget.profile;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          tooltip: widget.loc.tr('back'),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMl ? 'അക്ഷയ ഓപ്പറേറ്റർ ഫാസ്റ്റ് ട്രാക്ക് ടെർമിനൽ' : 'Akshaya Fast-Track Operator Terminal',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              isMl ? 'ഔദ്യോഗിക പോർട്ടൽ പ്രോസസ്സിംഗ് ഗൈഡ്' : 'Official Kerala Welfare Processing Roster',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isMl ? 'സത്യപ്രസ്താവന പ്രിന്റ് ചെയ്യുക' : 'Print Self-Declaration',
            icon: const Icon(Icons.assignment_turned_in_rounded),
            onPressed: () => SelfDeclarationService.exportAffidavit(
              profile: p,
              loc: widget.loc,
              share: false,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            children: [
              // Operator Intake Header Banner
              _buildOperatorHeader(isMl, isDark),
              const SizedBox(height: 16),

              // Profile Verification Summary Box
              _buildProfileSummaryCard(p, isMl, isDark),
              const SizedBox(height: 20),

              // Matched Schemes & Portal Routes
              Text(
                isMl
                  ? 'അപേക്ഷ സമർപ്പിക്കേണ്ട പോർട്ടലുകൾ (${potentialSchemes.length})'
                  : 'Target Portals & Actionable Schemes (${potentialSchemes.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              if (potentialSchemes.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMl
                        ? 'നിലവിലെ ഉത്തരങ്ങൾ പ്രകാരം നേരിട്ട് അപേക്ഷിക്കാവുന്ന പദ്ധതികൾ കണ്ടെത്തിയിട്ടില്ല.'
                        : 'No schemes met all mandatory criteria under current declarations.',
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                )
              else
                ...potentialSchemes.map((r) => _buildSchemeOperatorCard(r, isMl, isDark)),

              const SizedBox(height: 20),

              // Government Fee Cap Compliance Box
              _buildFeeCapCard(isMl, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatorHeader(bool isMl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMl ? 'അക്ഷയ ഓപ്പറേറ്റർ നിർദ്ദേശങ്ങൾ' : 'Akshaya Verification Protocol',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isMl
                      ? 'അപേക്ഷകന്റെ റേഷൻ കാർഡും ക്ഷേമനിധി പാസ്ബുക്കും പരിശോധിച്ച് താഴെ പറയുന്ന പോർട്ടലുകളിൽ നേരിട്ട് അപേക്ഷ രജിസ്റ്റർ ചെയ്യാം.'
                      : 'Verify original ration card & passbook before uploading. Use the quick portal links below to eliminate manual re-typing.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : const Color(0xFF166534),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSummaryCard(HouseholdProfile p, bool isMl, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMl ? 'അപേക്ഷകന്റെ സാക്ഷ്യപ്പെടുത്തിയ വിവരങ്ങൾ' : 'Verified Applicant Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF006D77).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.occupation == 'fishing'
                        ? (isMl ? 'മത്സ്യമേഖല' : 'Fishing Sector')
                        : p.occupation == 'plantation'
                            ? (isMl ? 'തോട്ടം മേഖല' : 'Plantation')
                            : (isMl ? 'മറ്റ് മേഖല' : 'Other'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006D77),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _buildFieldPair('District / ജില്ല', p.district ?? 'Not specified'),
                _buildFieldPair('Age / പ്രായം', p.age != null ? '${p.age} yrs' : 'Not answered'),
                _buildFieldPair('Welfare Board', p.isBoardMember == true ? 'Member (${p.yearsOfMembership ?? 0} yrs)' : 'Not Registered'),
                _buildFieldPair('Ration Card', p.rationCardCategory ?? 'Not answered'),
                _buildFieldPair('Monthly Income', p.monthlyIncome != null ? '₹${p.monthlyIncome}' : 'Not stated'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldPair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSchemeOperatorCard(EligibilityResult result, bool isMl, bool isDark) {
    final s = result.scheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF006D77), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.getName(isMl),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF006D77)),
                  ),
                  child: Text(
                    s.id,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF006D77)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.getDepartment(isMl),
              style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65)),
            ),
            const Divider(height: 16),

            // Documents Verification Checklist
            Text(
              isMl ? 'പരിശോധിക്കേണ്ട ഒറിജിനൽ രേഖകൾ:' : 'Original Documents to Verify & Scan:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),
            ...s.getRequiredDocuments(isMl).map((doc) {
              final isChecked = _verifiedDocs.contains('${s.id}_$doc');
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isChecked) {
                      _verifiedDocs.remove('${s.id}_$doc');
                    } else {
                      _verifiedDocs.add('${s.id}_$doc');
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        size: 18,
                        color: isChecked ? const Color(0xFF16A34A) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc,
                          style: TextStyle(
                            fontSize: 12,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            color: isChecked ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            // Official Portal Link Action
            if (s.officialUrl != null && s.officialUrl!.isNotEmpty)
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.tryParse(s.officialUrl!);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(isMl ? 'പോർട്ടൽ തുറക്കുക' : 'Open Official Portal'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: s.officialUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isMl ? 'പോർട്ടൽ ലിങ്ക് പകർത്തി' : 'Portal link copied to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: Text(isMl ? 'പകർത്തുക' : 'Copy URL'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCapCard(bool isMl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Text(
                isMl ? 'അക്ഷയ സേവന നിരക്ക് മാർഗ്ഗരേഖ (G.O. അംഗീകരിച്ചത്)' : 'Akshaya Service Fee Transparency (Govt. Approved)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMl
                ? '• ക്ഷേമ ആനുകൂല്യ ഓൺലൈൻ അപേക്ഷ സമർപ്പണം: പരമാവധി ₹25/-\n'
                  '• രേഖകൾ സ്കാൻ ചെയ്തു അപ്‌ലോഡ് ചെയ്യൽ: പേജിന് ₹5/-\n'
                  '• രസീത് പ്രിന്റൗട്ട്: ₹3/- (അധിക തുക ഈടാക്കുന്നത് നിയമവിരുദ്ധമാണ്).'
                : '• Online Welfare Application Upload: Max ₹25/-\n'
                  '• Document Scanning & Upload: ₹5 per page\n'
                  '• Acknowledgement Receipt Print: ₹3 (Charging excess fee is punishable under Kerala IT Act).',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: isDark ? Colors.grey[300] : const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }
}
