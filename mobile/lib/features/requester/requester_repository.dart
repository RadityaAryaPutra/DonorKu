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

  Future<void> create(Map<String, dynamic> data) async {
    await _dio.post('/blood-requests', data: data);
  }
}
