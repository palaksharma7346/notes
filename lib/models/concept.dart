class ConceptExplanation {
  const ConceptExplanation({
    required this.term,
    required this.explanation,
  });

  final String term;
  final String explanation;

  Map<String, dynamic> toJson() => {
        'term': term,
        'explanation': explanation,
      };

  factory ConceptExplanation.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return ConceptExplanation(
      term: map['term'] as String? ?? '',
      explanation: map['explanation'] as String? ?? '',
    );
  }
}
