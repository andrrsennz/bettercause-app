import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _baseUrlAndroid = 'http://10.0.2.2:8080/api/auth';
  static const String _baseUrliOS = 'http://localhost:8080/api/auth';

  final _storage = const FlutterSecureStorage();

  String _resolveBaseUrl() {
    if (Platform.isAndroid) return _baseUrlAndroid;
    if (Platform.isIOS) return _baseUrliOS;
    return _baseUrliOS;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${_resolveBaseUrl()}/register');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      await _storage.write(key: "token", value: data['token']);
      await _storage.write(key: "userId", value: data['userId']);
      await _storage.write(key: "name", value: data['name']);
      await _storage.write(key: "email", value: data['email']);
      return data;
    }

    throw Exception(data["message"]);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${_resolveBaseUrl()}/login');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      await _storage.write(key: "token", value: data['token']);
      await _storage.write(key: "userId", value: data['userId']);
      await _storage.write(key: "name", value: data['name']);
      await _storage.write(key: "email", value: data['email']);
      return data;
    }

    throw Exception(data["message"]);
  }
}
