import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';
import 'package:mongez/features/auth/models/auth.dart';
import 'package:mongez/features/auth/repos/auth_repo.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit({required this.authRepo}) : super(const RegisterInitial());

  final AuthRepo authRepo;

  late Auth auth;
  Uint8List? _imageBytes;

  Uint8List? get imageBytes => _imageBytes;

  void reset() {
    _imageBytes = null;
    emit(const RegisterInitial());
  }

  Future<void> setImage(XFile? file) async {
    if (file == null) {
      _imageBytes = null;
      emit(const RegisterInitial());
      return;
    }
    emit(RegisterImageLoading(_imageBytes));
    try {
      final bytes = await file.readAsBytes();
      _imageBytes = bytes;
      emit(RegisterImageSelected(bytes));
    } catch (_) {
      _imageBytes = null;
      emit(const RegisterInitial());
    }
  }

  Future<void> register({
    required String userName,
    required String name,
    required String password,
    required String phone,
    required String role,
    required String governorate,
    String city = "",
    String address = "",
  }) async {
    emit(RegisterLoading(_imageBytes));

    final result = await authRepo.register(
      userName: userName,
      name: name,
      password: password,
      phone: phone,
      role: role,
      governorate: governorate,
      city: city,
      address: address,
      profileImageBytes: _imageBytes,
    );

    result.fold(
      (failure) =>
          emit(RegisterFailure(errorMessage: failure.errorMessage, imageBytes: _imageBytes)),
      (auth) {
        this.auth = auth;
        emit(RegisterSuccess(auth: auth, imageBytes: _imageBytes));
      },
    );
  }
}
