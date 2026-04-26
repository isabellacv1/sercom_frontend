import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/proposal_request.dart';
import '../models/proposal_response.dart';

class ProposalRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ProposalResponse> submitProposal(ProposalRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/proposals',
        data: request.toJson(),
      );
      
      // Expected 201 Created from NestJS POST
      return ProposalResponse.fromJson(response.data);
      
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 409) {
          throw Exception('Ya te has postulado a esta misión. ¡Espera la respuesta del cliente!');
        } else if (e.response!.statusCode == 400) {
          final data = e.response!.data;
          final msg = data is Map ? data['message'] : 'Datos inválidos.';
          if (msg is List) {
             throw Exception(msg.join(', '));
          }
          throw Exception(msg.toString());
        } else {
          throw Exception('Error del servidor: ${e.response!.statusCode}');
        }
      }
      throw Exception('Error de conexión.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}
