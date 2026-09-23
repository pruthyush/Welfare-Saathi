import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/eligibility_result.dart';
import '../models/household_profile.dart';
import '../services/localization_service.dart';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart' as downloader;

/// Generates a professional, print-ready PDF screening report designed for
/// beneficiaries to take directly to an Akshaya e-Centre or Welfare Board office.
///
/// Strictly observes ethical safety and privacy rules:
/// 1. Prominently includes the mandatory non-guarantee disclaimer.
/// 2. NEVER states "You are eligible" — strictly employs "Potentially Eligible".
/// 3. Exports ZERO sensitive PII (no Aadhaar, no phone numbers, no passwords).
class PdfExportService {
  /// Generates the raw PDF bytes for a household's screening evaluation.
  static Future<Uint8List> generateScreeningReport({
    required HouseholdProfile profile,
    required List<EligibilityResult> results,
    required LocalizationService loc,
    bool includeHouseholdDetails = true,
    bool includePotentiallyEligible = true,
    bool includeMoreInfoNeeded = true,
    Set<String>? selectedSchemeIds,
  }) async {
    final pdf = pw.Document(compress: false);

    final potentialSchemes = results
        .where((r) => r.isPotentiallyEligible)
        .where((r) => selectedSchemeIds == null || selectedSchemeIds.contains(r.scheme.id))
        .toList();

    final incompleteSchemes = results
        .where((r) => r.isMoreInformationRequired)
        .where((r) => selectedSchemeIds == null || selectedSchemeIds.contains(r.scheme.id))
        .toList();

    final now = DateTime.now();
    final formattedDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Built-in standard Helvetica fonts ensure 100% crisp, zero-latency vector rendering
    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontOblique = pw.Font.helveticaOblique();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        header: (context) => _buildHeader(context, formattedDate, fontRegular, fontBold),
        footer: (context) => _buildFooter(context, fontRegular),
        build: (context) => [
          _buildLegalDisclaimerBox(fontRegular, fontBold),
          pw.SizedBox(height: 14),

          if (includeHouseholdDetails) ...[
            _buildHouseholdProfileSection(profile, fontRegular, fontBold),
            pw.SizedBox(height: 18),
          ],

          if (includePotentiallyEligible) ...[
            _buildSectionHeader(
              title: '1. POTENTIALLY ELIGIBLE SCHEMES (${potentialSchemes.length})',
              subtitle: 'Identified based on applicant screening answers and official rules',
              color: PdfColor.fromInt(0xFF006D77),
              fontBold: fontBold,
              fontRegular: fontRegular,
            ),
            pw.SizedBox(height: 8),
            if (potentialSchemes.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(
                  'No schemes met all affirmative criteria under current answers.',
                  style: pw.TextStyle(font: fontOblique, fontSize: 10, color: PdfColors.grey700),
                ),
              )
            else
              ...potentialSchemes.map((r) => _buildSchemeCard(
                    result: r,
                    isPotential: true,
                    fontRegular: fontRegular,
                    fontBold: fontBold,
                    fontOblique: fontOblique,
                  )),
            pw.SizedBox(height: 18),
          ],

          if (includeMoreInfoNeeded && incompleteSchemes.isNotEmpty) ...[
            _buildSectionHeader(
              title: '2. SCHEMES REQUIRING ADDITIONAL INFORMATION (${incompleteSchemes.length})',
              subtitle: 'Clarify missing details or documents with an Akshaya operator',
              color: PdfColor.fromInt(0xFFC05621),
              fontBold: fontBold,
              fontRegular: fontRegular,
            ),
            pw.SizedBox(height: 8),
            ...incompleteSchemes.map((r) => _buildSchemeCard(
                  result: r,
                  isPotential: false,
                  fontRegular: fontRegular,
                  fontBold: fontBold,
                  fontOblique: fontOblique,
                )),
            pw.SizedBox(height: 18),
          ],

          _buildAkshayaActionPlanBox(fontRegular, fontBold),
        ],
      ),
    );

    return pdf.save();
  }

  /// Downloads the screening PDF directly to the user's browser or device.
  static Future<void> downloadScreeningReport({
    required HouseholdProfile profile,
    required List<EligibilityResult> results,
    required LocalizationService loc,
    bool includeHouseholdDetails = true,
    bool includePotentiallyEligible = true,
    bool includeMoreInfoNeeded = true,
    Set<String>? selectedSchemeIds,
    String filename = 'welfare_saathi_screening_summary.pdf',
  }) async {
    final pdfBytes = await generateScreeningReport(
      profile: profile,
      results: results,
      loc: loc,
      includeHouseholdDetails: includeHouseholdDetails,
      includePotentiallyEligible: includePotentiallyEligible,
      includeMoreInfoNeeded: includeMoreInfoNeeded,
      selectedSchemeIds: selectedSchemeIds,
    );

    if (kIsWeb) {
      downloader.downloadPdfFile(pdfBytes, filename);
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: filename,
      );
    }
  }

  /// Shares the screening PDF via the native platform Share Sheet (WhatsApp, Files, Drive on Android).
  /// Falls back to client-side browser download when running on Flutter Web.
  static Future<void> shareScreeningReport({
    required HouseholdProfile profile,
    required List<EligibilityResult> results,
    required LocalizationService loc,
    bool includeHouseholdDetails = true,
    bool includePotentiallyEligible = true,
    bool includeMoreInfoNeeded = true,
    Set<String>? selectedSchemeIds,
    String filename = 'welfare_saathi_screening_summary.pdf',
  }) async {
    final pdfBytes = await generateScreeningReport(
      profile: profile,
      results: results,
      loc: loc,
      includeHouseholdDetails: includeHouseholdDetails,
      includePotentiallyEligible: includePotentiallyEligible,
      includeMoreInfoNeeded: includeMoreInfoNeeded,
      selectedSchemeIds: selectedSchemeIds,
    );

    if (kIsWeb) {
      downloader.downloadPdfFile(pdfBytes, filename);
    } else {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    }
  }

  /// Opens the native print dialog / spooler across Android, Web, and Windows.
  static Future<void> printScreeningReport({
    required HouseholdProfile profile,
    required List<EligibilityResult> results,
    required LocalizationService loc,
    bool includeHouseholdDetails = true,
    bool includePotentiallyEligible = true,
    bool includeMoreInfoNeeded = true,
    Set<String>? selectedSchemeIds,
    String filename = 'welfare_saathi_screening_summary.pdf',
  }) async {
    final pdfBytes = await generateScreeningReport(
      profile: profile,
      results: results,
      loc: loc,
      includeHouseholdDetails: includeHouseholdDetails,
      includePotentiallyEligible: includePotentiallyEligible,
      includeMoreInfoNeeded: includeMoreInfoNeeded,
      selectedSchemeIds: selectedSchemeIds,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: filename,
    );
  }

  // --- PDF Component Builders ---

  static String _cleanPdfText(String text) {
    return text
        .replaceAll('✓', '')
        .replaceAll('✔', '')
        .replaceAll('✗', '')
        .replaceAll('•', '-')
        .replaceAll('₹', 'Rs. ')
        .trim();
  }

  static pw.Widget _buildHeader(
    pw.Context context,
    String formattedDate,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF006D77), width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'WELFARE SAATHI (KSHEMA SAATHI)',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 16,
                  color: const PdfColor.fromInt(0xFF006D77),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Confidential Screening Summary - Akshaya e-Centre Facilitation Report',
                style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Generated: $formattedDate',
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
              ),
              pw.Text(
                'Organiser PS-07 Source of Truth',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font fontRegular) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Welfare Saathi | Offline Deterministic Welfare Assistant | No Sensitive PII Stored',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static const String legalDisclaimer =
      'This document is a screening summary based on the information provided by the applicant and the scheme rules available in Welfare Saathi. It does not guarantee eligibility or approval. Final verification and approval are performed by the relevant authority. All status references indicate "Potentially Eligible" status only.';

  static pw.Widget _buildLegalDisclaimerBox(pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFBEB),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B), width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 6,
                height: 6,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFD97706),
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                'MANDATORY REGULATORY DISCLAIMER & STATUS DEFINITION',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFF92400E),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            legalDisclaimer,
            style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: const PdfColor.fromInt(0xFF78350F), height: 1.3),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHouseholdProfileSection(
    HouseholdProfile profile,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    final occText = profile.occupation == 'fishing'
        ? 'Fishing / Allied Coastal Work'
        : profile.occupation == 'plantation'
            ? 'Plantation Labor (Tea/Coffee/Rubber/Cardamom)'
            : profile.occupation == 'other'
                ? 'General / Other Labor'
                : 'Not specified';

    final boardText = profile.isBoardMember == true
        ? 'Registered Member (${profile.yearsOfMembership != null ? "${profile.yearsOfMembership} yrs" : "tenure unstated"})'
        : profile.isBoardMember == false
            ? 'Not Registered'
            : 'Unsure / Not answered';

    final incomeText = profile.monthlyIncome != null
        ? 'Rs. ${profile.monthlyIncome}'
        : 'Skipped / Not declared';

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SCREENED HOUSEHOLD PROFILE DETAILS',
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: const PdfColor.fromInt(0xFF006D77)),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(children: [
                _buildTableCell('Sector:', fontBold, isLabel: true),
                _buildTableCell(occText, fontRegular),
                _buildTableCell('District:', fontBold, isLabel: true),
                _buildTableCell(profile.district ?? 'Not specified', fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Applicant Age:', fontBold, isLabel: true),
                _buildTableCell(profile.age != null ? '${profile.age} years' : 'Not answered', fontRegular),
                _buildTableCell('Welfare Board:', fontBold, isLabel: true),
                _buildTableCell(boardText, fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Ration Card:', fontBold, isLabel: true),
                _buildTableCell(profile.rationCardCategory ?? 'Not answered', fontRegular),
                _buildTableCell('Housing State:', fontBold, isLabel: true),
                _buildTableCell(profile.housingCondition ?? 'Not answered', fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Monthly Income:', fontBold, isLabel: true),
                _buildTableCell(incomeText, fontRegular),
                _buildTableCell('Student Child:', fontBold, isLabel: true),
                _buildTableCell(
                  profile.hasStudentChild == true
                      ? 'Yes (Higher Sec/College)'
                      : profile.hasStudentChild == false
                          ? 'No'
                          : 'Not answered',
                  fontRegular,
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isLabel = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8.5,
          color: isLabel ? PdfColors.grey800 : PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required PdfColor color,
    required pw.Font fontBold,
    required pw.Font fontRegular,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(font: fontBold, fontSize: 11, color: color),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildSchemeCard({
    required EligibilityResult result,
    required bool isPotential,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontOblique,
  }) {
    final scheme = result.scheme;
    final badgeColor = isPotential ? const PdfColor.fromInt(0xFF006D77) : const PdfColor.fromInt(0xFFD97706);
    final badgeBg = isPotential ? const PdfColor.fromInt(0xFFE6FFFA) : const PdfColor.fromInt(0xFFFFFBEB);
    final badgeLabel = isPotential ? 'POTENTIALLY ELIGIBLE' : 'MORE INFORMATION NEEDED';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: badgeColor, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Scheme Title and Badge
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      scheme.nameEn,
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.black),
                    ),
                    pw.Text(
                      'Scheme Code: ${scheme.id}',
                      style: pw.TextStyle(font: fontOblique, fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${scheme.departmentEn} | Sector: ${scheme.category.toUpperCase()}',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: badgeBg,
                  border: pw.Border.all(color: badgeColor, width: 0.6),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  badgeLabel,
                  style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: badgeColor),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Rule match / missing explanations
          if (isPotential && result.matchedRules.isNotEmpty) ...[
            pw.Text(
              'Matched Eligibility Conditions:',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: const PdfColor.fromInt(0xFF006D77)),
            ),
            pw.SizedBox(height: 2),
            ...result.matchedRules.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, top: 1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFF006D77))),
                    pw.Expanded(
                      child: pw.Text(
                        _cleanPdfText(r.explanationEn),
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),
          ],

          if (!isPotential && result.missingRules.isNotEmpty) ...[
            pw.Text(
              'Information Needed to Complete Verification:',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: const PdfColor.fromInt(0xFFC05621)),
            ),
            pw.SizedBox(height: 2),
            ...result.missingRules.map(
              (r) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 6, top: 1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('? ', style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFFC05621))),
                    pw.Expanded(
                      child: pw.Text(
                        _cleanPdfText(r.explanationEn),
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),
          ],

          // Checklist of Required Documents
          if (scheme.requiredDocumentsEn.isNotEmpty) ...[
            pw.Text(
              'Documents to Present at Akshaya Centre / Welfare Board:',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 8,
              runSpacing: 3,
              children: scheme.requiredDocumentsEn.map((doc) {
                return pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500, width: 0.8),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(doc, style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800)),
                  ],
                );
              }).toList(),
            ),
            pw.SizedBox(height: 6),
          ],

          // Application Channel and Next Steps
          if (scheme.nextStepsEn.isNotEmpty) ...[
            pw.Text(
              'Recommended Next Steps: ${scheme.nextStepsEn.first}',
              style: pw.TextStyle(font: fontOblique, fontSize: 8, color: PdfColors.grey700),
            ),
          ],

          if (scheme.officialUrl != null && scheme.officialUrl!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Official Portal: ${scheme.officialUrl}',
              style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: const PdfColor.fromInt(0xFF006D77)),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildAkshayaActionPlanBox(pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF16A34A), width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INSTRUCTIONS FOR BENEFICIARY AT THE AKSHAYA E-CENTRE',
            style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF15803D)),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '1. Carry this printed screening sheet along with original ration card and welfare fund passbook.\n'
            '2. Ask the Akshaya operator to check the active welfare portal for the schemes listed above.\n'
            '3. In case of missing information, bring revenue income certificates or ward member certifications.\n'
            '4. Keep the receipt and application reference acknowledgement number safe after submission.',
            style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: const PdfColor.fromInt(0xFF166534), height: 1.3),
          ),
        ],
      ),
    );
  }
}
