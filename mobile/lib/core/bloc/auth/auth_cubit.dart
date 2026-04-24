import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service = AuthService();

  AuthCubit() : super(AuthInitial());

  Future<void> login({required String username, required String password}) async {
    emit(AuthLoading());
    try {
      final user = await _service.login(username: username, password: password);
      emit(AuthSuccess(user));
    } on DioException catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> register({
    required String username,
    required String phone,
    required String address,
    required String password,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _service.register(
        username: username,
        phone: phone,
        address: address,
        password: password,
        role: role,
      );
      emit(AuthSuccess(user));
    } on DioException catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> loadProfile() async {
    emit(AuthLoading());
    try {
      final user = await _service.getProfile();
      emit(AuthSuccess(user));
    } on DioException catch (e) {
      emit(AuthError(_parseError(e)));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    emit(AuthLoggedOut());
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    return e.message ?? 'An error occurred';
  }
}
