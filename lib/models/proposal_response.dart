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
    return ProposalResponse(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? '',
      technicianId: json['technicianId'] ?? '',
      price: json['price'] ?? 0,
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      availableDate: json['availableDate'] ?? '',
      availableFrom: json['availableFrom'] ?? '',
      availableTo: json['availableTo'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      worker: json['worker'] != null ? WorkerInfo.fromJson(json['worker']) : null,
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
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      rating: json['rating'] ?? 0,
      ratingCount: json['ratingCount'] ?? 0,
      profileImageUrl: json['profileImageUrl'] ?? '',
    );
  }
}
