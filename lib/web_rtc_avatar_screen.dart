import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webrtc/Common_Files/Constant.dart';
import 'package:webrtc/Common_Files/SharedPreferencesService.dart';
import 'package:webrtc/Common_Files/commonAppColor.dart';
import 'package:webrtc/Core_Module/customButtonCreation.dart';
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

  GlobalKey _repaintKey = GlobalKey();
  Timer? _avatarTimer;

  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    // Default WebSocket URL (user can change in UI)
    // widget.signaling.onMessageReceived = _handleSignalingMessage;

    // _webrtcService.attachSignaling(widget.signaling);

    //  initWebRTC();
    // _startAvatarStream();
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
    _avatarTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
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
      print("Capture error: $e");
      return null;
    }
  }

  Future<void> initWebRTC() async {
    await _webrtcService.init();
    _webrtcService.onAvatarFrameReceived = (frame) {
      if (!mounted) return;
      setState(() {
        remoteAvatarFrame = frame;
      });
    };
  }

  Future<void> _connectWebRTC() async {
    try {
      print("Connecting...");
      widget.signaling.onMessageReceived = _handleSignalingMessage;

      _webrtcService.attachSignaling(widget.signaling);

      initWebRTC();
      _startAvatarStream();

      Future.delayed(Duration(seconds: 1), () async {
        final sdp = await _webrtcService.makeOffer();

        setState(() {
          _isConnected = true;
        });
      });
    } catch (e) {
      print("Connection failed: $e");
    }
  }

  Future<void> _disconnectWebRTC() async {
    print("Disconnecting...");
    try {
      _avatarTimer?.cancel(); // ✅ stop background timer
      _webrtcService.onAvatarFrameReceived = null; // ✅ drop callbacks
      widget.signaling.onMessageReceived = null; // ✅ detach signaling handler
      _webrtcService.dispose();

      setState(() {
        _isConnected = false;
        remoteAvatarFrame = null;
      });
    } catch (e) {
      print("Disconnection error: $e");
    }
  }

  @override
  void dispose() {
    _avatarTimer?.cancel(); // ✅ stop background timer
    _webrtcService.onAvatarFrameReceived = null; // ✅ drop callbacks
    widget.signaling.onMessageReceived = null; // ✅ detach signaling handler
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
            // child: Image.asset(
            //   'assets/bg.png', // Path to your image
            //   fit: BoxFit.cover, // Fills the available space
            // ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            margin: const EdgeInsets.only(top: 100),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    key: _repaintKey,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 2 - 110,
                      color: Colors.grey, //_currentColor,
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
                        ? SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height:
                                MediaQuery.of(context).size.height / 2 - 110,
                            child: Image.memory(
                              remoteAvatarFrame!,
                              gaplessPlayback: true,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width,
                            height:
                                MediaQuery.of(context).size.height / 2 - 110,
                            color: Colors.grey,
                          ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 30, left: 20, right: 20),
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
                          await _disconnectWebRTC();
                        } else {
                          await _connectWebRTC();
                        }
                        // Add your button onPressed logic here
                        // final sdp = await _webrtcService.makeOffer();
                        // print("String Show = $sdp");
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: IconButton(
              icon: Image.asset('assets/Back.png'),
              iconSize: 50,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showInputDialog() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Please enter valid SDP."),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Type something..."),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // return null
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  /// Show SDP for copy-paste
  void _showSDPPopup(String title, String sdp) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(sdp)),
        actions: [
          TextButton(
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
