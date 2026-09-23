import 'package:flutter/material.dart';
import '../controllers/screening_controller.dart';
import '../models/scheme.dart';
import '../services/localization_service.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/language_selector.dart';

class SchemeDirectoryScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final ValueChanged<Scheme> onSelectScheme;
  final VoidCallback onStartScreening;
  final VoidCallback onBack;

  const SchemeDirectoryScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onSelectScheme,
    required this.onStartScreening,
    required this.onBack,
  });

  @override
  State<SchemeDirectoryScreen> createState() => _SchemeDirectoryScreenState();
}

class _SchemeDirectoryScreenState extends State<SchemeDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSector = 'all'; // 'all', 'fishing', 'plantation'
  String _selectedBenefitType = 'all'; // 'all', 'pension', 'housing', 'education', 'medical', 'family'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Scheme> _getFilteredSchemes() {
    final all = widget.controller.repository.schemes;

    return all.where((scheme) {
      // Sector filter
      if (_selectedSector != 'all' && scheme.category != _selectedSector) {
        return false;
      }

      // Benefit type filter
      if (_selectedBenefitType != 'all') {
        final id = scheme.id.toUpperCase();
        switch (_selectedBenefitType) {
          case 'pension':
            if (id != 'SCHEME-01' && id != 'SCHEME-10') return false;
            break;
          case 'housing':
            if (id != 'SCHEME-03' && id != 'SCHEME-06' && id != 'SCHEME-12') return false;
            break;
          case 'education':
            if (id != 'SCHEME-04' && id != 'SCHEME-07') return false;
            break;
          case 'medical':
            if (id != 'SCHEME-05' && id != 'SCHEME-08' && id != 'SCHEME-11') return false;
            break;
          case 'family':
            if (id != 'SCHEME-02' && id != 'SCHEME-09' && id != 'SCHEME-13' && id != 'SCHEME-14' && id != 'SCHEME-15' && id != 'SCHEME-16') return false;
            break;
        }
      }

      // Search keyword filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchEn = scheme.nameEn.toLowerCase().contains(q) ||
            scheme.descriptionEn.toLowerCase().contains(q) ||
            scheme.departmentEn.toLowerCase().contains(q);
        final matchMl = scheme.nameMl.toLowerCase().contains(q) ||
            scheme.descriptionMl.toLowerCase().contains(q) ||
            scheme.departmentMl.toLowerCase().contains(q);
        if (!matchEn && !matchMl) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredSchemes = _getFilteredSchemes();
    final allSchemes = widget.controller.repository.schemes;
    final fishingCount = allSchemes.where((s) => s.category == 'fishing').length;
    final plantationCount = allSchemes.where((s) => s.category == 'plantation').length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          loc.tr('schemeDirectory'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: loc.tr('startScreening'),
            icon: const Icon(Icons.how_to_reg_rounded),
            onPressed: widget.onStartScreening,
          ),
          LanguageSelector(loc: loc),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Top Search and Sector Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: loc.tr('searchSchemes'),
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF444444) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),

                    const SizedBox(height: 12),

                    // Sector Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: '${loc.tr('allSectors')} (${allSchemes.length})',
                            isSelected: _selectedSector == 'all',
                            icon: Icons.apps_rounded,
                            onTap: () => setState(() => _selectedSector = 'all'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: '${loc.tr('fishingSector')} ($fishingCount)',
                            isSelected: _selectedSector == 'fishing',
                            icon: Icons.phishing_rounded,
                            onTap: () => setState(() => _selectedSector = 'fishing'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: '${loc.tr('plantationSector')} ($plantationCount)',
                            isSelected: _selectedSector == 'plantation',
                            icon: Icons.eco_rounded,
                            onTap: () => setState(() => _selectedSector = 'plantation'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Benefit Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryTag(
                            label: isMl ? 'എല്ലാ ആനുകൂല്യങ്ങളും' : 'All Benefits',
                            isSelected: _selectedBenefitType == 'all',
                            onTap: () => setState(() => _selectedBenefitType = 'all'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildCategoryTag(
                            label: isMl ? 'പെൻഷൻ' : 'Pensions',
                            isSelected: _selectedBenefitType == 'pension',
                            onTap: () => setState(() => _selectedBenefitType = 'pension'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildCategoryTag(
                            label: isMl ? 'ഭവനം & പുനരധിവാസം' : 'Housing & Relocation',
                            isSelected: _selectedBenefitType == 'housing',
                            onTap: () => setState(() => _selectedBenefitType = 'housing'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildCategoryTag(
                            label: isMl ? 'വിദ്യാഭ്യാസം' : 'Education & Scholarships',
                            isSelected: _selectedBenefitType == 'education',
                            onTap: () => setState(() => _selectedBenefitType = 'education'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildCategoryTag(
                            label: isMl ? 'ചികിത്സ & ഇൻഷുറൻസ്' : 'Medical & Insurance',
                            isSelected: _selectedBenefitType == 'medical',
                            onTap: () => setState(() => _selectedBenefitType = 'medical'),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 6),
                          _buildCategoryTag(
                            label: isMl ? 'വിവാഹം & പ്രസവം' : 'Marriage & Maternity',
                            isSelected: _selectedBenefitType == 'family',
                            onTap: () => setState(() => _selectedBenefitType = 'family'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Disclaimer Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: DisclaimerBanner(loc: loc, compact: true),
              ),

              // Count Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMl
                          ? 'കണ്ടെത്തിയ പദ്ധതികൾ: ${filteredSchemes.length} എണ്ണം'
                          : 'Showing ${filteredSchemes.length} of ${allSchemes.length} schemes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: widget.onStartScreening,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(
                        loc.tr('checkEligibility'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Scheme Cards List
              Expanded(
                child: filteredSchemes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 56,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isMl
                                    ? 'തിരഞ്ഞെടുത്ത വിവരങ്ങൾക്ക് അനുയോജ്യമായ പദ്ധതികൾ കണ്ടെത്തിയില്ല.'
                                    : 'No schemes match your search criteria.',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredSchemes.length,
                        itemBuilder: (context, index) {
                          final scheme = filteredSchemes[index];
                          return _buildDirectoryCard(scheme, isMl, isDark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
              : (isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                : (isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white70 : const Color(0xFF006D77)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF06D6A0) : const Color(0xFFE0F2F1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF06D6A0) : const Color(0xFF006D77))
                : (isDark ? const Color(0xFF444444) : const Color(0xFFD1D5DB)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.black : const Color(0xFF004D40))
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryCard(Scheme scheme, bool isMl, bool isDark) {
    final isFishing = scheme.category == 'fishing';
    final docs = scheme.getRequiredDocuments(isMl);
    final channels = scheme.getApplicationChannels(isMl);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category & Department Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isFishing ? const Color(0xFF00838F) : const Color(0xFF558B2F),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  scheme.id,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            // Sponsoring Board / Department
            Text(
              scheme.getDepartment(isMl),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),

            const SizedBox(height: 12),

            // Overview Description
            Text(
              scheme.getDescription(isMl),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),

            const Divider(height: 24),

            // Key Eligibility Rules Preview
            Text(
              isMl ? 'പ്രധാന അർഹതാ മാനദണ്ഡങ്ങൾ:' : 'Key Eligibility Criteria:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...scheme.rules.take(3).map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isMl ? r.labelMl : r.labelEn,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // Snapshot: Docs & Application Channel
            Row(
              children: [
                Icon(Icons.folder_shared_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  isMl ? '${docs.length} രേഖകൾ ആവശ്യമാണ്' : '${docs.length} Documents Required',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                if (channels.isNotEmpty) ...[
                  const Icon(Icons.pin_drop_outlined, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      channels.first,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 18),

            // Card Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.onStartScreening,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(
                    isMl ? 'അർഹത പരിശോധിക്കുക' : 'Check Eligibility',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => widget.onSelectScheme(scheme),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: Text(
                    isMl ? 'സമ്പൂർണ്ണ വിവരങ്ങൾ' : 'Complete Information',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
