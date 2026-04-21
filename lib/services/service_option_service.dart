import '../core/api_client.dart';
import '../models/service_option_model.dart';

class ServiceOptionService {
  final api = ApiClient().dio;

  Future<List<ServiceOptionModel>> getByCategory(String categoryId) async {
    final response = await api.get('/service-options/category/$categoryId');

    final List data = response.data;
    return data.map((e) => ServiceOptionModel.fromJson(e)).toList();
  }
}