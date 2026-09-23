import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class RationCardModel {
  final String? code;
  final String nameEn;
  final String nameMl;
  final String subtitleEn;
  final String subtitleMl;
  final Color primaryColor;
  final Color darkAccent;
  final Color lightBg;
  final Color textColor;
  final String badgeText;

  const RationCardModel({
    required this.code,
    required this.nameEn,
    required this.nameMl,
    required this.subtitleEn,
    required this.subtitleMl,
    required this.primaryColor,
    required this.darkAccent,
    required this.lightBg,
    required this.textColor,
    required this.badgeText,
  });
}

class RationCardSelector extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  final bool isMalayalam;

  const RationCardSelector({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.isMalayalam,
  });

  static const List<RationCardModel> cards = [
    RationCardModel(
      code: 'AAY',
      nameEn: 'Yellow Card',
      nameMl: 'മഞ്ഞ കാർഡ്',
      subtitleEn: 'Antyodaya Anna Yojana (Most vulnerable / Priority)',
      subtitleMl: 'അന്ത്യോദയ അന്ന യോജന (അതീവ മുൻഗണന വിഭാഗം)',
      primaryColor: Color(0xFFF59E0B),
      darkAccent: Color(0xFFB45309),
      lightBg: Color(0xFFFFFBEB),
      textColor: Color(0xFF78350F),
      badgeText: 'AAY',
    ),
    RationCardModel(
      code: 'PHH',
      nameEn: 'Pink Card',
      nameMl: 'പിങ്ക് കാർഡ്',
      subtitleEn: 'Priority Household (BPL equivalent welfare schemes)',
      subtitleMl: 'മുൻഗണനാ കാർഡ് (ബി.പി.എൽ ആനുകൂല്യങ്ങൾ ഉള്ളത്)',
      primaryColor: Color(0xFFEC4899),
      darkAccent: Color(0xFFBE185D),
      lightBg: Color(0xFFFDF2F8),
      textColor: Color(0xFF831843),
      badgeText: 'PHH',
    ),
    RationCardModel(
      code: 'NPHH',
      nameEn: 'Blue Card',
      nameMl: 'നീല കാർഡ്',
      subtitleEn: 'Non-Priority Subsidy (Subsidized coastal/plantation rations)',
      subtitleMl: 'സബ്സിഡി കാർഡ് (മുൻഗണനേതര സബ്സിഡി വിഭാഗം)',
      primaryColor: Color(0xFF2563EB),
      darkAccent: Color(0xFF1D4ED8),
      lightBg: Color(0xFFEFF6FF),
      textColor: Color(0xFF1E3A8A),
      badgeText: 'NPHH',
    ),
    RationCardModel(
      code: 'Non-Priority',
      nameEn: 'White Card',
      nameMl: 'വെള്ള കാർഡ്',
      subtitleEn: 'Non-Priority General (Non-subsidized category)',
      subtitleMl: 'വെള്ള കാർഡ് (പൊതുവിഭാഗം / സബ്സിഡി ഇല്ലാത്തത്)',
      primaryColor: Color(0xFF64748B),
      darkAccent: Color(0xFF334155),
      lightBg: Color(0xFFF8FAFC),
      textColor: Color(0xFF0F172A),
      badgeText: 'NPNS',
    ),
  ];

  @override
  State<RationCardSelector> createState() => _RationCardSelectorState();
}

class _RationCardSelectorState extends State<RationCardSelector> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final idx = RationCardSelector.cards.indexWhere((c) => c.code == widget.selectedCategory);
    _currentPage = idx >= 0 ? idx : 0;
    _pageController = PageController(
      viewportFraction: 0.84,
      initialPage: _currentPage,
    );
  }

  @override
  void didUpdateWidget(covariant RationCardSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      final idx = RationCardSelector.cards.indexWhere((c) => c.code == widget.selectedCategory);
      if (idx >= 0 && idx != _currentPage && _pageController.hasClients) {
        _pageController.animateToPage(
          idx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = !kIsWeb || screenWidth < 650;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile)
          _buildMobileSwiper(context)
        else
          _buildDesktopGrid(context),

        const SizedBox(height: 8),

        // Unsure / Skip Button
        Center(
          child: TextButton.icon(
            onPressed: () => widget.onChanged(null),
            icon: Icon(
              widget.selectedCategory == null ? Icons.check_circle : Icons.help_outline,
              size: 16,
              color: widget.selectedCategory == null ? const Color(0xFF006D77) : Colors.grey[600],
            ),
            label: Text(
              widget.isMalayalam
                  ? 'ഉറപ്പില്ല / കാർഡ് വിഭാഗം അറിയില്ല'
                  : 'Unsure / Card type not specified',
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.selectedCategory == null ? FontWeight.bold : FontWeight.normal,
                color: widget.selectedCategory == null ? const Color(0xFF006D77) : Colors.grey[700],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Mobile Touch Swiper (PageView) ---
  Widget _buildMobileSwiper(BuildContext context) {
    final isMl = widget.isMalayalam;

    return Column(
      children: [
        SizedBox(
          height: 184,
          child: PageView.builder(
            controller: _pageController,
            itemCount: RationCardSelector.cards.length,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              widget.onChanged(RationCardSelector.cards[idx].code);
            },
            itemBuilder: (context, index) {
              final card = RationCardSelector.cards[index];
              final isSelected = widget.selectedCategory == card.code;

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? _currentPage.toDouble()) - index;
                    value = (1 - (value.abs() * 0.12)).clamp(0.88, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 184,
                      width: Curves.easeOut.transform(value) * 360,
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                    widget.onChanged(card.code);
                  },
                  child: _buildCardCover(card, isSelected, isMl),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            RationCardSelector.cards.length,
            (idx) {
              final isCur = _currentPage == idx;
              final card = RationCardSelector.cards[idx];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isCur ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCur ? card.primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Web / Desktop Box Grid ---
  Widget _buildDesktopGrid(BuildContext context) {
    final isMl = widget.isMalayalam;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: RationCardSelector.cards.length,
      itemBuilder: (context, index) {
        final card = RationCardSelector.cards[index];
        final isSelected = widget.selectedCategory == card.code;

        return InkWell(
          onTap: () => widget.onChanged(card.code),
          borderRadius: BorderRadius.circular(14),
          child: _buildCardCover(card, isSelected, isMl),
        );
      },
    );
  }

  // --- Shared Kerala Card Cover UI ---
  Widget _buildCardCover(RationCardModel card, bool isSelected, bool isMl) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? card.darkAccent : card.primaryColor.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: card.primaryColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: card.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KERALA CIVIL SUPPLIES',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: card.darkAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: card.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          // Main Card Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMl ? card.nameMl : card.nameEn,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: card.textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isMl ? card.subtitleMl : card.subtitleEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: card.textColor.withValues(alpha: 0.85),
                  height: 1.25,
                ),
              ),
            ],
          ),

          // Selection Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSelected
                    ? (isMl ? '✓ തിരഞ്ഞെടുത്തു' : '✓ Selected')
                    : (isMl ? 'തിരഞ്ഞെടുക്കാൻ തൊടുക' : 'Tap to select'),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? card.darkAccent : Colors.grey[600],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: card.darkAccent, size: 18)
              else
                Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
