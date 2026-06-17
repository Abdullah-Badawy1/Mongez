import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/profile/data/models/profile_model.dart';
import 'package:mongez/features/profile/domain/profile_repository.dart';
import 'package:mongez/services/api_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiService apiService;

  ProfileRepositoryImpl(this.apiService);

  @override
  Future<Either<Failure, ProfileModel>> getProfile() async {
    try {
      final data = await apiService.get(endPoint: Endpoints.userMe);
      return right(ProfileModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileModel>> updateProfile({
    String? username,
    String? nameAr,
    String? email,
    String? phone,
    String? governorate,
    String? city,
    String? address,
    Uint8List? profileImageBytes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (nameAr != null) body['name_ar'] = nameAr;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (governorate != null) body['governorate'] = governorate;
      if (city != null) body['city'] = city;
      if (address != null) body['address'] = address;

      late Map<String, dynamic> data;
      if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
        final file = MultipartFile.fromBytes(
          profileImageBytes,
          filename: 'profile_image.jpg',
        );
        data = await apiService.patchMultipart(
          endPoint: Endpoints.userMe,
          fields: body,
          file: file,
          fileField: 'avatar',
        );
      } else {
        data = await apiService.patch(endPoint: Endpoints.userMe, body: body);
      }
      return right(ProfileModel.fromJson(data));
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWorkerProfile({
    int? categoryId,
    int? experienceYears,
    bool? isAvailable,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (categoryId != null) body['category_id'] = categoryId;
      if (experienceYears != null) body['experience_years'] = experienceYears;
      if (isAvailable != null) body['is_available'] = isAvailable;

      await apiService.patch(endPoint: Endpoints.workersMe, body: body);
      return right(null);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      }
      return left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
