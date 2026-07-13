import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiClient {
  static const String tokenKey = 'ejari_token';
  static const String legacyTokenKey = 'user_token';
  static const String apiBaseUrlKey = 'api_base_url';

  static http.Response _demoResponse(String path, {String method = 'GET'}) {
    final payload = jsonEncode({
      'success': false,
      'demo': true,
      'method': method,
      'path': path,
      'message': 'Remote API calls are disabled in demo mode',
    });
    return http.Response(payload, 501,
        headers: {'content-type': 'application/json; charset=utf-8'});
  }

  // Get backend API base URL dynamically
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customUrl = prefs.getString(apiBaseUrlKey);
    if (customUrl != null && customUrl.isNotEmpty) {
      return customUrl;
    }

    return AppConfig.resolvedApiBaseUrl;
  }

  // Get stored authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token != null) {
      return token.isNotEmpty ? token : null;
    }

    final legacyToken = prefs.getString(legacyTokenKey);
    return legacyToken != null && legacyToken.isNotEmpty ? legacyToken : null;
  }

  // Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Clear authentication token
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(legacyTokenKey);
  }

  // Common headers builder
  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // HTTP GET request
  static Future<http.Response> get(String path) async {
    if (AppConfig.demoMode) return _demoResponse(path);
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) return _demoResponse(path);
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    debugPrint('API GET Request: $uri');
    return await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }

  // HTTP POST request
  static Future<http.Response> post(
      String path, Map<String, dynamic> body) async {
    if (AppConfig.demoMode) return _demoResponse(path, method: 'POST');
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) return _demoResponse(path, method: 'POST');
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    debugPrint('API POST Request: $uri');
    return await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  // HTTP PUT request
  static Future<http.Response> put(
      String path, Map<String, dynamic> body) async {
    if (AppConfig.demoMode) return _demoResponse(path, method: 'PUT');
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) return _demoResponse(path, method: 'PUT');
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    debugPrint('API PUT Request: $uri');
    return await http
        .put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  // HTTP DELETE request
  static Future<http.Response> delete(String path) async {
    if (AppConfig.demoMode) return _demoResponse(path, method: 'DELETE');
    final baseUrl = await getBaseUrl();
    if (baseUrl.isEmpty) return _demoResponse(path, method: 'DELETE');
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();

    debugPrint('API DELETE Request: $uri');
    return await http
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 10));
  }
}
