class TopicNote {
  const TopicNote({
    required this.topic,
    required this.description,
    required this.subtopics,
  });

  final String topic;
  final String description;
  final List<SubtopicNote> subtopics;

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'description': description,
        'subtopics': subtopics.map((item) => item.toJson()).toList(),
      };

  factory TopicNote.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawSubtopics = map['subtopics'];
    return TopicNote(
      topic: map['topic'] as String? ?? '',
      description: map['description'] as String? ?? '',
      subtopics: rawSubtopics is List
          ? rawSubtopics
              .whereType<Map<dynamic, dynamic>>()
              .map(SubtopicNote.fromJson)
              .toList(growable: false)
          : const [],
    );
  }
}

class SubtopicNote {
  const SubtopicNote({
    required this.heading,
    required this.points,
  });

  final String heading;
  final List<String> points;

  Map<String, dynamic> toJson() => {
        'heading': heading,
        'points': points,
      };

  factory SubtopicNote.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawPoints = map['points'];
    return SubtopicNote(
      heading: map['heading'] as String? ?? '',
      points: rawPoints is List
          ? rawPoints.map((point) => point.toString()).toList(growable: false)
          : const [],
    );
  }
}
