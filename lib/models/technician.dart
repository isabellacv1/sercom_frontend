import 'proposal.dart';

class Technician {
  final String id;
  final String name;
  final String title;
  final double rating;
  final int reviewsCount;
  final int totalMissions;
  final double yearsExperience;
  final String distance;
  final double proposedPrice;
  final String profileImageUrl;
  final bool isRecommended;
  final List<String> tags;
  final String about;
  final List<String> portfolioUrls;

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
  });

  factory Technician.fromProposal(Proposal p) {
    return Technician(
      id: p.technicianId,
      name: p.profile?.fullName ?? 'Técnico',
      title: 'Técnico de la plataforma',
      rating: p.profile?.ratingAvg ?? 0.0,
      reviewsCount: p.profile?.ratingCount ?? 0,
      totalMissions: p.profile?.ratingCount ?? 0, 
      yearsExperience: 2.0, // Mock
      distance: p.profile?.city ?? 'Sin ubicación',
      proposedPrice: p.price.toDouble(),
      profileImageUrl: p.profile?.avatarUrl ?? 'https://ui-avatars.com/api/?name=User',
      tags: ['Categoría I'],
      about: p.message,
      portfolioUrls: [],
    );
  }
}


final mockTechnicians = [
  Technician(
    id: '1',
    name: 'Carlos M.',
    title: 'Electricista Certificado',
    rating: 4.9,
    reviewsCount: 128,
    totalMissions: 128,
    yearsExperience: 4.5,
    distance: 'A 2.5 km de distancia',
    proposedPrice: 45.0,
    profileImageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300',
    isRecommended: true,
    tags: ['Cat.II', 'Maestro de Redes', 'Racha de 10'],
    about: 'Soy técnico electricista certificado con amplia experiencia en instalaciones residenciales y comerciales. Me especializo en modernización de tableros y sistemas inteligentes...',
    portfolioUrls: [
      'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=500',
      'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=500',
      'https://images.unsplash.com/photo-1581092335397-9583eb92d232?w=500',
    ],
  ),
  Technician(
    id: '2',
    name: 'Roberto G.',
    title: 'Técnico Electricista',
    rating: 4.7,
    reviewsCount: 84,
    totalMissions: 84,
    yearsExperience: 3.0,
    distance: 'A 1.2 km de distancia',
    proposedPrice: 40.0,
    profileImageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300',
    tags: ['Cat.I'],
    about: 'Atención rápida a emergencias.',
    portfolioUrls: [],
  ),
  Technician(
    id: '3',
    name: 'Ana P.',
    title: 'Especialista en iluminación',
    rating: 5.0,
    reviewsCount: 215,
    totalMissions: 215,
    yearsExperience: 6.0,
    distance: 'A 4.0 km de distancia',
    proposedPrice: 50.0,
    profileImageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300',
    tags: ['Cat.III'],
    about: 'Iluminación residencial top.',
    portfolioUrls: [],
  ),
];
