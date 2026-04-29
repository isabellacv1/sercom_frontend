import '../models/mission_status.dart';

class MissionModel {
  final String id;
  final String description;
  final String address;
  final String status;
  final int? minBudget;
  final int? maxBudget;
  final String? serviceTitle;
  final String? categoryName;
  final int nearbyTechnicians;
  final int? offerCount;
  final String? statusLabel;
  final String? createdAtRelative;
  final int? priceMin;
  final int? priceMax;
  final double? latitude;
  final double? longitude;
  final String? scheduledDate;
  final String? scheduledFrom;
  final String? scheduledTo;
  final String? scheduledAt;

  MissionModel({
    required this.id,
    required this.description,
    required this.address,
    required this.status,
    this.minBudget,
    this.maxBudget,
    this.serviceTitle,
    this.categoryName,
    this.nearbyTechnicians = 0,
    this.offerCount,
    this.statusLabel,
    this.createdAtRelative,
    this.priceMin,
    this.priceMax,
    this.latitude,
    this.longitude,
    this.scheduledDate,
    this.scheduledFrom,
    this.scheduledTo,
    this.scheduledAt,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final normalizedStatus = MissionStatus.normalize(json['status']?.toString());
    final category = json['category'];
    final serviceOption = json['service_option'] ?? json['serviceOption'];

    final categoryName = json['category_name']?.toString() ??
        (category is Map ? category['name']?.toString() : null);

    final serviceTitle = (serviceOption is Map
            ? serviceOption['title']?.toString()
            : null) ??
        json['service_title']?.toString() ??
        json['title']?.toString();

    return MissionModel(
      id: json['id']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: normalizedStatus,

      minBudget: json['min_budget'] ?? json['budget_min'],
      maxBudget: json['max_budget'] ?? json['budget_max'],

      serviceTitle: serviceTitle,
      categoryName: categoryName,

      nearbyTechnicians: json['nearby_technicians'] ?? 0,
      offerCount: json['offer_count'],

      // Importante: el label sale del status real
      statusLabel: MissionStatus.label(normalizedStatus),

      createdAtRelative: json['created_at_relative']?.toString(),

      priceMin: json['price_min'] ?? json['budget_min'],
      priceMax: json['price_max'] ?? json['budget_max'],

      latitude: json['latitude'] == null
          ? null
          : double.tryParse(json['latitude'].toString()),

      longitude: json['longitude'] == null
          ? null
          : double.tryParse(json['longitude'].toString()),

      scheduledDate: json['scheduled_date']?.toString(),
      scheduledFrom: json['scheduled_from']?.toString(),
      scheduledTo: json['scheduled_to']?.toString(),
      scheduledAt: json['scheduled_at']?.toString(),
    );
  }

  MissionModel copyWith({
    String? id,
    String? description,
    String? address,
    String? status,
    int? minBudget,
    int? maxBudget,
    String? serviceTitle,
    String? categoryName,
    int? nearbyTechnicians,
    int? offerCount,
    String? statusLabel,
    String? createdAtRelative,
    int? priceMin,
    int? priceMax,
    double? latitude,
    double? longitude,
    String? scheduledDate,
    String? scheduledFrom,
    String? scheduledTo,
    String? scheduledAt,
  }) {
    final normalizedStatus = MissionStatus.normalize(status ?? this.status);

    return MissionModel(
      id: id ?? this.id,
      description: description ?? this.description,
      address: address ?? this.address,
      status: normalizedStatus,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      categoryName: categoryName ?? this.categoryName,
      nearbyTechnicians: nearbyTechnicians ?? this.nearbyTechnicians,
      offerCount: offerCount ?? this.offerCount,
      statusLabel: statusLabel ?? MissionStatus.label(normalizedStatus),
      createdAtRelative: createdAtRelative ?? this.createdAtRelative,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledFrom: scheduledFrom ?? this.scheduledFrom,
      scheduledTo: scheduledTo ?? this.scheduledTo,
      scheduledAt: scheduledAt ?? this.scheduledAt,
    );
  }
}