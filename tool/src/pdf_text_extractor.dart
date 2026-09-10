import 'dart:io';
import 'dart:typed_data';

/// Extracts the text layer of a PDF via poppler's `pdftotext`.
///
/// `-layout` keeps the column alignment the minutes rely on, so the parsers
/// can tell a heading apart from an indented continuation line.
class PdfTextExtractor {
  const PdfTextExtractor({this.executable = 'pdftotext'});

  final String executable;

  Future<String> extract(Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp('council_pdf');
    final file = File('${directory.path}/document.pdf');
    try {
      await file.writeAsBytes(bytes);
      final result = await Process.run(executable, [
        '-layout',
        '-enc',
        'UTF-8',
        file.path,
        '-',
      ]);
      if (result.exitCode != 0) {
        throw PdfExtractionException('${result.stderr}'.trim());
      }
      return result.stdout as String;
    } finally {
      await directory.delete(recursive: true);
    }
  }

  Future<void> ensureAvailable() async {
    try {
      final result = await Process.run(executable, ['-v']);
      if (result.exitCode != 0 && result.exitCode != 99) {
        throw PdfExtractionException('`$executable -v` failed');
      }
    } on ProcessException catch (error) {
      throw PdfExtractionException(
        '`$executable` not found (${error.message}). '
        'Install poppler-utils (Linux) or `brew install poppler` (macOS).',
      );
    }
  }
}

class PdfExtractionException implements Exception {
  const PdfExtractionException(this.message);

  final String message;

  @override
  String toString() => 'PDF extraction failed: $message';
}
