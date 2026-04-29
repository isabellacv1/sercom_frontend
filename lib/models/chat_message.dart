class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime? createdAt;
  final bool isRead;
  final String? attachmentUrl;
  final String messageType;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.createdAt,
    this.isRead = false,
    this.attachmentUrl,
    this.messageType = 'text',
  });

  bool isMine(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender =
        _asMap(json['sender']) ??
        _asMap(json['user']) ??
        _asMap(json['author']) ??
        _asMap(json['profile']);

    return ChatMessage(
      id: _firstString([json['id'], json['_id'], json['messageId']]) ?? '',
      roomId: _firstString([
            json['roomId'],
            json['room_id'],
            json['chatRoomId'],
            json['chat_room_id'],
            _asMap(json['room'])?['id'],
          ]) ??
          '',
      senderId: _firstString([
            json['senderId'],
            json['sender_id'],
            json['userId'],
            json['user_id'],
            json['authorId'],
            sender?['id'],
            sender?['userId'],
          ]) ??
          '',
      senderName: _firstString([
            sender?['fullName'],
            sender?['full_name'],
            sender?['name'],
            sender?['email'],
          ]) ??
          'Usuario',
      content: _firstString([
            json['content'],
            json['message'],
            json['text'],
            json['body'],
          ]) ??
          '',
      createdAt: _parseDate(_firstString([
        json['createdAt'],
        json['created_at'],
        json['sentAt'],
        json['timestamp'],
      ])),
      isRead: json['is_read'] == true ||
          json['isRead'] == true ||
          json['read'] == true ||
          json['readAt'] != null ||
          json['read_at'] != null,
      attachmentUrl: _firstString([
        json['attachmentUrl'],
        json['attachment_url'],
      ]),
      messageType: _firstString([
            json['messageType'],
            json['message_type'],
          ]) ??
          'text',
    );
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

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
