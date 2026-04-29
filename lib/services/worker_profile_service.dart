import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../core/api_client.dart';

class WorkerProfileService {
  final Dio api = ApiClient().dio;

  Future<Map<String, dynamic>> getMyWorkerProfile() async {
    try {
      final response = await api.get('/worker-profile/me');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception('Formato inválido en perfil de trabajador');
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo cargar el perfil de trabajador'));
    }
  }

  Future<Map<String, dynamic>> updateBio(String bio) async {
    try {
      final response = await api.patch(
        '/worker-profile/me/bio',
        data: {
          'bio': bio,
        },
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo actualizar la biografía'));
    }
  }

  Future<List<dynamic>> setCoverageZones(List<String> zoneIds) async {
    try {
      final response = await api.patch(
        '/worker-profile/me/zones',
        data: {
          'zone_ids': zoneIds,
        },
      );
      final data = response.data;

      if (data is List) return data;
      return [];
    } catch (e) {
      throw Exception(_readError(e, 'No se pudieron guardar las zonas'));
    }
  }

  Future<List<dynamic>> setWorkerSkills(List<Map<String, dynamic>> skills) async {
    try {
      final response = await api.patch(
        '/worker-profile/me/skills',
        data: {
          'skills': skills,
        },
      );
      final data = response.data;

      if (data is List) return data;
      return [];
    } catch (e) {
      throw Exception(_readError(e, 'No se pudieron guardar las categorías'));
    }
  }

  Future<Map<String, dynamic>> uploadPortfolioFile({
    required PlatformFile file,
    String? title,
  }) async {
    try {
      final bytes = file.bytes;

      if (bytes == null) {
        throw Exception('No se pudo leer el archivo seleccionado');
      }

      final formData = FormData.fromMap({
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      final response = await api.post(
        '/worker-profile/me/portfolio/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo subir el archivo del portafolio'));
    }
  }

  Future<Map<String, dynamic>> addPortfolioItem({
    required String fileUrl,
    required String fileType,
    String? title,
  }) async {
    try {
      final response = await api.post(
        '/worker-profile/me/portfolio',
        data: {
          'file_url': fileUrl,
          'file_type': fileType,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        },
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo agregar el portafolio'));
    }
  }

  Future<void> removePortfolioItem(String itemId) async {
    try {
      await api.delete('/worker-profile/me/portfolio/$itemId');
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo eliminar el item del portafolio'));
    }
  }

  Future<Map<String, dynamic>> publishProfile() async {
    try {
      final response = await api.post('/worker-profile/me/publish');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo publicar el perfil'));
    }
  }

  Future<Map<String, dynamic>> unpublishProfile() async {
    try {
      final response = await api.post('/worker-profile/me/unpublish');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'data': data};
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo despublicar el perfil'));
    }
  }

  String _readError(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map) {
        final message = data['message'] ?? data['error'];

        if (message is List && message.isNotEmpty) {
          return message.join(', ');
        }

        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    final text = error.toString().replaceAll('Exception: ', '').trim();

    if (text.isNotEmpty) {
      return text;
    }

    return fallback;
  }
}