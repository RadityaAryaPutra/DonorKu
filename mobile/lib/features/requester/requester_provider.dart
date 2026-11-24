import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import 'requester_models.dart';
import 'requester_repository.dart';

class RequesterProvider extends ChangeNotifier {
  final _repo = RequesterRepository();

  List<MyRequest> items = [];
  bool loading = false;
  bool initialized = false;
  String? error;

  List<MyRequest> get open => items.where((r) => r.isOpen).toList();
  List<MyRequest> get closed => items.where((r) => !r.isOpen).toList();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      items = await _repo.fetchMine();
    } catch (e) {
      error = apiErrorMessage(e);
    } finally {
      loading = false;
      initialized = true;
      notifyListeners();
    }
  }

  Future<String?> create(Map<String, dynamic> data) async {
    try {
      await _repo.create(data);
      await load();
      return null;
    } catch (e) {
      return apiErrorMessage(e);
    }
  }
}
