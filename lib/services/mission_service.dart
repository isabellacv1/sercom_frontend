import '../core/api_client.dart';
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

    return MissionModel.fromJson(data['service']);
  }

  Future<List<MissionModel>> getMyMissions() async {
    final response = await api.get('/services/me');

    final data = response.data as List;
    return data.map((e) => MissionModel.fromJson(e)).toList();
  }

  Future<MissionModel> getMissionById(String missionId) async {
    final response = await api.get('/services/me/$missionId');

    return MissionModel.fromJson(response.data);
  }
}