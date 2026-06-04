import 'package:dio/dio.dart';

/// Normalizes Dio errors into a single user-presentable message string.
///
/// Why this exists:
/// The Django REST API returns errors in three shapes:
///   1. `{"error": "..."}`            — single-message endpoints
///   2. `{"detail": "..."}`           — DRF default permission/auth errors
///   3. `{"field": ["msg1", "msg2"]}` — serializer validation errors
///
/// Without normalization every screen has to re-implement this parsing.
class ApiError {
  final String message;
  final int? statusCode;

  const ApiError(this.message, {this.statusCode});

  factory ApiError.from(Object error) {
    if (error is DioException) return _fromDio(error);
    return ApiError(error.toString());
  }

  static ApiError _fromDio(DioException e) {
    final code = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      // Shape 1 + 2
      for (final key in const ['error', 'detail', 'message']) {
        final v = data[key];
        if (v is String && v.isNotEmpty) {
          return ApiError(v, statusCode: code);
        }
      }
      // Shape 3: serializer errors — collect first message per field
      final parts = <String>[];
      data.forEach((field, value) {
        if (value is List && value.isNotEmpty) {
          parts.add('$field: ${value.first}');
        } else if (value is String) {
          parts.add('$field: $value');
        }
      });
      if (parts.isNotEmpty) {
        return ApiError(parts.join('\n'), statusCode: code);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError('Network timeout. Check your connection.',
            statusCode: code);
      case DioExceptionType.connectionError:
        return ApiError('Could not reach the server.', statusCode: code);
      case DioExceptionType.badCertificate:
        return ApiError('Bad SSL certificate.', statusCode: code);
      case DioExceptionType.cancel:
        return ApiError('Request cancelled.', statusCode: code);
      case DioExceptionType.unknown:
      case DioExceptionType.badResponse:
        return ApiError(
          e.message ?? 'Something went wrong.',
          statusCode: code,
        );
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isThrottled => statusCode == 429;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => message;
}
