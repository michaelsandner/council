import 'dart:io';

import 'src/council_archive.dart';
import 'src/pdf_text_extractor.dart';
import 'src/scrape_runner.dart';
import 'src/session_net_client.dart';

const _baseUrl = 'https://www.buergerinfo-langenzenn.de';
const _mode = '32832';
const _outputPath = 'web/data';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final extractor = const PdfTextExtractor();
  await extractor.ensureAvailable();

  final client = SessionNetClient(baseUrl: _baseUrl, mode: _mode);
  final runner = ScrapeRunner(
    client: client,
    archive: CouncilArchive(Directory(options.output)),
    extractor: extractor,
    log: stdout.writeln,
  );

  try {
    final report = await runner.run(
      fromYear: options.fromYear,
      toYear: options.toYear,
    );
    stdout.writeln(report);
    exitCode = 0;
  } finally {
    client.close();
  }
}

class _Options {
  _Options({required this.fromYear, required this.toYear, required this.output});

  final int fromYear;
  final int toYear;
  final String output;

  static _Options parse(List<String> args) {
    final now = DateTime.now().year;
    var fromYear = now - 3;
    var toYear = now + 1;
    var output = _outputPath;

    for (final arg in args) {
      final parts = arg.split('=');
      if (parts.length != 2) continue;
      switch (parts.first) {
        case '--from-year':
          fromYear = int.parse(parts.last);
        case '--to-year':
          toYear = int.parse(parts.last);
        case '--output':
          output = parts.last;
      }
    }
    return _Options(fromYear: fromYear, toYear: toYear, output: output);
  }
}
