import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which documents the reader has already been shown, so a newly
/// published Bekanntmachung or Niederschrift can be marked as new.
class SeenDocumentsStore {
  const SeenDocumentsStore();

  static const _key = 'seen_document_ids';

  Future<Set<String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> save(Set<String> documentIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_key, documentIds.toList());
  }
}
