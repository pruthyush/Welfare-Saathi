import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LanguageSelector extends StatelessWidget {
  final LocalizationService loc;

  const LanguageSelector({
    super.key,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final isMl = loc.isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
