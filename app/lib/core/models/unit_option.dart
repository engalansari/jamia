class UnitOption {
  const UnitOption({
    required this.unitId,
    required this.nameAr,
    required this.nameEn,
    required this.sortOrder,
    required this.isActive,
  });

  final String unitId;
  final String nameAr;
  final String nameEn;
  final int sortOrder;
  final bool isActive;

  factory UnitOption.fromJson(Map<String, dynamic> json) {
    return UnitOption(
      unitId: json['unitId'] as String? ?? '',
      nameAr: json['nameAr'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
