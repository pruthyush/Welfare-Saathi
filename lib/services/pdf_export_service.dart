import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/eligibility_result.dart';
import '../models/household_profile.dart';
import '../services/localization_service.dart';
import 'pdf_font_helper.dart';
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
    final theme = await PdfFontHelper.getPdfTheme();
    final pdf = pw.Document(theme: theme, compress: false);

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

    final fontRegular = PdfFontHelper.getLatinRegular();
    final fontBold = PdfFontHelper.getLatinBold();
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
              title: '1. POTENTIALLY ELIGIBLE SCHEMES (${potentialSchemes.length}) (${PdfFontHelper.shape("സാധ്യതയുള്ള അർഹത")})',
              subtitle: 'Identified based on applicant screening answers and official rules',
              color: const PdfColor.fromInt(0xFF006D77),
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
              title: '2. SCHEMES REQUIRING ADDITIONAL INFORMATION (${incompleteSchemes.length}) (${PdfFontHelper.shape("കൂടുതൽ വിവരങ്ങൾ ആവശ്യമാണ്")})',
              subtitle: 'Clarify missing details or documents with an Akshaya operator',
              color: const PdfColor.fromInt(0xFFC05621),
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
          pw.SizedBox(height: 18),

          // Integrated Akshaya Operator View & Verification Roster Pages
          pw.NewPage(),
          _buildAkshayaOperatorViewPages(
            profile: profile,
            potentialSchemes: potentialSchemes,
            fontRegular: fontRegular,
            fontBold: fontBold,
            fontOblique: fontOblique,
          ),
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
            'SCREENED HOUSEHOLD PROFILE DETAILS (${PdfFontHelper.shape("കുടുംബ വിവരങ്ങൾ")})',
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: const PdfColor.fromInt(0xFF006D77)),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(2.8),
              2: const pw.FlexColumnWidth(2.2),
              3: const pw.FlexColumnWidth(2.8),
            },
            children: [
              pw.TableRow(children: [
                _buildTableCell('Sector (${PdfFontHelper.shape("മേഖല")}):', fontBold, isLabel: true),
                _buildTableCell(occText, fontRegular),
                _buildTableCell('District (${PdfFontHelper.shape("ജില്ല")}):', fontBold, isLabel: true),
                _buildTableCell(profile.district ?? 'Not specified', fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Age (${PdfFontHelper.shape("വയസ്സ്")}):', fontBold, isLabel: true),
                _buildTableCell(profile.age != null ? '${profile.age} years' : 'Not answered', fontRegular),
                _buildTableCell('Board (${PdfFontHelper.shape("ബോർഡ്")}):', fontBold, isLabel: true),
                _buildTableCell(boardText, fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Ration Card (${PdfFontHelper.shape("കാർഡ്")}):', fontBold, isLabel: true),
                _buildTableCell(profile.rationCardCategory ?? 'Not answered', fontRegular),
                _buildTableCell('Housing (${PdfFontHelper.shape("ഭവനം")}):', fontBold, isLabel: true),
                _buildTableCell(profile.housingCondition ?? 'Not answered', fontRegular),
              ]),
              pw.TableRow(children: [
                _buildTableCell('Income (${PdfFontHelper.shape("വരുമാനം")}):', fontBold, isLabel: true),
                _buildTableCell(incomeText, fontRegular),
                _buildTableCell('Children (${PdfFontHelper.shape("മക്കൾ")}):', fontBold, isLabel: true),
                _buildTableCell(
                  profile.hasStudentChild == true
                      ? 'Yes (${PdfFontHelper.shape("ഉണ്ട്")})'
                      : profile.hasStudentChild == false
                          ? 'No (${PdfFontHelper.shape("ഇല്ല")})'
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

    final chEn = scheme.applicationChannelsEn.isNotEmpty ? scheme.applicationChannelsEn.first : '';
    final chMl = (scheme.applicationChannelsMl.isNotEmpty && scheme.applicationChannelsMl.first.isNotEmpty)
        ? ' (${PdfFontHelper.shape(scheme.applicationChannelsMl.first)})'
        : '';

    final stepEn = scheme.nextStepsEn.isNotEmpty ? scheme.nextStepsEn.first : '';
    final stepMl = (scheme.nextStepsMl.isNotEmpty && scheme.nextStepsMl.first.isNotEmpty)
        ? ' (${PdfFontHelper.shape(scheme.nextStepsMl.first)})'
        : '';

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
                      '${scheme.nameEn}${scheme.nameMl.isNotEmpty ? " (${PdfFontHelper.shape(scheme.nameMl)})" : ""}',
                      style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: PdfColors.black),
                    ),
                    pw.Text(
                      'Scheme Code: ${scheme.id}',
                      style: pw.TextStyle(font: fontOblique, fontSize: 8, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${scheme.departmentEn}${scheme.departmentMl.isNotEmpty ? " (${PdfFontHelper.shape(scheme.departmentMl)})" : ""} | Sector: ${scheme.category.toUpperCase()}',
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
              'Documents to Present (${PdfFontHelper.shape("ആവശ്യമായ രേഖകൾ")}):',
              style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: PdfColors.grey800),
            ),
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 8,
              runSpacing: 3,
              children: List.generate(scheme.requiredDocumentsEn.length, (idx) {
                final docEn = scheme.requiredDocumentsEn[idx];
                final docMl = (idx < scheme.requiredDocumentsMl.length && scheme.requiredDocumentsMl[idx].isNotEmpty)
                    ? ' (${PdfFontHelper.shape(scheme.requiredDocumentsMl[idx])})'
                    : '';
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
                    pw.Text('$docEn$docMl', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800)),
                  ],
                );
              }),
            ),
            pw.SizedBox(height: 6),
          ],

          // Application Channel and Next Steps
          if (scheme.applicationChannelsEn.isNotEmpty) ...[
            pw.Text(
              'Where to Apply (${PdfFontHelper.shape("എവിടെ അപേക്ഷിക്കാം")}): $chEn$chMl',
              style: pw.TextStyle(font: fontRegular, fontSize: 8, color: const PdfColor.fromInt(0xFF006D77)),
            ),
            pw.SizedBox(height: 2),
          ],

          if (scheme.nextStepsEn.isNotEmpty) ...[
            pw.Text(
              'Next Steps (${PdfFontHelper.shape("അടുത്ത ഘട്ടങ്ങൾ")}): $stepEn$stepMl',
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

  static pw.Widget _buildAkshayaOperatorViewPages({
    required HouseholdProfile profile,
    required List<EligibilityResult> potentialSchemes,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontOblique,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'AKSHAYA OPERATOR PROCESSING ROSTER (${PdfFontHelper.shape("അക്ഷയ ഓപ്പറേറ്റർ പ്രോസസ്സിംഗ് ഗൈഡ്")})',
          subtitle: 'Official intake protocol, physical document verification checklist, and direct portal upload routes',
          color: const PdfColor.fromInt(0xFF006D77),
          fontBold: fontBold,
          fontRegular: fontRegular,
        ),
        pw.SizedBox(height: 8),

        // Operator Verification Protocol Box
        pw.Container(
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
                'AKSHAYA OPERATOR VERIFICATION PROTOCOL (${PdfFontHelper.shape("ഓപ്പറേറ്റർ നിർദ്ദേശങ്ങൾ")})',
                style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF15803D)),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '1. Verify original ration card, welfare fund passbook, and bank passbook linked with Aadhaar before upload.\n'
                '2. Check off physical documents on the scanning checklist below as they are scanned and uploaded.\n'
                '3. Use the direct departmental portal URLs listed below to fast-track submission without manual re-typing.\n'
                '4. Issue official printed government acknowledgement receipt with reference tracking number.',
                style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: const PdfColor.fromInt(0xFF166534), height: 1.3),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Verified Applicant Profile Summary Box
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'VERIFIED APPLICANT INTAKE PROFILE (${PdfFontHelper.shape("അപേക്ഷകന്റെ വിവരങ്ങൾ")})',
                style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Sector: ${profile.occupation == "fishing" ? "Fishing Sector / മത്സ്യം" : profile.occupation == "plantation" ? "Plantation / തോട്ടം" : "Other Sector"}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8),
                  ),
                  pw.Text(
                    'District: ${profile.district ?? "Not specified"}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8),
                  ),
                  pw.Text(
                    'Age: ${profile.age != null ? "${profile.age} yrs" : "Not stated"}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8),
                  ),
                  pw.Text(
                    'Board: ${profile.isBoardMember == true ? "Member (${profile.yearsOfMembership ?? 0} yrs)" : "Not Registered"}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8),
                  ),
                  pw.Text(
                    'Ration: ${profile.rationCardCategory ?? "Not stated"}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),

        // Actionable Schemes with Physical Document Scanning Checklist & Portal URLs
        pw.Text(
          'SCHEME PROCESSING ROSTER & DOCUMENT SCANNING CHECKLIST',
          style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: const PdfColor.fromInt(0xFF006D77)),
        ),
        pw.SizedBox(height: 6),

        if (potentialSchemes.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'No actionable potential schemes found under current answers.',
              style: pw.TextStyle(font: fontOblique, fontSize: 8.5, color: PdfColors.grey700),
            ),
          )
        else
          ...potentialSchemes.map((r) => _buildOperatorSchemeCard(
                result: r,
                fontRegular: fontRegular,
                fontBold: fontBold,
                fontOblique: fontOblique,
              )),

        pw.SizedBox(height: 12),

        // Government Approved Akshaya Fee Schedule Transparency
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFFFFBEB),
            border: pw.Border.all(color: const PdfColor.fromInt(0xFFF59E0B), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'GOVERNMENT APPROVED AKSHAYA SERVICE FEE SCHEDULE (G.O. Rt. No. 12/2021/ITD)',
                style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF92400E)),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '• Online Welfare Application Upload: Max Rs. 25/-\n'
                '• Document Scanning & Upload: Rs. 5/- per page\n'
                '• Acknowledgement Receipt Printout: Rs. 3/-\n'
                'Statutory Notice: Charging excess fee above government mandated rates is strictly prohibited under Kerala IT Rules and punishable under law.',
                style: pw.TextStyle(font: fontRegular, fontSize: 8, color: const PdfColor.fromInt(0xFF78350F), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOperatorSchemeCard({
    required EligibilityResult result,
    required pw.Font fontRegular,
    required pw.Font fontBold,
    required pw.Font fontOblique,
  }) {
    final scheme = result.scheme;
    final nameEn = scheme.nameEn;
    final nameMl = scheme.nameMl.isNotEmpty ? ' (${PdfFontHelper.shape(scheme.nameMl)})' : '';
    final deptEn = scheme.departmentEn;
    final deptMl = scheme.departmentMl.isNotEmpty ? ' (${PdfFontHelper.shape(scheme.departmentMl)})' : '';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF006D77), width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '$nameEn$nameMl',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF006D77)),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFE0F2F1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  scheme.id,
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFF006D77)),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '$deptEn$deptMl',
            style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 5),

          // Portal Upload Link
          if (scheme.officialUrl != null && scheme.officialUrl!.isNotEmpty) ...[
            pw.Text(
              'Direct Official Portal: ${scheme.officialUrl}',
              style: pw.TextStyle(font: fontBold, fontSize: 8, color: const PdfColor.fromInt(0xFF1D4ED8)),
            ),
            pw.SizedBox(height: 4),
          ],

          // Checklist of physical documents for scanning
          pw.Text(
            'Physical Verification & Scanning Checklist (${PdfFontHelper.shape("പരിശോധിക്കേണ്ട രേഖകൾ")}):',
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800),
          ),
          pw.SizedBox(height: 3),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: List.generate(scheme.requiredDocumentsEn.length, (idx) {
              final docEn = scheme.requiredDocumentsEn[idx];
              final docMl = (idx < scheme.requiredDocumentsMl.length && scheme.requiredDocumentsMl[idx].isNotEmpty)
                  ? ' (${PdfFontHelper.shape(scheme.requiredDocumentsMl[idx])})'
                  : '';
              return pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    width: 9,
                    height: 9,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey700, width: 0.9),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text('$docEn$docMl', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey800)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
