import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();

  factory ChatSocketService() => _instance;

  ChatSocketService._internal();

  IO.Socket? _socket;
  final AuthService _authService = AuthService();

  // Cambia esta URL según dónde corras el backend
  static const String baseUrl = 'http://localhost:3000';

  IO.Socket get socket {
    if (_socket == null) {
      throw Exception('Socket no inicializado');
    }
    return _socket!;
  }

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Socket conectado: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('Socket desconectado');
    });

    _socket!.onConnectError((error) {
      print('Error conectando socket: $error');
    });

    _socket!.onError((error) {
      print('Error socket: $error');
    });
  }

  Future<void> joinRoom(String roomId) async {
    final userId = await _authService.getUserId();

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('No se pudo identificar el usuario actual');
    }

    if (!isConnected) {
      await connect();
    }

    socket.emit('joinRoom', {
      'roomId': roomId,
      'userId': userId.trim(),
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final userId = await _authService.getUserId();

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('No se pudo identificar el usuario actual');
    }

    if (!isConnected) {
      await connect();
    }

    socket.emit('sendMessage', {
      'roomId': roomId,
      'senderId': userId.trim(),
      'content': content,
    });
  }

  Future<void> markAsRead(String roomId) async {
    final userId = await _authService.getUserId();

    if (userId == null || userId.trim().isEmpty) {
      throw Exception('No se pudo identificar el usuario actual');
    }

    if (!isConnected) {
      await connect();
    }

    socket.emit('markAsRead', {
      'roomId': roomId,
      'userId': userId.trim(),
    });
  }

  void listenNewMessages(void Function(ChatMessage message) callback) {
    socket.off('newMessage');

    socket.on('newMessage', (data) {
      if (data is Map) {
        final message = ChatMessage.fromJson(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );

        callback(message);
      }
    });
  }

  void listenMessagesRead(void Function(Map<String, dynamic> data) callback) {
    socket.off('messagesRead');

    socket.on('messagesRead', (data) {
      if (data is Map) {
        callback(
          data.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    });
  }

  void leaveRoom(String roomId) {
    socket.emit('leaveRoom', {
      'roomId': roomId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}