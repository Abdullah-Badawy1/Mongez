import 'package:equatable/equatable.dart';

import 'tokens.dart';
import 'user.dart';

class Auth extends Equatable {
  final String? message;
  final User? user;
  final Tokens? tokens;

  const Auth({this.message, this.user, this.tokens});

  factory Auth.fromJson(Map<String, dynamic> json) => Auth(
    message: json['message'] as String?,
    user: json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>),
    tokens: json['tokens'] == null
        ? null
        : Tokens.fromJson(json['tokens'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'message': message,
    'user': user?.toJson(),
    'tokens': tokens?.toJson(),
  };

  @override
  List<Object?> get props => [message, user, tokens];
}
