// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';

// class webrtc_Avatar {
//   RTCPeerConnection? _peerConnection;
//   MediaStream? _localStream;

//   final RTCVideoRenderer localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

//   Timer? _avatarTimer;

//   /// Initialize renderers and PeerConnection
//   Future<void> initLocalMedia() async {
//     await localRenderer.initialize();
//     await remoteRenderer.initialize();
//     await _initPeerConnection();
//     await _initLocalAvatarStream();
//   }

//   /// Initialize PeerConnection
//   Future<void> _initPeerConnection() async {
//     final configuration = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ]
//     };

//     _peerConnection = await createPeerConnection(configuration);

//     _peerConnection!.onTrack = (RTCTrackEvent event) {
//       if (event.streams.isNotEmpty) {
//         remoteRenderer.srcObject = event.streams[0];
//       }
//     };

//     _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
//       print("ICE candidate: ${candidate.candidate}");
//       // TODO: Send candidate to remote peer via signaling
//     };
//   }

//   /// Create a local avatar stream with simple shapes
//   Future<void> _initLocalAvatarStream() async {
//     // Audio track (optional)
//     final stream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});

//     final videoTrack = await _createCanvasVideoTrack(width: 320, height: 240);
//     stream.addTrack(videoTrack);

//     _localStream = stream;
//     localRenderer.srcObject = _localStream;

//     // Add track to PeerConnection
//     _peerConnection?.addTrack(videoTrack, stream);
//   }

//   /// Draw avatar frames and create video track
//   Future<MediaStreamTrack> _createCanvasVideoTrack({required int width, required int height}) async {
//     final stream = await createLocalMediaStream('avatar_stream');
//     final videoTrack = await Helper.createVideoTrack('avatar_track', width, height);

//     stream.addTrack(videoTrack);

//     _avatarTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
//       final recorder = await videoTrack.startFrameCapture(width: width, height: height);
//       final ui.Image frame = await _drawAvatarFrame(width, height);
//       await recorder.sendFrame(frame);
//       frame.dispose();
//     });

//     return videoTrack;
//   }

//   /// Simple avatar with "bland shapes"
//   Future<ui.Image> _drawAvatarFrame(int width, int height) async {
//     final recorder = ui.PictureRecorder();
//     final canvas = ui.Canvas(recorder);
//     final paint = ui.Paint()..color = Colors.blueAccent;

//     canvas.drawRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), Paint()..color=Colors.white);
//     canvas.drawCircle(Offset(width / 2, height / 2), 50, paint);
//     canvas.drawRect(Rect.fromLTWH(100, 100, 40, 40), Paint()..color=Colors.red);

//     final picture = recorder.endRecording();
//     return picture.toImage(width, height);
//   }

//   /// Create offer
//   Future<String> makeOffer() async {
//     final offer = await _peerConnection!.createOffer();
//     await _peerConnection!.setLocalDescription(offer);
//     return offer.sdp!;
//   }

//   /// Create answer
//   Future<String> makeAnswer() async {
//     final answer = await _peerConnection!.createAnswer();
//     await _peerConnection!.setLocalDescription(answer);
//     return answer.sdp!;
//   }

//   /// Set remote SDP
//   Future<void> setRemoteDescription(String sdp, String type) async {
//     await _peerConnection!.setRemoteDescription(RTCSessionDescription(sdp, type));
//   }

//   /// Dispose everything
//   Future<void> dispose() async {
//     _avatarTimer?.cancel();
//     localRenderer.dispose();
//     remoteRenderer.dispose();
//     _localStream?.dispose();
//     _peerConnection?.close();
//     _peerConnection = null;
//   }
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc/SignalingService.dart';

class webrtc_Avatar {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

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
    // final config = {
    //   'iceServers': [
    //     {'urls': 'stun:stun.l.google.com:19302'},
    //   ]
    // };

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

    // _peerConnection = await createPeerConnection(config);

    // _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
    //   print("ICE Candidate: ${candidate.candidate}");
    //   // Send candidate via signaling to remote peer
    // };

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
