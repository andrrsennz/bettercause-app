import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/onboarding_question.dart';
import '../../services/onboarding_service.dart';
import '../../components/onboarding/progress_bar.dart';
import '../../components/onboarding/option_card';
import '../../components/onboarding/age_selector.dart';

class OnboardingQuestionScreen extends StatefulWidget {
  final OnboardingQuestion question;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const OnboardingQuestionScreen({
    super.key,
    required this.question,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<OnboardingQuestionScreen> createState() =>
      _OnboardingQuestionScreenState();
}

class _OnboardingQuestionScreenState extends State<OnboardingQuestionScreen> {
  late Set<String> selectedOptions;
  int? selectedAge;

  @override
  void initState() {
    super.initState();
    _loadSavedResponse();
  }

  void _loadSavedResponse() {
    final service = context.read<OnboardingService>();
    final savedOptions = service.getSelectedOptions(widget.question.id);

    if (savedOptions != null) {
      if (widget.question.type == QuestionType.ageSelector) {
        selectedAge = int.tryParse(savedOptions.first);
      } else {
        selectedOptions = Set.from(savedOptions);
      }
    } else {
      selectedOptions = {};
    }
  }

  void _toggleOption(String optionId) {
    setState(() {
      if (widget.question.type == QuestionType.singleChoice) {
        selectedOptions = {optionId};
      } else {
        if (selectedOptions.contains(optionId)) {
          selectedOptions.remove(optionId);
        } else {
          selectedOptions.add(optionId);
        }
      }
    });
  }

  void _handleContinue() {
    final service = context.read<OnboardingService>();

    if (widget.question.type == QuestionType.ageSelector) {
      if (selectedAge != null) {
        service.saveResponse(widget.question.id, [selectedAge.toString()]);
        widget.onNext();
      }
    } else {
      if (selectedOptions.isNotEmpty) {
        service.saveResponse(widget.question.id, selectedOptions.toList());
        widget.onNext();
      }
    }
  }

  bool get _canContinue {
    if (widget.question.type == QuestionType.ageSelector) {
      return selectedAge != null;
    }
    return selectedOptions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B7FED),
      body: SafeArea(
        child: Column(
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.question.category,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1.0,
                ),
              ),
            ),

            // White card container
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: OnboardingProgressBar(
                        currentStep: widget.question.currentStep,
                        totalSteps: widget.question.totalSteps,
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Question title (centered)
                            Text(
                              widget.question.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D2D2D),
                                height: 1.3,
                              ),
                            ),

                            if (widget.question.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                widget.question.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],

                            const SizedBox(height: 32),

                            // Options
                            if (widget.question.type == QuestionType.ageSelector)
                              AgeSelector(
                                selectedAge: selectedAge,
                                onAgeSelected: (age) {
                                  setState(() {
                                    selectedAge = age;
                                  });
                                },
                              )
                            else
                              _buildOptions(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Bottom buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Back button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onBack,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF666666),
                                side: const BorderSide(color: Color(0xFFE5E5E5)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Continue button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _canContinue ? _handleContinue : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B7FED),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(0xFFE5E5E5),
                                disabledForegroundColor: const Color(0xFF999999),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: widget.question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OptionCard(
            label: option.label,
            subtitle: option.subtitle,
            isSelected: selectedOptions.contains(option.id),
            onTap: () => _toggleOption(option.id),
          ),
        );
      }).toList(),
    );
  }
}