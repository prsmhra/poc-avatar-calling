import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc/SignalingService.dart';

class TranslationMessage {
  final String text;
  final String languageCode;
  final int timestamp; // For sync

  TranslationMessage({
    required this.text,
    required this.languageCode,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'languageCode': languageCode,
        'timestamp': timestamp,
      };

  factory TranslationMessage.fromJson(Map<String, dynamic> json) {
    return TranslationMessage(
      text: json['text'] as String,
      languageCode: json['languageCode'] as String,
      timestamp: json['timestamp'] as int,
    );
  }
}

class webrtc_Avatar {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Text translation channel with metadata
  RTCDataChannel? textChannel;
  Function(TranslationMessage)? onTranslationReceived;

  // Avatar frame channel
  RTCDataChannel? avatarDataChannel;
  Function(Uint8List)? onAvatarFrameReceived;

  SignalingService? signaling;

  void attachSignaling(SignalingService service) {
    signaling = service;
  }

  Future<void> init() async {
    await _initPeerConnection();
    await _initLocalMedia();
    _createDataChannel();
  }

  Future<void> _initPeerConnection() async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': ['turn:relay1.expressturn.com:3480'],
          'username': '000000002076490292',
          'credential': 'xeVMl4/BdaroVSZzietZyc4Swu4=',
        },
      ],
    };
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (candidate) {
      if (signaling != null) {
        signaling!.send({
          'type': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    _peerConnection!.onDataChannel = (RTCDataChannel channel) {
      if (channel.label == 'avatarChannel') {
        avatarDataChannel = channel;
        avatarDataChannel!.onMessage = (RTCDataChannelMessage message) {
          final Uint8List bytes = base64Decode(message.text);
          if (onAvatarFrameReceived != null) onAvatarFrameReceived!(bytes);
        };
      } else if (channel.label == 'textChannel') {
        textChannel = channel;
        _setupTextChannelListener();
      }
    };
  }

  Future<void> _initLocalMedia() async {
    final constraints = {'audio': true, 'video': false};
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  void _createDataChannel() async {
    // Avatar channel
    avatarDataChannel = await _peerConnection!.createDataChannel(
      'avatarChannel',
      RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30,
    );

    avatarDataChannel!.onMessage = (RTCDataChannelMessage message) {
      final Uint8List bytes = base64Decode(message.text);
      if (onAvatarFrameReceived != null) onAvatarFrameReceived!(bytes);
    };

    // Text translation channel
    textChannel = await _peerConnection!.createDataChannel(
      'textChannel',
      RTCDataChannelInit()..ordered = true,
    );

    _setupTextChannelListener();
  }

  void _setupTextChannelListener() {
    textChannel!.onMessage = (RTCDataChannelMessage message) {
      try {
        final json = jsonDecode(message.text) as Map<String, dynamic>;
        final translationMsg = TranslationMessage.fromJson(json);
        if (onTranslationReceived != null) {
          onTranslationReceived!(translationMsg);
        }
      } catch (e) {
        print('❌ Error parsing translation message: $e');
      }
    };
  }

  void sendTranslation(String text, String languageCode) {
    if (textChannel != null &&
        textChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final message = TranslationMessage(
        text: text,
        languageCode: languageCode,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      final json = jsonEncode(message.toJson());
      textChannel!.send(RTCDataChannelMessage(json));
      print('📤 Sent translation: $text [$languageCode]');
    } else {
      print('⚠️ Text channel not open');
    }
  }

  void sendAvatarFrame(Uint8List frameBytes) {
    if (avatarDataChannel != null &&
        avatarDataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final encoded = base64Encode(frameBytes);
      avatarDataChannel!.send(RTCDataChannelMessage(encoded));
    }
  }

  Future<String> makeOffer() async {
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    signaling?.send({'type': 'offer', 'sdp': offer.sdp});
    return offer.sdp!;
  }

  Future<String> makeAnswer() async {
    try {
      if (_peerConnection?.setRemoteDescription == null) {
        return 'Cannot create answer: remote description not set yet!';
      }

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      signaling?.send({'type': 'answer', 'sdp': answer.sdp});
      return answer.sdp!;
    } catch (e) {
      return 'Error creating answer: $e';
    }
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    if (!isValidSdp(sdp)) {
      print('Invalid SDP received!');
      return;
    }
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, type),
    );
  }

  Future<void> addIceCandidate(
    String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  ) async {
    await _peerConnection!.addCandidate(
      RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
    );
  }

  bool isValidSdp(String sdp) {
    if (sdp.trim().isEmpty) return false;
    return sdp.trim().startsWith('v=0');
  }

  Future<void> dispose() async {
    avatarDataChannel?.close();
    textChannel?.close();
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
  }
}