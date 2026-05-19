import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/widgets.dart';
import '../../models/session.dart';
import 'upload_provider.dart';

class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(uploadProvider);
    final notifier = ref.read(uploadProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Notes')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: PrimaryButton(
          label: 'Process My Notes →',
          icon: Icons.auto_awesome_rounded,
          onPressed: files.isEmpty
              ? null
              : () => context.push('/processing', extra: List<NoteFile>.from(files)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Text(
            'Choose your study material',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add one or more PDFs, gallery photos, or fresh camera scans.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 22),
          _UploadOptionCard(
            emoji: '📄',
            title: 'Upload PDF',
            subtitle: 'Pick one or more PDF note files',
            onTap: notifier.pickPdf,
          ),
          const SizedBox(height: 14),
          _UploadOptionCard(
            emoji: '🖼️',
            title: 'Upload Image',
            subtitle: 'Choose note images from gallery',
            onTap: notifier.pickImages,
          ),
          const SizedBox(height: 14),
          _UploadOptionCard(
            emoji: '📷',
            title: 'Scan Notes',
            subtitle: 'Use your camera for handwritten pages',
            onTap: notifier.scanNotes,
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const SectionTitle('Selected Files'),
              const Spacer(),
              if (files.isNotEmpty)
                TextButton.icon(
                  onPressed: notifier.clear,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (files.isEmpty)
            const SoftContainer(
              child: Text(
                'No files selected yet.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _FileThumbnail(
                    file: files[index],
                    onRemove: () => notifier.remove(files[index].id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _UploadOptionCard extends StatelessWidget {
  const _UploadOptionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SoftContainer(
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _FileThumbnail extends StatelessWidget {
  const _FileThumbnail({required this.file, required this.onRemove});

  final NoteFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isImage = file.type == NoteFileType.image;
    return SizedBox(
      width: 124,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: isImage && File(file.path).existsSync()
                    ? Image.file(File(file.path), fit: BoxFit.cover)
                    : const Center(
                        child: Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                file.type.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.danger,
                minimumSize: const Size(32, 32),
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
