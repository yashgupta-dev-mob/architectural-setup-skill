import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/note.dart';

/// Thrown when the server answered with an unexpected status code, or when
/// no answer arrived at all (then [statusCode] is 0).
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Thrown by [ApiService.fetchNotes] when the server answers 401.
class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'UnauthorizedException';
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://api.fieldnotes.example.com';

  final http.Client _client;

  /// POST /v1/auth/login. Returns the token on 200.
  Future<String> login(String email, String password) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/v1/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException(0, 'Request timed out');
    } on http.ClientException {
      throw const ApiException(0, 'Network error');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['token'] as String;
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(response, 'Login failed'),
    );
  }

  /// GET /v1/notes. Returns the notes on 200, throws
  /// [UnauthorizedException] on 401.
  Future<List<Note>> fetchNotes(String token) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$baseUrl/v1/notes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException(0, 'Request timed out');
    } on http.ClientException {
      throw const ApiException(0, 'Network error');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (body['notes'] as List<dynamic>?) ?? const <dynamic>[];
      return items
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    if (response.statusCode == 401) {
      throw const UnauthorizedException();
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(response, 'Failed to fetch notes'),
    );
  }

  /// POST /v1/notes. Returns the created note on 201.
  Future<Note> createNote(String token, String title, String body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/v1/notes'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'title': title, 'body': body}),
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException(0, 'Request timed out');
    } on http.ClientException {
      throw const ApiException(0, 'Network error');
    }

    if (response.statusCode == 201) {
      return Note.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(response, 'Failed to create note'),
    );
  }

  /// DELETE /v1/notes/{id}. Succeeds only on 204.
  Future<void> deleteNote(String token, String id) async {
    final http.Response response;
    try {
      response = await _client
          .delete(
            Uri.parse('$baseUrl/v1/notes/$id'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException(0, 'Request timed out');
    } on http.ClientException {
      throw const ApiException(0, 'Network error');
    }

    if (response.statusCode == 204) {
      return;
    }
    throw ApiException(
      response.statusCode,
      _errorMessage(response, 'Failed to delete note'),
    );
  }

  /// The server's `error` string when the body is a JSON object that has
  /// one, otherwise [fallback].
  String _errorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // Not a JSON body (for example an HTML error page).
    }
    return fallback;
  }
}
