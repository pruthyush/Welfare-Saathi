import 'package:flutter/material.dart';

/// Reusable top-left Back button for Welfare Saathi.
///
/// Designed to sit consistently in the AppBar leading position or screen header.
/// Features:
/// - Standard Material back arrow icon (`Icons.arrow_back`).
/// - Accessible tooltip/label ('Back' or localized string).
/// - Proper spacing from top and left edges without covering screen content.
/// - Matches existing Welfare Saathi visual styling in both light and high-contrast modes.
class AppBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String? tooltip;

  const AppBackButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: tooltip ?? 'Back',
        color: isDark ? const Color(0xFFFFD166) : const Color(0xFF006D77),
        splashRadius: 22,
        onPressed: onPressed,
      ),
    );
  }
}
