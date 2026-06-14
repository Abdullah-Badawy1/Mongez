class Governorate {
  /// Stable machine code stored on the User in the backend
  /// (e.g. "cairo", "kafr_sheikh").
  final String code;

  /// English label — fallback for non-Arabic locales.
  final String nameEn;

  /// Arabic label — the primary display name in the app.
  final String nameAr;

  const Governorate({
    required this.code,
    required this.nameEn,
    required this.nameAr,
  });

  factory Governorate.fromJson(Map<String, dynamic> json) => Governorate(
        code: json['code'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
      );

  /// Pick the locale-appropriate display name.
  String displayName(bool isArabic) => isArabic ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Governorate && other.code == code);

  @override
  int get hashCode => code.hashCode;
}
