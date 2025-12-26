class UserPreferences {
  final List<String> preferenceTags;
  final List<String> avoidIngredients;
  final List<String> healthConditions;

  UserPreferences({
    this.preferenceTags = const [],
    this.avoidIngredients = const [],
    this.healthConditions = const [],
  });

  bool get hasPreferences => preferenceTags.isNotEmpty;
  bool get hasAvoidList => avoidIngredients.isNotEmpty;
  bool get hasHealthConditions => healthConditions.isNotEmpty;

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferenceTags: (json['preferenceTags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avoidIngredients: (json['avoidIngredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      healthConditions: (json['healthConditions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferenceTags': preferenceTags,
      'avoidIngredients': avoidIngredients,
      'healthConditions': healthConditions,
    };
  }
}