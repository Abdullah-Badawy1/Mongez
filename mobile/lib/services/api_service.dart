import 'package:dio/dio.dart';
import 'package:mongez/services/api_client.dart';

class ApiService {
  final DioClient dioClient;

  ApiService(this.dioClient);

  Future<dynamic> get({
    required String endPoint,
    Map<String, dynamic>? queryParameters,
  }) async {
    var response = await dioClient.dio.get(
      endPoint,
      queryParameters: queryParameters,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> post({
    required String endPoint,
    Map<String, dynamic>? body,
  }) async {
    var response = await dioClient.dio.post(endPoint, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> put({
    required String endPoint,
    Map<String, dynamic>? body,
  }) async {
    var response = await dioClient.dio.put(endPoint, data: body);
    return response.data;
  }

  Future<dynamic> patch({
    required String endPoint,
    Map<String, dynamic>? body,
  }) async {
    var response = await dioClient.dio.patch(endPoint, data: body);
    return response.data;
  }

  Future<dynamic> delete({
    required String endPoint,
  }) async {
    var response = await dioClient.dio.delete(endPoint);
    return response.data;
  }

  Future<Map<String, dynamic>> postMultipart({
    required String endPoint,
    required Map<String, dynamic> fields,
    required MultipartFile file,
    required String fileField,
  }) async {
    final formData = FormData.fromMap({
      ...fields,
      fileField: file,
    });
    var response = await dioClient.dio.post(endPoint, data: formData);
    return response.data;
  }

  Future<Map<String, dynamic>> patchMultipart({
    required String endPoint,
    required Map<String, dynamic> fields,
    MultipartFile? file,
    String? fileField,
  }) async {
    if (file != null && fileField != null) {
      fields[fileField] = file;
    }
    final formData = FormData.fromMap(fields);
    var response = await dioClient.dio.patch(endPoint, data: formData);
    return response.data;
  }
}
