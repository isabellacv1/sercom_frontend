import '../core/api_client.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import 'auth_service.dart';

class ChatService {
  final api = ApiClient().dio;
  final AuthService _authService = AuthService();

  Future<String> requireCurrentUserId() async {
    final userId = await _authService.getUserId();
    if (userId == null || userId.trim().isEmpty) {
      throw Exception('No se pudo identificar el usuario actual');
    }
    return userId.trim();
  }

  Future<ChatRoom> getRoomByService(String serviceId) async {
    final currentUserId = await requireCurrentUserId();
    final response = await api.get('/chat/service/$serviceId/room');
    final room = _extractMap(response.data, fallbackKey: 'room');

    if (room == null) {
      throw Exception('Formato inválido al cargar la sala');
    }

    return ChatRoom.fromJson(room, currentUserId: currentUserId);
  }

  Future<List<ChatRoom>> getMyRooms() async {
    final currentUserId = await requireCurrentUserId();
    final response = await api.get('/chat/users/$currentUserId/rooms');
    final data = _extractList(response.data, fallbackKey: 'rooms');

    final rooms = data
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((room) => ChatRoom.fromJson(room, currentUserId: currentUserId))
        .where((room) => room.id.isNotEmpty)
        .toList();

    rooms.sort((a, b) {
      final aDate = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return rooms;
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    final response = await api.get('/chat/rooms/$roomId/messages');
    final data = _extractList(response.data, fallbackKey: 'messages');

    final messages = data
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();

    messages.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });

    return messages;
  }

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String content,
  }) async {
    final senderId = await requireCurrentUserId();

    final response = await api.post(
      '/chat/messages',
      data: {'roomId': roomId, 'senderId': senderId, 'content': content},
    );

    final message = _extractMap(response.data, fallbackKey: 'message');

    if (message == null) {
      throw Exception('Respuesta inválida del servidor');
    }

    return ChatMessage.fromJson(message);
  }

  Future<void> markAsRead(String roomId) async {
    final userId = await requireCurrentUserId();
    await api.patch('/chat/rooms/$roomId/read', data: {'userId': userId});
  }

  List<dynamic> _extractList(dynamic value, {required String fallbackKey}) {
    if (value is List) return value;
    if (value is Map) {
      final map = value.map((key, value) => MapEntry(key.toString(), value));
      final nested =
          map[fallbackKey] ?? map['data'] ?? map['items'] ?? map['result'];
      if (nested is List) return nested;
    }
    return const [];
  }

  Map<String, dynamic>? _extractMap(
    dynamic value, {
    required String fallbackKey,
  }) {
    final direct = _asMap(value);
    if (direct == null) return null;

    final nested = direct[fallbackKey] ?? direct['data'] ?? direct['result'];
    return _asMap(nested) ?? direct;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
