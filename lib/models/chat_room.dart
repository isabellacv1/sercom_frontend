import 'chat_message.dart';

class ChatRoom {
  final String id;
  final String serviceId;
  final String title;
  final String participantName;
  final String participantSubtitle;
  final String participantAvatarUrl;
  final String lastMessagePreview;
  final DateTime? updatedAt;
  final int unreadCount;

  ChatRoom({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.participantName,
    required this.participantSubtitle,
    required this.participantAvatarUrl,
    required this.lastMessagePreview,
    this.updatedAt,
    this.unreadCount = 0,
  });

  factory ChatRoom.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final service =
        _asMap(json['service']) ??
        _asMap(json['mission']) ??
        _asMap(json['request']);

    final lastMessageMap =
    _asMap(json['lastMessage']) ??
    _asMap(json['latestMessage']) ??
    _lastMessageFromList(json['chat_messages']) ??
    _lastMessageFromList(json['messages']);
    
    final lastMessage = lastMessageMap != null
        ? ChatMessage.fromJson(lastMessageMap)
        : null;

    final participant = _resolveParticipant(json, currentUserId);

    return ChatRoom(
      id:
          _firstString([
            json['id'],
            json['_id'],
            json['roomId'],
            json['room_id'],
          ]) ??
          '',
      serviceId:
          _firstString([
            json['serviceId'],
            json['service_id'],
            service?['id'],
            service?['serviceId'],
          ]) ??
          '',
      title:
          _firstString([
            service?['service_title'],
            service?['serviceTitle'],
            service?['title'],
            service?['name'],
            json['serviceTitle'],
            json['service_title'],
            json['title'],
          ]) ??
          'Servicio técnico',
      participantName:
          _firstString([
            participant?['fullName'],
            participant?['full_name'],
            participant?['name'],
            participant?['email'],
          ]) ??
          'Contacto',
      participantSubtitle:
          _firstString([
            participant?['specialty'],
            participant?['role'],
            participant?['activeRole'],
            participant?['active_role'],
            service?['category_name'],
            service?['categoryName'],
          ]) ??
          'Chat de servicio',
      participantAvatarUrl:
          _firstString([
            participant?['profileImageUrl'],
            participant?['avatarUrl'],
            participant?['avatar'],
            participant?['photoUrl'],
          ]) ??
          '',
      lastMessagePreview:
          _firstString([
            lastMessage?.content,
            json['lastMessagePreview'],
            json['preview'],
          ]) ??
          'Sin mensajes todavía',
      updatedAt: _parseDate(
        _firstString([
          lastMessageMap?['createdAt'],
          lastMessageMap?['created_at'],
          json['updatedAt'],
          json['updated_at'],
          json['createdAt'],
          json['created_at'],
        ]),
      ),
      unreadCount: _parseInt(
        json['unreadCount'] ??
            json['unread_count'] ??
            json['unreadMessagesCount'] ??
            json['unread_messages_count'],
      ),
    );
  }

  static Map<String, dynamic>? _resolveParticipant(
    Map<String, dynamic> json,
    String? currentUserId,
  ) {
    final candidates = <Map<String, dynamic>>[
      ..._mapList(json['participants']),
      ..._mapList(json['users']),
      if (_asMap(json['worker']) != null) _asMap(json['worker'])!,
      if (_asMap(json['technician']) != null) _asMap(json['technician'])!,
      if (_asMap(json['client']) != null) _asMap(json['client'])!,
      if (_asMap(json['customer']) != null) _asMap(json['customer'])!,
      if (_asMap(json['user']) != null) _asMap(json['user'])!,
    ];

    if (candidates.isEmpty) return null;

    if (currentUserId == null || currentUserId.isEmpty) {
      return candidates.first;
    }

    for (final candidate in candidates) {
      final id = _firstString([
        candidate['id'],
        candidate['userId'],
        candidate['user_id'],
        candidate['_id'],
      ]);
      if (id != null && id != currentUserId) {
        return candidate;
      }
    }

    return candidates.first;
  }

  static Map<String, dynamic>? _lastMessageFromList(dynamic value) {
    if (value is! List || value.isEmpty) return null;
    return _asMap(value.last);
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
