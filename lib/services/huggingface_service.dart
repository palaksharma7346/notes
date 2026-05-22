import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class HuggingFaceService {
  static String get _apiKey {
    final huggingFaceKey = dotenv.env['HUGGINGFACE_API_KEY']?.trim();
    if (huggingFaceKey != null && huggingFaceKey.isNotEmpty) {
      return huggingFaceKey;
    }
    return dotenv.env['HF_TOKEN']?.trim() ?? '';
  }

  static String get _apiBaseUrl {
    final configured = dotenv.env['HUGGINGFACE_API_BASE_URL']?.trim();
    final baseUrl = configured?.isNotEmpty == true
        ? configured!
        : AppConstants.huggingFaceApiBaseUrl;
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static Future<String> _callHuggingFace({
    required String prompt,
    File? imageFile,
    List<File> imageFiles = const [],
  }) async {
    if (_isMissingApiKey(_apiKey)) {
      throw Exception(
        'Add your Hugging Face token to the .env file before generating study material.',
      );
    }

    final images = [
      if (imageFile != null) imageFile,
      ...imageFiles,
    ];
    final hasImages = images.isNotEmpty;
    final userContent = hasImages
        ? await _visionContent(prompt: prompt, images: images)
        : prompt;

    final body = jsonEncode({
      'model': _modelFor(hasImages: hasImages),
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a precise study assistant. Follow formatting instructions exactly.',
        },
        {
          'role': 'user',
          'content': userContent,
        },
      ],
      'temperature': 0.7,
      'max_tokens': 4096,
      'stream': false,
    });

    http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_apiBaseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    } catch (_) {
      throw Exception(
        'Hugging Face API request failed. Please check your network connection and API configuration.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractContent(data);
    }

    final message = _errorMessage(response.body);
    throw Exception(_friendlyHuggingFaceError(response.statusCode, message));
  }

  static Future<List<Map<String, dynamic>>> _visionContent({
    required String prompt,
    required List<File> images,
  }) async {
    final content = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': prompt,
      },
    ];

    for (final image in images) {
      final bytes = await image.readAsBytes();
      final mimeType = _mimeTypeFor(image.path);
      content.add({
        'type': 'image_url',
        'image_url': {
          'url': 'data:$mimeType;base64,${base64Encode(bytes)}',
        },
      });
    }

    return content;
  }

  static String prepareNotesText(String notesText, {bool hasImages = false}) {
    var prepared = notesText.trim();
    if (prepared.isEmpty && hasImages) {
      prepared =
          'The attached images contain handwritten or photographed notes. Analyze the visual content directly.';
    }
    if (prepared.length > AppConstants.maxAiInputCharacters) {
      prepared =
          '${prepared.substring(0, AppConstants.maxAiInputCharacters)}\n\n(content trimmed for processing)';
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
    return _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
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
    final raw = await _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
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
    final raw = await _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
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
    final raw = await _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
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
    final raw = await _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
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
    final raw = await _callHuggingFace(
      prompt: prompt,
      imageFile: image,
      imageFiles: images,
    );
    return _decodeJsonList(raw);
  }

  static String _modelFor({required bool hasImages}) {
    final model = hasImages
        ? _configuredValue([
            'HUGGINGFACE_VISION_MODEL',
            'HUGGINGFACE_MODEL',
            'HF_MODEL',
          ])
        : _configuredValue([
            'HUGGINGFACE_MODEL',
            'HF_MODEL',
          ]);
    if (model != null) return model;
    return hasImages
        ? AppConstants.huggingFaceDefaultVisionModel
        : AppConstants.huggingFaceDefaultTextModel;
  }

  static String? _configuredValue(List<String> keys) {
    for (final key in keys) {
      final value = dotenv.env[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static bool _isMissingApiKey(String value) {
    final normalized = value.toLowerCase();
    return normalized.isEmpty ||
        normalized == 'your_huggingface_token_here' ||
        normalized == 'hf_your_token_here' ||
        normalized == 'your_hf_token_here';
  }

  static String _mimeTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  static String _extractContent(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final first = choices.first;
      if (first is Map) {
        final message = first['message'];
        if (message is Map) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content;
          }
          if (content is List) {
            final text = content
                .whereType<Map>()
                .map((part) => part['text'])
                .whereType<String>()
                .join();
            if (text.trim().isNotEmpty) return text;
          }
        }
        final text = first['text'];
        if (text is String && text.trim().isNotEmpty) return text;
      }
    }
    throw Exception('Hugging Face returned no generated text.');
  }

  static String _errorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map) {
        final error = decoded['error'];
        if (error is String) return error;
        if (error is Map) {
          return error['message']?.toString() ?? responseBody;
        }
        return decoded['message']?.toString() ?? responseBody;
      }
    } catch (_) {
      return responseBody;
    }
    return responseBody;
  }

  static String _friendlyHuggingFaceError(int statusCode, String message) {
    if (statusCode == 400) {
      return 'Hugging Face rejected the request. Check the configured model and request payload. $message';
    }
    if (statusCode == 401) {
      return 'The Hugging Face token was rejected. Check HUGGINGFACE_API_KEY or HF_TOKEN in the .env file.';
    }
    if (statusCode == 403) {
      return 'This Hugging Face token cannot access the selected model or lacks Inference Providers permission.';
    }
    if (statusCode == 404) {
      return 'Hugging Face could not find the configured model. Set HUGGINGFACE_MODEL or HUGGINGFACE_VISION_MODEL in .env.';
    }
    if (statusCode == 429) {
      return 'The Hugging Face API rate limit or quota was reached. Try again later or choose another model/provider.';
    }
    if (statusCode == 503) {
      return 'The selected Hugging Face model provider is temporarily unavailable. Try again or choose another model.';
    }
    return 'Hugging Face API error: $statusCode $message';
  }

  static List<Map<String, dynamic>> _decodeJsonList(String raw) {
    var cleaned =
        raw.replaceAll(RegExp(r'```json|```', caseSensitive: false), '').trim();
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
