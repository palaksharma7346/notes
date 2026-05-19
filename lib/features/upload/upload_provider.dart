import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/session.dart';

final uploadProvider = StateNotifierProvider.autoDispose<UploadNotifier, List<NoteFile>>((ref) {
  return UploadNotifier();
});

class UploadNotifier extends StateNotifier<List<NoteFile>> {
  UploadNotifier() : super(const []);

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (result == null) return;

    final files = result.files
        .where((file) => file.path != null)
        .map(
          (file) => NoteFile(
            id: _id(),
            name: file.name,
            path: file.path!,
            type: NoteFileType.pdf,
          ),
        )
        .toList(growable: false);
    _append(files);
  }

  Future<void> pickImages() async {
    final images = await _imagePicker.pickMultiImage(imageQuality: 92);
    if (images.isEmpty) return;

    final files = images
        .map(
          (image) => NoteFile(
            id: _id(),
            name: image.name.isNotEmpty ? image.name : _fileName(image.path),
            path: image.path,
            type: NoteFileType.image,
          ),
        )
        .toList(growable: false);
    _append(files);
  }

  Future<void> scanNotes() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (image == null) return;

    _append([
      NoteFile(
        id: _id(),
        name: image.name.isNotEmpty ? image.name : _fileName(image.path),
        path: image.path,
        type: NoteFileType.image,
      ),
    ]);
  }

  void remove(String id) {
    state = state.where((file) => file.id != id).toList(growable: false);
  }

  void clear() {
    state = const [];
  }

  void _append(List<NoteFile> files) {
    final existingPaths = state.map((file) => file.path).toSet();
    state = [
      ...state,
      ...files.where((file) => !existingPaths.contains(file.path)),
    ];
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  String _fileName(String path) => path.split(Platform.pathSeparator).last;
}
