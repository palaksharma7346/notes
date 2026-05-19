enum NoteFileType {
  pdf,
  image;

  String get label => this == NoteFileType.pdf ? 'PDF' : 'IMAGE';

  static NoteFileType fromName(String value) {
    return value == NoteFileType.pdf.name ? NoteFileType.pdf : NoteFileType.image;
  }
}

class NoteFile {
  const NoteFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
  });

  final String id;
  final String name;
  final String path;
  final NoteFileType type;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'type': type.name,
      };

  factory NoteFile.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    return NoteFile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled file',
      path: map['path'] as String? ?? '',
      type: NoteFileType.fromName(map['type'] as String? ?? NoteFileType.image.name),
    );
  }
}

class StudySession {
  const StudySession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.files,
    required this.extractedText,
    this.generatedContent = const {},
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<NoteFile> files;
  final String extractedText;
  final Map<String, dynamic> generatedContent;

  bool hasFeature(String key) => generatedContent.containsKey(key);

  List<NoteFile> get imageFiles =>
      files.where((file) => file.type == NoteFileType.image).toList(growable: false);

  StudySession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<NoteFile>? files,
    String? extractedText,
    Map<String, dynamic>? generatedContent,
  }) {
    return StudySession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      files: files ?? this.files,
      extractedText: extractedText ?? this.extractedText,
      generatedContent: generatedContent ?? this.generatedContent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'files': files.map((file) => file.toJson()).toList(),
        'extractedText': extractedText,
        'generatedContent': generatedContent,
      };

  factory StudySession.fromJson(Map<dynamic, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawFiles = map['files'];
    final rawGenerated = map['generatedContent'];
    return StudySession(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Study Session',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      files: rawFiles is List
          ? rawFiles
              .whereType<Map<dynamic, dynamic>>()
              .map(NoteFile.fromJson)
              .toList(growable: false)
          : const [],
      extractedText: map['extractedText'] as String? ?? '',
      generatedContent: rawGenerated is Map
          ? Map<String, dynamic>.from(rawGenerated)
          : const {},
    );
  }
}
