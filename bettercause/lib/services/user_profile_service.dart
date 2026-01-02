import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile_model.dart';
import '../models/user_preferences_model.dart';
import '../models/category_preference_model.dart';
import '../services/category_preference_service.dart';


class ProfileService {
  static const String baseUrl = 'https://englacial-joelle-nondichogamic.ngrok-free.dev/api';

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

  Future<UserPreferences> getUserPreferences(String userId) async {
  print('🔍 [GET_USER_PREFS] ========== STARTING ==========');
  print('🔍 [GET_USER_PREFS] Fetching preferences for userId: $userId');

  // Fetch category preferences (food & beverages)
  final categoryService = CategoryPreferenceService();
  
  CategoryPreferenceData? categoryData;
  try {
    categoryData = await categoryService.getCategoryPreferences(
      userId,
      'food_beverages',
    );
    print('🔍 [GET_USER_PREFS] ✅ Got category data');
  } catch (e) {
    print('❌ [GET_USER_PREFS] Error fetching category data: $e');
    // Continue with empty data
  }

  // Fetch user profile to get personal values
  UserProfile? profile;
  try {
    profile = await getUserProfile(userId);
    print('🔍 [GET_USER_PREFS] ✅ Got user profile');
    print('🔍 [GET_USER_PREFS] Personal values: ${profile.personalValues}');
  } catch (e) {
    print('❌ [GET_USER_PREFS] Error fetching profile: $e');
    // Continue with empty data
  }

  // Convert CategoryPreferenceData → UserPreferences
  final preferenceTags = <String>[];
  final avoidIngredients = <String>[];
  
  if (categoryData != null) {
    print('🔍 [GET_USER_PREFS] Processing ${categoryData.sections.length} sections');
    
    for (var section in categoryData.sections) {
      print('🔍 [GET_USER_PREFS] Section: "${section.sectionTitle}" with ${section.options.length} options');
      
      for (var option in section.options) {
        print('🔍 [GET_USER_PREFS]   Option: "${option.title}" = ${option.isEnabled}');
        
        if (!option.isEnabled) continue;
        
        print('✅ [GET_USER_PREFS]   ✓ ENABLED: "${option.title}"');
        
        // Map to preference tags (for Personal Fit)
        if (section.sectionTitle == 'Dietary Restrictions') {
          preferenceTags.add(option.title);
          print('🔍 [GET_USER_PREFS]     → Added to preferenceTags');
        } else if (section.sectionTitle == 'Health Goals') {
          preferenceTags.add(option.title);
          print('🔍 [GET_USER_PREFS]     → Added to preferenceTags');
        } else if (section.sectionTitle == 'Nutrient Preferences') {
          preferenceTags.add(option.title);
          print('🔍 [GET_USER_PREFS]     → Added to preferenceTags');
        }
        
        // Map to avoid list (for Ingredient Compatibility)
        if (section.sectionTitle == 'Ingredients Sensitivity') {
          avoidIngredients.add(option.title.toLowerCase());
          print('🔍 [GET_USER_PREFS]     → Added to avoidIngredients');
        }
      }
    }
  } else {
    print('⚠ [GET_USER_PREFS] No category data available!');
  }

  // Extract health conditions from personal values
  final healthConditions = <String>[];
  
  if (profile != null) {
    print('🔍 [GET_USER_PREFS] Processing personal values...');
    profile.personalValues.forEach((key, isEnabled) {
      print('🔍 [GET_USER_PREFS]   Personal value: "$key" = $isEnabled');
      
      if (isEnabled) {
        // Map personal values to health conditions
        final condition = key.toLowerCase()
            .replaceAll('-friendly', '')
            .replaceAll('_', ' ')
            .trim();
        healthConditions.add(condition);
        print('✅ [GET_USER_PREFS]     → Added to healthConditions: "$condition"');
      }
    });
  } else {
    print('⚠ [GET_USER_PREFS] No profile data available!');
  }

  print('🔍 [GET_USER_PREFS] ========== RESULTS ==========');
  print('🔍 [GET_USER_PREFS] Preference tags (${preferenceTags.length}): $preferenceTags');
  print('🔍 [GET_USER_PREFS] Avoid ingredients (${avoidIngredients.length}): $avoidIngredients');
  print('🔍 [GET_USER_PREFS] Health conditions (${healthConditions.length}): $healthConditions');
  print('🔍 [GET_USER_PREFS] ========== DONE ==========');

  return UserPreferences(
    preferenceTags: preferenceTags,
    avoidIngredients: avoidIngredients,
    healthConditions: healthConditions,
  );
  }

  Future<void> logout(String userId) async {
    // Implement logout logic
    print('🔍 [LOGOUT] User $userId logged out');
  }

  // ADD THIS METHOD to your existing ProfileService class

}