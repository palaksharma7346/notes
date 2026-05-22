# NoteGenius

NoteGenius is an AI-powered Flutter study assistant for Android and iOS. Students can upload PDFs or note images, then generate summaries, quizzes, flashcards, exam questions, topic-wise notes, and simplified concept explanations with Hugging Face Inference Providers.

## Setup

1. Install Flutter and Android tooling.
2. Put your Hugging Face token in `.env`:

```env
HUGGINGFACE_API_KEY=hf_your_token_here
HUGGINGFACE_MODEL=openai/gpt-oss-120b:fastest
HUGGINGFACE_VISION_MODEL=zai-org/GLM-4.5V:fastest
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
