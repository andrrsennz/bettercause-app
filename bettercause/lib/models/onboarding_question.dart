enum QuestionType {
  singleChoice,
  multipleChoice,
  ageSelector,
}

enum SelectionStyle {
  card, // For larger card-style options
  chip, // For smaller chip-style options
}

class OnboardingOption {
  final String id;
  final String label;
  final String? subtitle;

  const OnboardingOption({
    required this.id,
    required this.label,
    this.subtitle,
  });
}

class OnboardingQuestion {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final QuestionType type;
  final SelectionStyle selectionStyle;
  final List<OnboardingOption> options;
  final int currentStep;
  final int totalSteps;

  const OnboardingQuestion({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.selectionStyle,
    required this.options,
    required this.currentStep,
    required this.totalSteps,
  });
}