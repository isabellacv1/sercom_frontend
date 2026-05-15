import 'package:dio/dio.dart';
import '../core/api_client.dart';

class CertificationInfo {
  final String id;
  final String name;
  final String category;
  final String? difficulty;

  CertificationInfo({
    required this.id,
    required this.name,
    required this.category,
    this.difficulty,
  });

  factory CertificationInfo.fromJson(Map<String, dynamic> json) =>
      CertificationInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        difficulty: json['difficulty'] as String?,
      );
}

class CompletedCertItem {
  final String enrollmentId;
  final String completedAt;
  final CertificationInfo certification;

  CompletedCertItem({
    required this.enrollmentId,
    required this.completedAt,
    required this.certification,
  });

  factory CompletedCertItem.fromJson(Map<String, dynamic> json) =>
      CompletedCertItem(
        enrollmentId: json['enrollment_id'] as String,
        completedAt: json['completed_at'] as String,
        certification: CertificationInfo.fromJson(
          json['certification'] as Map<String, dynamic>,
        ),
      );
}

class WorkerCompletedCertsResponse {
  final Map<String, dynamic> worker;
  final List<CompletedCertItem> certifications;
  final int totalCompleted;
  final bool hasCertifications;

  WorkerCompletedCertsResponse({
    required this.worker,
    required this.certifications,
    required this.totalCompleted,
    required this.hasCertifications,
  });

  factory WorkerCompletedCertsResponse.fromJson(Map<String, dynamic> json) =>
      WorkerCompletedCertsResponse(
        worker: json['worker'] as Map<String, dynamic>,
        certifications: (json['certifications'] as List)
            .map((e) => CompletedCertItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalCompleted: json['total_completed'] as int,
        hasCertifications: json['has_certifications'] as bool,
      );
}

// ── Modelos de progreso ────────────────────────────────────────────────────

class ModuleWithProgress {
  final String id;
  final String title;
  final String? description;
  final int orderIndex;
  final bool isCompleted;
  final String? completedAt;

  ModuleWithProgress({
    required this.id,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.isCompleted,
    this.completedAt,
  });

  factory ModuleWithProgress.fromJson(Map<String, dynamic> json) =>
      ModuleWithProgress(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        orderIndex: json['order_index'] as int,
        isCompleted: json['is_completed'] as bool,
        completedAt: json['completed_at'] as String?,
      );
}

class EnrollmentInfo {
  final String id;
  final String status;
  final int completedModules;
  final int totalModules;
  final String? completedAt;
  final String enrolledAt;

  EnrollmentInfo({
    required this.id,
    required this.status,
    required this.completedModules,
    required this.totalModules,
    this.completedAt,
    required this.enrolledAt,
  });

  factory EnrollmentInfo.fromJson(Map<String, dynamic> json) => EnrollmentInfo(
        id: json['id'] as String,
        status: json['status'] as String,
        completedModules: json['completed_modules'] as int,
        totalModules: json['total_modules'] as int,
        completedAt: json['completed_at'] as String?,
        enrolledAt: json['enrolled_at'] as String,
      );
}

/// Respuesta de GET /certifications/:id/me/progress
class CertProgressResponse {
  final EnrollmentInfo enrollment;
  final CertificationInfo certification;
  final int progressPercent;
  final List<ModuleWithProgress> modules;

  CertProgressResponse({
    required this.enrollment,
    required this.certification,
    required this.progressPercent,
    required this.modules,
  });

  factory CertProgressResponse.fromJson(Map<String, dynamic> json) =>
      CertProgressResponse(
        enrollment: EnrollmentInfo.fromJson(
          json['enrollment'] as Map<String, dynamic>,
        ),
        certification: CertificationInfo.fromJson(
          json['certification'] as Map<String, dynamic>,
        ),
        progressPercent: json['progress_percent'] as int,
        modules: (json['modules'] as List)
            .map((e) =>
                ModuleWithProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── Service ──────────────────────────────────────────────────────────────

class CertificationService {
  final Dio _api = ApiClient().dio;

  /// HU Cliente: certificaciones completadas de un trabajador (público)
  Future<WorkerCompletedCertsResponse> getWorkerCompletedCertifications(
    String workerId,
  ) async {
    try {
      final response = await _api.get(
        '/certifications/workers/$workerId/completed',
      );
      return WorkerCompletedCertsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception(_readError(e, 'No se pudieron cargar las certificaciones'));
    }
  }

  /// HU Trabajador: progreso en una certificación específica
  Future<CertProgressResponse> getMyProgress(String certificationId) async {
    try {
      final response = await _api.get(
        '/certifications/$certificationId/me/progress',
      );
      return CertProgressResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo cargar el progreso'));
    }
  }

  /// HU Trabajador: marcar un módulo como completado
  Future<CertProgressResponse> completeModule(
    String certificationId,
    String moduleId,
  ) async {
    try {
      final response = await _api.post(
        '/certifications/$certificationId/me/modules/complete',
        data: {'module_id': moduleId},
      );
      return CertProgressResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception(_readError(e, 'No se pudo completar el módulo'));
    }
  }

  String _readError(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message is List && message.isNotEmpty) return message.join(', ');
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }
    final text = error.toString().replaceAll('Exception: ', '').trim();
    return text.isNotEmpty ? text : frallback;
  }
}
