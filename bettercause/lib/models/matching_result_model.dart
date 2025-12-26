class MatchingResult {
  final double totalScore; // 0-100
  final String category; // "Great", "Good", "Moderate", "Poor", "Very Poor"
  final Map<String, double> breakdown; // Individual scores for each factor
  final String? confidenceLabel; // null, "Low confidence - limited data", or warning
  final bool showScoreOnly; // If true, only show breakdown, no total score

  MatchingResult({
    required this.totalScore,
    required this.category,
    required this.breakdown,
    this.confidenceLabel,
    this.showScoreOnly = false,
  });

  @override
  String toString() {
    return 'Score: ${totalScore.toStringAsFixed(1)}% ($category)${confidenceLabel != null ? ' - $confidenceLabel' : ''}';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'category': category,
      'breakdown': breakdown,
      'confidenceLabel': confidenceLabel,
      'showScoreOnly': showScoreOnly,
    };
  }
}