import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import 'donor_models.dart';

class DonorRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<DonorProfileData?> fetchProfile() async {
    try {
      final res = await _dio.get('/donor-profile');
      final body = res.data;
      if (body is! Map) return null;
      final inner = body['data'] ?? body['profile'] ?? body;
      if (inner is Map && inner['blood_type'] != null) {
        return DonorProfileData.fromJson(Map<String, dynamic>.from(inner));
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> saveProfile(DonorProfileData profile) async {
    await _dio.put('/donor-profile', data: profile.toJson());
  }

  Future<NearbyResult> fetchNearby(double radius) async {
    try {
      final res = await _dio.get(
        '/matching/requests',
        queryParameters: {'radius': radius},
      );
      final body = Map<String, dynamic>.from(res.data as Map);
      final items = (body['data'] as List)
          .map(
            (e) => NearbyRequest.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      return NearbyResult(
        eligible: body['eligible'] == true,
        reason: body['reason'] as String?,
        items: items,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        return const NearbyResult(eligible: false, needsProfile: true);
      }
      rethrow;
    }
  }

  Future<RespondResult> respond(int requestId) async {
    try {
      final res = await _dio.post('/blood-requests/$requestId/respond');
      final body = Map<String, dynamic>.from(res.data as Map);
      final contact = body['contact'] is Map
          ? Map<String, dynamic>.from(body['contact'] as Map)
          : <String, dynamic>{};
      return RespondResult(
        name: contact['name'] as String?,
        phone: contact['phone'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return const RespondResult(alreadyResponded: true);
      }
      rethrow;
    }
  }
}
