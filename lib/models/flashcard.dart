class Flashcard {
  const Flashcard({
    required this.front,
    required this.back,
  });

  final String front;
  final String back;

  Map<String, dynamic> toJson() => {
        'front': front,
        'back': back,
      };

  factory Flashcard.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return Flashcard(
      front: map['front'] as String? ?? '',
      back: map['back'] as String? ?? '',
    );
  }
}
