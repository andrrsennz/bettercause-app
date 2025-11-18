class OnboardingContent {
  final String title;
  final String description;
  final String imagePath;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// Onboarding data
List<OnboardingContent> onboardingContents = [
  OnboardingContent(
    title: "Purchasing what's good for you shouldn't be this hard.",
    description:
        "Understanding labels, ingredient lists, and claims while shopping can feel overwhelming when you actually care about what goes into your body and the world around you.",
    imagePath: 'assets/images/bettercause_onboarding1.png',
  ),
  OnboardingContent(
    title: "We are here to help and guide you.",
    description:
        "See what's behind every product, understand what matters to you, and discover options that actually fit your values and preferences.",
    imagePath: 'assets/images/bettercause_onboarding2.png',
  ),
  OnboardingContent(
    title: "Feel confident consuming what you buy.",
    description:
        "With every search, you'll learn more about your products, and maybe about yourself too. Welcome to a new way of choosing better.",
    imagePath: 'assets/images/bettercause_onboarding3.png',
  ),
];