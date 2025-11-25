import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:webrtc/AudioSTTTTS.dart';
import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/CustomDropdown.dart';
import 'package:webrtc/Common_Files/SharedPreferencesService.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:webrtc/Core_Module/customButtonCreation.dart';
import 'package:webrtc/LocalTranslator.dart';
import 'package:webrtc/LanguageDetector.dart';
import 'package:webrtc/SignalingService.dart';
import 'package:webrtc/webrtc_Avatar.dart';

class web_rtc_avatar_screen extends StatefulWidget {
  const web_rtc_avatar_screen({
    super.key,
    required this.title,
    this.prefsService,
    required this.signaling,
  });

  final String? title;
  final SharedPreferencesService? prefsService;
  final SignalingService signaling;

  @override
  State<web_rtc_avatar_screen> createState() => web_rtc_avatar_screenState();
}

class web_rtc_avatar_screenState extends State<web_rtc_avatar_screen> {
  final webrtc_Avatar _webrtcService = webrtc_Avatar();
  Uint8List? remoteAvatarFrame;

  // Translation components
  final AudioSTTTTS audio = AudioSTTTTS();
  final LocalTranslator translator = LocalTranslator();
  final LanguageDetector languageDetector = LanguageDetector();
  
  String receivedTranslatedText = '';
  String detectedLanguage = 'Unknown';
  
  // Supported language pairs (you can add more)
  TranslateLanguage primaryLang = TranslateLanguage.english;
  TranslateLanguage secondaryLang = TranslateLanguage.hindi;

  GlobalKey _repaintKey = GlobalKey();
  Timer? _avatarTimer;

  bool _isConnected = false;
  bool _isListening = false;
  String locationNumStr = 'Doc_Male.glb';

  final List<String> locationNumberItem = [
    'Doc_Male.glb',
    'Doc_Female.glb',
    'Patient_Male.glb',
    'Patient_Female.glb',
  ];

  @override
  void initState() {
    super.initState();

    _initTranslator();
    widget.signaling.onMessageReceived = _handleSignalingMessage;
    _webrtcService.attachSignaling(widget.signaling);

    initWebRTC();
    _startAvatarStream();

    Future.delayed(const Duration(seconds: 3), () {
      sendString(locationNumStr);
    });
  }

  Future<void> _initTranslator() async {
    // Initialize bidirectional translation: English ↔ Hindi
    await translator.init(
      languageA: primaryLang,
      languageB: secondaryLang,
    );
    print('✅ Translator initialized: ${primaryLang.bcpCode} ↔ ${secondaryLang.bcpCode}');
  }

  void _handleSignalingMessage(Map<String, dynamic> message) async {
    final type = message['type'];
    switch (type) {
      case 'offer':
        await _webrtcService.setRemoteDescription(message['sdp'], 'offer');
        await _webrtcService.makeAnswer();
        break;
      case 'answer':
        await _webrtcService.setRemoteDescription(message['sdp'], 'answer');
        break;
      case 'ice':
        await _webrtcService.addIceCandidate(
          message['candidate'],
          message['sdpMid'],
          message['sdpMLineIndex'],
        );
        break;
    }
  }

  void _startAvatarStream() {
    _avatarTimer?.cancel();
    // 15 FPS for better lip-sync
    _avatarTimer = Timer.periodic(Duration(milliseconds: 66), (timer) async {
      final bytes = await _captureContainer();
      if (bytes != null) {
        _webrtcService.sendAvatarFrame(bytes);
      }
    });
  }

