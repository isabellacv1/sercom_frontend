import '../core/display_formatters.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: readStringValue(json, ['id']) ?? '',
      name: readStringValue(json, ['name', 'title']) ?? '',
      icon: readStringValue(json, ['icon']),
    );
  }
}
