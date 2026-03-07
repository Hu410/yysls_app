import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OcrResult {
  final String fullText;
  const OcrResult({required this.fullText});
}

class OcrService {
  TextRecognizer? _recognizer;

  TextRecognizer get _chineseRecognizer {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
    return _recognizer!;
  }

  Future<OcrResult> recognizeFromFile(File imageFile) async {
    debugPrint('[OCR-Service] 调用 ML Kit 中文识别, 路径: ${imageFile.path}');
    debugPrint('[OCR-Service] 文件存在: ${imageFile.existsSync()}, 大小: ${imageFile.existsSync() ? imageFile.lengthSync() : 0} bytes');

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognized = await _chineseRecognizer.processImage(inputImage);

      final fullText = recognized.text;
      debugPrint('[OCR-Service] 识别完成, 文本长度: ${fullText.length}');
      debugPrint('[OCR-Service] 前300字: ${fullText.substring(0, fullText.length > 300 ? 300 : fullText.length)}');

      return OcrResult(fullText: fullText);
    } catch (e, stack) {
      debugPrint('[OCR-Service] 识别异常: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  void dispose() {
    _recognizer?.close();
    _recognizer = null;
  }
}

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(() => service.dispose());
  return service;
});
