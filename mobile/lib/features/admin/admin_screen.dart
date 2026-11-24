import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';

class PendingRequest {
  const PendingRequest({
    required this.id,
    required this.patientInitial,
    required this.label,
    required this.unitsNeeded,
    required this.hospitalName,
    required this.neededUntil,
    this.hospitalAddress,
    this.notes,
    this.requesterName,
    this.requesterPhone,
  });

  final int id;
  final String patientInitial;
  final String label;
  final int unitsNeeded;
  final String hospitalName;
  final String? hospitalAddress;
  final String? notes;
  final DateTime neededUntil;
  final String? requesterName;
  final String? requesterPhone;

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    final requester = json['requester'] is Map
        ? Map<String, dynamic>.from(json['requester'] as Map)
        : <String, dynamic>{};
    return PendingRequest(
      id: json['id'] as int,
      patientInitial: (json['patient_initial'] ?? '-').toString(),
      label: '${json['blood_type']}${json['rhesus']}',
      unitsNeeded: int.parse(json['units_needed'].toString()),
      hospitalName: json['hospital_name'] as String,
      hospitalAddress: json['hospital_address'] as String?,
      notes: json['notes'] as String?,
      neededUntil: DateTime.parse(json['needed_until'] as String).toLocal(),
      requesterName: requester['name'] as String?,
      requesterPhone: requester['phone'] as String?,
    );
  }
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final Dio _dio = ApiClient.instance.dio;

  List<PendingRequest> _items = [];
  bool _loading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/admin/blood-requests');
      final body = Map<String, dynamic>.from(res.data as Map);
      final items = (body['data'] as List)
          .map(
            (e) => PendingRequest.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(
    PendingRequest item,
    Future<void> Function() action,
    String message,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = item.id);
    try {
      await action();
      await _load();
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _verify(PendingRequest item) {
    return _act(
      item,
      () => _dio.post('/admin/blood-requests/${item.id}/verify'),
      'Permintaan diverifikasi.',
    );
  }

  Future<void> _reject(PendingRequest item) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak permintaan'),
        content: TextField(
          controller: controller,
          maxLength: 255,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Alasan penolakan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (reason != null && mounted) {
      await _act(
        item,
        () => _dio.post(
          '/admin/blood-requests/${item.id}/reject',
          data: {'rejection_reason': reason},
        ),
        'Permintaan ditolak.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi permintaan'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.primary))
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'Tidak ada permintaan yang menunggu verifikasi.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (final item in _items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PendingCard(
                      item: item,
                      busy: _busyId == item.id,
                      onVerify: () => _verify(item),
                      onReject: () => _reject(item),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.item,
    required this.busy,
    required this.onVerify,
    required this.onReject,
  });

  final PendingRequest item;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[
      'Pasien: ${item.patientInitial} · ${item.unitsNeeded} kantong',
      if (item.hospitalAddress != null && item.hospitalAddress!.isNotEmpty)
        item.hospitalAddress!,
      'Dibutuhkan paling lambat ${formatDateTime(item.neededUntil)}',
      if (item.requesterName != null)
        'Pemohon: ${item.requesterName}${item.requesterPhone != null ? ' (${item.requesterPhone})' : ''}',
      if (item.notes != null && item.notes!.isNotEmpty)
        'Catatan: ${item.notes}',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.hospitalName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: busy ? null : onVerify,
                  child: const Text('Verifikasi'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: busy ? null : onReject,
                child: const Text('Tolak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
