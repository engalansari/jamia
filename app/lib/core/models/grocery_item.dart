class GroceryItem {
  const GroceryItem({
    required this.itemId,
    required this.nameAr,
    required this.nameEn,
    required this.categoryId,
    required this.defaultUnit,
    required this.isFavorite,
    required this.isActive,
    this.defaultImageUrl,
  });

  final String itemId;
  final String nameAr;
  final String nameEn;
  final String categoryId;
  final String defaultUnit;
  final bool isFavorite;
  final bool isActive;
  final String? defaultImageUrl;

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    return GroceryItem(
      itemId: json['itemId'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      defaultUnit: json['defaultUnit'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      defaultImageUrl: json['defaultImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'categoryId': categoryId,
      'defaultUnit': defaultUnit,
      'isFavorite': isFavorite,
      'isActive': isActive,
      'defaultImageUrl': defaultImageUrl,
    };
  }
}
