import 'package:flutter_test/flutter_test.dart';

import 'package:note_genius/core/constants.dart';
import 'package:note_genius/services/huggingface_service.dart';

void main() {
  test('prepareNotesText describes image-only sessions', () {
    final prepared = HuggingFaceService.prepareNotesText('', hasImages: true);

    expect(prepared, contains('attached images'));
  });

  test('prepareNotesText trims oversized notes', () {
    final prepared = HuggingFaceService.prepareNotesText(
      'a' * (AppConstants.maxAiInputCharacters + 1),
    );

    expect(prepared.length, greaterThan(AppConstants.maxAiInputCharacters));
    expect(prepared, contains('(content trimmed for processing)'));
  });
}
