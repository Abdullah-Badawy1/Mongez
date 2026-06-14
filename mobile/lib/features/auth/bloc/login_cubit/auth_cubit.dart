import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/repos/auth_repo.dart';

part 'auth_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required this.authRepo}) : super(LoginInitial());

  final AuthRepo authRepo;

  late Auth auth;

  void reset() {
    emit(LoginInitial());
  }

  Future<void> login({
    required String userName,
    required String password,
  }) async {
    emit(LoginLoading());

    final result = await authRepo.login(userName: userName, password: password);

    result.fold(
      (failure) => emit(LoginFailure(errorMessage: failure.errorMessage)),
      (auth) {
        this.auth = auth;
        emit(LoginSuccess(auth: auth));
      },
    );
  }
}

