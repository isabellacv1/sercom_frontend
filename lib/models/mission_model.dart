import '../core/display_formatters.dart';

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
    this.scheduledDate,
    this.scheduledFrom,
    this.scheduledTo,
    this.scheduledAt,
    this.latitude,
    this.longitude,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    final scheduledAtValue =
        json['scheduled_at']?.toString() ?? json['scheduledAt']?.toString();

    return MissionModel(
      id: readStringValue(json, ['id']) ?? '',
      description: readStringValue(json, ['description']) ?? '',
      address: readStringValue(json, ['address']) ?? '',
      status: readStringValue(json, ['status']) ?? 'pending',
      minBudget: readIntValue(json, ['min_budget', 'budget_min', 'minBudget']),
      maxBudget: readIntValue(json, ['max_budget', 'budget_max', 'maxBudget']),
      serviceTitle: readStringValue(json, ['service_title', 'serviceTitle', 'title']),
      categoryName: readStringValue(json, ['category_name', 'categoryName']),
      nearbyTechnicians: readIntValue(
            json,
            ['nearby_technicians', 'nearbyTechnicians'],
          ) ??
          0,
      offerCount: readIntValue(json, [
        'offer_count',
        'offerCount',
        'offers_count',
        'offersCount',
        'proposal_count',
        'proposalCount',
        'proposals_count',
        'proposalsCount',
      ]),
      statusLabel: readStringValue(json, ['status_label', 'statusLabel']),
      createdAtRelative: readStringValue(
        json,
        ['created_at_relative', 'createdAtRelative'],
      ),
      priceMin: readIntValue(json, ['price_min', 'priceMin', 'min_budget', 'budget_min']),
      priceMax: readIntValue(json, ['price_max', 'priceMax', 'max_budget', 'budget_max']),
      scheduledAt: scheduledAtValue,
      scheduledDate: readStringValue(
            json,
            [
              'scheduled_date',
              'scheduledDate',
              'service_date',
              'serviceDate',
              'requested_date',
              'requestedDate',
              'date',
            ],
          ) ??
          scheduledAtValue,
      scheduledFrom: readStringValue(
        json,
        ['scheduled_from', 'scheduledFrom', 'available_from', 'availableFrom'],
      ),
      scheduledTo: readStringValue(
        json,
        ['scheduled_to', 'scheduledTo', 'available_to', 'availableTo'],
      ),
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
    );
  }
}