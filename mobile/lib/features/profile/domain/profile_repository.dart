import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/profile/data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileModel>> getProfile();
  Future<Either<Failure, ProfileModel>> updateProfile({
    String? username,
    String? nameAr,
    String? email,
    String? phone,
    String? governorate,
    String? city,
    String? address,
    Uint8List? profileImageBytes,
  });
  Future<Either<Failure, void>> updateWorkerProfile({
    int? categoryId,
    int? experienceYears,
    bool? isAvailable,
  });
}
