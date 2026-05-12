import 'dart:convert';
import 'dart:io';

class SimpleResponse {
  const SimpleResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

class SimpleHttp {
  Future<SimpleResponse> request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      headers?.forEach(request.headers.set);
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      return SimpleResponse(
        response.statusCode,
        await response.transform(utf8.decoder).join(),
      );
    } finally {
      client.close();
    }
  }
}
