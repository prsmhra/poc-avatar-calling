import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LocalTranslator {
  OnDeviceTranslator? translatorAtoB; // e.g., English → Hindi
  OnDeviceTranslator? translatorBtoA; // e.g., Hindi → English
  final modelManager = OnDeviceTranslatorModelManager();

  TranslateLanguage? _langA;
  TranslateLanguage? _langB;

  Future<void> init({
    required TranslateLanguage languageA,
    required TranslateLanguage languageB,
  }) async {
    _langA = languageA;
    _langB = languageB;

    // Download both language models
    await _ensureModelDownloaded(languageA);
    await _ensureModelDownloaded(languageB);

    // Create bidirectional translators
    translatorAtoB = OnDeviceTranslator(
      sourceLanguage: languageA,
      targetLanguage: languageB,
    );

    translatorBtoA = OnDeviceTranslator(
      sourceLanguage: languageB,
      targetLanguage: languageA,
    );
  }

  Future<void> _ensureModelDownloaded(TranslateLanguage lang) async {
    if (!await modelManager.isModelDownloaded(lang.bcpCode)) {
      print('📥 Downloading ${lang.bcpCode} model...');
      await modelManager.downloadModel(lang.bcpCode);
      print('✅ ${lang.bcpCode} model downloaded');
    }
  }

  /// Translate from Language A to Language B
  Future<String> translateAtoB(String text) async {
    if (translatorAtoB == null) {
      throw Exception('Translator not initialized');
    }
    return await translatorAtoB!.translateText(text);
  }

  /// Translate from Language B to Language A
  Future<String> translateBtoA(String text) async {
    if (translatorBtoA == null) {
      throw Exception('Translator not initialized');
    }
    return await translatorBtoA!.translateText(text);
  }

  void dispose() {
    translatorAtoB?.close();
    translatorBtoA?.close();
  }

  // Helper to get BCP code for TTS
  String getLanguageCode(TranslateLanguage lang) {
    return lang.bcpCode;
  }
}