class ServiceOptionModel {
  final String id;
  final String categoryId;
  final String title;
  final String description;
  final String? specialistLevel;

  ServiceOptionModel({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.description,
    this.specialistLevel,
  });

  factory ServiceOptionModel.fromJson(Map<String, dynamic> json) {
    return ServiceOptionModel(
      id: json['id'].toString(),
      categoryId: json['category_id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      specialistLevel: json['specialist_level'],
    );
  }
}