class CategoryPreferenceOption {
  final String title;
  final String description;
  bool isEnabled;

  CategoryPreferenceOption({
    required this.title,
    required this.description,
    this.isEnabled = false,
  });

  factory CategoryPreferenceOption.fromJson(Map<String, dynamic> json) {
    return CategoryPreferenceOption(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isEnabled: json['isEnabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isEnabled': isEnabled,
    };
  }
}

class CategoryPreferenceSection {
  final String sectionTitle;
  final List<CategoryPreferenceOption> options;

  CategoryPreferenceSection({
    required this.sectionTitle,
    required this.options,
  });

  factory CategoryPreferenceSection.fromJson(Map<String, dynamic> json) {
    return CategoryPreferenceSection(
      sectionTitle: json['sectionTitle'] ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((option) => CategoryPreferenceOption.fromJson(option))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sectionTitle': sectionTitle,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

class CategoryPreferenceData {
  final String categoryName;
  final String categoryIcon;
  final List<CategoryPreferenceSection> sections;

  CategoryPreferenceData({
    required this.categoryName,
    required this.categoryIcon,
    required this.sections,
  });

  factory CategoryPreferenceData.fromJson(Map<String, dynamic> json) {
    return CategoryPreferenceData(
      categoryName: json['categoryName'] ?? '',
      categoryIcon: json['categoryIcon'] ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((section) => CategoryPreferenceSection.fromJson(section))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  int getTotalEnabledCount() {
    int count = 0;
    for (var section in sections) {
      count += section.options.where((option) => option.isEnabled).length;
    }
    return count;
  }

  int getTotalOptionsCount() {
    int count = 0;
    for (var section in sections) {
      count += section.options.length;
    }
    return count;
  }
}