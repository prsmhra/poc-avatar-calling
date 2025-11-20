import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class AudioSTTTTS {
  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  Future<void> speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.speak(text);
  }

  Future<void> startListening(Function(String) onText) async {
    bool available = await speech.initialize();
    if (!available) return;

    speech.listen(
      onResult: (result) => onText(result.recognizedWords),
    );
  }

  void stopListening() {
    speech.stop();
  }
}
