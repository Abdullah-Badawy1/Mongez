import 'package:equatable/equatable.dart';
import 'package:mongez/core/constants/api_constants.dart';

/// Promote `/media/...` paths to absolute URLs so Image.network can
/// fetch them even when the backend serializer was instantiated without
/// `request` context (older endpoints) and returned a relative path.
String? _absoluteMediaUrl(String? raw) {
  if (raw == null || raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final base = ApiConstants.baseUrl;
  final hostEnd = base.endsWith('/api/') ? base.length - 'api/'.length : base.length;
  final host = base.substring(0, hostEnd).replaceAll(RegExp(r'/+$'), '');
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '$host$path';
}

class WorkerModel extends Equatable {
  final int id;
  final int? userId;
  final String? username;
  final String? nameAr;
  final String? displayName;
  final String? phone;
  final String? address;
  final String? governorate;        // machine key (e.g. "cairo")
  final String? governorateLabel;   // human label (e.g. "Cairo")
  final String? city;
  final String? profileImage;
  final String? role;
  final int? categoryId;
  final String? categoryName;
  final String? categoryImage;
  final String? profession;
  final String? professionAr;
  final String description;
  final String? descriptionAr;
  final int experienceYears;
  final double? hourlyRate;
  final double? minimumCharge;
  final String currency;
  final List<String> specialties;
  final List<String> specialtiesAr;
  final List<String> languages;
  final int responseTimeMinutes;
  final double completionRate;
  final double acceptRate;
  final int workingHoursStart;
  final int workingHoursEnd;
  final bool worksFriday;
  final double? latitude;
  final double? longitude;
  final int serviceRadiusKm;
  final double averageRating;
  final int completedJobs;
  final bool isVerified;
  final bool isFeatured;
  final bool isAvailable;
  final double score;
  final String? createdAt;

  const WorkerModel({
    required this.id,
    this.userId,
    this.username,
    this.nameAr,
    this.displayName,
    this.phone,
    this.address,
    this.governorate,
    this.governorateLabel,
    this.city,
    this.profileImage,
    this.role,
    this.categoryId,
    this.categoryName,
    this.categoryImage,
    this.profession,
    this.professionAr,
    this.description = '',
    this.descriptionAr,
    this.experienceYears = 0,
    this.hourlyRate,
    this.minimumCharge,
    this.currency = 'EGP',
    this.specialties = const [],
    this.specialtiesAr = const [],
    this.languages = const ['ar'],
    this.responseTimeMinutes = 30,
    this.completionRate = 0.0,
    this.acceptRate = 0.0,
    this.workingHoursStart = 8,
    this.workingHoursEnd = 22,
    this.worksFriday = false,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm = 10,
    this.averageRating = 0.0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.isFeatured = false,
    this.isAvailable = true,
    this.score = 0.0,
    this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    // The backend exposes the category either at the top level as
    // `service_category` (current shape) or as `category` (legacy).
    final category = (json['service_category'] ?? json['category']) as Map<String, dynamic>?;
    return WorkerModel(
      id: json['id'] as int,
      userId: user?['id'] as int?,
      username: user?['username'] as String?,
      nameAr: user?['name_ar'] as String?,
      displayName: user?['display_name'] as String?,
      phone: user?['phone'] as String?,
      address: user?['address'] as String?,
      governorate: user?['governorate'] as String?,
      governorateLabel: user?['governorate_label'] as String?,
      city: user?['city'] as String?,
      profileImage: _absoluteMediaUrl(
        (user?['avatar_url'] ?? user?['profile_image']) as String?,
      ),
      role: user?['role'] as String?,
      // Prefer the flat `service_category_id` (always populated) over the
      // nested object — old screens passed worker.categoryId to /api/orders/
      // and got a 400 when it resolved to null.
      categoryId: (json['service_category_id'] as int?) ?? category?['id'] as int?,
      categoryName: category?['name'] as String?,
      categoryImage: (category?['icon'] ?? category?['image']) as String?,
      profession: json['profession'] as String?,
      professionAr: json['profession_ar'] as String?,
      description: (json['bio'] ?? json['description'] ?? '') as String,
      descriptionAr: json['bio_ar'] as String?,
      experienceYears: json['experience_years'] as int? ?? 0,
      hourlyRate: _asDouble(json['hourly_rate']),
      minimumCharge: _asDouble(json['minimum_charge']),
      currency: (json['currency'] as String?) ?? 'EGP',
      specialties: _csv(json['specialties_list'] ?? json['specialties']),
      specialtiesAr: _csv(json['specialties_list_ar'] ?? json['specialties_ar']),
      languages: _csv(json['languages_list'] ?? json['languages']),
      responseTimeMinutes: json['response_time_minutes'] as int? ?? 30,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      acceptRate: (json['accept_rate'] as num?)?.toDouble() ?? 0.0,
      workingHoursStart: json['working_hours_start'] as int? ?? 8,
      workingHoursEnd: json['working_hours_end'] as int? ?? 22,
      worksFriday: json['works_friday'] as bool? ?? false,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      serviceRadiusKm: json['service_radius_km'] as int? ?? 10,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      completedJobs: json['completed_jobs'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] as String?,
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static List<String> _csv(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    if (v is String) {
      return v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  /// Locale-aware specialties list.
  List<String> specialtiesFor(String languageCode) {
    if (languageCode == 'ar' && specialtiesAr.isNotEmpty) return specialtiesAr;
    return specialties;
  }

  String workingHoursLabel() {
    String fmt(int h) {
      final hh = h % 24;
      final ampm = hh >= 12 ? 'PM' : 'AM';
      final disp = hh % 12 == 0 ? 12 : hh % 12;
      return '$disp $ampm';
    }
    return '${fmt(workingHoursStart)} – ${fmt(workingHoursEnd)}';
  }

  /// Locale-aware best name to display.
  String nameFor(String languageCode) {
    if (languageCode == 'ar' && (nameAr?.isNotEmpty ?? false)) return nameAr!;
    return displayName ?? username ?? '';
  }

  String professionFor(String languageCode) {
    if (languageCode == 'ar' && (professionAr?.isNotEmpty ?? false)) {
      return professionAr!;
    }
    return profession ?? categoryName ?? '';
  }

  String bioFor(String languageCode) {
    if (languageCode == 'ar' && (descriptionAr?.isNotEmpty ?? false)) {
      return descriptionAr!;
    }
    return description;
  }

  /// Best human-readable location string.
  String locationLabel(String languageCode) {
    final parts = <String>[];
    if ((city ?? '').isNotEmpty) parts.add(city!);
    if ((governorateLabel ?? '').isNotEmpty) parts.add(governorateLabel!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'experience_years': experienceYears,
    'is_available': isAvailable,
  };

  @override
  List<Object?> get props => [
    id, userId, username, nameAr, phone, address, governorate, city,
    profileImage, role, categoryId, categoryName, profession, professionAr,
    description, descriptionAr, experienceYears, hourlyRate, minimumCharge,
    currency, specialties, specialtiesAr, languages, responseTimeMinutes,
    completionRate, acceptRate, workingHoursStart, workingHoursEnd,
    worksFriday, latitude, longitude, serviceRadiusKm,
    averageRating, completedJobs, isVerified, isFeatured, isAvailable, score,
  ];
}
