import '../core/display_formatters.dart';

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
      id: readStringValue(json, ['id']) ?? '',
      categoryId: readStringValue(json, ['category_id', 'categoryId']) ?? '',
      title: readStringValue(json, ['title', 'name']) ?? '',
      description: readStringValue(json, ['description']) ?? '',
      specialistLevel: readStringValue(
        json,
        ['specialist_level', 'specialistLevel', 'recommended_specialist'],
      ),
    );
  }
}
