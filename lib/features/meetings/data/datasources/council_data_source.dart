import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads the JSON the scraper publishes next to the app.
///
/// Same origin as the PWA, so no CORS is involved; the council site itself
/// sends no `Access-Control-Allow-Origin` and cannot be read from a browser.
class CouncilDataSource {
  CouncilDataSource({http.Client? httpClient, Uri? baseUri})
    : _http = httpClient ?? http.Client(),
      _baseUri = baseUri ?? Uri.base;

  final http.Client _http;
  final Uri _baseUri;

  Future<Map<String, dynamic>> fetchIndex() => _fetchJson('data/index.json');

  Future<Map<String, dynamic>> fetchDetail(String meetingId) =>
      _fetchJson('data/meetings/$meetingId.json');

  Future<Map<String, dynamic>> _fetchJson(String path) async {
    final uri = _baseUri
        .resolve(path)
        .replace(
          queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
        );
    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw CouncilDataException(
        'Daten konnten nicht geladen werden (${response.statusCode}).',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class CouncilDataException implements Exception {
  const CouncilDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
