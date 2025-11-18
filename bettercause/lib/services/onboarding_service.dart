import 'package:flutter/foundation.dart';
import '../../models/onboarding_response.dart';

class OnboardingService extends ChangeNotifier {
  final OnboardingData _data = OnboardingData();

  OnboardingData get data => _data;

  void saveResponse(String questionId, List<String> selectedOptionIds) {
    _data.addResponse(
      OnboardingResponse(
        questionId: questionId,
        selectedOptionIds: selectedOptionIds,
      ),
    );
    notifyListeners();
  }

  List<String>? getSelectedOptions(String questionId) {
    return _data.getResponse(questionId)?.selectedOptionIds;
  }

  bool hasResponse(String questionId) {
    return _data.hasResponse(questionId);
  }

  /// Call this when onboarding is complete to send data to backend
  Future<void> submitToBackend() async {
    try {
      final jsonData = _data.toJson();
      
      // TODO: Replace with actual API call
      // Example:
      // await dio.post('/api/onboarding', data: jsonData);
      
      debugPrint('Submitting onboarding data: $jsonData');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      debugPrint('Onboarding data submitted successfully');
    } catch (e) {
      debugPrint('Error submitting onboarding data: $e');
      rethrow;
    }
  }

  void reset() {
    _data.responses.clear();
    notifyListeners();
  }
}