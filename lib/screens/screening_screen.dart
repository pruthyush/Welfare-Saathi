import 'package:flutter/material.dart';
import '../controllers/screening_controller.dart';
import '../services/localization_service.dart';
import '../widgets/app_back_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/ration_card_selector.dart';

class ScreeningScreen extends StatefulWidget {
  final ScreeningController controller;
  final LocalizationService loc;
  final VoidCallback onComplete;
  final VoidCallback onBackToWelcome;

  const ScreeningScreen({
    super.key,
    required this.controller,
    required this.loc,
    required this.onComplete,
    required this.onBackToWelcome,
  });

  @override
  State<ScreeningScreen> createState() => _ScreeningScreenState();
}

class _ScreeningScreenState extends State<ScreeningScreen> {
  late String? _occupation;
  late int? _age;
  late String? _district;
  late int? _monthlyIncome;
  late bool? _isBoardMember;
  late int? _yearsOfMembership;
  late String? _rationCardCategory;
  late String? _housingCondition;
  late bool? _hasStudentChild;
  late String? _specialStatus;

  late TextEditingController _ageController;
  late TextEditingController _incomeController;
  late TextEditingController _yearsController;

  final List<String> _districts = [
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
  void initState() {
    super.initState();
    _syncFromController();
  }

  void _syncFromController() {
    final p = widget.controller.profile;
    _occupation = p.occupation;
    _age = p.age;
    _district = p.district;
    _monthlyIncome = p.monthlyIncome;
    _isBoardMember = p.isBoardMember;
    _yearsOfMembership = p.yearsOfMembership;
    _rationCardCategory = p.rationCardCategory;
    _housingCondition = p.housingCondition;
    _hasStudentChild = p.hasStudentChild;
    _specialStatus = p.specialStatus ?? 'none';

    _ageController = TextEditingController(text: _age != null ? _age.toString() : '');
    _incomeController = TextEditingController(
      text: _monthlyIncome != null ? _monthlyIncome.toString() : '',
    );
    _yearsController = TextEditingController(
      text: _yearsOfMembership != null ? _yearsOfMembership.toString() : '',
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  void _saveCurrentStepToController() {
    final updated = widget.controller.profile.copyWith(
      occupation: _occupation,
      age: _age,
      district: _district,
      monthlyIncome: _monthlyIncome,
      isBoardMember: _isBoardMember,
      yearsOfMembership: _yearsOfMembership,
      rationCardCategory: _rationCardCategory,
      housingCondition: _housingCondition,
      hasStudentChild: _hasStudentChild,
      specialStatus: _specialStatus,
      clearOccupation: _occupation == null,
      clearAge: _age == null,
      clearDistrict: _district == null,
      clearMonthlyIncome: _monthlyIncome == null,
      clearIsBoardMember: _isBoardMember == null,
      clearYearsOfMembership: _yearsOfMembership == null,
      clearRationCardCategory: _rationCardCategory == null,
      clearHousingCondition: _housingCondition == null,
      clearHasStudentChild: _hasStudentChild == null,
      clearSpecialStatus: _specialStatus == null,
    );
    widget.controller.updateProfile(updated);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.controller.currentStep;
    final loc = widget.loc;
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          tooltip: loc.tr('back'),
          onPressed: () {
            if (step > 0) {
              _saveCurrentStepToController();
              widget.controller.prevStep();
            } else {
              widget.onBackToWelcome();
            }
          },
        ),
        title: Text(
          '${loc.tr('step')} ${step + 1} ${loc.tr('of')} 3',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          LanguageSelector(loc: loc),
          const SizedBox(width: 16),
        ],
      ),
      body: isDesktop
          ? Column(
              children: [
                // Progress Bar
                LinearProgressIndicator(
                  value: (step + 1) / 3,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Step Questions
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _getStepTitle(step, isMl),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getStepSubtitle(step, isMl),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (step == 0) _buildStep0(context),
                              if (step == 1) _buildStep1(context),
                              if (step == 2) _buildStep2(context),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right Column: Live Household Profile & Screening Preview
                        SizedBox(
                          width: 420,
                          child: _buildDesktopLiveSummaryCard(context, isMl, isDark, theme),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (step > 0)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _saveCurrentStepToController();
                              widget.controller.prevStep();
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: Text(loc.tr('back')),
                          ),
                        ),
                      if (step > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _saveCurrentStepToController();
                            if (step < 2) {
                              widget.controller.nextStep();
                            } else {
                              widget.controller.evaluateCurrentProfile();
                              widget.controller.saveCurrentProfileToRemote();
                              widget.onComplete();
                            }
                          },
                          icon: Icon(step < 2 ? Icons.arrow_forward : Icons.check_circle_outline),
                          label: Text(
                            step < 2 ? loc.tr('next') : loc.tr('submit'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    // Progress Bar
                    LinearProgressIndicator(
                      value: (step + 1) / 3,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _getStepTitle(step, isMl),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getStepSubtitle(step, isMl),
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (step == 0) _buildStep0(context),
                            if (step == 1) _buildStep1(context),
                            if (step == 2) _buildStep2(context),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Navigation Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (step > 0)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _saveCurrentStepToController();
                                  widget.controller.prevStep();
                                },
                                icon: const Icon(Icons.arrow_back),
                                label: Text(loc.tr('back')),
                              ),
                            ),
                          if (step > 0) const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _saveCurrentStepToController();
                                if (step < 2) {
                                  widget.controller.nextStep();
                                } else {
                                  widget.controller.evaluateCurrentProfile();
                                  widget.controller.saveCurrentProfileToRemote();
                                  widget.onComplete();
                                }
                              },
                              icon: Icon(step < 2 ? Icons.arrow_forward : Icons.check_circle_outline),
                              label: Text(
                                step < 2 ? loc.tr('next') : loc.tr('submit'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getStepTitle(int step, bool isMl) {
    switch (step) {
      case 0:
        return widget.loc.tr('step1Category');
      case 1:
        return widget.loc.tr('step2Board');
      case 2:
      default:
        return widget.loc.tr('step3Economic');
    }
  }

  String _getStepSubtitle(int step, bool isMl) {
    switch (step) {
      case 0:
        return isMl
            ? 'നിങ്ങളുടെ തൊഴിൽ മേഖലയും താമസിക്കുന്ന ജില്ലയും തിരഞ്ഞെടുക്കുക'
            : 'Select your primary work sector and district';
      case 1:
        return isMl
            ? 'പ്രായവും ക്ഷേമനിധി ബോർഡ് അംഗത്വ വിവരങ്ങളും രേഖപ്പെടുത്തുക'
            : 'Specify worker age and official board membership details';
      case 2:
      default:
        return isMl
            ? 'വരുമാനവും റേഷൻ കാർഡും ഭവന സാഹചര്യങ്ങളും രേഖപ്പെടുത്തുക'
            : 'Provide household income and living status (optional fields can be skipped)';
    }
  }

  // STEP 0: Occupation & Location
  Widget _buildStep0(BuildContext context) {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('occupationLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        _buildRadioOption<String>(
          title: loc.tr('occupationFishing'),
          subtitle: isMl ? 'പരമ്പരാഗത മത്സ്യത്തൊഴിലാളി, അനുബന്ധ വിപണനം' : 'Traditional coastal fish worker, vending & drying',
          icon: Icons.phishing_rounded,
          value: 'fishing',
          groupValue: _occupation,
          onChanged: (val) => setState(() => _occupation = val),
        ),
        const SizedBox(height: 10),
        _buildRadioOption<String>(
          title: loc.tr('occupationPlantation'),
          subtitle: isMl ? 'തേയില, കാപ്പി, റബ്ബർ, ഏലം തോട്ടം തൊഴിലാളി' : 'Tea, Coffee, Rubber, or Cardamom labor',
          icon: Icons.eco_rounded,
          value: 'plantation',
          groupValue: _occupation,
          onChanged: (val) => setState(() => _occupation = val),
        ),
        const SizedBox(height: 10),
        _buildRadioOption<String>(
          title: loc.tr('occupationOther'),
          subtitle: isMl ? 'മറ്റ് മേഖലകളിൽ ജോലി ചെയ്യുന്നവർ' : 'Private / general non-plantation labor',
          icon: Icons.work_outline_rounded,
          value: 'other',
          groupValue: _occupation,
          onChanged: (val) => setState(() => _occupation = val),
        ),

        const SizedBox(height: 28),
        Text(
          loc.tr('districtLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          value: _district,
          hint: Text(isMl ? 'ജില്ല തിരഞ്ഞെടുക്കുക (Select District)' : 'Select District (Optional)'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല (Not selected)' : 'Not selected / Unsure'),
            ),
            ..._districts.map((d) {
              return DropdownMenuItem<String?>(value: d, child: Text(d));
            }),
          ],
          onChanged: (val) => setState(() => _district = val),
        ),
      ],
    );
  }

  // STEP 1: Age & Board Membership
  Widget _buildStep1(BuildContext context) {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.tr('ageLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: loc.tr('ageHint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.cake_outlined),
                  filled: true,
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val.trim());
                  setState(() => _age = parsed);
                },
              ),
            ),
            const SizedBox(width: 12),
            // Quick stepper buttons for accessibility
            IconButton.filledTonal(
              icon: const Icon(Icons.remove),
              onPressed: () {
                final current = _age;
                if (current != null && current > 18) {
                  setState(() {
                    _age = current - 1;
                    _ageController.text = _age.toString();
                  });
                }
              },
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: () {
                final current = _age;
                if (current == null) {
                  setState(() {
                    _age = 18;
                    _ageController.text = '18';
                  });
                } else if (current < 95) {
                  setState(() {
                    _age = current + 1;
                    _ageController.text = _age.toString();
                  });
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 28),
        Text(
          loc.tr('isBoardMemberLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: loc.tr('yes'),
                isSelected: _isBoardMember == true,
                onSelected: () => setState(() => _isBoardMember = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: loc.tr('no'),
                isSelected: _isBoardMember == false,
                onSelected: () => setState(() => _isBoardMember = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildChoiceChip(
                label: isMl ? 'അറിയില്ല / വ്യക്തമല്ല' : 'Not answered / Unsure',
                isSelected: _isBoardMember == null,
                onSelected: () => setState(() => _isBoardMember = null),
              ),
            ),
          ],
        ),

        if (_isBoardMember == true) ...[
          const SizedBox(height: 24),
          Text(
            loc.tr('yearsMembershipLabel'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _yearsController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: isMl ? 'ഉദാ: 6' : 'e.g. 6',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.history_edu_rounded),
              filled: true,
            ),
            onChanged: (val) {
              final parsed = int.tryParse(val);
              setState(() => _yearsOfMembership = parsed);
            },
          ),
        ],
      ],
    );
  }

  // STEP 2: Economic & Living Conditions
  Widget _buildStep2(BuildContext context) {
    final loc = widget.loc;
    final isMl = loc.isMalayalam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly Income with Skip Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                loc.tr('monthlyIncomeLabel'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _monthlyIncome = null;
                  _incomeController.clear();
                });
              },
              child: Text(
                _monthlyIncome == null
                    ? (isMl ? 'ഒഴിവാക്കി (Skipped)' : 'Skipped')
                    : loc.tr('skipQuestion'),
                style: TextStyle(
                  color: _monthlyIncome == null ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _incomeController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: loc.tr('incomeHint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.currency_rupee_rounded),
            filled: true,
          ),
          onChanged: (val) {
            final parsed = int.tryParse(val);
            setState(() => _monthlyIncome = parsed);
          },
        ),

        const SizedBox(height: 24),
        Text(
          loc.tr('rationCardLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          isMl
              ? 'നിങ്ങളുടെ റേഷൻ കാർഡിന്റെ നിറം തിരഞ്ഞെടുക്കുക'
              : 'Select your Kerala Ration Card color cover',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 12),
        RationCardSelector(
          selectedCategory: _rationCardCategory,
          isMalayalam: isMl,
          onChanged: (val) => setState(() => _rationCardCategory = val),
        ),

        const SizedBox(height: 24),
        Text(
          loc.tr('housingLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _buildRadioOption<String?>(
          title: isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല / ഉറപ്പില്ല' : 'Not answered / Unsure',
          subtitle: isMl ? 'ഭവന അവസ്ഥ രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Housing condition not specified',
          icon: Icons.help_outline_rounded,
          value: null,
          groupValue: _housingCondition,
          onChanged: (val) => setState(() => _housingCondition = val),
        ),
        const SizedBox(height: 8),
        _buildRadioOption<String?>(
          title: loc.tr('housingDilapidated'),
          subtitle: isMl ? 'അടിയന്തര അറ്റകുറ്റപ്പണി ആവശ്യമായ ലയം അല്ലെങ്കിൽ കൂര' : 'Layam or temporary shelter needing renovation',
          icon: Icons.home_repair_service_outlined,
          value: 'dilapidated',
          groupValue: _housingCondition,
          onChanged: (val) => setState(() => _housingCondition = val),
        ),
        const SizedBox(height: 8),
        _buildRadioOption<String?>(
          title: loc.tr('housingHomeless'),
          subtitle: isMl ? 'സ്വന്തമായി വീടില്ലാത്ത അവസ്ഥ' : 'Homeless / living on leased/insecure land',
          icon: Icons.cottage_outlined,
          value: 'homeless',
          groupValue: _housingCondition,
          onChanged: (val) => setState(() => _housingCondition = val),
        ),
        const SizedBox(height: 8),
        _buildRadioOption<String?>(
          title: loc.tr('housingPucca'),
          subtitle: isMl ? 'വാസയോഗ്യമായ കോൺക്രീറ്റ് വീട്' : 'Own sturdy pucca concrete home',
          icon: Icons.house_rounded,
          value: 'pucca',
          groupValue: _housingCondition,
          onChanged: (val) => setState(() => _housingCondition = val),
        ),

        const SizedBox(height: 24),
        Text(
          loc.tr('hasStudentChildLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildChoiceChip(
                label: loc.tr('yes'),
                isSelected: _hasStudentChild == true,
                onSelected: () => setState(() => _hasStudentChild = true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: loc.tr('no'),
                isSelected: _hasStudentChild == false,
                onSelected: () => setState(() => _hasStudentChild = false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildChoiceChip(
                label: isMl ? 'ഉറപ്പില്ല' : 'Unsure',
                isSelected: _hasStudentChild == null,
                onSelected: () => setState(() => _hasStudentChild = null),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Text(
          loc.tr('specialStatusLabel'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _specialStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.people_outline),
            filled: true,
          ),
          items: [
            DropdownMenuItem(value: 'none', child: Text(loc.tr('specialStatusNone'))),
            DropdownMenuItem(value: 'widowed', child: Text(loc.tr('specialStatusWidowed'))),
            DropdownMenuItem(value: 'destitute', child: Text(loc.tr('specialStatusDestitute'))),
            DropdownMenuItem(value: 'disabled', child: Text(loc.tr('specialStatusDisabled'))),
          ],
          onChanged: (val) => setState(() => _specialStatus = val),
        ),
      ],
    );
  }

  Widget _buildRadioOption<T>({
    required String title,
    required String subtitle,
    required IconData icon,
    required T value,
    required T? groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0F2F1))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                : (isDark ? const Color(0xFF444444) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                  : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
              : (isDark ? const Color(0xFF262626) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                : (isDark ? const Color(0xFF444444) : const Color(0xFFD1D5DB)),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLiveSummaryCard(
    BuildContext context,
    bool isMl,
    bool isDark,
    ThemeData theme,
  ) {
    final occText = _occupation == 'fishing'
        ? (isMl ? 'പരമ്പരാഗത മത്സ്യത്തൊഴിലാളി' : 'Coastal Fishing Labor')
        : _occupation == 'plantation'
            ? (isMl ? 'തോട്ടം തൊഴിലാളി' : 'Plantation Labor')
            : _occupation == 'other'
                ? (isMl ? 'ജനറൽ / മറ്റ് തൊഴിലാളി' : 'General / Informal Labor')
                : (isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not selected');

    final boardText = _isBoardMember == true
        ? (isMl
            ? 'അംഗം (${_yearsOfMembership ?? 0} വർഷം)'
            : 'Member (${_yearsOfMembership ?? 0} Years)')
        : _isBoardMember == false
            ? (isMl ? 'അംഗമല്ല' : 'Non-Member')
            : (isMl ? 'വ്യക്തമാക്കിയിട്ടില്ല' : 'Not specified');

    final cardText = _rationCardCategory == 'AAY'
        ? (isMl ? 'മഞ്ഞ കാർഡ് (AAY)' : 'Yellow Card (AAY)')
        : _rationCardCategory == 'PHH'
            ? (isMl ? 'പിങ്ക് കാർഡ് (PHH)' : 'Pink Card (PHH)')
            : _rationCardCategory == 'NPHH'
                ? (isMl ? 'നീല കാർഡ് (NPHH)' : 'Blue Card (NPHH)')
                : _rationCardCategory == 'Non-Priority'
                    ? (isMl ? 'വെള്ള കാർഡ് (Non-Priority)' : 'White Card')
                    : (isMl ? 'തിരഞ്ഞെടുത്തിട്ടില്ല' : 'Not selected');

    return Container(
      padding: const EdgeInsets.all(22),
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
                  color: (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMl ? 'തത്സമയ വിവര സംഗ്രഹം' : 'Live Applicant Summary',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isMl ? 'വിൻഡോസ് / ഡെസ്ക്ടോപ്പ് പ്രിവ്യൂ' : 'Desktop Workbench View',
                      style: TextStyle(
                        fontSize: 11.5,
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
          const SizedBox(height: 12),

          _buildSummaryItem(
            isMl ? 'തൊഴിൽ മേഖല' : 'Primary Sector',
            occText,
            Icons.work_outline_rounded,
            theme,
            isDark,
          ),
          _buildSummaryItem(
            isMl ? 'ജില്ല' : 'District',
            _district ?? (isMl ? 'നൽകിയിട്ടില്ല' : 'Not specified'),
            Icons.location_on_outlined,
            theme,
            isDark,
          ),
          _buildSummaryItem(
            isMl ? 'പ്രായം' : 'Applicant Age',
            _age != null ? '$_age ${isMl ? "വയസ്സ്" : "Years"}' : (isMl ? 'നൽകിയിട്ടില്ല' : 'Not specified'),
            Icons.cake_outlined,
            theme,
            isDark,
          ),
          _buildSummaryItem(
            isMl ? 'റേഷൻ കാർഡ്' : 'Ration Card',
            cardText,
            Icons.credit_card_rounded,
            theme,
            isDark,
          ),
          _buildSummaryItem(
            isMl ? 'ക്ഷേമനിധി ബോർഡ്' : 'Welfare Board',
            boardText,
            Icons.badge_outlined,
            theme,
            isDark,
          ),
          _buildSummaryItem(
            isMl ? 'മാസവരുമാനം' : 'Monthly Income',
            _monthlyIncome != null ? 'Rs. $_monthlyIncome /-' : (isMl ? 'രേഖപ്പെടുത്തിയിട്ടില്ല' : 'Not entered'),
            Icons.currency_rupee_rounded,
            theme,
            isDark,
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262626) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF006D77)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMl
                        ? '16 കേരള സർക്കാർ ക്ഷേമപദ്ധതികളുമായി തത്സമയം പൊരുത്തപ്പെടുത്തുന്നു. പൂർണ്ണമായും സുരക്ഷിതവും രഹസ്യവുമായിരിക്കും.'
                        : 'Evaluated deterministically across 16 official Kerala welfare schemes with zero PII retention.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

