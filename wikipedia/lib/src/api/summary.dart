import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import '../model/summary.dart';

Future<Summary> getRandomSummary() async {
  final http.Client client = http.Client();

  try {
    final url = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/random/summary',
    );

    final http.Response response = await client.get(url);

    if (response.statusCode == 200) {
      final Map<String, Object?> jsonData = jsonDecode(response.body) as Map<String, Object?>;
      return Summary.fromJson(jsonData);
    } else {
      throw HttpException(
        '[WikipediaApiClient.getRandomArticleSummary] '
        'statusCode=${response.statusCode}, body=${response.body}',
      );
    }
  } on FormatException {
    rethrow;
  } finally {
    client.close();
  }
}

Future<Summary> getArticleSummaryByTitle(String articleTitle) async {
  final http.Client client = http.Client();
  try {
    final Uri url = Uri.https(
      'en.wikipedia.org',
      '/api/rest_v1/page/summary/$articleTitle',
    );
    final http.Response response = await client.get(url);
    if (response.statusCode == 200) {
      final Map<String, Object?> jsonData =
          jsonDecode(response.body) as Map<String, Object?>;
      return Summary.fromJson(jsonData);
    } else {
      throw HttpException(
        '[WikipediaApiClient.getArticleSummaryByTitle] '
        'statusCode=${response.statusCode}, body=${response.body}',
      );
    }
  } on FormatException {
    // todo: log exceptions
    rethrow;
  } finally {
    client.close();
  }
}