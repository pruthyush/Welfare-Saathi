import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Reorders pre-base and two-part Malayalam vowels to visual order for PDF rendering,
/// and normalizes chillaksharams to atomic Unicode codepoints (U+0D7A..U+0D7F).
String shapeMalayalamForPdf(String text) {
  // 1. Normalize legacy chillu sequences (Consonant + Virama + ZWJ or standalone chillu)
  var s = text
      .replaceAll('ര്\u200D', 'ർ')
      .replaceAll('ന്\u200D', 'ൻ')
      .replaceAll('ല്\u200D', 'ൽ')
      .replaceAll('ള്\u200D', 'ൾ')
      .replaceAll('ണ്\u200D', 'ൺ')
      .replaceAll('ക്\u200D', 'ൿ');

  final runes = s.runes.toList();
  final result = <int>[];

  // Helper to check if a rune is a Malayalam consonant (0x0D15..0x0D3A)
  bool isConsonant(int r) => (r >= 0x0D15 && r <= 0x0D3A);
  bool isVirama(int r) => r == 0x0D4D;

  int i = 0;
  while (i < runes.length) {
    // Check if current rune is a consonant
    if (isConsonant(runes[i])) {
      // Find the entire consonant cluster: C (+ virama + C)*
      int clusterStart = i;
      int clusterEnd = i + 1;
      while (clusterEnd < runes.length - 1 &&
          isVirama(runes[clusterEnd]) &&
          isConsonant(runes[clusterEnd + 1])) {
        clusterEnd += 2;
      }

      // Check if cluster is followed by a vowel sign
      if (clusterEnd < runes.length) {
        int vowel = runes[clusterEnd];
        // Pre-base vowels: െ (0x0D46), േ (0x0D47), ൈ (0x0D48)
        if (vowel == 0x0D46 || vowel == 0x0D47 || vowel == 0x0D48) {
          result.add(vowel); // Place vowel before cluster
          for (int c = clusterStart; c < clusterEnd; c++) {
            result.add(runes[c]);
          }
          i = clusterEnd + 1;
          continue;
        }
        // Two-part vowels:
        // ൊ (0x0D4A) -> െ (0x0D46) + Cluster + ാ (0x0D3E)
        else if (vowel == 0x0D4A) {
          result.add(0x0D46);
          for (int c = clusterStart; c < clusterEnd; c++) {
            result.add(runes[c]);
          }
          result.add(0x0D3E);
          i = clusterEnd + 1;
          continue;
        }
        // ോ (0x0D4B) -> േ (0x0D47) + Cluster + ാ (0x0D3E)
        else if (vowel == 0x0D4B) {
          result.add(0x0D47);
          for (int c = clusterStart; c < clusterEnd; c++) {
            result.add(runes[c]);
          }
          result.add(0x0D3E);
          i = clusterEnd + 1;
          continue;
        }
        // ൌ (0x0D4C) -> െ (0x0D46) + Cluster + ൗ (0x0D57)
        else if (vowel == 0x0D4C) {
          result.add(0x0D46);
          for (int c = clusterStart; c < clusterEnd; c++) {
            result.add(runes[c]);
          }
          result.add(0x0D57);
          i = clusterEnd + 1;
          continue;
        }
      }
    }

    result.add(runes[i]);
    i++;
  }

  return String.fromCharCodes(result);
}

void main() {
  test('Test Malayalam font rendering with visual reordering', () async {
    final regularBytes = File('assets/fonts/NotoSansMalayalam-Regular.ttf').readAsBytesSync();
    final boldBytes = File('assets/fonts/NotoSansMalayalam-Bold.ttf').readAsBytesSync();

    final fontMalayalam = pw.Font.ttf(ByteData.view(regularBytes.buffer));
    final fontMalayalamBold = pw.Font.ttf(ByteData.view(boldBytes.buffer));

    final fontLatin = pw.Font.helvetica();
    final fontLatinBold = pw.Font.helveticaBold();

    final theme = pw.ThemeData.withFont(
      base: fontLatin,
      bold: fontLatinBold,
      fontFallback: [fontMalayalam, fontMalayalamBold],
    );

    final pdf = pw.Document(theme: theme, compress: false);

    final styleRegular = pw.TextStyle(
      font: fontLatin,
      fontFallback: [fontMalayalam],
      fontSize: 10,
    );
    final styleBold = pw.TextStyle(
      font: fontLatinBold,
      fontFallback: [fontMalayalamBold, fontMalayalam],
      fontSize: 12,
    );

    final lines = [
      'GOVERNMENT OF KERALA / WELFARE BOARD FACILITATION',
      'SELF DECLARATION AFFIDAVIT (സത്യപ്രസ്താവന)',
      'Primary Sector (പ്രധാന മേഖല)',
      'District of Residence (താമസിക്കുന്ന ജില്ല)',
      'Applicant Age (അപേക്ഷകന്റെ വയസ്സ്)',
      'Monthly Income (പ്രതിമാസ വരുമാനം)',
      'Housing Condition (ഭവന സ്ഥിതി)',
      'Required Documents (ആവശ്യമായ രേഖകൾ)',
      'Where to Apply (എവിടെ അപേക്ഷിക്കാം)',
      'Next Steps (അടുത്ത ഘട്ടങ്ങൾ)',
      'Potentially Eligible (സാധ്യതയുള്ള അർഹത)',
      'കുടുംബ വിവരങ്ങൾ',
      'തൊഴിൽ',
      'നിങ്ങളുടെ വിവരങ്ങൾ പരിശോധിക്കുക',
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (var line in lines) ...[
                pw.Text(
                  shapeMalayalamForPdf(line),
                  style: line.startsWith('GOV') || line.startsWith('SELF') ? styleBold : styleRegular,
                ),
                pw.SizedBox(height: 6),
              ],
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    expect(bytes.isNotEmpty, isTrue);
    File('test_output_malayalam.pdf').writeAsBytesSync(bytes);
  });
}
