class ExamQuestion {
  const ExamQuestion({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  factory ExamQuestion.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return ExamQuestion(
      question: map['question'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
    );
  }
}
