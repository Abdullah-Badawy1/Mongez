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
    required String name,
    required String password,
    required String phone,
    required String role,
    required String governorate,
    String city,
    String address,
    Uint8List? profileImageBytes,
  });
}

