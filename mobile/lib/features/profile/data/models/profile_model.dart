import 'package:equatable/equatable.dart';
import 'package:mongez/features/auth/models/user.dart';

class ProfileModel extends Equatable {
  final int id;
  final String username;
  final String? nameAr;
  final String? displayName;
  final String phone;
  final String address;
  final String? governorate;
  final String? governorateLabel;
  final String? city;
  final String? profileImage;
  final String role;
  final String? dateJoined;
  final int? workerId;
  final int? experienceYears;
  final double? averageRating;
  final int? completedJobs;
  final bool? isAvailable;
  final int? categoryId;
  final String? categoryName;

  const ProfileModel({
    required this.id,
    required this.username,
    this.nameAr,
    this.displayName,
    required this.phone,
    this.address = '',
    this.governorate,
    this.governorateLabel,
    this.city,
    this.profileImage,
    this.role = 'client',
    this.dateJoined,
    this.workerId,
    this.experienceYears,
    this.averageRating,
    this.completedJobs,
    this.isAvailable,
    this.categoryId,
    this.categoryName,
  });

  factory ProfileModel.fromUser(User user) {
    return ProfileModel(
      id: user.id ?? 0,
      username: user.username ?? '',
      nameAr: user.nameAr,
      displayName: user.displayName,
      phone: user.phone ?? '',
      address: user.address ?? '',
      governorate: user.governorate,
      governorateLabel: user.governorateLabel,
      city: user.city,
      profileImage: user.profileImage,
      role: user.role ?? 'client',
      dateJoined: user.dateJoined?.toIso8601String(),
    );
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      nameAr: json['name_ar'] as String?,
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      governorate: json['governorate'] as String?,
      governorateLabel: json['governorate_label'] as String?,
      city: json['city'] as String?,
      profileImage: (json['avatar_url'] ?? json['profile_image']) as String?,
      role: json['role'] as String? ?? 'client',
      dateJoined: json['date_joined'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'phone': phone,
    'address': address,
  };

  ProfileModel copyWith({
    String? username,
    String? phone,
    String? address,
    String? profileImage,
    int? workerId,
    int? experienceYears,
    double? averageRating,
    int? completedJobs,
    bool? isAvailable,
    int? categoryId,
    String? categoryName,
  }) {
    return ProfileModel(
      id: id,
      username: username ?? this.username,
      nameAr: nameAr,
      displayName: displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      governorate: governorate,
      governorateLabel: governorateLabel,
      city: city,
      profileImage: profileImage ?? this.profileImage,
      role: role,
      dateJoined: dateJoined,
      workerId: workerId ?? this.workerId,
      experienceYears: experienceYears ?? this.experienceYears,
      averageRating: averageRating ?? this.averageRating,
      completedJobs: completedJobs ?? this.completedJobs,
      isAvailable: isAvailable ?? this.isAvailable,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
    );
  }

  @override
  List<Object?> get props => [
    id, username, nameAr, displayName, phone, address,
    governorate, governorateLabel, city, profileImage, role,
    dateJoined, workerId, experienceYears, averageRating,
    completedJobs, isAvailable, categoryId, categoryName,
  ];
}
