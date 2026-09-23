import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  final LocalizationService loc;
  final bool? compact;

  const LanguageSelector({
    super.key,
    required this.loc,
    this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final useCompact = compact ?? (screenWidth < 600);

    if (useCompact) {
      // Sleek compact toggle for mobile AppBars (avoids RenderFlex overflow)
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : const Color(0xFFE8F1F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactPill(
              label: 'മല',
              isSelected: isMl,
              isDark: isDark,
              onTap: () => loc.setLanguage('ml'),
            ),
            _buildCompactPill(
              label: 'EN',
              isSelected: !isMl,
              isDark: isDark,
              onTap: () => loc.setLanguage('en'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFE8F1F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            context: context,
            label: 'മലയാളം',
            isSelected: isMl,
            onTap: () => loc.setLanguage('ml'),
          ),
          _buildPill(
            context: context,
            label: 'English',
            isSelected: !isMl,
            onTap: () => loc.setLanguage('en'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF006D77)),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : const Color(0xFF006D77)),
          ),
        ),
      ),
    );
  }
}
