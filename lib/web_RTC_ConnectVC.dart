import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/SharedPreferencesService.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:webrtc/Core_Module/customButtonCreation.dart';
import 'package:webrtc/Core_Module/customLabelCreation.dart';
import 'package:webrtc/Core_Module/customTextFieldCreation.dart';
import 'package:webrtc/SignalingService.dart';
import 'package:webrtc/web_rtc_avatar_screen.dart';

class web_RTC_ConnectVC extends StatefulWidget {
  const web_RTC_ConnectVC({super.key, required this.title, this.prefsService});

  final String? title;
  final SharedPreferencesService? prefsService;

  @override
  State<web_RTC_ConnectVC> createState() => web_RTC_ConnectVCState();
}

class web_RTC_ConnectVCState extends State<web_RTC_ConnectVC> {
  final SignalingService _signaling = SignalingService();
  final TextEditingController ipAddressTextField = TextEditingController();
  bool _isConnected = false;
  // late IOWebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    // Default WebSocket URL (user can change in UI)
     ipAddressTextField.text = "";

    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
  // Ask for camera
  var cameraStatus = await Permission.camera.status;
  if (!cameraStatus.isGranted) {
    cameraStatus = await Permission.camera.request();
  }

  // Ask for mic (optional)
  var micStatus = await Permission.microphone.status;
  if (!micStatus.isGranted) {
    micStatus = await Permission.microphone.request();
  }

  if (cameraStatus.isGranted && micStatus.isGranted) {
    print('✅ Camera & Mic permission granted');
  } else {
    print('❌ Permission denied');
  }
}

  void _connectToWebSocket() async {
    final url = ipAddressTextField.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a WebSocket URL')),
      );
      return;
    }

    // Optional: prevent double-taps while connecting
    if (mounted) {
      setState(() {
        _isConnected =
            false; // or set a `_isConnecting = true` flag if you have one
      });
    }

    try {
      _signaling.connect(url);
      setState(() {
          _isConnected = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connecting to $url')));

      // final connected = await _signaling.connect(
      //   url,
      //   timeout: const Duration(seconds: 8),
      //   waitForReadyMessage:
      //       true, // set to false if you don't have server 'ready'
      //   readyType: 'ready',
      //   readyTimeout: const Duration(seconds: 5),
      // );
      // if (!mounted) return;
      // if (connected) {
      //   setState(() {
      //     _isConnected = true;
      //   });
      //   ScaffoldMessenger.of(
      //     context,
      //   ).showSnackBar(SnackBar(content: Text('Connecting to $url')));
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Failed to connect signaling')),
      //   );
      // }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
    }
  }

  @override
  void dispose() {
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
            // child: Image.asset(
            //   'assets/bg.png', // Path to your image
            //   fit: BoxFit.cover, // Fills the available space
            // ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            margin: EdgeInsets.only(top: 100),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // set onTap to unfocus
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: const AssetImage('assets/AppLogo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    customLabelCreation(
                      headingText: 'Connected to signaling server.',
                      textFontName: font_roboto,
                      textFontSize: 20,
                    ),
                    customTextFieldCreation(
                      controllerTextEditing: ipAddressTextField,
                      hintText: 'ws://<host>:<port>',
                      obscureText: false,
                      textFontSize: 16,
                      textFontName: font_roboto,
                    ),
                    Container(
                      height: 2,
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      child: const Divider(color: Colors.black),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 50, left: 20, right: 20),
                      child: ElevatedButton(
                        onPressed: _isConnected ? null : _connectToWebSocket,
                        child: Text(_isConnected ? 'Connected' : 'Connect'),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 100, left: 20, right: 20),
                      child: customButtonCreation(
                        buttonFontSize: 18,
                        fontName: font_roboto,
                        fontWeight: FontWeight.w400,
                        buttonHeight: 60,
                        title: 'Continue',
                        backgroundColor: _isConnected
                            ? Colors.green
                            : commonAppColor.grayLightColor,
                        borderColor: _isConnected
                            ? Colors.green
                            : commonAppColor.grayLightColor,
                        textColor: _isConnected ? Colors.white : Colors.black,
                        onPressed: () {
                          // Add your button onPressed logic here
                          if (_isConnected) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => web_rtc_avatar_screen(
                                  prefsService: widget.prefsService,
                                  signaling: _signaling,
                                  title: 'Avatar Screen',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
