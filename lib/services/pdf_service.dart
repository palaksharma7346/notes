import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static Future<String> extractText(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }
}
