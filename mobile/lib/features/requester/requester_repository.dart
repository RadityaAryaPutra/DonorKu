import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import 'requester_models.dart';

class RequesterRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<MyRequest>> fetchMine() async {
    final res = await _dio.get('/blood-requests');
    final body = Map<String, dynamic>.from(res.data as Map);
    return (body['data'] as List)
        .map((e) => MyRequest.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<MyRequest> fetchOne(int id) async {
    final res = await _dio.get('/blood-requests/$id');
    final body = Map<String, dynamic>.from(res.data as Map);
    return MyRequest.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _dio.post('/blood-requests', data: data);
  }

  Future<List<ResponseItem>> fetchResponses(int requestId) async {
    final res = await _dio.get('/blood-requests/$requestId/responses');
    final body = Map<String, dynamic>.from(res.data as Map);
    return (body['data'] as List)
        .map((e) => ResponseItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> approve(int responseId) async {
    await _dio.post('/responses/$responseId/approve');
  }

  Future<void> reject(int responseId) async {
    await _dio.post('/responses/$responseId/reject');
  }

  Future<void> complete(int responseId) async {
    await _dio.post('/responses/$responseId/complete');
  }
}
