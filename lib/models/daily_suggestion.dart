class DailySuggestion {
  final String greeting;
  final String weatherAdvice;
  final String motivationMessage;
  final List<String> tasks;
  final List<String> recommendations;

  DailySuggestion({
    required this.greeting,
    required this.weatherAdvice,
    required this.motivationMessage,
    required this.tasks,
    required this.recommendations,
  });

  factory DailySuggestion.fromMap(Map<String, dynamic> map) {
    return DailySuggestion(
      greeting: map['greeting'] ?? '',
      weatherAdvice: map['weatherAdvice'] ?? '',
      motivationMessage: map['motivationMessage'] ?? '',
      tasks: List<String>.from(map['tasks'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
    );
  }
}