import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/api/api_error.dart';
import 'package:mongez/core/cache/json_cache.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/core/models/user_model.dart';

/// All methods throw [ApiError] (never raw [DioException]) so call sites can
/// surface error.message directly to the user.
class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );
      return await _saveAndReturnUser(response);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserModel> register({
    required String username,
    String? email,
    required String phone,
    required String address,
    required String password,
    required String role,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          if (email != null && email.isNotEmpty) 'email': email,
          'phone': phone,
          'address': address,
          'password': password,
          'role': role,
        },
      );
      return await _saveAndReturnUser(response);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    try {
      final response = await _dio.patch(ApiConstants.me, data: body);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        ApiConstants.passwordChange,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      final tokens = response.data['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await AppPrefs.setAccessToken(tokens['access'] as String);
      }
    } on DioException catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> logout() async {
    final refresh = AppPrefs.refreshToken;
    if (refresh != null) {
      try {
        await _dio.post(ApiConstants.logout, data: {'refresh': refresh});
      } on DioException catch (_) {
        // Best effort — we always clear local tokens regardless.
      }
    }
    await AppPrefs.clearTokens();
    await JsonCache.clearAll();
  }

  Future<UserModel> _saveAndReturnUser(Response response) async {
    final data = response.data as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await AppPrefs.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
      role: user.role,
      username: user.username,
    );
    return user;
  }
}
