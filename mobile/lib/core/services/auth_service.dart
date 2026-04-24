import 'package:dio/dio.dart';
import 'package:mongez/core/api/api_client.dart';
import 'package:mongez/core/api/api_constants.dart';
import 'package:mongez/core/helpers.dart';
import 'package:mongez/core/models/user_model.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );
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

  Future<UserModel> register({
    required String username,
    required String phone,
    required String address,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'username': username,
        'phone': phone,
        'address': address,
        'password': password,
        'role': role,
      },
    );
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

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateProfile({
    String? username,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;
    final response = await _dio.patch(ApiConstants.me, data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => AppPrefs.clearTokens();
}
