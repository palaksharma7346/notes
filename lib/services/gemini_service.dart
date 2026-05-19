import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl = AppConstants.geminiModelUrl;

  static Future<String> _callGemini({
    required String prompt,
    File? imageFile,
    List<File> imageFiles = const [],
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'your_gemini_api_key_here') {
      throw Exception('Add your Gemini API key to the .env file before generating study material.');
    }

    final url = Uri.parse('$_baseUrl?key=$_apiKey');
    final parts = <Map<String, dynamic>>[];
    final images = [
      if (imageFile != null) imageFile,
      ...imageFiles,
    ];

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      parts.add({
        'inline_data': {
          'mime_type': _mimeTypeFor(image.path),
          'data': base64Image,
        },
      });
    }

    parts.add({'text': prompt});

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
      }
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['candidates'][0]['content']['parts'][0]['text'] as String;
    }

    final decoded = jsonDecode(response.body);
    final message = decoded is Map && decoded['error'] is Map
        ? decoded['error']['message']
        : response.body;
    throw Exception('Gemini API error: ${response.statusCode} $message');
  }

  static String prepareNotesText(String notesText, {bool hasImages = false}) {
    var prepared = notesText.trim();
    if (prepared.isEmpty && hasImages) {
      prepared = 'The attached images contain handwritten or photographed notes. Analyze the visual content directly.';
    }
    if (prepared.length > AppConstants.maxGeminiInputCharacters) {
      prepared = '${prepared.substring(0, AppConstants.maxGeminiInputCharacters)}\n\n(content trimmed for processing)';
    }
    return prepared;
  }

  static Future<String> generateSummary(
    String notesText, {
    File? image,
    List<File> images = const [],
    String style = 'Detailed',
  }) async {
    final prompt = '''
You are an expert study assistant helping students understand their notes.
Given the following notes content, generate a well-structured $style summary with:

A brief overview paragraph
Key concepts in bullet points organized by topic
Important definitions highlighted
A "remember this" section with the 3 most critical points

Notes content:
$notesText
''';
    return _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
  }

  static Future<List<Map<String, dynamic>>> generateQuiz(
    String notesText, {
    File? image,
    List<File> images = const [],
  }) async {
    final prompt = '''
You are a quiz generator. Based on the following notes, generate exactly 10 multiple-choice questions.
Rules:

Each question must test understanding, not just memory
Each question has exactly 4 options labeled A, B, C, D
One option is correct, others are plausible but wrong
Include a brief explanation for the correct answer

Return ONLY a valid JSON array. No extra text, no markdown backticks. Format:
[
{
"question": "Question text here?",
"options": ["Option A", "Option B", "Option C", "Option D"],
"correct_index": 0,
"explanation": "Brief explanation of why this is correct"
}
]
Notes content:
$notesText
''';
    final raw = await _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
    return _decodeJsonList(raw);
  }

  static Future<List<Map<String, dynamic>>> generateFlashcards(
    String notesText, {
    File? image,
    List<File> images = const [],
  }) async {
    final prompt = '''
You are a flashcard creator. Based on the following notes, generate 15 flashcards for active recall studying.
Rules:

Front: a term, concept name, or question
Back: the definition, explanation, or answer
Keep fronts short (under 10 words)
Keep backs clear and concise (1-3 sentences)

Return ONLY a valid JSON array. No extra text, no markdown backticks. Format:
[
{
"front": "Term or question",
"back": "Definition or answer"
}
]
Notes content:
$notesText
''';
    final raw = await _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
    return _decodeJsonList(raw);
  }

  static Future<List<Map<String, dynamic>>> generateExamQuestions(
    String notesText, {
    File? image,
    List<File> images = const [],
  }) async {
    final prompt = '''
You are an experienced teacher. Based on these notes, generate 8 important exam questions a student should be able to answer.
Rules:

Mix question types: definition, explain, compare, apply
Provide a detailed model answer for each
Order from basic to advanced

Return ONLY a valid JSON array. No extra text, no markdown backticks. Format:
[
{
"question": "Exam question here?",
"answer": "Detailed model answer here"
}
]
Notes content:
$notesText
''';
    final raw = await _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
    return _decodeJsonList(raw);
  }

  static Future<List<Map<String, dynamic>>> generateTopicNotes(
    String notesText, {
    File? image,
    List<File> images = const [],
  }) async {
    final prompt = '''
You are a note organizer. Restructure the following notes into clean, organized topic-wise notes.
Rules:

Identify all major topics and subtopics
Rewrite content under each topic in clear bullet points
Add a one-line topic description
Sort topics in logical learning order

Return ONLY a valid JSON array. No extra text, no markdown backticks. Format:
[
{
"topic": "Topic name",
"description": "One line about this topic",
"subtopics": [
{
"heading": "Subtopic heading",
"points": ["Point 1", "Point 2", "Point 3"]
}
]
}
]
Notes content:
$notesText
''';
    final raw = await _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
    return _decodeJsonList(raw);
  }

  static Future<List<Map<String, dynamic>>> generateConceptExplanations(
    String notesText, {
    File? image,
    List<File> images = const [],
  }) async {
    final prompt = '''
You are a teacher who simplifies complex ideas. From the following notes, identify the 10 most difficult or technical terms/concepts and explain each one simply.
Rules:

Explain as if teaching a 16-year-old student
Use simple language and relatable analogies
Keep each explanation to 2-3 sentences max

Return ONLY a valid JSON array. No extra text, no markdown backticks. Format:
[
{
"term": "Technical term or concept",
"explanation": "Simple plain-English explanation with analogy if helpful"
}
]
Notes content:
$notesText
''';
    final raw = await _callGemini(prompt: prompt, imageFile: image, imageFiles: images);
    return _decodeJsonList(raw);
  }

  static String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  static List<Map<String, dynamic>> _decodeJsonList(String raw) {
    var cleaned = raw.replaceAll(RegExp(r'```json|```', caseSensitive: false), '').trim();
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start >= 0 && end > start) {
      cleaned = cleaned.substring(start, end + 1);
    }
    final decoded = jsonDecode(cleaned) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
