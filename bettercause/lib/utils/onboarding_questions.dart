import '../../models/onboarding_question.dart';
class OnboardingQuestions {
  static List<OnboardingQuestion> getQuestions() {
    return [
      // Question 1: How do you want us to assist you best?
      OnboardingQuestion(
        id: 'assist_preference',
        category: 'GENERAL PREFERENCES',
        title: 'How do you want us to\nassist you best?',
        subtitle: 'Select all that apply',
        type: QuestionType.multipleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 1,
        totalSteps: 7,
        options: const [
          OnboardingOption(
            id: 'find_products',
            label: 'Help me find products that fit my diet &\nhealth needs',
          ),
          OnboardingOption(
            id: 'healthy_alternatives',
            label: 'Help me choose healthy products that are\nsafe to eat',
          ),
          OnboardingOption(
            id: 'shop_sustainably',
            label: 'Help me shop more sustainably and\nethically',
          ),
          OnboardingOption(
            id: 'better_choices',
            label: 'Help me find better and more balanced\nchoices around me',
          ),
        ],
      ),

      // Question 2: Daily habits and routine
      OnboardingQuestion(
        id: 'daily_habits',
        category: 'GENERAL PREFERENCES',
        title: 'How would you describe\nyour daily habits and\nroutine?',
        subtitle: '',
        type: QuestionType.singleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 2,
        totalSteps: 7,
        options: const [
          OnboardingOption(
            id: 'balanced_healthy',
            label: 'Balanced! I maintain a generally healthy &\nconsious lifestyle.',
          ),
          OnboardingOption(
            id: 'balance_consistently',
            label: 'Average. I tend to balance, not consistently.',
          ),
          OnboardingOption(
            id: 'better_balanced',
            label: 'Could be better. I often feel out of balance.',
          ),
        ],
      ),

      // Question 3: Health conditions
      OnboardingQuestion(
        id: 'health_conditions',
        category: 'GENERAL PREFERENCES',
        title: 'Do you have any of these\nexisting health conditions\nto consider?',
        subtitle: 'Select all that apply',
        type: QuestionType.multipleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 3,
        totalSteps: 7,
        options: const [
          OnboardingOption(id: 'diabetes', label: 'Diabetes'),
          OnboardingOption(id: 'hypertension', label: 'Hypertension / High Blood Pressure'),
          OnboardingOption(id: 'high_cholesterol', label: 'High cholesterol'),
          OnboardingOption(id: 'acid_reflux', label: 'Acid reflux'),
          OnboardingOption(id: 'lactose_intolerance', label: 'Lactose intolerance'),
        ],
      ),

      // Question 4: Body/condition concerns
      OnboardingQuestion(
        id: 'body_concerns',
        category: 'GENERAL PREFERENCES',
        title: 'What concerns you most\nabout your body or\ncondition lately?',
        subtitle: 'Select all that apply',
        type: QuestionType.multipleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 4,
        totalSteps: 7,
        options: const [
          OnboardingOption(id: 'low_energy', label: 'Low energy or fatigue'),
          OnboardingOption(id: 'sugar_cravings', label: 'Sugar spikes or unstable blood sugar'),
          OnboardingOption(id: 'managing_weight', label: 'Difficulty managing weight'),
          OnboardingOption(id: 'poor_hydration', label: 'Poor hydration'),
          OnboardingOption(id: 'inflammation', label: 'Inflammation or body aches'),
          OnboardingOption(id: 'lack_sleep', label: 'Lack of sleep'),
        ],
      ),

      // Question 5: Dietary lifestyle
      OnboardingQuestion(
        id: 'dietary_lifestyle',
        category: 'DIET & FOOD PREFERENCES',
        title: 'Do you follow any dietary\nlifestyle?',
        subtitle: 'Select all that apply',
        type: QuestionType.multipleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 5,
        totalSteps: 7,
        options: const [
          OnboardingOption(id: 'vegan', label: 'Vegan'),
          OnboardingOption(id: 'vegetarian', label: 'Vegetarian'),
          OnboardingOption(id: 'pescatarian', label: 'Pescatarian'),
          OnboardingOption(id: 'low_carb', label: 'Low Carb / Keto Diet'),
          OnboardingOption(id: 'gluten_free', label: 'Gluten-free'),
          OnboardingOption(id: 'dairy_free', label: 'Dairy-free'),
          OnboardingOption(id: 'halal', label: 'Halal'),
        ],
      ),

      // Question 6: Gender
      OnboardingQuestion(
        id: 'gender',
        category: 'ABOUT YOU',
        title: 'What is your gender?',
        subtitle: 'We use this information to provide you\npersonalized suggestions.',
        type: QuestionType.singleChoice,
        selectionStyle: SelectionStyle.card,
        currentStep: 6,
        totalSteps: 7,
        options: const [
          OnboardingOption(id: 'female', label: 'Female'),
          OnboardingOption(id: 'male', label: 'Male'),
          OnboardingOption(id: 'prefer_not_to_say', label: 'Prefer not to say'),
        ],
      ),

      // Question 7: Age
      OnboardingQuestion(
        id: 'age',
        category: 'ABOUT YOU',
        title: 'What is your age?',
        subtitle: 'We use this information to provide you\npersonalized suggestions.',
        type: QuestionType.ageSelector,
        selectionStyle: SelectionStyle.chip,
        currentStep: 7,
        totalSteps: 7,
        options: const [], // Age selector doesn't use predefined options
      ),
    ];
  }
}