class Category {
  const Category({
    required this.categoryId,
    required this.nameAr,
    required this.nameEn,
    required this.sortOrder,
    required this.isActive,
  });

  final String categoryId;
  final String nameAr;
  final String nameEn;
  final int sortOrder;
  final bool isActive;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
