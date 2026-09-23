import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class DisclaimerBanner extends StatelessWidget {
  final LocalizationService loc;
  final bool compact;

  const DisclaimerBanner({
    super.key,
    required this.loc,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFFFFD166) : const Color(0xFFF59E0B),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: isDark ? const Color(0xFFFFD166) : const Color(0xFFD97706),
            size: compact ? 20 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc.tr('disclaimerText'),
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFFE8A3) : const Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
