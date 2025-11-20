import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LocalTranslator {
  late OnDeviceTranslator translator;
  final modelManager = OnDeviceTranslatorModelManager();

  Future<void> init({
    required TranslateLanguage from,
    required TranslateLanguage to,
  }) async {
    // Download source language model
    if (!await modelManager.isModelDownloaded(from.bcpCode)) {
      await modelManager.downloadModel(from.bcpCode);
    }

    // Download target model
    if (!await modelManager.isModelDownloaded(to.bcpCode)) {
      await modelManager.downloadModel(to.bcpCode);
    }

    // Create translator
    translator = OnDeviceTranslator(
      sourceLanguage: from,
      targetLanguage: to,
    );
  }

  Future<String> translate(String text) async {
    return await translator.translateText(text);
  }

  void dispose() {
    translator.close();
  }
}
