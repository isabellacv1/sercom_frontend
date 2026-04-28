import '../core/display_formatters.dart';

class Proposal {
  final String id;
  final String serviceId;
  final String technicianId;
  final num price;
  final String message;
  final String? estimatedDuration;
  final String status;

  final String? availableDate;
  final String? availableFrom;
  final String? availableTo;

  final Profile? profile;

  Proposal({
    required this.id,
    required this.serviceId,
    required this.technicianId,
    required this.price,
    required this.message,
    this.estimatedDuration,
    required this.status,
    this.availableDate,
    this.availableFrom,
    this.availableTo,
    this.profile,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    final worker = (json['worker'] ?? json['technician'])
        as Map<String, dynamic>?;

    return Proposal(
      id: readStringValue(json, ['id']) ?? '',
      serviceId: readStringValue(json, ['serviceId', 'service_id']) ?? '',
      technicianId: worker != null
          ? readStringValue(worker, ['id']) ?? ''
          : readStringValue(
                json,
                ['technicianId', 'technician_id', 'workerId', 'worker_id'],
              ) ??
              '',
      price: num.tryParse(readValue(json, ['price'])?.toString() ?? '0') ?? 0,
      message: readStringValue(json, ['description', 'message']) ?? '',
      estimatedDuration: readStringValue(
        json,
        ['estimatedTime', 'estimated_time', 'estimatedDuration', 'estimated_duration'],
      ),
      status: readStringValue(json, ['status']) ?? 'pending',
      availableDate: readStringValue(json, ['availableDate', 'available_date']),
      availableFrom: readStringValue(json, ['availableFrom', 'available_from']),
      availableTo: readStringValue(json, ['availableTo', 'available_to']),
      profile: worker != null ? Profile.fromJson(worker) : null,
    );
  }

  String get formattedTimeRange {
    final availability = formatAvailabilityLabel(
      from: availableFrom,
      to: availableTo,
      fallback: '',
    );

    if (availability.isNotEmpty) return availability;

    if (estimatedDuration != null && estimatedDuration!.isNotEmpty) {
      return estimatedDuration!;
    }

    return 'Tiempo no especificado';
  }
}

class Profile {
  final String fullName;
  final String avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final String city;
  final String? specialty;
  final String? specialistLevel;
  final int? completedMissions;
  final double? yearsExperience;
  final List<String> skills;
  final List<String> portfolioUrls;

  Profile({
    required this.fullName,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.city,
    this.specialty,
    this.specialistLevel,
    this.completedMissions,
    this.yearsExperience,
    this.skills = const [],
    this.portfolioUrls = const [],
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final name = readStringValue(json, ['fullName', 'full_name', 'name']) ??
        'Técnico';

    return Profile(
      fullName: name,

      avatarUrl: readStringValue(
            json,
            ['profileImageUrl', 'profile_image_url', 'avatarUrl', 'avatar_url'],
          ) ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=2563EB&color=fff',

      ratingAvg:
          readDoubleValue(json, ['rating', 'ratingAvg', 'rating_avg']) ?? 0,

      ratingCount:
          readIntValue(json, ['ratingCount', 'rating_count', 'reviewsCount']) ??
              0,

      city: readStringValue(json, ['city', 'location']) ?? '',
      specialty: readStringValue(json, ['specialty', 'speciality', 'title']),
      specialistLevel: readStringValue(
        json,
        ['specialistLevel', 'specialist_level', 'categoryLevel', 'category_level'],
      ),
      completedMissions: readIntValue(
        json,
        ['completedMissions', 'completed_missions', 'totalMissions', 'total_missions'],
      ),
      yearsExperience: readDoubleValue(
        json,
        ['yearsExperience', 'years_experience', 'experienceYears', 'experience_years'],
      ),
      skills: readStringListValue(json, ['skills', 'tags']),
      portfolioUrls: readStringListValue(
        json,
        ['portfolioUrls', 'portfolio_urls', 'portfolio'],
      ),
    );
  }
}
