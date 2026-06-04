import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mongez/core/api/api_error.dart';
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
    } catch (e) {
      emit(AuthError(_message(e)));
    }
  }

  Future<void> register({
    required String username,
    String? email,
    required String phone,
    required String address,
    required String password,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _service.register(
        username: username,
        email: email,
        phone: phone,
        address: address,
        password: password,
        role: role,
      );
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(_message(e)));
    }
  }

  Future<void> loadProfile() async {
    emit(AuthLoading());
    try {
      final user = await _service.getProfile();
      emit(AuthSuccess(user));
    } catch (e) {
      emit(AuthError(_message(e)));
    }
  }

  Future<void> logout() async {
    await _service.logout();
    emit(AuthLoggedOut());
  }

  /// Services in this app throw [ApiError] on failure (never raw [DioException]),
  /// but we keep the fallback for any non-API surface that still raises.
  String _message(Object e) {
    if (e is ApiError) return e.message;
    return ApiError.from(e).message;
  }
}
