import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';

class LanguageDetector {
  final languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  /// Detect language from text
  /// Returns BCP-47 language code (e.g., "en", "hi", "es")
  Future<String?> detectLanguage(String text) async {
    try {
      final languageCode = await languageIdentifier.identifyLanguage(text);
      
      // If confidence is too low, returns "und" (undetermined)
      if (languageCode == 'und') {
        print('⚠️ Language detection uncertain');
        return null;
      }
      
      print('🔍 Detected language: $languageCode');
      return languageCode;
    } catch (e) {
      print('❌ Language detection error: $e');
      return null;
    }
  }

  /// Get possible languages with confidence scores
  Future<List<IdentifiedLanguage>> getPossibleLanguages(String text) async {
    try {
      final languages = await languageIdentifier.identifyPossibleLanguages(text);
      return languages;
    } catch (e) {
      print('❌ Error getting possible languages: $e');
      return [];
    }
  }

  void dispose() {
    languageIdentifier.close();
  }

  /// Convert ML Kit language code to locale ID for STT
  /// e.g., "en" → "en-US", "hi" → "hi-IN"
  String languageCodeToLocale(String languageCode) {
    final Map<String, String> languageToLocale = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'ja': 'ja-JP',
      'zh': 'zh-CN',
      'ar': 'ar-SA',
      'pt': 'pt-BR',
      'ru': 'ru-RU',
      'it': 'it-IT',
      'ko': 'ko-KR',
    };
    
    return languageToLocale[languageCode] ?? 'en-US';
  }

  /// Convert locale ID to TranslateLanguage
  TranslateLanguageCode localeToTranslateLanguage(String locale) {
    // Extract language code (before hyphen)
    final langCode = locale.split('-').first.toLowerCase();
    
    final Map<String, TranslateLanguageCode> localeToLang = {
      'en': TranslateLanguageCode.english,
      'hi': TranslateLanguageCode.hindi,
      'es': TranslateLanguageCode.spanish,
      'fr': TranslateLanguageCode.french,
      'de': TranslateLanguageCode.german,
      'ja': TranslateLanguageCode.japanese,
      'zh': TranslateLanguageCode.chinese,
      'ar': TranslateLanguageCode.arabic,
      'pt': TranslateLanguageCode.portuguese,
      'ru': TranslateLanguageCode.russian,
      'it': TranslateLanguageCode.italian,
      'ko': TranslateLanguageCode.korean,
    };
    
    return localeToLang[langCode] ?? TranslateLanguageCode.english;
  }
}

// Helper enum matching google_mlkit_translation
enum TranslateLanguageCode {
  english,
  hindi,
  spanish,
  french,
  german,
  japanese,
  chinese,
  arabic,
  portuguese,
  russian,
  italian,
  korean,
}