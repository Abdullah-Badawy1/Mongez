import 'package:equatable/equatable.dart';

class Tokens extends Equatable {
  final String? access;
  final String? refresh;

  const Tokens({this.access, this.refresh});

  factory Tokens.fromJson(Map<String, dynamic> json) => Tokens(
    access: json['access'] as String?,
    refresh: json['refresh'] as String?,
  );

  Map<String, dynamic> toJson() => {'access': access, 'refresh': refresh};

  @override
  List<Object?> get props => [access, refresh];
}
