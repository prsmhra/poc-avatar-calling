import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AudioSTTTTS {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  // Store current language settings
  String _currentLanguage = "en-US";

  Future<void> speak(String text, {String? languageCode}) async {
    // Use provided language or fall back to current
    final lang = languageCode ?? _currentLanguage;
    
    await tts.setLanguage(lang);
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5); // Adjust for clarity
    await tts.speak(text);
  }

  Future<void> startListening(
    Function(String) onText, {
    String? localeId,
  }) async {
    bool available = await speech.initialize();
    if (!available) return;

    speech.listen(
      onResult: (result) => onText(result.recognizedWords),
      localeId: localeId, // Support different input languages
    );
  }

  void stopListening() {
    speech.stop();
  }

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
  }

  Future<void> dispose() async {
    await tts.stop();
    speech.stop();
  }
}