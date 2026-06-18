import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:mongez/core/constants/api_constants.dart';

class CategoriesModel extends Equatable {
  final int? id;
  final String? name;
  final String? nameAr;
  final String? image;
  final String? icon;       // icon key sent by backend (e.g. "plumbing")
  final String? description;
  final String? descriptionAr;

  const CategoriesModel({
    this.id,
    this.name,
    this.nameAr,
    this.image,
    this.icon,
    this.description,
    this.descriptionAr,
  });

  factory CategoriesModel.fromJson(Map<String, dynamic> json) =>
      CategoriesModel(
        id: json['id'] as int?,
        name: json['name'] as String?,
        nameAr: json['name_ar'] as String?,
        image: json['image'] as String?,
        icon: json['icon'] as String?,
        description: json['description'] as String?,
        descriptionAr: json['description_ar'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'name_ar': nameAr,
    'image': image, 'icon': icon,
    'description': description, 'description_ar': descriptionAr,
  };

  String? get imageUrl =>
      image != null && image!.isNotEmpty ? '${ApiConstants.baseUrl}$image' : null;

  /// Locale-aware display name.
  String displayName(String languageCode) {
    if (languageCode == 'ar' && (nameAr?.isNotEmpty ?? false)) return nameAr!;
    return name ?? '';
  }

  /// Bilingual label "English — Arabic" for pickers that should show
  /// both at once (e.g. worker sign-up category dropdown). Falls back
  /// to whichever side is populated.
  String get bilingualLabel {
    final en = (name ?? '').trim();
    final ar = (nameAr ?? '').trim();
    if (en.isNotEmpty && ar.isNotEmpty) return '$en — $ar';
    return en.isNotEmpty ? en : ar;
  }

  /// Map backend icon key → Material Icons. Falls back to a category icon.
  IconData get iconData {
    switch ((icon ?? '').toLowerCase()) {
      case 'plumbing': return Icons.plumbing_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'hammer': return Icons.handyman_rounded;
      case 'brush': return Icons.brush_rounded;
      case 'ac_unit': return Icons.ac_unit_rounded;
      case 'local_laundry_service': return Icons.local_laundry_service_rounded;
      case 'kitchen': return Icons.kitchen_rounded;
      case 'cleaning_services': return Icons.cleaning_services_rounded;
      case 'satellite_alt': return Icons.satellite_alt_rounded;
      case 'grid_view': return Icons.grid_view_rounded;
      case 'construction': return Icons.construction_rounded;
      case 'yard': return Icons.yard_rounded;
      default: return Icons.category_rounded;
    }
  }

  @override
  List<Object?> get props => [id, name, nameAr, image, icon, description, descriptionAr];
}
