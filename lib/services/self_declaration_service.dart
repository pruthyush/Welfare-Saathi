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

    final occMalayalam = profile.occupation == 'fishing'
        ? 'പരമ്പരാഗത മത്സ്യത്തൊഴിലാളി / അനുബന്ധ മത്സ്യ വിപണന മേഖല'
        : profile.occupation == 'plantation'
            ? 'തോട്ടം തൊഴിലാളി മേഖല (തേയില/കാപ്പി/റബ്ബർ/ഏലം)'
            : profile.occupation == 'other'
                ? 'ജനറൽ / മറ്റ് സ്വകാര്യ തൊഴിൽ'
                : 'വ്യക്തമാക്കിയിട്ടില്ല';

    final occEnglish = profile.occupation == 'fishing'
        ? 'Traditional Coastal Fishing / Allied Fish Labor'
        : profile.occupation == 'plantation'
            ? 'Plantation Labor (Tea/Coffee/Rubber/Cardamom)'
            : profile.occupation == 'other'
                ? 'General / Other Labor'
                : 'Not specified';

    final boardMalayalam = profile.isBoardMember == true
        ? 'രജിസ്റ്റർ ചെയ്ത ക്ഷേമനിധി അംഗം (${profile.yearsOfMembership != null ? "${profile.yearsOfMembership} വർഷം" : "കാലയളവ് വ്യക്തമല്ല"})'
        : profile.isBoardMember == false
            ? 'ക്ഷേമനിധി ബോർഡിൽ ഇതുവരെ രജിസ്റ്റർ ചെയ്തിട്ടില്ല'
            : 'ഉറപ്പില്ല / വ്യക്തമാക്കിയിട്ടില്ല';

    final cardMalayalam = profile.rationCardCategory == 'AAY'
        ? 'മഞ്ഞ കാർഡ് (AAY - അതീവ മുൻഗണനാ വിഭാഗം)'
        : profile.rationCardCategory == 'PHH'
            ? 'പിങ്ക് കാർഡ് (PHH - മുൻഗണനാ വിഭാഗം / ബി.പി.എൽ)'
            : profile.rationCardCategory == 'NPHH'
                ? 'നീല കാർഡ് (NPHH - മുൻഗണനേതര സബ്സിഡി കാർഡ്)'
                : profile.rationCardCategory == 'Non-Priority'
                    ? 'വെള്ള കാർഡ് (പൊതു വിഭാഗം)'
                    : 'രേഖപ്പെടുത്തിയിട്ടില്ല / ഉറപ്പില്ല';

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
                        'SELF DECLARATION AFFIDAVIT / സത്യപ്രസ്താവന',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
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
                  'TO WHOMSOEVER IT MAY CONCERN / അധികാരികൾ മുൻപാകെ:',
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
                  'DECLARED APPLICANT & HOUSEHOLD PARTICULARS / സാക്ഷ്യപ്പെടുത്തിയ വിവരങ്ങൾ:',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: const PdfColor.fromInt(0xFF006D77)),
                ),
                pw.SizedBox(height: 6),

                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(4.5),
                  },
                  children: [
                    _buildTableRow('Primary Sector / പ്രധാന തൊഴിൽ:', '$occEnglish\n($occMalayalam)', fontBold, fontRegular),
                    _buildTableRow('District of Residence / ജില്ല:', profile.district ?? 'Not specified (വ്യക്തമാക്കിയിട്ടില്ല)', fontBold, fontRegular),
                    _buildTableRow('Applicant Age / പ്രായം:', profile.age != null ? '${profile.age} Years (വയസ്സ്)' : 'Not declared', fontBold, fontRegular),
                    _buildTableRow('Welfare Board Membership / ക്ഷേമനിധി ബോർഡ്:', boardMalayalam, fontBold, fontRegular),
                    _buildTableRow('Ration Card Category / റേഷൻ കാർഡ്:', cardMalayalam, fontBold, fontRegular),
                    _buildTableRow(
                      'Declared Monthly Income / മാസവരുമാനം:',
                      profile.monthlyIncome != null ? 'Rs. ${profile.monthlyIncome} /-' : 'Not declared (രേഖപ്പെടുത്തിയിട്ടില്ല)',
                      fontBold,
                      fontRegular,
                    ),
                    _buildTableRow(
                      'Housing Condition / ഭവന അവസ്ഥ:',
                      profile.housingCondition == 'dilapidated'
                          ? 'Dilapidated / Layam / Emergency Repairs Needed (ലയം / അറ്റകുറ്റപ്പണി ആവശ്യമുള്ളത്)'
                          : 'General / Adequate (സാധാരണ ഭവനം)',
                      fontBold,
                      fontRegular,
                    ),
                    _buildTableRow(
                      'Student Children / പഠിക്കുന്ന മക്കൾ:',
                      profile.hasStudentChild == true ? 'Yes - Enrolled in Higher Secondary/College (ഉണ്ട്)' : 'No / None declared (ഇല്ല)',
                      fontBold,
                      fontRegular,
                    ),
                  ],
                ),

                pw.SizedBox(height: 18),

                // Formal Oath in Malayalam & English
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
                        'DECLARATION & VERIFICATION / സത്യവാങ്മൂലം:',
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '1. മുകളിൽ നൽകിയിട്ടുള്ള എല്ലാ വിവരങ്ങളും എന്റെ പൂർണ്ണ അറിവിലും ബോധ്യത്തിലും സത്യസന്ധമാണെന്ന് ഇതിനാൽ ഉറപ്പുനൽകുന്നു.\n'
                        '2. അർഹത പരിശോധനയ്ക്കായി ആവശ്യപ്പെടുന്ന യഥാർത്ഥ റേഷൻ കാർഡ്, ക്ഷേമനിധി പാസ്ബുക്ക്, വരുമാന സർട്ടിഫിക്കറ്റ് എന്നിവ വില്ലേജ് ഓഫീസർക്കോ അക്ഷയ ഓപ്പറേറ്റർക്കോ മുൻപാകെ ഹാജരാക്കാൻ ഞാൻ ബാധ്യസ്ഥനാണ്.\n'
                        '3. All facts stated above are accurate to the best of my knowledge and belief.',
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
                        pw.Text('Date / തീയതി: $formattedDate', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                        pw.SizedBox(height: 4),
                        pw.Text('Place / സ്ഥലം: ${profile.district ?? "Kerala"}', style: pw.TextStyle(font: fontRegular, fontSize: 8.5)),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'Akshaya Verification Seal / വില്ലേജ് ഓഫീസ് സീൽ',
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
                          'Signature / Thumb Impression\n(അപേക്ഷകന്റെ ഒപ്പ് / വിരലടയാളം)',
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
