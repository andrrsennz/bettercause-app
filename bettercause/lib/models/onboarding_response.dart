class OnboardingResponse {
  final String questionId;
  final List<String> selectedOptionIds;

  const OnboardingResponse({
    required this.questionId,
    required this.selectedOptionIds,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selectedOptionIds': selectedOptionIds,
      };

  factory OnboardingResponse.fromJson(Map<String, dynamic> json) =>
      OnboardingResponse(
        questionId: json['questionId'] as String,
        selectedOptionIds:
            (json['selectedOptionIds'] as List).cast<String>(),
      );
}

class OnboardingData {
  final Map<String, OnboardingResponse> responses;

  OnboardingData({Map<String, OnboardingResponse>? responses})
      : responses = responses ?? {};

  void addResponse(OnboardingResponse response) {
    responses[response.questionId] = response;
  }

  OnboardingResponse? getResponse(String questionId) {
    return responses[questionId];
  }

  bool hasResponse(String questionId) {
    return responses.containsKey(questionId);
  }

  Map<String, dynamic> toJson() => {
        'responses': responses.values.map((r) => r.toJson()).toList(),
      };

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    final responsesMap = <String, OnboardingResponse>{};
    for (final responseJson in json['responses'] as List) {
      final response = OnboardingResponse.fromJson(responseJson);
      responsesMap[response.questionId] = response;
    }
    return OnboardingData(responses: responsesMap);
  }
}