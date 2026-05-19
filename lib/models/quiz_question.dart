class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
      };

  factory QuizQuestion.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final options = map['options'];
    return QuizQuestion(
      question: map['question'] as String? ?? '',
      options: options is List
          ? options.map((item) => item.toString()).toList(growable: false)
          : const [],
      correctIndex: map['correct_index'] is int
          ? map['correct_index'] as int
          : int.tryParse('${map['correct_index']}') ?? 0,
      explanation: map['explanation'] as String? ?? '',
    );
  }
}
