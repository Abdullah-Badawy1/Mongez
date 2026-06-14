// ignore: file_names
import 'package:dio/dio.dart';

abstract class Failure {
  final String errorMessage;

  const Failure({required this.errorMessage});
}

class ServerFailure extends Failure {
  ServerFailure({required super.errorMessage});

  factory ServerFailure.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.cancel:
        return ServerFailure(
          errorMessage: "Request to API server was cancelled",
        );
      case DioExceptionType.connectionTimeout:
        return ServerFailure(
          errorMessage: "Connection timeout with API server",
        );
      case DioExceptionType.receiveTimeout:
        return ServerFailure(
          errorMessage: "Receive timeout in connection with API server",
        );
      case DioExceptionType.badResponse:
        final data = dioException.response?.data;
        String message = "Oops! Something went wrong.";

        if (data is Map) {
          if (data.containsKey('non_field_errors')) {
            message = data['non_field_errors'][0];
          } else if (data.containsKey('detail')) {
            message = data['detail'];
          } else {
            message = data.values.first is List
                ? data.values.first[0]
                : data.values.first.toString();
          }
        }

        return ServerFailure(errorMessage: message);
      case DioExceptionType.sendTimeout:
        return ServerFailure(
          errorMessage: "Send timeout in connection with API server",
        );
      case DioExceptionType.connectionError:
        return ServerFailure(errorMessage: "Connection error occurred");
      default:
        return ServerFailure(errorMessage: "Unexpected error occurred");
    }
  }
}
