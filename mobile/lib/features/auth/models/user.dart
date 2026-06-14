import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String? username;
  final String? nameAr;
  final String? displayName;
  final String? phone;
  final String? address;
  final String? governorate;
  final String? governorateLabel;
  final String? city;
  final String? profileImage;
  final String? role;
  final DateTime? dateJoined;

  const User({
    this.id,
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
    this.dateJoined,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as int?,
    username: json['username'] as String?,
    nameAr: json['name_ar'] as String?,
    displayName: json['display_name'] as String?,
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    governorate: json['governorate'] as String?,
    governorateLabel: json['governorate_label'] as String?,
    city: json['city'] as String?,
    profileImage: (json['avatar_url'] ?? json['profile_image']) as String?,
    role: json['role'] as String?,
    dateJoined: json['date_joined'] == null
        ? null
        : DateTime.parse(json['date_joined'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'name_ar': nameAr,
    'display_name': displayName,
    'phone': phone,
    'address': address,
    'governorate': governorate,
    'governorate_label': governorateLabel,
    'city': city,
    'profile_image': profileImage,
    'role': role,
    'date_joined': dateJoined?.toIso8601String(),
  };

  String nameFor(String languageCode) {
    if (languageCode == 'ar' && (nameAr?.isNotEmpty ?? false)) return nameAr!;
    return displayName ?? username ?? '';
  }

  String locationLabel() {
    final parts = <String>[];
    if ((city ?? '').isNotEmpty) parts.add(city!);
    if ((governorateLabel ?? '').isNotEmpty) parts.add(governorateLabel!);
    if (parts.isEmpty && (address ?? '').isNotEmpty) return address!;
    return parts.join(', ');
  }

  @override
  List<Object?> get props {
    return [
      id, username, nameAr, displayName, phone, address,
      governorate, governorateLabel, city, profileImage, role, dateJoined,
    ];
  }
}
