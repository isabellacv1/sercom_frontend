import 'proposal.dart';

class Technician {
  final String id;
  final String name;
  final String title;
  final double rating;
  final int reviewsCount;
  final int? totalMissions;
  final double? yearsExperience;
  final String distance;
  final double proposedPrice;
  final String profileImageUrl;
  final bool isRecommended;
  final List<String> tags;
  final String about;
  final List<String> portfolioUrls;
  final String? availableDate;
  final String? availableFrom;
  final String? availableTo;

  Technician({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviewsCount,
    required this.totalMissions,
    required this.yearsExperience,
    required this.distance,
    required this.proposedPrice,
    required this.profileImageUrl,
    this.isRecommended = false,
    required this.tags,
    required this.about,
    required this.portfolioUrls,
    this.availableDate,
    this.availableFrom,
    this.availableTo,
  });

  factory Technician.fromProposal(Proposal p) {
    final profile = p.profile;
    final name = profile?.fullName.trim().isNotEmpty == true
        ? profile!.fullName.trim()
        : 'Técnico';
    final tags = <String>{
      if (profile?.specialistLevel?.trim().isNotEmpty == true)
        profile!.specialistLevel!.trim(),
      ...?profile?.skills,
    }.toList();

    return Technician(
      id: p.technicianId,
      name: name,
      title: profile?.specialty?.trim().isNotEmpty == true
          ? profile!.specialty!.trim()
          : 'Profesional de Sercom',
      rating: profile?.ratingAvg ?? 0.0,
      reviewsCount: profile?.ratingCount ?? 0,
      totalMissions: profile?.completedMissions,
      yearsExperience: profile?.yearsExperience,
      distance: profile?.city.trim().isNotEmpty == true
          ? profile!.city.trim()
          : 'Ubicación no disponible',
      proposedPrice: p.price.toDouble(),
      profileImageUrl: profile?.avatarUrl ??
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=2563EB&color=fff',
      tags: tags,
      about: p.message.trim().isNotEmpty
          ? p.message.trim()
          : 'Sin descripción de la propuesta',
      portfolioUrls: profile?.portfolioUrls ?? const [],
      availableDate: p.availableDate,
      availableFrom: p.availableFrom,
      availableTo: p.availableTo,
    );
  }
}
