import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../model/article.dart';

Future<List<Article>> getArticleByTitle(String title) async {
  final http.Client client = http.Client();
  try {
    final Uri url = Uri.https(
      'en.wikipedia.org',
      '/w/api.php',
      <String, Object?>{
        'action': 'query',
        'format': 'json',
        'titles': title.trim(),
        'prop': 'extracts',
        'explaintext': '',
      },
    );
    final http.Response response = await client.get(url);
    if (response.statusCode == 200) {
      final Map<String, Object?> jsonData =
          jsonDecode(response.body) as Map<String, Object?>;
      return Article.listFromJson(jsonData);
    } else {
      throw HttpException(
        '[WikipediaApiClient.getArticleByTitle] '
        'statusCode=${response.statusCode}, '
        'body=${response.body}',
      );
    }
  } on FormatException {
    rethrow;
  } finally {
    client.close();
  }
}
