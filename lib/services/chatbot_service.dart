import 'package:dio/dio.dart';
import '../models/chatbot_response.dart';
class ChatbotService {

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000',
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<ChatbotResponse> sendMessage(
  List<Map<String, dynamic>> messages,
  ) async {

    try {

      final response = await _dio.post(
        '/chatbot/message',

        data: {
          'messages': messages,
        },
      );

      return ChatbotResponse.fromJson(
        response.data,
      );

    } on DioException catch (e) {

      print(
        'CHATBOT ERROR: ${e.response?.data}',
      );

      return ChatbotResponse(
        reply:
            'Ocurrió un error comunicándose con el asistente.',

        readyToCreate: false,
      );
    }
  }
}