import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/household_profile.dart';
import '../services/localization_service.dart';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart' as downloader;

/// Generates an official 1-page Malayalam Self-Declaration Affidavit (സത്യപ്രസ്താവന)
/// pre-filled with household screening details, ready to be presented to
/// the Village Officer, Akshaya Operator, or Welfare Board Inspector.
class SelfDeclarationService {
  /// Generates the raw PDF bytes for the self-declaration affidavit.
  static Future<Uint8List> generateAffidavitPdf({
    required HouseholdProfile profile,
    required LocalizationService loc,
  }) async {
    final pdf = pw.Document(compress: false);

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final fontRegular = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final fontOblique = pw.Font.helveticaOblique();

    final occRomanized = profile.occupation == 'fishing'
        ? 'Traditional Coastal Fishing & Allied Labor (Matsyathozhilali)'
        : profile.occupation == 'plantation'
            ? 'Plantation Labor - Tea/Coffee/Rubber/Cardamom (Thottam Thozhilali)'
            : profile.occupation == 'other'
                ? 'General / Other Informal Labor (Podhu Thozhil)'
                : 'Not specified';

    final boardRomanized = profile.isBoardMember == true
        ? 'Registered Welfare Board Member (Kshemanidhi Member - ${profile.yearsOfMembership != null ? "${profile.yearsOfMembership} Years" : "Duration unspecified"})'
        : profile.isBoardMember == false
            ? 'Not Registered with Welfare Board (Anangam Alla)'
            : 'Unsure / Verification Required';

    final cardRomanized = profile.rationCardCategory == 'AAY'
        ? 'Antyodaya Anna Yojana (AAY - Yellow Card / Atheeva Mun-ganana)'
        : profile.rationCardCategory == 'PHH'
            ? 'Priority Household (PHH - Pink Card / BPL Mun-ganana)'
            : profile.rationCardCategory == 'NPHH'
                ? 'Non-Priority Subsidy (NPHH - Blue Card / Mun-gananethara)'
                : profile.rationCardCategory == 'Non-Priority'
                    ? 'Non-Priority General (White Card / Podhu Vibhagam)'
                    : 'Not declared / Verification Required';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: const PdfColor.fromInt(0xFF006D77), width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'GOVERNMENT OF KERALA / WELFARE BOARD FACILITATION',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'SELF-DECLARATION AFFIDAVIT (SATHYA PRASTHAVANA)',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14.5,
                          color: const PdfColor.fromInt(0xFF006D77),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'For Welfare Entitlement Verification at Akshaya e-Centres & Village Offices',
                        style: pw.TextStyle(font: fontOblique, fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: const PdfColor.fromInt(0xFF006D77),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // Preamble Text
                pw.Text(
                  'TO WHOMSOEVER IT MAY CONCERN (ADHIKARIKAL MUNPAKE):',
                  style: pw.TextStyle(font: fontBold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'I hereby solemnly state that the household and socio-economic information '
                  'declared below has been submitted truthfully for preliminary screening against '
                  'Kerala State Welfare Schemes via Welfare Saathi.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9, height: 1.3),
                ),

                pw.SizedBox(height: 14),

                // Declared Profile Table
                pw.Text(
                  'DECLARED APPLICANT & HOUSEHOLD PARTICULARS (VIVARANANGAL):',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF006D77)),
                ),
                pw.SizedBox(height: 6),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.6),
                    1: const pw.FlexColumnWidth(4.4),
                  },
                  children: [
                    _buildTableRow('Primary Sector (Thozhil Mekhala):', occRomanized, fontBold, fontRegular),
                    _buildTableRow('District of Residence (Jilla):', profile.district != null ? '${profile.district} District' : 'Not specified', fontBold, fontRegular),
                    _buildTableRow('Applicant Age (Vayassu):', profile.age != null ? '${profile.age} Years' : 'Not declared', fontBold, fontRegular),
                    _buildTableRow('Welfare Board Membership (Kshemanidhi):', boardRomanized, fontBold, fontRegular),
                    _buildTableRow('Ration Card Category (Ration Card):', cardRomanized, fontBold, fontRegular),
                    _buildTableRow(
                      'Declared Monthly Income (Varumanam):',
                      profile.monthlyIncome != null ? 'Rs. ${profile.monthlyIncome} /- per month' : 'Not declared',
                      fontBold,
                      fontRegular,
                    ),
                    _buildTableRow(
                      'Housing Condition (Bhavanam):',
                      profile.housingCondition == 'dilapidated'
                          ? 'Dilapidated / Layam / Emergency Repairs Needed'
                          : 'General / Adequate Shelter',
                      fontBold,
                      fontRegular,
                    ),
                    _buildTableRow(
                      'Student Children (Makkal):',
                      profile.hasStudentChild == true ? 'Yes - Enrolled in Higher Secondary/College' : 'No / None declared',
                      fontBold,
                      fontRegular,
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // Formal Oath in Romanized & English
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DECLARATION & VERIFICATION (SATHYAVANGMULAM):',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '1. I hereby declare that all household and socio-economic particulars stated above are true and correct to the best of my knowledge and belief (Purna bodhyathil sathyasandhamanu).\n'
                        '2. I undertake to present original documents including Ration Card, Welfare Board Passbook, and Income Certificate upon request before the Village Officer or Akshaya Facilitator for verification.\n'
                        '3. This declaration is submitted truthfully for preliminary welfare entitlement screening under Kerala State Social Security and Welfare Board Schemes.',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, height: 1.35),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Signature & Seal Block
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date (Theeyathi): $formattedDate', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('Place (Sthalam): ${profile.district ?? "Kerala"}', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Akshaya Verification Seal / Village Office Seal',
                            style: pw.TextStyle(font: fontOblique, fontSize: 7, color: PdfColors.grey600),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          height: 35,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey500, width: 1)),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Signature / Thumb Impression\n(Oppu / Viraladayalam)',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: pw.TextStyle(font: fontRegular, fontSize: 8)),
        ),
      ],
    );
  }

  /// Exports or shares the Malayalam affidavit directly.
  static Future<void> exportAffidavit({
    required HouseholdProfile profile,
    required LocalizationService loc,
    bool share = false,
  }) async {
    final bytes = await generateAffidavitPdf(profile: profile, loc: loc);
    const filename = 'welfare_saathi_self_declaration.pdf';

    if (kIsWeb) {
      downloader.downloadPdfFile(bytes, filename);
    } else if (share) {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    } else {
      await Printing.layoutPdf(onLayout: (format) async => bytes, name: filename);
    }
  }
}
