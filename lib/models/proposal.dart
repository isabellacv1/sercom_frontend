class Proposal {
  final String id;
  final String serviceId;
  final String technicianId;
  final num price;
  final String message;
  final String? estimatedDuration;
  final String status;
  final Profile? profile;

  Proposal({
    required this.id,
    required this.serviceId,
    required this.technicianId,
    required this.price,
    required this.message,
    this.estimatedDuration,
    required this.status,
    this.profile,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    try {
      return Proposal(
        id: json['id']?.toString() ?? '',
        serviceId: json['service_id']?.toString() ?? '',
        technicianId: json['technician_id']?.toString() ?? '',
        price: num.tryParse(json['price']?.toString() ?? '0') ?? 0,
        message: json['message']?.toString() ?? '',
        estimatedDuration: json['estimated_duration']?.toString(),
        status: json['status']?.toString() ?? 'pending',
        profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
      );
    } catch (e) {
      print('PARSING ERROR: $e');
      return Proposal(
        id: '',
        serviceId: '',
        technicianId: '',
        price: 0,
        message: 'Error local cargando propuesta',
        status: 'error',
      );
    }
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
    try {
      return Profile(
        fullName: json['full_name']?.toString() ?? 'Técnico',
        avatarUrl: json['profile_image_url']?.toString() ?? 'https://ui-avatars.com/api/?name=User',
        ratingAvg: double.tryParse(json['rating_avg']?.toString() ?? '0.0') ?? 0.0,
        ratingCount: int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0,
        city: json['city']?.toString() ?? 'Sin ubicación',
      );
    } catch (e) {
      print('PARSING ERROR: $e');
      return Profile(
        fullName: 'Técnico Desconocido',
        avatarUrl: 'https://ui-avatars.com/api/?name=User',
        ratingAvg: 0.0,
        ratingCount: 0,
        city: 'Sin ubicación',
      );
    }
  }
}
