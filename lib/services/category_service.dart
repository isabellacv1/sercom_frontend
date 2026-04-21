import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/category_model.dart';
import '../models/service_option_model.dart';

class CategoryService {
  final Dio api = ApiClient().dio;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await api.get('/service-categories');

      print('CATEGORIES STATUS: ${response.statusCode}');
      print('CATEGORIES DATA: ${response.data}');

      final data = response.data;

      if (data is List) {
        return data
            .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Formato inválido en categorías');
    } on DioException catch (e) {
      print('ERROR CATEGORÍAS: ${e.response?.statusCode}');
      print('ERROR DATA: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      }

      throw Exception('Error al cargar categorías');
    } catch (e) {
      print('ERROR GENERAL CATEGORÍAS: $e');
      throw Exception('Error inesperado al cargar categorías');
    }
  }

  Future<List<ServiceOptionModel>> getServicesByCategory(
      String categoryId) async {
    try {
      final response =
          await api.get('/service-categories/$categoryId/services');

      print('SERVICES STATUS: ${response.statusCode}');
      print('SERVICES DATA: ${response.data}');

      final data = response.data;

      if (data is List) {
        return data
            .map((e) =>
                ServiceOptionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Formato inválido en servicios');
    } on DioException catch (e) {
      print('ERROR SERVICES: ${e.response?.statusCode}');
      print('ERROR DATA: ${e.response?.data}');

      if (e.response?.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      }

      throw Exception('Error al cargar servicios');
    } catch (e) {
      print('ERROR GENERAL SERVICES: $e');
      throw Exception('Error inesperado al cargar servicios');
    }
  }
}