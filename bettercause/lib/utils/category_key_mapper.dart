class CategoryKeyMapper {
  static final Map<String, String> uiToBackend = {
    'Vegan Diet': 'vegan_diet',
    'Vegetarian': 'vegetarian',
    'Pescatarian': 'pescatarian',
    'Gluten-Free': 'gluten_free',
    'Lactose-Free': 'lactose_free',

    'Weight Loss': 'weight_loss',
    'Muscle Gain': 'muscle_gain',
    'Balanced Diet': 'balanced_diet',
    'Diabetic-Friendly': 'diabetic_friendly',
    'Heart Health': 'heart_health',
    'Energy Boost': 'energy_boost',

    'Low Sodium': 'low_sodium',
    'Low Sugar': 'low_sugar',
    'High Protein': 'high_protein',
    'High Fiber': 'high_fiber',
    'Low Fat': 'low_fat',
    'Low Cholesterol': 'low_cholesterol',

    'Nuts': 'nuts',
    'Soy': 'soy',
    'Eggs': 'eggs',
  };

  // UI → backend
  static String toBackendKey(String uiKey) {
    return uiToBackend[uiKey] ?? uiKey;
  }

  // backend → UI
  static String? backendToUi(String backendKey) {
    try {
      return uiToBackend.entries
          .firstWhere((e) => e.value == backendKey)
          .key;
    } catch (_) {
      return null;
    }
  }
}
