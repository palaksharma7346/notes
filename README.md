# NoteGenius

NoteGenius is an AI-powered Flutter study assistant for Android and iOS. Students can upload PDFs or note images, then generate summaries, quizzes, flashcards, exam questions, topic-wise notes, and simplified concept explanations with Google Gemini 1.5 Flash.

## Setup

1. Install Flutter and Android tooling.
2. Put your Gemini API key in `.env`:

```env
GEMINI_API_KEY=your_real_key_here
```

3. Run:

```bash
flutter pub get
flutter run
```

To build Android:

```bash
flutter build apk --release
```

The APK is produced at `build/app/outputs/flutter-apk/app-release.apk`.
