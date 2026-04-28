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
  final int offerCount;
  final String? statusLabel;
  final String? createdAtRelative;
  final int? priceMin;
  final int? priceMax;

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
    this.offerCount = 0,
    this.statusLabel,
    this.createdAtRelative,
    this.priceMin,
    this.priceMax,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'],
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      status: json['status'] ?? 'pending',
      minBudget: json['min_budget'],
      maxBudget: json['max_budget'],
      serviceTitle: json['service_title'],
      categoryName: json['category_name'],
      nearbyTechnicians: json['nearby_technicians'] ?? 0,
      offerCount: json['offer_count'] ?? 0,
      statusLabel: json['status_label'],
      createdAtRelative: json['created_at_relative'],
      priceMin: json['price_min'],
      priceMax: json['price_max'],
    );
  }
}