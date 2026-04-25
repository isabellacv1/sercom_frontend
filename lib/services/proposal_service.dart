import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/proposal_request.dart';
import '../models/proposal.dart';

class ProposalService {
  final ApiClient _apiClient = ApiClient();

  Future<void> submitProposal(ProposalRequest request) async {
    try {
      await _apiClient.dio.post(
        '/proposals',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 409) {
          throw Exception('Ya ofertaste para este servicio.');
        } else if (e.response!.statusCode == 400) {
          final data = e.response!.data;
          final msg = data is Map
              ? data['message']
              : 'Datos inválidos o servicio cerrado.';
          throw Exception(msg);
        } else {
          throw Exception('Error del servidor: ${e.response!.statusCode}');
        }
      }
      throw Exception('Error de conexión.');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
  Future<void> acceptProposal(String proposalId) async {
  try {
    await _apiClient.dio.post('/proposals/$proposalId/accept');
  } catch (e) {
    throw Exception('Error al aceptar la propuesta');
  }
}
  Future<List<Proposal>> getProposalsByService(String serviceId) async {
    try {
      final response = await _apiClient.dio.get(
        '/proposals/service/$serviceId',
      );

      final List data = response.data['proposals'] ?? [];

      return data.map((item) {
        return Proposal.fromJson(item);
      }).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Error cargando propuestas: ${e.response!.statusCode}');
      }

      throw Exception('Error de conexión cargando propuestas.');
    } catch (e) {
      throw Exception('Error inesperado cargando propuestas: $e');
    }
  }
}