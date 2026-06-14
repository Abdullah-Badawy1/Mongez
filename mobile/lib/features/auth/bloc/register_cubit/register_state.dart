part of 'register_cubit.dart';

@immutable
sealed class RegisterState {
  final Uint8List? imageBytes;
  const RegisterState({this.imageBytes});
}

final class RegisterInitial extends RegisterState {
  const RegisterInitial() : super();
}

final class RegisterImageLoading extends RegisterState {
  const RegisterImageLoading(Uint8List? imageBytes) : super(imageBytes: imageBytes);
}

final class RegisterImageSelected extends RegisterState {
  const RegisterImageSelected(Uint8List imageBytes) : super(imageBytes: imageBytes);
}

final class RegisterLoading extends RegisterState {
  const RegisterLoading(Uint8List? imageBytes) : super(imageBytes: imageBytes);
}

final class RegisterSuccess extends RegisterState {
  final Auth auth;
  const RegisterSuccess({required this.auth, super.imageBytes});
}

final class RegisterFailure extends RegisterState {
  final String errorMessage;
  const RegisterFailure({required this.errorMessage, super.imageBytes});
}
