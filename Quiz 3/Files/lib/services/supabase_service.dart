import 'dart:convert';

import '../models/submission.dart';
import 'simple_http.dart';

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  bool get isReady => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}

class SupabaseService {
  SupabaseService(this.config);

  final SupabaseConfig config;
  final SimpleHttp _http = SimpleHttp();

  Map<String, String> get _headers {
    return {
      'apikey': config.anonKey,
      'Authorization': 'Bearer ${config.anonKey}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Prefer': 'return=representation',
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = config.url.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base/rest/v1/$path').replace(queryParameters: query);
  }

  Future<List<Submission>> fetchSubmissions() async {
    _ensureReady();
    final response = await _http.request(
      'GET',
      _uri('submissions', {'select': '*', 'order': 'created_at.desc'}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded
        .map((row) => Submission.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Submission> createSubmission(Submission input) async {
    _ensureReady();
    final response = await _http.request(
      'POST',
      _uri('submissions'),
      headers: _headers,
      body: input.toInputJson(),
    );
    _throwIfNeeded(response);
    return Submission.fromJson(
      (jsonDecode(response.body) as List<dynamic>).first
          as Map<String, dynamic>,
    );
  }

  Future<Submission> updateSubmission(String id, Submission input) async {
    _ensureReady();
    final data = input.toInputJson()
      ..['updated_at'] = DateTime.now().toIso8601String();
    final response = await _http.request(
      'PATCH',
      _uri('submissions', {'id': 'eq.$id'}),
      headers: _headers,
      body: data,
    );
    _throwIfNeeded(response);
    return Submission.fromJson(
      (jsonDecode(response.body) as List<dynamic>).first
          as Map<String, dynamic>,
    );
  }

  Future<void> deleteSubmission(String id) async {
    _ensureReady();
    final response = await _http.request(
      'DELETE',
      _uri('submissions', {'id': 'eq.$id'}),
      headers: _headers,
    );
    _throwIfNeeded(response);
  }

  void _ensureReady() {
    if (!config.isReady) {
      throw Exception('Add your Supabase URL and anon API key first.');
    }
  }

  void _throwIfNeeded(SimpleResponse response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.body.contains('PGRST205') ||
        response.body.contains('schema cache')) {
      throw Exception('TABLE_NOT_FOUND');
    }
    throw Exception(
      response.body.isEmpty
          ? 'Request failed (${response.statusCode})'
          : response.body,
    );
  }
}
