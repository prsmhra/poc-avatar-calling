import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc/SignalingService.dart';

class webrtc_Avatar {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  //For Translator ******************
  // ****** TEXT TRANSLATOR CHANNEL *******
  RTCDataChannel? textChannel;
  Function(String)? onTextReceived;
  //**********************************/

  RTCDataChannel? avatarDataChannel;
  Function(Uint8List)? onAvatarFrameReceived;

  //For Web Socket
  SignalingService? signaling;
  void attachSignaling(SignalingService service) {
    signaling = service;
  }

  // Initialize PeerConnection and data channel
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
      avatarDataChannel = channel;
      avatarDataChannel!.onMessage = (RTCDataChannelMessage message) {
        final Uint8List bytes = base64Decode(message.text);
        if (onAvatarFrameReceived != null) onAvatarFrameReceived!(bytes);
      };
    };
  }

  Future<void> _initLocalMedia() async {
    // Only audio or no media; video is false
    final constraints = {'audio': true, 'video': false};
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  void _createDataChannel() async {
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

    // --- TEXT CHANNEL FOR TRANSLATION ---
    textChannel = await _peerConnection!.createDataChannel(
      'textChannel',
      RTCDataChannelInit()..ordered = true,
    );

    textChannel!.onMessage = (RTCDataChannelMessage message) {
      if (onTextReceived != null) {
        onTextReceived!(message.text);
      }
    };
  }

  void sendTextMessage(String text) {
  if (textChannel != null &&
      textChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
    textChannel!.send(RTCDataChannelMessage(text));
  } else {
    print("⚠️ Text channel not open");
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
    // Send offer via WebSocket automatically
    signaling?.send({'type': 'offer', 'sdp': offer.sdp});
    return offer.sdp!;
  }

  Future<String> makeAnswer() async {
    try {
      // Check if remote SDP is set
      if (_peerConnection?.setRemoteDescription == null) {
        return 'Cannot create answer: remote description not set yet!';
      }

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      signaling?.send({'type': 'answer', 'sdp': answer.sdp});
      return answer.sdp!;
    } catch (e) {
      return 'Error creating answer: $e'; // safely return null instead of crashing
    }
  }

  Future<void> setRemoteDescription(String sdp, String type) async {
    if (!isValidSdp(sdp)) {
      print("Invalid SDP received!");
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
    return sdp.trim().startsWith("v=0");
  }

  Future<void> dispose() async {
    avatarDataChannel?.close();
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
  }
}
