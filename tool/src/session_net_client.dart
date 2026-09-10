import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Reads the public SessionNet ("Bürgerinfo") instance of the city.
class SessionNetClient {
  SessionNetClient({
    required this.baseUrl,
    required this.mode,
    http.Client? httpClient,
    this.pauseBetweenRequests = const Duration(milliseconds: 250),
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String mode;
  final Duration pauseBetweenRequests;
  final http.Client _http;

  static const _userAgent =
      'council-pwa-scraper (+https://github.com/michaelsandner/council)';

  Uri _listUri(int year, {bool minutesOnly = false}) {
    return Uri.parse('$baseUrl/si0046.php').replace(
      queryParameters: {
        '__cjahr': '$year',
        '__cmonat': '1',
        '__canz': '12',
        if (minutesOnly) ...{'smccont': '12', '__cselect': '81920'},
        'smcmode': mode,
      },
    );
  }

  Uri documentUri(String documentId) {
    return Uri.parse('$baseUrl/getfile.php').replace(
      queryParameters: {'id': documentId, 'type': 'do', 'smcmode': mode},
    );
  }

  Future<String> fetchAppointments(int year) => _getText(_listUri(year));

  Future<String> fetchMinutesIndex(int year) =>
      _getText(_listUri(year, minutesOnly: true));

  Future<Uint8List> downloadDocument(String documentId) async {
    final response = await _get(documentUri(documentId));
    return response.bodyBytes;
  }

  Future<String> _getText(Uri uri) async => (await _get(uri)).body;

  Future<http.Response> _get(Uri uri) async {
    await Future<void>.delayed(pauseBetweenRequests);
    final response = await _http.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) {
      throw SessionNetException(uri, response.statusCode);
    }
    return response;
  }

  void close() => _http.close();
}

class SessionNetException implements Exception {
  const SessionNetException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'SessionNet request failed ($statusCode): $uri';
}
