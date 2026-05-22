import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../models/session.dart';
import '../../services/huggingface_service.dart';
import '../../services/pdf_service.dart';
import '../home/home_provider.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.files});

  final List<NoteFile> files;

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  final _steps = const [
    'Reading your files...',
    'Extracting content...',
    'Sending to AI...',
    'Almost ready...',
  ];

  int _stepIndex = 0;
  double _progress = 0.08;
  String? _error;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _process());
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    if (widget.files.isEmpty) {
      setState(() => _error =
          'No files were selected. Go back and add at least one note file.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _stepIndex = 0;
      _progress = 0.08;
    });

    try {
      await _advance(0, 0.18);
      final textBuffer = StringBuffer();

      await _advance(1, 0.42);
      for (final noteFile
          in widget.files.where((file) => file.type == NoteFileType.pdf)) {
        final text = await PdfService.extractText(File(noteFile.path));
        if (text.trim().isNotEmpty) {
          textBuffer
            ..writeln('--- ${noteFile.name} ---')
            ..writeln(text.trim())
            ..writeln();
        }
      }

      await _advance(2, 0.72);
      final hasImages =
          widget.files.any((file) => file.type == NoteFileType.image);
      final preparedText = HuggingFaceService.prepareNotesText(
        textBuffer.toString(),
        hasImages: hasImages,
      );

      await _advance(3, 0.92);
      final session = StudySession(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _sessionTitle(widget.files),
        createdAt: DateTime.now(),
        files: widget.files,
        extractedText: preparedText,
      );
      await ref.read(sessionsProvider.notifier).upsertSession(session);

      if (mounted) {
        setState(() => _progress = 1);
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (mounted) context.go('/hub/${session.id}');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'I could not process the selected files. $error';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _advance(int index, double progress) async {
    if (!mounted) return;
    setState(() {
      _stepIndex = index;
      _progress = progress;
    });
    await Future<void>.delayed(const Duration(milliseconds: 550));
  }

  String _sessionTitle(List<NoteFile> files) {
    if (files.length == 1) return files.first.name;
    final hasPdf = files.any((file) => file.type == NoteFileType.pdf);
    final hasImage = files.any((file) => file.type == NoteFileType.image);
    if (hasPdf && hasImage) return 'Mixed Session';
    return 'Multi-file session';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _error == null
            ? _ProcessingBody()
            : _ErrorBody(error: _error!, onRetry: _process),
      ),
    );
  }

  Widget _ProcessingBody() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/study_loading.json',
            width: 220,
            repeat: true,
          ),
          const SizedBox(height: 28),
          Text(
            _steps[_stepIndex],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Preparing your AI study workspace.',
            style: TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: _progress,
              backgroundColor: Colors.white,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FeatureError(message: error, onRetry: onRetry);
  }
}
