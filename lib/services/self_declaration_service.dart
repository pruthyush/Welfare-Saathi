import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/household_profile.dart';
import '../services/localization_service.dart';
import 'pdf_font_helper.dart';
import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart' as downloader;

/// Generates an official 1-page Malayalam Self-Declaration Affidavit (സത്യപ്രസ്താവന)
/// pre-filled with household screening details, ready to be presented to
/// the Village Officer, Akshaya Operator, or Welfare Board Inspector.
///
/// Features embedded Noto Sans Malayalam TrueType fonts and visual glyph shaping
/// for 100% vector-crisp rendering across all devices without system font dependencies.
class SelfDeclarationService {
  /// Generates the raw PDF bytes for the self-declaration affidavit.
  static Future<Uint8List> generateAffidavitPdf({
    required HouseholdProfile profile,
    required LocalizationService loc,
  }) async {
    final theme = await PdfFontHelper.getPdfTheme();
    final pdf = pw.Document(theme: theme, compress: false);

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    final fontBold = PdfFontHelper.getLatinBold();

    final occEnglish = profile.occupation == 'fishing'
        ? 'Traditional Coastal Fishing & Allied Labor'
        : profile.occupation == 'plantation'
            ? 'Plantation Labor (Tea/Coffee/Rubber/Cardamom)'
            : profile.occupation == 'other'
                ? 'General / Other Informal Labor'
                : 'Not specified';

    final occMalayalam = profile.occupation == 'fishing'
        ? 'പരമ്പരാഗത മത്സ്യത്തൊഴിലാളി'
        : profile.occupation == 'plantation'
            ? 'തോട്ടം തൊഴിലാളി'
            : profile.occupation == 'other'
                ? 'പൊതു തൊഴിലാളി'
                : 'വ്യക്തമാക്കിയിട്ടില്ല';

    final boardEnglish = profile.isBoardMember == true
        ? 'Registered Welfare Board Member (${profile.yearsOfMembership != null ? "${profile.yearsOfMembership} Years" : "Duration unspecified"})'
        : profile.isBoardMember == false
            ? 'Not Registered with Welfare Board'
            : 'Unsure / Verification Required';

    final boardMalayalam = profile.isBoardMember == true
        ? 'ക്ഷേമനിധി ബോർഡ് അംഗം'
        : profile.isBoardMember == false
            ? 'അംഗമല്ല'
            : 'പരിശോധന ആവശ്യമാണ്';

    final cardEnglish = profile.rationCardCategory == 'AAY'
        ? 'Antyodaya Anna Yojana (AAY - Yellow Card)'
        : profile.rationCardCategory == 'PHH'
            ? 'Priority Household (PHH - Pink Card / BPL)'
            : profile.rationCardCategory == 'NPHH'
                ? 'Non-Priority Subsidy (NPHH - Blue Card)'
                : profile.rationCardCategory == 'Non-Priority'
                    ? 'Non-Priority General (White Card)'
                    : 'Not declared / Verification Required';

    final cardMalayalam = profile.rationCardCategory == 'AAY'
        ? 'മഞ്ഞ കാർഡ് (AAY)'
        : profile.rationCardCategory == 'PHH'
            ? 'പിങ്ക് കാർഡ് (PHH)'
            : profile.rationCardCategory == 'NPHH'
                ? 'നീല കാർഡ് (NPHH)'
                : profile.rationCardCategory == 'Non-Priority'
                    ? 'വെള്ള കാർഡ്'
                    : 'രേഖപ്പെടുത്തിയിട്ടില്ല';

    final housingEnglish = profile.housingCondition == 'dilapidated'
        ? 'Dilapidated / Layam / Emergency Repairs Needed'
        : 'General / Adequate Shelter';

    final housingMalayalam = profile.housingCondition == 'dilapidated'
        ? 'വാസയോഗ്യമല്ലാത്ത വീട് / ലയം'
        : 'സാധാരണ ഭവനം';

    final studentEnglish = profile.hasStudentChild == true
        ? 'Yes - Enrolled in Higher Secondary/College'
        : 'No / None declared';

    final studentMalayalam = profile.hasStudentChild == true ? 'ഉണ്ട്' : 'ഇല്ല';

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
                        'SELF-DECLARATION AFFIDAVIT (${PdfFontHelper.shape("സത്യപ്രസ്താവന")})',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14.5,
                          color: const PdfColor.fromInt(0xFF006D77),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'For Welfare Entitlement Verification at Akshaya e-Centres & Village Offices',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      pw.Container(
                        margin: const pw.EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: const PdfColor.fromInt(0xFF006D77),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Preamble Text
                pw.Text(
                  'TO WHOMSOEVER IT MAY CONCERN (${PdfFontHelper.shape("അധികാരികൾ മുൻപാകെ")}):',
                  style: pw.TextStyle(font: fontBold, fontSize: 9.5),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'I hereby solemnly state that the household and socio-economic information '
                  'declared below has been submitted truthfully for preliminary screening against '
                  'Kerala State Welfare Schemes via Welfare Saathi.',
                  style: const pw.TextStyle(fontSize: 9, height: 1.3),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '(${PdfFontHelper.shape("ക്ഷേമ സാഥി വഴി ലഭ്യമായ വിവരങ്ങളുടെ അടിസ്ഥാനത്തിൽ എൻ്റെ കുടുംബ വിവരങ്ങൾ സത്യസന്ധമായി ഇവിടെ രേഖപ്പെടുത്തുന്നു.")})',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700, height: 1.25),
                ),

                pw.SizedBox(height: 12),

                // Declared Profile Table
                pw.Text(
                  'DECLARED APPLICANT & HOUSEHOLD PARTICULARS (${PdfFontHelper.shape("കുടുംബ വിവരങ്ങൾ")}):',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF006D77)),
                ),
                pw.SizedBox(height: 6),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3.0),
                    1: const pw.FlexColumnWidth(4.2),
                  },
                  children: [
                    _buildTableRow(
                      'Primary Sector (${PdfFontHelper.shape("പ്രധാന മേഖല")}):',
                      '$occEnglish\n(${PdfFontHelper.shape(occMalayalam)})',
                      fontBold,
                    ),
                    _buildTableRow(
                      'District of Residence (${PdfFontHelper.shape("താമസിക്കുന്ന ജില്ല")}):',
                      '${profile.district ?? "Not specified"} District',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Applicant Age (${PdfFontHelper.shape("അപേക്ഷകന്റെ വയസ്സ്")}):',
                      profile.age != null
                          ? '${profile.age} Years (${profile.age} ${PdfFontHelper.shape("വയസ്സ്")})'
                          : 'Not declared',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Welfare Board Membership (${PdfFontHelper.shape("ക്ഷേമ ബോർഡ് അംഗത്വം")}):',
                      '$boardEnglish\n(${PdfFontHelper.shape(boardMalayalam)})',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Ration Card Category (${PdfFontHelper.shape("റേഷൻ കാർഡ്")}):',
                      '$cardEnglish\n(${PdfFontHelper.shape(cardMalayalam)})',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Monthly Income (${PdfFontHelper.shape("പ്രതിമാസ വരുമാനം")}):',
                      profile.monthlyIncome != null ? 'Rs. ${profile.monthlyIncome} /- per month' : 'Not declared',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Housing Condition (${PdfFontHelper.shape("ഭവന സ്ഥിതി")}):',
                      '$housingEnglish\n(${PdfFontHelper.shape(housingMalayalam)})',
                      fontBold,
                    ),
                    _buildTableRow(
                      'Student Children (${PdfFontHelper.shape("വിദ്യാർത്ഥികളായ മക്കൾ")}):',
                      '$studentEnglish (${PdfFontHelper.shape(studentMalayalam)})',
                      fontBold,
                    ),
                  ],
                ),

                pw.SizedBox(height: 14),

                // Formal Oath in English & Malayalam
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
                        'DECLARATION & VERIFICATION (${PdfFontHelper.shape("സത്യവാങ്മൂലം")}):',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '1. I hereby declare that all household and socio-economic particulars stated above are true and correct to the best of my knowledge and belief.\n'
                        '   (${PdfFontHelper.shape("മുകളിൽ പ്രസ്താവിച്ചിട്ടുള്ള വിവരങ്ങളെല്ലാം എൻ്റെ പൂർണ്ണ ബോധ്യത്തിലും അറിവിലും സത്യസന്ധവുമാണ്.")})\n'
                        '2. I undertake to present original documents including Ration Card, Welfare Board Passbook, and Income Certificate upon request before the Village Officer or Akshaya Facilitator for verification.\n'
                        '   (${PdfFontHelper.shape("ആവശ്യപ്പെടുന്ന പക്ഷം റേഷൻ കാർഡ്, ക്ഷേമനിധി പാസ്ബുക്ക് തുടങ്ങിയ അസൽ രേഖകൾ പരിശോധനയ്ക്കായി ഹാജരാക്കാം.")})\n'
                        '3. This declaration is submitted truthfully for preliminary welfare entitlement screening under Kerala State Social Security and Welfare Board Schemes.',
                        style: const pw.TextStyle(fontSize: 7.8, height: 1.35),
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
                        pw.Text('Date (${PdfFontHelper.shape("തീയതി")}): $formattedDate', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('Place (${PdfFontHelper.shape("സ്ഥലം")}): ${profile.district ?? "Kerala"}', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Akshaya Verification Seal / Village Office Seal',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
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
                          'Signature / Thumb Impression\n(${PdfFontHelper.shape("ഒപ്പ് / വിരലടയാളം")})',
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
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 8, height: 1.25)),
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
