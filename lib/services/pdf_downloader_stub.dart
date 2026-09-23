import 'dart:typed_data';

/// Fallback / VM stub for non-web environments (such as unit testing).
void downloadPdfFile(Uint8List bytes, String filename) {
  // No-op on Dart VM / test runner
}
