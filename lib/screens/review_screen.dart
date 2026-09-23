import 'package:flutter/material.dart';
import '../controllers/screening_controller.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';
import '../widgets/ration_card_helper.dart';

class ReviewScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onRecalculate;
  final VoidCallback onBack;

  const ReviewScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onRecalculate,
    required this.onBack,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final p = controller.profile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(
          loc.tr('reviewAnswers'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          LanguageSelector(loc: loc),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instruction banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isMl
                              ? 'ഏതെങ്കിലും ഉത്തരം തിരുത്താൻ [മാറ്റുക] അമർത്തുക. ശേഷം [വീണ്ടും പരിശോധിക്കുക] അമർത്തുക.'
                              : 'Tap [Edit] to update any answer, then tap [Recalculate] to re-run screening.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF004D40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Table / Card of Household Answers
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow(
                          label: isMl ? 'പ്രധാന തൊഴിൽ' : 'Primary Occupation',
                          value: _formatOccupation(p.occupation, isMl),
                          onEdit: () => _editOccupationDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'അപേക്ഷകന്റെ പ്രായം' : 'Applicant Age',
                          value: p.age != null ? '${p.age} ${isMl ? 'വയസ്സ്' : 'years'}' : (isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Not provided'),
                          onEdit: () => _editAgeDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'ജില്ല' : 'District',
                          value: p.district ?? (isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not selected'),
                          onEdit: () => _editDistrictDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'പ്രതിമാസ വരുമാനം' : 'Monthly Income',
                          value: p.monthlyIncome != null
                              ? '₹${p.monthlyIncome}'
                              : (isMl ? 'ഒഴിവാക്കി (Skipped)' : 'Skipped / Missing'),
                          valueColor: p.monthlyIncome == null ? Colors.orange : null,
                          onEdit: () => _editIncomeDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'ക്ഷേമനിധി ബോർഡ് അംഗത്വം' : 'Board Membership',
                          value: p.isBoardMember == true
                              ? (isMl ? 'ഉണ്ട്' : 'Yes')
                              : p.isBoardMember == false
                                  ? (isMl ? 'ഇല്ല' : 'No')
                                  : (isMl ? 'വ്യക്തമല്ല' : 'Unsure'),
                          onEdit: () => _editBoardDialog(context),
                        ),
                        if (p.isBoardMember == true) ...[
                          const Divider(),
                          _buildRow(
                            label: isMl ? 'അംഗത്വ കാലാവധി' : 'Years of Membership',
                            value: p.yearsOfMembership != null
                                ? '${p.yearsOfMembership} ${isMl ? 'വർഷം' : 'years'}'
                                : (isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Not provided'),
                            onEdit: () => _editYearsDialog(context),
                          ),
                        ],
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'റേഷൻ കാർഡ് വിഭാഗം' : 'Ration Card',
                          value: p.rationCardCategory != null
                              ? RationCardOption.getByCode(p.rationCardCategory).getLabel(isMl)
                              : (isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not selected'),
                          onEdit: () => _editRationCardDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'ഭവന സാഹചര്യം' : 'Housing Condition',
                          value: _formatHousing(p.housingCondition, isMl),
                          onEdit: () => _editHousingDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'പഠിക്കുന്ന കുട്ടികൾ' : 'Student Dependent',
                          value: p.hasStudentChild == true
                              ? (isMl ? 'ഉണ്ട്' : 'Yes')
                              : p.hasStudentChild == false
                                  ? (isMl ? 'ഇല്ല' : 'No')
                                  : (isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Not answered / Unsure'),
                          onEdit: () => _editStudentDialog(context),
                        ),
                        const Divider(),
                        _buildRow(
                          label: isMl ? 'പ്രത്യേക സാഹചര്യം' : 'Special Status',
                          value: p.specialStatus ?? 'none',
                          onEdit: () => _editSpecialStatusDialog(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Recalculate Button
                ElevatedButton.icon(
                  onPressed: () {
                    widget.controller.evaluateCurrentProfile();
                    widget.onRecalculate();
                  },
                  icon: const Icon(Icons.sync_rounded, size: 24),
                  label: Text(
                    loc.tr('recalculate'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    Color? valueColor,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: valueColor,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: Text(widget.loc.tr('edit')),
          ),
        ],
      ),
    );
  }

  String _formatOccupation(String? occ, bool isMl) {
    if (occ == 'fishing') {
      return isMl ? 'മത്സ്യത്തൊഴിലാളി' : 'Fishing / Allied';
    } else if (occ == 'plantation') {
      return isMl ? 'തോട്ടം തൊഴിലാളി' : 'Plantation Worker';
    } else if (occ == 'other') {
      return isMl ? 'മറ്റ് തൊഴിൽ' : 'Other / General';
    }
    return isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not selected';
  }

  String _formatHousing(String? h, bool isMl) {
    if (h == 'dilapidated') {
      return isMl ? 'ജീർണ്ണിച്ച ലയം / കൂര' : 'Dilapidated / Layam';
    } else if (h == 'homeless') {
      return isMl ? 'ഭവനരഹിതർ' : 'Homeless / No land';
    } else if (h == 'kutcha') {
      return isMl ? 'താൽക്കാലിക വീട്' : 'Kutcha House';
    } else if (h == 'pucca') {
      return isMl ? 'കോൺക്രീറ്റ് വീട്' : 'Pucca House';
    }
    return isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല / ഉറപ്പില്ല' : 'Not answered / Unsure';
  }

  // Edit Dialogs
  void _editOccupationDialog(BuildContext context) {
    final selected = widget.controller.profile.occupation;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.loc.tr('occupationLabel')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String?>(
              title: Text(widget.loc.isMalayalam ? 'തിരഞ്ഞെടുത്തിട്ടില്ല (രേഖപ്പെടുത്തിയിട്ടില്ല)' : 'Not selected / Unsure'),
              value: null,
              groupValue: selected,
              onChanged: (v) {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearOccupation: true),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            RadioListTile<String?>(
              title: Text(widget.loc.tr('occupationFishing')),
              value: 'fishing',
              groupValue: selected,
              onChanged: (v) {
                if (v != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(occupation: v),
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(widget.loc.tr('occupationPlantation')),
              value: 'plantation',
              groupValue: selected,
              onChanged: (v) {
                if (v != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(occupation: v),
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
            RadioListTile<String?>(
              title: Text(widget.loc.tr('occupationOther')),
              value: 'other',
              groupValue: selected,
              onChanged: (v) {
                if (v != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(occupation: v),
                  );
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editAgeDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.controller.profile.age?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.loc.tr('ageLabel')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.loc.tr('ageHint'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearAge: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.isMalayalam ? 'ഒഴിവാക്കുക' : 'Clear / Unset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.loc.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearAge: true),
                );
              } else {
                final age = int.tryParse(text);
                if (age != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(age: age),
                  );
                }
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('save')),
          ),
        ],
      ),
    );
  }

  void _editDistrictDialog(BuildContext context) {
    final districts = ['Alappuzha', 'Ernakulam', 'Idukki', 'Wayanad', 'Kollam', 'Thiruvananthapuram', 'Kozhikode', 'Thrissur'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('districtLabel')),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearDistrict: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                widget.loc.isMalayalam ? 'തിരഞ്ഞെടുത്തിട്ടില്ല (രേഖപ്പെടുത്തിയിട്ടില്ല)' : 'Not selected / Unsure',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ),
          ...districts.map((d) {
            return SimpleDialogOption(
              onPressed: () {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(district: d),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(d, style: const TextStyle(fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _editIncomeDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.controller.profile.monthlyIncome?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.loc.tr('monthlyIncomeLabel')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: widget.loc.tr('incomeHint'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearMonthlyIncome: true),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(widget.loc.tr('skipQuestion')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.loc.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearMonthlyIncome: true),
                );
              } else {
                final inc = int.tryParse(text);
                if (inc != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(monthlyIncome: inc),
                  );
                }
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('save')),
          ),
        ],
      ),
    );
  }

  void _editBoardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('isBoardMemberLabel')),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearIsBoardMember: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(
              widget.loc.isMalayalam ? 'വ്യക്തമല്ല / ഉറപ്പില്ല (രേഖപ്പെടുത്തിയിട്ടില്ല)' : 'Unsure / Not answered',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(isBoardMember: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('yes'), style: const TextStyle(fontSize: 16)),
          ),
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(isBoardMember: false),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('no'), style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _editYearsDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.controller.profile.yearsOfMembership?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.loc.tr('yearsMembershipLabel')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearYearsOfMembership: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.isMalayalam ? 'ഒഴിവാക്കുക' : 'Clear / Unset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(widget.loc.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearYearsOfMembership: true),
                );
              } else {
                final y = int.tryParse(text);
                if (y != null) {
                  widget.controller.updateProfile(
                    widget.controller.profile.copyWith(yearsOfMembership: y),
                  );
                }
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('save')),
          ),
        ],
      ),
    );
  }

  void _editRationCardDialog(BuildContext context) {
    final isMl = widget.loc.isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('rationCardLabel')),
        children: RationCardOption.allOptions.map((opt) {
          final isSelected = opt.code == widget.controller.profile.rationCardCategory;
          return SimpleDialogOption(
            onPressed: () {
              if (opt.code == null) {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(clearRationCardCategory: true),
                );
              } else {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(rationCardCategory: opt.code),
                );
              }
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: opt.buildVisualRow(isMl, isSelected: isSelected, isDark: isDark),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editHousingDialog(BuildContext context) {
    final housings = ['dilapidated', 'homeless', 'kutcha', 'pucca'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('housingLabel')),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearHousingCondition: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                widget.loc.isMalayalam ? 'രേഖപ്പെടുത്തിയിട്ടില്ല / ഉറപ്പില്ല' : 'Not answered / Unsure',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ),
          ...housings.map((h) {
            return SimpleDialogOption(
              onPressed: () {
                widget.controller.updateProfile(
                  widget.controller.profile.copyWith(housingCondition: h),
                );
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(h, style: const TextStyle(fontSize: 16)),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _editStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('hasStudentChildLabel')),
        children: [
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(clearHasStudentChild: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(
              widget.loc.isMalayalam ? 'ഉറപ്പില്ല / രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Not answered / Unsure',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(hasStudentChild: true),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('yes'), style: const TextStyle(fontSize: 16)),
          ),
          SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(hasStudentChild: false),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(widget.loc.tr('no'), style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _editSpecialStatusDialog(BuildContext context) {
    final statuses = ['none', 'widowed', 'destitute', 'disabled'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.loc.tr('specialStatusLabel')),
        children: statuses.map((s) {
          return SimpleDialogOption(
            onPressed: () {
              widget.controller.updateProfile(
                widget.controller.profile.copyWith(specialStatus: s),
              );
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(s, style: const TextStyle(fontSize: 16)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
