import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'donor_models.dart';
import 'donor_repository.dart';

class DonorProvider extends ChangeNotifier {
  final _repo = DonorRepository();

  DonorProfileData? profile;
  NearbyResult? nearby;
  bool loading = false;
  bool initialized = false;
  bool saving = false;
  String? error;
  double radius = 5;
  final Set<int> respondedIds = {};

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await _repo.fetchProfile();
      if (profile != null && profile!.hasLocation) {
        nearby = await _repo.fetchNearby(radius);
      } else {
        nearby = null;
      }
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      loading = false;
      initialized = true;
      notifyListeners();
    }
  }

  void setRadius(double value) {
    radius = value;
    load();
  }

  Future<String?> saveProfile(DonorProfileData data) async {
    saving = true;
    notifyListeners();
    try {
      await _repo.saveProfile(data);
      await load();
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<String?> toggleAvailable(bool value) async {
    final current = profile;
    if (current == null) return null;
    return saveProfile(current.copyWith(isAvailable: value));
  }

  Future<RespondResult> respond(int requestId) async {
    try {
      final result = await _repo.respond(requestId);
      respondedIds.add(requestId);
      notifyListeners();
      return result;
    } catch (e) {
      return RespondResult(error: apiErrorMessage(e));
    }
  }
}