  Future<Uint8List?> _captureContainer() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Capture error: $e');
      return null;
    }
  }

  Future<void> initWebRTC() async {
    await _webrtcService.init();

    // Handle incoming avatar frames
    _webrtcService.onAvatarFrameReceived = (frame) {
      if (!mounted) return;
      setState(() {
        remoteAvatarFrame = frame;
      });
    };

    // Handle incoming translations
    _webrtcService.onTranslationReceived = (translationMsg) async {
      if (!mounted) return;

      print('📥 Received: ${translationMsg.text} [${translationMsg.languageCode}]');

      // Detect which language we received
      String? detectedLang = await languageDetector.detectLanguage(translationMsg.text);
      
      String textToSpeak = translationMsg.text;
      String speakLocale = translationMsg.languageCode;

      // If it's in the other language, translate it back
      if (detectedLang == secondaryLang.bcpCode.split('-').first) {
        // Received secondary language, translate to primary
        textToSpeak = await translator.translateBtoA(translationMsg.text);
        speakLocale = primaryLang.bcpCode
        print('🔄 Translated back: $textToSpeak');
      } else if (detectedLang == primaryLang.bcpCode.split('-').first) {
        // Received primary language, translate to secondary
        textToSpeak = await translator.translateAtoB(translationMsg.text);
        speakLocale = secondaryLang.bcpCode;
        print('🔄 Translated: $textToSpeak');
      }

      setState(() {
        receivedTranslatedText = textToSpeak;
        detectedLanguage = detectedLang ?? 'Unknown';
      });

      // Speak in appropriate language
      await audio.speak(textToSpeak, languageCode: speakLocale);
    };
  }

  void startAutoTranslation() async {
    if (_isListening) {
      stopSpeaking();
      return;
    }

    setState(() {
      _isListening = true;
    });

    // Listen with default device locale first
    // We'll detect language from the text afterwards
    audio.startListening(
      (spokenText) async {
        if (spokenText.trim().isEmpty) return;

        print('🎤 Heard: $spokenText');

        // Detect language from spoken text
        String? detectedLang = await languageDetector.detectLanguage(spokenText);
        
        if (detectedLang == null) {
          print('⚠️ Could not detect language, defaulting to primary');
          detectedLang = primaryLang.bcpCode.split('-').first;
        }

        setState(() {
          detectedLanguage = detectedLang!;
        });

        String translated;
        String targetLocale;

        // Translate based on detected language
        if (detectedLang == primaryLang.bcpCode.split('-').first) {
          // Speaking primary language → translate to secondary
          translated = await translator.translateAtoB(spokenText);
          targetLocale = secondaryLang.bcpCode;
          print('🔄 English → Hindi: $translated');
        } else if (detectedLang == secondaryLang.bcpCode.split('-').first) {
          // Speaking secondary language → translate to primary
          translated = await translator.translateBtoA(spokenText);
          targetLocale = primaryLang.bcpCode;
          print('🔄 Hindi → English: $translated');
        } else {
          // Unknown language, send as-is
          translated = spokenText;
          targetLocale = primaryLang.bcpCode;
          print('⚠️ Unknown language, sending as-is');
        }

        // Send translated text
        _webrtcService.sendTranslation(translated, targetLocale);

        // Show what we sent
        setState(() {
          receivedTranslatedText = 'Sent ($detectedLang): $translated';
        });
      },
    );
  }

  void stopSpeaking() {
    audio.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    _avatarTimer?.cancel();
    _webrtcService.onAvatarFrameReceived = null;
    _webrtcService.onTranslationReceived = null;
    widget.signaling.onMessageReceived = null;
    audio.dispose();
    translator.dispose();
    languageDetector.dispose();
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: Colors.white,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            margin: const EdgeInsets.only(top: 120),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Local avatar
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2 - 110,
                      color: Colors.grey,
                      child: const Center(
                        child: AndroidView(viewType: 'camera_native_view'),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Remote avatar
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 2 - 110,
                    child: remoteAvatarFrame != null
                        ? Image.memory(
                            remoteAvatarFrame!,
                            gaplessPlayback: true,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height / 2 - 110,
                            color: Colors.grey,
                            child: Center(
                              child: Text(
                                'Waiting for remote avatar...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                  ),

                  // Language detection status
                  if (detectedLanguage != 'Unknown')
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🌐 Detected: $detectedLanguage',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Translation status
                  if (receivedTranslatedText.isNotEmpty)
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        receivedTranslatedText,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                  // Call button
                  Container(
                    margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                    child: customButtonCreation(
                      buttonFontSize: 18,
                      fontName: font_roboto,
                      fontWeight: FontWeight.w400,
                      buttonHeight: 60,
                      title: _isConnected ? 'Disconnect' : 'Call',
                      backgroundColor: _isConnected
                          ? Colors.red
                          : commonAppColor.buttonColor,
                      borderColor: _isConnected
                          ? Colors.red
                          : commonAppColor.buttonColor,
                      textColor: Colors.black,
                      onPressed: () async {
                        if (_isConnected) {
                          stopSpeaking();
                          // Handle disconnect
                        } else {
                          final sdp = await _webrtcService.makeOffer();
                          print('📤 Offer SDP: $sdp');
                          setState(() {
                            _isConnected = true;
                          });
                        }
                      },
                    ),
                  ),

                  // Auto translation button (detects language automatically)
                  Container(
                    margin: EdgeInsets.only(top: 10, left: 20, right: 20),
                    child: customButtonCreation(
                      buttonFontSize: 18,
                      fontName: font_roboto,
                      fontWeight: FontWeight.w400,
                      buttonHeight: 60,
                      title: _isListening
                          ? '🔴 Stop Auto-Translation'
                          : '🎤 Start Auto-Translation',
                      backgroundColor: _isListening ? Colors.red : Colors.green,
                      borderColor: _isListening ? Colors.red : Colors.green,
                      textColor: Colors.white,
                      onPressed: startAutoTranslation,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header with back button and avatar selector
          Container(
            height: 80,
            margin: EdgeInsets.only(top: 40, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Image.asset('assets/Back.png'),
                  iconSize: 80,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Container(
                  height: 50,
                  width: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: commonAppColor.buttonColor,
                    border: Border.all(
                      color: commonAppColor.buttonColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              locationNumStr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: font_roboto,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.normal,
                                fontSize: 16,
                                color: commonAppColor.blackColor,
                              ),
                            ),
                          ),
                          Container(
                            color: commonAppColor.yellowColor,
                            alignment: Alignment.center,
                            width: 50,
                            height: 50,
                            child: Image.asset('assets/Drop_down.png'),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        width: 200,
                        child: customDropDown(
                          items: locationNumberItem,
                          valueChanged: (value) {
                            setState(() {
                              locationNumStr = value!;
                            });
                            sendString(value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendString(String fileName) async {
    final response = await Constant.platform.invokeMethod('sendFileName', {
      'file_name': fileName,
    });
    print(response);
  }
}