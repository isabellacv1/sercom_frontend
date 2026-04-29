import '../core/api_client.dart';

class ConfirmationService {
  final api = ApiClient().dio;

  /// PATCH /services/:id/confirm
  /// Retorna el servicio actualizado incluyendo status, worker_confirmation, client_confirmation.
  Future<Map<String, dynamic>> confirmCompletion(String serviceId) async {
    final response = await api.patch('/services/$serviceId/confirm');
    return response.data as Map<String, dynamic>;
  }
}
