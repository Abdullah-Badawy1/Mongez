import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:mongez/errors/failure.dart';
import 'package:mongez/features/auth/models/auth.dart';

abstract class AuthRepo {
  Future<Either<Failure, Auth>> login({
    required String userName,
    required String password,
  });
  Future<Either<Failure, Auth>> register({
    required String userName,
    required String password,
    required String address,
    required String phone,
    required String role,
    Uint8List? profileImageBytes,
  });
}

