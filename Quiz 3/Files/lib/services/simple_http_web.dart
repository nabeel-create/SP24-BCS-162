// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

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
    final response = await html.HttpRequest.request(
      uri.toString(),
      method: method,
      requestHeaders: headers,
      sendData: body == null ? null : jsonEncode(body),
    );
    return SimpleResponse(response.status ?? 0, response.responseText ?? '');
  }
}
