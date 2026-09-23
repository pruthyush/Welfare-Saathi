import 'package:flutter/material.dart';

/// Defines visual and localized metadata for Kerala Ration Card categories.
///
/// Enables vulnerable citizens and low-literacy beneficiaries to immediately
/// recognize and select their ration card by its physical color (Yellow, Pink, Blue, White).
class RationCardOption {
  final String? code;
  final String nameEn;
  final String nameMl;
  final Color cardColor;
  final Color borderColor;
  final Color bgTint;
  final Color textColor;

  const RationCardOption({
    required this.code,
    required this.nameEn,
    required this.nameMl,
    required this.cardColor,
    required this.borderColor,
    required this.bgTint,
    required this.textColor,
  });

  String getLabel(bool isMalayalam) => isMalayalam ? nameMl : nameEn;

  static const List<RationCardOption> allOptions = [
    RationCardOption(
      code: null,
      nameEn: 'Not answered / Unsure',
      nameMl: 'തിരഞ്ഞെടുത്തിട്ടില്ല (രേഖപ്പെടുത്തിയിട്ടില്ല)',
      cardColor: Color(0xFFCFD8DC),
      borderColor: Color(0xFF90A4AE),
      bgTint: Color(0xFFECEFF1),
      textColor: Color(0xFF455A64),
    ),
    RationCardOption(
      code: 'AAY',
      nameEn: 'Yellow Card (AAY - Antyodaya Anna Yojana)',
      nameMl: 'മഞ്ഞ കാർഡ് (AAY - അതീവ മുൻഗണന)',
      cardColor: Color(0xFFFFD54F), // Vibrant golden yellow
      borderColor: Color(0xFFD4A017),
      bgTint: Color(0xFFFFFDE7),
      textColor: Color(0xFF7F6000),
    ),
    RationCardOption(
      code: 'PHH',
      nameEn: 'Pink Card (PHH - Priority Household)',
      nameMl: 'പിങ്ക് കാർഡ് (PHH - മുൻഗണന വിഭാഗം)',
      cardColor: Color(0xFFF48FB1), // Vibrant pink
      borderColor: Color(0xFFC2185B),
      bgTint: Color(0xFFFCE4EC),
      textColor: Color(0xFF880E4F),
    ),
    RationCardOption(
      code: 'NPHH',
      nameEn: 'Blue Card (NPHH - Non-Priority Subsidy)',
      nameMl: 'നീല കാർഡ് (NPHH - സബ്സിഡി ഇതര മുൻഗണന)',
      cardColor: Color(0xFF64B5F6), // Vibrant blue
      borderColor: Color(0xFF1565C0),
      bgTint: Color(0xFFE3F2FD),
      textColor: Color(0xFF0D47A1),
    ),
    RationCardOption(
      code: 'Non-Priority',
      nameEn: 'White Card (Non-Priority / General)',
      nameMl: 'വെള്ള കാർഡ് (പൊതു വിഭാഗം)',
      cardColor: Colors.white,
      borderColor: Color(0xFF78909C),
      bgTint: Color(0xFFFAFAFA),
      textColor: Color(0xFF263238),
    ),
  ];

  static RationCardOption getByCode(String? code) {
    return allOptions.firstWhere(
      (opt) => opt.code == code,
      orElse: () => allOptions.first,
    );
  }

  /// Builds a rich, color-coded visual row suitable for dropdown menus,
  /// dialog options, and review summaries.
  Widget buildVisualRow(bool isMalayalam, {bool isSelected = false, bool isDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.transparent : bgTint.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor.withValues(alpha: isSelected ? 1.0 : 0.6),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Visual Physical Card Representation
          Container(
            width: 26,
            height: 18,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 2,
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Descriptive Label
          Expanded(
            child: Text(
              getLabel(isMalayalam),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isDark ? Colors.white : textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Category Code Pill
          if (code != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Text(
                code!,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
