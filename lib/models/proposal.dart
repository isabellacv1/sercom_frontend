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
    return Proposal(
      id: json['id']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      technicianId: json['worker']?['id']?.toString() ?? '',
      price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      message: json['description']?.toString() ?? '',
      estimatedDuration: json['estimatedTime']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      availableDate: json['availableDate']?.toString(),
      availableFrom: json['availableFrom']?.toString(),
      availableTo: json['availableTo']?.toString(),
      profile: json['worker'] != null
          ? Profile.fromJson(json['worker'])
          : null,
    );
  }

  String get formattedTimeRange {
    if (availableFrom != null && availableTo != null) {
      String from = _formatTime(availableFrom!);
      String to = _formatTime(availableTo!);
      return '$from - $to';
    }

    if (estimatedDuration != null && estimatedDuration!.isNotEmpty) {
      return estimatedDuration!;
    }

    return 'Tiempo no especificado';
  }

  String _formatTime(String time) {
    return time.length >= 5 ? time.substring(0, 5) : time;
  }
}

class Profile {
  final String fullName;
  final String avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final String city;

  Profile({
    required this.fullName,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.city,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      fullName: json['name']?.toString() ?? 'Técnico',
      avatarUrl: json['profileImageUrl']?.toString() ??
          'https://ui-avatars.com/api/?name=${json['name'] ?? 'User'}',
      ratingAvg:
          double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0,
      ratingCount:
          int.tryParse(json['ratingCount']?.toString() ?? '0') ?? 0,
      city: json['city'],
    );
  }
}