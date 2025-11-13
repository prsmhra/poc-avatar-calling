import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/SharedPreferencesService.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:webrtc/Core_Module/custom360RotationImage.dart';
import 'package:webrtc/web_RTC_ConnectVC.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsService = SharedPreferencesService();
  await prefsService.init();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    CameraChannel.initialize();
    runApp(MyApp(prefsService: prefsService));
  });
}

class CameraChannel {
  static const MethodChannel _channel = MethodChannel('camera_channel');

  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onFrameData') {
        final arg = call.arguments as String;
        try {
          final Map<String, dynamic> map = jsonDecode(arg);

          final frameBase64 = map['frame'] as String?;
          final avatarBase64 = map['avatarView'] as String?;
          final blendshapes = map['blendshapes'] as dynamic;

          Uint8List? frameBytes;
          Uint8List? avatarBytes;
          if (frameBase64 != null && frameBase64.isNotEmpty) {
            frameBytes = base64Decode(frameBase64);
          }
          if (avatarBase64 != null && avatarBase64.isNotEmpty) {
            avatarBytes = base64Decode(avatarBase64);
          }

          debugPrint(
            'Received onFrameData — blendshapes length: ${_lengthOf(blendshapes)}',
          );

          FrameStream.instance.add(
            FrameData(frameBytes, avatarBytes, blendshapes),
          );
        } catch (e) {
          debugPrint('Error parsing onFrameData: $e');
        }
      }
      return null;
    });
  }

  static int _lengthOf(dynamic v) {
    if (v == null) return 0;
    if (v is List) return v.length;
    if (v is String) {
      try {
        final parsed = jsonDecode(v);
        if (parsed is List) return parsed.length;
      } catch (_) {}
    }
    return 0;
  }
}

// Simple singleton stream to receive frames in UI
class FrameStream {
  FrameStream._private();
  static final instance = FrameStream._private();
  final _controller = StreamController<FrameData>.broadcast();
  Stream<FrameData> get stream => _controller.stream;
  void add(FrameData data) => _controller.add(data);
}

class FrameData {
  final Uint8List? frameBytes;
  final Uint8List? avatarBytes;
  final dynamic blendshapes;
  FrameData(this.frameBytes, this.avatarBytes, this.blendshapes);
}

class MyApp extends StatelessWidget {
  final SharedPreferencesService? prefsService;
  const MyApp({Key? key, this.prefsService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Camera Host View',
      // Keep existing screens intact; add route for web_rtc_avatar_screen so
      // SplashScreen can navigate to it using the existing pushNamed call.
      debugShowCheckedModeBanner: false,
      home: SplashScreen(title: 'Splash'),

      routes: {
        // '/web_rtc_avatar_screen': (context) => web_rtc_avatar_screen(
        //   title: 'web_rtc_avatar_screen',
        //   prefsService: prefsService,
        // ),
        '/web_RTC_ConnectVC': (context) => web_RTC_ConnectVC(
          title: 'web_RTC_ConnectVC',
          prefsService: prefsService,
        ),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.title});
  final String? title;

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WakelockPlus.enable();

    Timer(
      const Duration(seconds: 3),
      () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/web_RTC_ConnectVC',
        (route) => false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: commonAppColor.whiteColor,
            child: Image.asset(
              'assets/bg.png', // Path to your image
              fit: BoxFit.cover, // Fills the available space
            ),
          ),
          Container(
            color: Colors.transparent,
            width: MediaQuery.of(context).size.width,
            height: screenHeight,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.center,
                    margin: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: screenHeight / 2 + 130,
                    ),
                    child: const Text(
                      'Avatar Video Calling',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: font_roboto,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.normal,
                        fontSize: 20,
                        color: commonAppColor.blackColor,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
                    alignment: Alignment.center,
                    child: const custom360RotationImage(),
                  ),
                  Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.only(
                      top: 100,
                      left: 20,
                      right: 20,
                    ),
                    child: const Text(
                      "©2025 HCLTech All rights reserved.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: font_roboto,
                        fontWeight: FontWeight.normal,
                        fontStyle: FontStyle.normal,
                        fontSize: 13,
                        color: commonAppColor.blackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // ),
    );
  }
}
