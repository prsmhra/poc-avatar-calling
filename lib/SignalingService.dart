import 'dart:convert';
import 'package:web_socket_channel/io.dart';

class SignalingService {
  IOWebSocketChannel? channel;
  void Function(Map<String, dynamic>)? onMessageReceived;

  Future<void> connect(String url) async {
    try {
      print("🔌 Connecting to $url ...");
      channel = IOWebSocketChannel.connect(url);
      print("✅ Connected to signaling server: $url");

      channel!.stream.listen((message) {
        final data = jsonDecode(message);
        onMessageReceived?.call(data);
      }, onError: (error) {
        print("❌ WebSocket error: $error");
      }, onDone: () {
        print("🔌 WebSocket closed.");
      });
    } catch (e) {
      print("❌ Failed to connect: $e");
    }
  }

  void send(Map<String, dynamic> data) {
    if (channel == null) {
      print("⚠️ Cannot send message — WebSocket not connected!");
      return;
    }
    final json = jsonEncode(data);
    print("📤 Sending: $json");
    channel!.sink.add(json);
  }

  void disconnect() {
    channel?.sink.close();
    print("🔌 Disconnected.");
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io'; // <-- for WebSocket.connect and pingInterval
// import 'package:web_socket_channel/io.dart';

// enum ConnectionStateEx { disconnected, connecting, connected }

// class SignalingService {
//   IOWebSocketChannel? _channel;
//   WebSocket? _socket; // keep underlying socket to check readyState & set pingInterval
//   StreamSubscription? _sub;

//   // Public callback (like you had)
//   void Function(Map<String, dynamic>)? onMessageReceived;

//   // Connection state
//   final _stateCtrl = StreamController<ConnectionStateEx>.broadcast();
//   ConnectionStateEx _state = ConnectionStateEx.disconnected;

//   Stream<ConnectionStateEx> get connectionStates => _stateCtrl.stream;
//   ConnectionStateEx get state => _state;
//   bool get isConnected =>
//       _state == ConnectionStateEx.connected &&
//       _socket != null &&
//       _socket!.readyState == WebSocket.open;

//   void _setState(ConnectionStateEx s) {
//     _state = s;
//     _stateCtrl.add(s);
//   }

//   /// Connect and only return true when the WebSocket handshake completes.
//   /// Optionally, wait for an application-level "ready" message to be extra sure.
//   Future<bool> connect(
//     String url, {
//     Duration timeout = const Duration(seconds: 10),
//     bool waitForReadyMessage = false,
//     String readyType = 'ready', // adjust if your server sends a different type
//     Duration readyTimeout = const Duration(seconds: 5),
//     Duration pingInterval = const Duration(seconds: 30),
//   }) async {
//     if (isConnected) return true;

//     _setState(ConnectionStateEx.connecting);

//     try {
//       // 1) Await the real TCP/WebSocket handshake
//       _socket = await WebSocket.connect(url).timeout(timeout);
//       // Optional: automate pings to detect broken connections
//       _socket!.pingInterval = pingInterval;

//       // 2) Wrap in IOWebSocketChannel
//       _channel = IOWebSocketChannel(_socket!);

//       // 3) Start listening
//       _sub = _channel!.stream.listen(
//         (message) {
//           // If you want to complete "ready" handshake when a specific message arrives:
//           if (waitForReadyMessage) {
//             try {
//               final data = jsonDecode(message);
//               if (data is Map && data['type'] == readyType) {
//                 // ready confirmed
//                 _readyCompleter?.complete(true);
//               }
//               // Forward to app handler
//               onMessageReceived?.call(Map<String, dynamic>.from(data));
//             } catch (_) {
//               // If it's not JSON, ignore or handle differently
//             }
//           } else {
//             // No explicit ready handshake — just forward
//             try {
//               final data = jsonDecode(message);
//               onMessageReceived?.call(Map<String, dynamic>.from(data));
//             } catch (_) {
//               // handle non-JSON if needed
//             }
//           }
//         },
//         onError: (error, [st]) {
//           _readyCompleter?.completeError(error);
//           _cleanup();
//           _setState(ConnectionStateEx.disconnected);
//         },
//         onDone: () {
//           _readyCompleter?.complete(false);
//           _cleanup();
//           _setState(ConnectionStateEx.disconnected);
//         },
//         cancelOnError: true,
//       );

//       // 4) Mark as connected at transport level
//       _setState(ConnectionStateEx.connected);

//       // 5) Optionally wait for an app-level "ready" message
//       if (waitForReadyMessage) {
//         final ok = await _waitForReady(readyTimeout);
//         if (!ok) {
//           // app-level handshake failed; cleanly disconnect
//           await disconnect();
//           return false;
//         }
//       }

//       return true;
//     } on TimeoutException {
//       _cleanup();
//       _setState(ConnectionStateEx.disconnected);
//       return false;
//     } catch (e) {
//       _cleanup();
//       _setState(ConnectionStateEx.disconnected);
//       return false;
//     }
//   }

//   Completer<bool>? _readyCompleter;
//   Future<bool> _waitForReady(Duration timeout) {
//     _readyCompleter = Completer<bool>();
//     return _readyCompleter!.future.timeout(timeout, onTimeout: () => false);
//   }

//   /// Send JSON map safely
//   void send(Map<String, dynamic> data) {
//     if (!isConnected) {
//       print("⚠️ Cannot send — WebSocket not connected");
//       return;
//     }
//     final json = jsonEncode(data);
//     _channel!.sink.add(json);
//   }

//   /// Graceful disconnect
//   Future<void> disconnect([int? code, String? reason]) async {
//     try {
//       await _sub?.cancel();
//     } catch (_) {}
//     try {
//       await _channel?.sink.close(code, reason);
//     } catch (_) {}
//     _cleanup();
//     _setState(ConnectionStateEx.disconnected);
//   }

//   void _cleanup() {
//     _sub = null;
//     _channel = null;
//     _socket = null;
//     _readyCompleter = null;
//   }

//   void dispose() {
//     _stateCtrl.close();
//     disconnect();
//   }
// }