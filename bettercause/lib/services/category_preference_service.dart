import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/category_preference_model.dart';
import '../utils/category_key_mapper.dart';

class CategoryPreferenceService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  CategoryPreferenceData _buildFoodTemplate() {
    return CategoryPreferenceData(
      categoryName: 'Food & Beverages',
      categoryIcon: '🍔',
      sections: [
        CategoryPreferenceSection(
          sectionTitle: 'Dietary Restrictions',
          options: [
            CategoryPreferenceOption(
              title: 'Vegan Diet',
              description: 'Excludes all animal products',
            ),
            CategoryPreferenceOption(
              title: 'Vegetarian',
              description: 'Includes fish, excludes other meats.',
            ),
            CategoryPreferenceOption(
              title: 'Pescatarian',
              description: 'Includes fish, excludes other meats.',
            ),
            CategoryPreferenceOption(
              title: 'Gluten-Free',
              description: 'Avoids wheat, barley, and rye',
            ),
            CategoryPreferenceOption(
              title: 'Lactose-Free',
              description: 'Avoids dairy containing lactose',
            ),
          ],
        ),
        CategoryPreferenceSection(
          sectionTitle: 'Health Goals',
          options: [
            CategoryPreferenceOption(
              title: 'Weight Loss',
              description: 'Low calorie and high protein foods',
            ),
            CategoryPreferenceOption(
              title: 'Muscle Gain',
              description: 'High protein and calorie dense',
            ),
            CategoryPreferenceOption(
              title: 'Balanced Diet',
              description: 'Maintain a moderate nutrient intake',
            ),
            CategoryPreferenceOption(
              title: 'Diabetic-Friendly',
              description: 'Moderate sugar, low GI choices',
            ),
            CategoryPreferenceOption(
              title: 'Heart Health',
              description: 'Unsaturated fats and low sodium',
            ),
            CategoryPreferenceOption(
              title: 'Energy Boost',
              description: 'Carbs, vitamins, and iron sources.',
            ),
          ],
        ),
        CategoryPreferenceSection(
          sectionTitle: 'Nutrient Preferences',
          options: [
            CategoryPreferenceOption(
              title: 'Low Sodium',
              description: 'Reduced sodium content',
            ),
            CategoryPreferenceOption(
              title: 'Low Sugar',
              description: 'Minimized added sugars',
            ),
            CategoryPreferenceOption(
              title: 'High Protein',
              description: 'More protein content',
            ),
            CategoryPreferenceOption(
              title: 'High Fiber',
              description: 'For good digestion and heart health',
            ),
            CategoryPreferenceOption(
              title: 'Low Fat',
              description: 'Reduced total fat content.',
            ),
            CategoryPreferenceOption(
              title: 'Low Cholesterol',
              description: 'Minimized cholesterol sources.',
            ),
          ],
        ),
        CategoryPreferenceSection(
          sectionTitle: 'Ingredients Sensitivity',
          options: [
            CategoryPreferenceOption(
              title: 'Nuts',
              description: 'Avoid tree nuts and peanuts',
            ),
            CategoryPreferenceOption(
              title: 'Soy',
              description: 'Avoid soy-based products',
            ),
            CategoryPreferenceOption(
              title: 'Eggs',
              description: 'Avoid foods containing eggs',
            ),
          ],
        ),
      ],
    );
  }

  Future<Map<String, bool>> _fetchServerStates(
    String userId,
    String categoryType,
  ) async {
    final url = Uri.parse(
      '$baseUrl/users/$userId/preferences/category?category=$categoryType',
    );

    print('🔍 [FETCH] Making GET request...');
    print('🔍 [FETCH] URL: $url');

    final res = await http.get(url);
    
    print('🔍 [FETCH] STATUS CODE: ${res.statusCode}');
    print('🔍 [FETCH] RAW RESPONSE: ${res.body}');

    if (res.statusCode != 200) {
      print('❌ [FETCH] Failed with status: ${res.statusCode}');
      throw Exception("Failed to load prefs: ${res.statusCode}");
    }

    final decoded = json.decode(res.body);
    print('🔍 [FETCH] DECODED TYPE: ${decoded.runtimeType}');
    print('🔍 [FETCH] DECODED VALUE: $decoded');

    // CASE A — backend returned [] (THIS IS THE BUG!)
    if (decoded is List) {
      print('⚠️ [FETCH] Backend returned array instead of object!');
      print('⚠️ [FETCH] This means the backend code is NOT updated yet!');
      return {};
    }

    // CASE B — backend returned { preferences: {...} }
    if (decoded is Map<String, dynamic>) {
      final prefs = decoded['preferences'];
      print('🔍 [FETCH] PREFERENCES: $prefs');

      if (prefs is Map<String, dynamic>) {
        final Map<String, bool> converted = {};
        prefs.forEach((backendKey, val) {
          final uiKey = CategoryKeyMapper.backendToUi(backendKey);
          print('🔍 [FETCH] MAPPING: $backendKey → $uiKey = $val');
          if (uiKey != null) {
            converted[uiKey] = val == true;
          }
        });
        print('✅ [FETCH] CONVERTED MAP: $converted');
        return converted;
      }
    }

    print('⚠️ [FETCH] Unexpected response format, returning empty map');
    return {};
  }

  Future<CategoryPreferenceData> getCategoryPreferences(
    String userId,
    String categoryType,
  ) async {
    print('🔍 [GET_PREFS] Getting preferences for $userId, $categoryType');
    
    CategoryPreferenceData base;
    if (categoryType == 'food_beverages') {
      base = _buildFoodTemplate();
    } else {
      base = _buildFoodTemplate();
    }

    final serverStates = await _fetchServerStates(userId, categoryType);
    print('🔍 [GET_PREFS] Server states: $serverStates');

    int enabledCount = 0;
    for (final section in base.sections) {
      for (final option in section.options) {
        final uiTitle = option.title;

        if (serverStates.containsKey(uiTitle)) {
          option.isEnabled = serverStates[uiTitle]!;
          if (option.isEnabled) enabledCount++;
          print('🔍 [GET_PREFS] Set "$uiTitle" = ${option.isEnabled}');
        }
      }
    }

    print('✅ [GET_PREFS] Total enabled: $enabledCount');
    return base;
  }

  Future<bool> updateCategoryPreference(
    String userId,
    String categoryType,
    String key,
    bool value,
  ) async {
    final url = Uri.parse('$baseUrl/users/$userId/preferences/category');
    final backendKey = CategoryKeyMapper.toBackendKey(key);

    print('🔍 [UPDATE] Making PATCH request...');
    print('🔍 [UPDATE] URL: $url');
    print('🔍 [UPDATE] UI Key: $key');
    print('🔍 [UPDATE] Backend Key: $backendKey');
    print('🔍 [UPDATE] Value: $value');

    final body = json.encode({
      'category': categoryType,
      'key': backendKey,
      'value': value,
    });
    
    print('🔍 [UPDATE] Request body: $body');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('🔍 [UPDATE] Response status: ${response.statusCode}');
    print('🔍 [UPDATE] Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ [UPDATE] Success!');
      return true;
    } else {
      print('❌ [UPDATE] Failed!');
      return false;
    }
  }
}