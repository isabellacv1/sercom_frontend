class ChatbotResponse {

  final String reply;

  final bool readyToCreate;

  final Map<String, dynamic>?
      missionDraft;

  ChatbotResponse({
    required this.reply,
    required this.readyToCreate,
    this.missionDraft,
  });

  factory ChatbotResponse.fromJson(
    Map<String, dynamic> json,
  ) {

    return ChatbotResponse(
      reply: json['reply'] ?? '',

      readyToCreate:
          json['readyToCreate'] ?? false,

      missionDraft:
          json['missionDraft'],
    );
  }
}