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
            message = _firstString(data['non_field_errors']);
          } else if (data.containsKey('detail')) {
            message = data['detail'].toString();
          } else {
            // Field-level DRF validation errors look like
            //   {"username": ["..."], "phone": ["..."]}.
            // Joining "<field>: <msg>" makes it obvious which input
            // failed — the previous code surfaced just "this field is
            // required" with no hint about which field.
            final lines = <String>[];
            data.forEach((field, value) {
              final msg = _firstString(value);
              if (msg.isNotEmpty) {
                lines.add(field == 'non_field_errors'
                    ? msg
                    : '$field: $msg');
              }
            });
            if (lines.isNotEmpty) message = lines.join('\n');
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

  static String _firstString(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is List && v.isNotEmpty) return _firstString(v.first);
    return v.toString();
  }
}
