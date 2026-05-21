import 'package:flutter/material.dart';

class AppConstants {
  static const appName = 'NoteGenius';
  static const tagline = 'Study Smarter with AI';
  static const sessionsBox = 'sessions';
  static const maxGeminiInputCharacters = 25000;
  static const geminiApiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const geminiTextModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
  ];
}

class AppColors {
  static const primary = Color(0xFF3D52A0);
  static const secondary = Color(0xFF7091E6);
  static const accent = Color(0xFF8697C4);
  static const background = Color(0xFFEDE8F5);
  static const surface = Colors.white;
  static const success = Color(0xFF2E7D32);
  static const danger = Color(0xFFC62828);
  static const warning = Color(0xFFF6C85F);
  static const ink = Color(0xFF182033);
  static const muted = Color(0xFF6B7280);
}

class FeatureKeys {
  static const summary = 'summary';
  static const quiz = 'quiz';
  static const flashcards = 'flashcards';
  static const questions = 'questions';
  static const topics = 'topics';
  static const concepts = 'concepts';
}
