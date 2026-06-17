import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:mongez/core/constants/endpoints.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/repos/auth_repo.dart';
import 'package:mongez/services/api_service.dart';
import 'package:mongez/services/helper.dart';

class AuthRepoImplementation implements AuthRepo {
  final ApiService apiService;

  AuthRepoImplementation(this.apiService);

  @override
  Future<Either<Failure, Auth>> login({
    required String userName,
    required String password,
  }) async {
    try {
      var data = await apiService.post(
        endPoint: Endpoints.login,
        body: {"username": userName, "password": password},
      );

      Auth user = Auth.fromJson(data);

      if (user.tokens?.access != null) {
        await PrefHelper.saveToken(user.tokens!.access!);
      }
      if (user.tokens?.refresh != null) {
        await PrefHelper.saveRefreshToken(user.tokens!.refresh!);
      }

      return right(user);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      } else {
        return left(ServerFailure(errorMessage: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, Auth>> register({
    required String userName,
    required String name,
    required String password,
    required String phone,
    required String role,
    required String governorate,
    String city = "",
    String address = "",
    Uint8List? profileImageBytes,
  }) async {
    try {
      final Map<String, dynamic> body = {
        "username": userName,
        // Backend stores the human display name in `name_ar`; the field
        // accepts any unicode (Arabic or Latin, with spaces).
        "name_ar": name,
        "password": password,
        "phone": phone,
        "role": role,
        "governorate": governorate,
      };
      if (city.isNotEmpty) body["city"] = city;
      if (address.isNotEmpty) body["address"] = address;

      late Map<String, dynamic> data;

      if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
        final file = MultipartFile.fromBytes(
          profileImageBytes,
          filename: 'profile_image.jpg',
        );
        data = await apiService.postMultipart(
          endPoint: Endpoints.register,
          fields: body,
          file: file,
          fileField: "avatar",
        );
      } else {
        data = await apiService.post(
          endPoint: Endpoints.register,
          body: body,
        );
      }

      Auth user = Auth.fromJson(data);

      if (user.tokens?.access != null) {
        await PrefHelper.saveToken(user.tokens!.access!);
      }
      if (user.tokens?.refresh != null) {
        await PrefHelper.saveRefreshToken(user.tokens!.refresh!);
      }

      return right(user);
    } catch (e) {
      if (e is DioException) {
        return left(ServerFailure.fromDioException(e));
      } else {
        return left(ServerFailure(errorMessage: e.toString()));
      }
    }
  }
}
