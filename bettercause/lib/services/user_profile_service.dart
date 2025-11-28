import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';

class ProfileService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  Future<UserProfile> getUserProfile(String userId) async {
    final url = Uri.parse('$baseUrl/users/$userId/profile');
    
    print('🔍 [PROFILE] Fetching profile for userId: $userId');
    
    final res = await http.get(url);

    print('🔍 [PROFILE] Status: ${res.statusCode}');
    print('🔍 [PROFILE] Response: ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    final data = json.decode(res.body);
    return UserProfile.fromJson(data);
  }

  Future<bool> updatePersonalValue(String userId, String key, bool value) async {
    final url = Uri.parse('$baseUrl/users/$userId/preferences/personal');

    print('🔍 [PERSONAL] Making PATCH request...');
    print('🔍 [PERSONAL] URL: $url');
    print('🔍 [PERSONAL] Key: $key');
    print('🔍 [PERSONAL] Value: $value');

    final body = json.encode({
      'key': key,
      'value': value,
    });

    print('🔍 [PERSONAL] Request body: $body');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('🔍 [PERSONAL] Response status: ${response.statusCode}');
    print('🔍 [PERSONAL] Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ [PERSONAL] Success!');
      return true;
    } else {
      print('❌ [PERSONAL] Failed!');
      return false;
    }
  }

  Future<void> logout(String userId) async {
    // Implement logout logic
    print('🔍 [LOGOUT] User $userId logged out');
  }
}