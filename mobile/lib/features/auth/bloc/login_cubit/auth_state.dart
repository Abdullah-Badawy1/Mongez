part of 'auth_cubit.dart';

@immutable
sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final Auth auth;
  LoginSuccess({required this.auth});
}

final class LoginFailure extends LoginState {
  final String errorMessage;
  LoginFailure({required this.errorMessage});
}

// final class FetchAllProductsLoading extends FetchAllProductsState {}

// final class FetchAllProductsFailure extends FetchAllProductsState {
//   final String errorMessage;
//   const FetchAllProductsFailure({required this.errorMessage});
// }

// final class FetchAllProductsSuccess extends FetchAllProductsState {
//   final List<Products> products;
//   const FetchAllProductsSuccess({required this.products});
// }
