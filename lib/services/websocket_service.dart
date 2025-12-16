import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  Function(List<double>)? onDataReceived; // Callback

  WebSocketService({required this.url});
  
  void connect() {
    _channel = IOWebSocketChannel.connect(url);
    _channel!.stream.listen((data) {
        var decodedData = jsonDecode(data);
        if (decodedData is List) {
          onDataReceived?.call(decodedData.cast<double>());
        }
    }, onError: (error) {
      Logger().e('Error en WebSocket: $error');
      reconnect();
    }, onDone: () {
      reconnect();
    });
  }

  void reconnect() {
    Future.delayed(Duration(seconds: 3), () {
      connect();
    });
  }

  void disconnect() {
    _channel?.sink.close();
  }
}