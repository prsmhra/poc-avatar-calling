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