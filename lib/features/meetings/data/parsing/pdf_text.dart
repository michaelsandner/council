const _hyphenKeepers = {'und', 'oder', 'bzw', 'sowie', 'bis', 'als', 'wie'};

final _pageFooter = RegExp(r'Seite\s+\d+\s+von\s+\d+');

/// Item numbers are `4.` or `6.1.`. The 1-2 digit limit per segment keeps a
/// date such as `25.11.2025.` from matching, and the two-space gap keeps an
/// enumeration inside a Beschluss (`3. Die Verwaltung ...`, one space) apart
/// from a real item, whose title is padded out to a fixed column.
final _numbered = RegExp(r'^(\d{1,2}(?:\.\d{1,2})*\.)\s{2,}(\S.*)$');

class TextLine {
  const TextLine(this.text, this.indent);

  final String text;
  final int indent;

  bool get isBlank => text.isEmpty;
}

List<TextLine> toLines(String raw) {
  return raw.split('\n').map((line) {
    final withoutTabs = line.replaceAll('\t', '    ').replaceAll('\r', '');
    final trimmed = withoutTabs.trimRight();
    final indent = trimmed.length - trimmed.trimLeft().length;
    return TextLine(trimmed.trim(), trimmed.isEmpty ? 0 : indent);
  }).toList();
}

List<TextLine> withoutPageFurniture(List<TextLine> lines) {
  return lines.where((line) => !_pageFooter.hasMatch(line.text)).toList();
}

String normalizeSpaces(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Joins wrapped lines back into paragraphs, undoing the hyphenation that
/// pdftotext preserves from the justified source layout.
String joinWrapped(Iterable<String> lines) {
  var result = '';
  for (final line in lines) {
    final piece = line.trim();
    if (piece.isEmpty) {
      if (result.isNotEmpty && !result.endsWith('\n\n')) result += '\n\n';
      continue;
    }
    if (result.isEmpty || result.endsWith('\n\n')) {
      result += piece;
      continue;
    }
    if (_continuesHyphenatedWord(result, piece)) {
      result = stripHyphen(result) + piece;
    } else {
      result += ' $piece';
    }
  }
  return result.trim();
}

bool _continuesHyphenatedWord(String soFar, String next) {
  if (!soFar.endsWith('-')) return false;
  final firstWord = next.split(RegExp(r'[\s,.;:]')).first.toLowerCase();
  if (firstWord.isEmpty || _hyphenKeepers.contains(firstWord)) return false;
  final firstChar = next[0];
  if (firstChar != firstChar.toLowerCase()) return false;
  final beforeHyphen = soFar.substring(0, soFar.length - 1);
  if (beforeHyphen.isEmpty) return false;
  return RegExp(r'[a-zäöüß]$').hasMatch(beforeHyphen);
}

/// Removes the trailing hyphen when the two halves are joined directly.
String stripHyphen(String value) =>
    value.endsWith('-') ? value.substring(0, value.length - 1) : value;

({String number, String rest})? matchNumberedItem(String line) {
  final match = _numbered.firstMatch(line);
  if (match == null) return null;
  return (number: match.group(1)!, rest: match.group(2)!.trim());
}

DateTime? parseGermanDate(String value) {
  final match = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(value);
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
  );
}

String? parseTime(String value) =>
    RegExp(r'(\d{1,2}:\d{2})').firstMatch(value)?.group(1);

int? parseSessionNumber(String heading) {
  final match = RegExp(r'^(\d+)\.\s*Sitzung').firstMatch(heading.trim());
  return match == null ? null : int.parse(match.group(1)!);
}

/// Bump when a parser change makes previously stored results outdated; the
/// scraper re-parses every document when the published version differs.
const parserVersion = 4;
