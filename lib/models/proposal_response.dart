import '../core/display_formatters.dart';

class ProposalResponse {
  final String id;
  final String serviceId;
  final String technicianId;
  final num price;
  final String message;
  final String status;
  final String availableDate;
  final String availableFrom;
  final String availableTo;
  final DateTime createdAt;
  final WorkerInfo? worker;

  ProposalResponse({
    required this.id,
    required this.serviceId,
    required this.technicianId,
    required this.price,
    required this.message,
    required this.status,
    required this.availableDate,
    required this.availableFrom,
    required this.availableTo,
    required this.createdAt,
    this.worker,
  });

  factory ProposalResponse.fromJson(Map<String, dynamic> json) {
    final workerJson = (json['worker'] ?? json['technician'])
        as Map<String, dynamic>?;

    return ProposalResponse(
      id: readStringValue(json, ['id']) ?? '',
      serviceId: readStringValue(json, ['serviceId', 'service_id']) ?? '',
      technicianId: readStringValue(
            json,
            ['technicianId', 'technician_id', 'workerId', 'worker_id'],
          ) ??
          '',
      price: num.tryParse(readValue(json, ['price'])?.toString() ?? '0') ?? 0,
      message: readStringValue(json, ['message', 'description']) ?? '',
      status: readStringValue(json, ['status']) ?? 'pending',
      availableDate: readStringValue(json, ['availableDate', 'available_date']) ?? '',
      availableFrom: readStringValue(json, ['availableFrom', 'available_from']) ?? '',
      availableTo: readStringValue(json, ['availableTo', 'available_to']) ?? '',
      createdAt: DateTime.tryParse(
            readStringValue(json, ['createdAt', 'created_at']) ?? '',
          ) ??
          DateTime.now(),
      worker: workerJson != null ? WorkerInfo.fromJson(workerJson) : null,
    );
  }
}

class WorkerInfo {
  final String id;
  final String name;
  final num rating;
  final int ratingCount;
  final String profileImageUrl;

  WorkerInfo({
    required this.id,
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.profileImageUrl,
  });

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: readStringValue(json, ['id']) ?? '',
      name: readStringValue(json, ['fullName', 'full_name', 'name']) ?? '',
      rating: readDoubleValue(json, ['rating', 'ratingAvg', 'rating_avg']) ?? 0,
      ratingCount: readIntValue(json, ['ratingCount', 'rating_count']) ?? 0,
      profileImageUrl: readStringValue(
            json,
            ['profileImageUrl', 'profile_image_url', 'avatarUrl', 'avatar_url'],
          ) ??
          '',
    );
  }
}
