import '../core/api_client.dart';
import '../models/mission_status.dart';
import '../models/mission_model.dart';

class MissionService {
  final api = ApiClient().dio;

  Future<MissionModel> createMission({
    required String categoryId,
    required String serviceOptionId,
    required String title,
    required String description,
    required String address,
    int? minBudget,
    int? maxBudget,
    double? latitude,
    double? longitude,
  }) async {
    final response = await api.post(
      '/services',
      data: {
        'category_id': categoryId,
        'service_option_id': serviceOptionId,
        'title': title,
        'description': description,
        'address': address,
        'budget_min': minBudget,
        'budget_max': maxBudget,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      if (data['service'] is Map<String, dynamic>) {
        return MissionModel.fromJson(data['service']);
      }

      return MissionModel.fromJson(data);
    }

    throw Exception('Respuesta inválida al crear la misión');
  }

  Future<List<MissionModel>> getMyMissions() async {
    final response = await api.get('/services/me');

    final data = response.data;

    if (data is List) {
      return data
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['services'] is List) {
      return (data['services'] as List)
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Respuesta inválida al consultar misiones');
  }

  Future<List<MissionModel>> getMissionsByStatus(String status) async {
    final normalizedStatus = MissionStatus.normalize(status);

    final response = await api.get(
      '/missions',
      queryParameters: {
        'status': normalizedStatus,
      },
    );

    final data = response.data;

    if (data is List) {
      return data
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['missions'] is List) {
      return (data['missions'] as List)
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['services'] is List) {
      return (data['services'] as List)
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Respuesta inválida al consultar misiones por estado');
  }

  Future<List<MissionModel>> getNearbyOpportunities({
    required double latitude,
    required double longitude,
    double radiusKm = 15,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await api.get(
      '/services/opportunities',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
        'page': page,
        'limit': limit,
      },
    );

    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return [];
    }

    final items = raw['data'];
    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(MissionModel.fromJson)
        .toList();
  }

  Future<MissionModel> getMissionById(String missionId) async {
    final response = await api.get('/services/me/$missionId');

    final data = response.data;

    if (data is Map<String, dynamic>) {
      if (data['service'] is Map<String, dynamic>) {
        return MissionModel.fromJson(data['service']);
      }

      return MissionModel.fromJson(data);
    }

    throw Exception('Respuesta inválida al consultar la misión');
  }

 Future<MissionModel> updateMissionStatus({
  required String missionId,
  required String status,
}) async {
  final normalizedStatus = MissionStatus.normalize(status);

  final response = await api.patch(
    '/services/$missionId/status',
    data: {
      'status': normalizedStatus,
    },
  );

  final data = response.data;

  if (data is Map<String, dynamic>) {
    if (data['service'] is Map<String, dynamic>) {
      return MissionModel.fromJson(data['service']);
    }

    return MissionModel.fromJson(data);
  }

  throw Exception('Respuesta inválida al actualizar el estado');
}
}