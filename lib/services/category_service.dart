import '../core/api_client.dart';

class CategoryService {
  final api = ApiClient().dio;

  Future<dynamic> getCategories() async {
    final response = await api.get('/service-categories');
    return response.data;
  }
}