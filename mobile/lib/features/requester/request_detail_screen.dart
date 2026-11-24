import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import 'requester_models.dart';
import 'requester_provider.dart';
import 'requester_repository.dart';

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final int requestId;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _repo = RequesterRepository();

  MyRequest? _request;
  List<ResponseItem> _responses = [];
  bool _loading = true;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final request = await _repo.fetchOne(widget.requestId);
      final responses =
          request.status == 'aktif' || request.status == 'terpenuhi'
          ? await _repo.fetchResponses(widget.requestId)
          : <ResponseItem>[];
      if (!mounted) return;
      setState(() {
        _request = request;
        _responses = responses;
        _error = null;
      });
      context.read<RequesterProvider>().load();
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(
    int responseId,
    Future<void> Function() action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyId = responseId);
    try {
      await action();
      await _reload();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmComplete(ResponseItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tandai donor selesai?'),
        content: Text(
          'Pastikan ${item.name} sudah mendonorkan darahnya. Jumlah kantong terpenuhi akan bertambah dan tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, selesai'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _act(
        item.id,
        () => _repo.complete(item.id),
        'Donor ditandai selesai.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail permintaan')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (request == null)
                Text(
                  _error ?? 'Permintaan tidak ditemukan.',
                  style: const TextStyle(color: AppColors.primary),
                )
              else ...[
                _HeaderCard(request: request),
                const SizedBox(height: 20),
                ..._buildResponses(request),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResponses(MyRequest request) {
    if (request.status == 'menunggu_verifikasi') {
      return const [
        _Hint(
          'Permintaanmu sedang diperiksa admin. Pendonor baru dapat melihatnya setelah diverifikasi.',
        ),
      ];
    }
    if (request.status == 'ditolak') {
      return [
        _Hint(
          'Permintaan ditolak admin.${request.rejectionReason != null ? ' Alasan: ${request.rejectionReason}' : ''}',
        ),
      ];
    }

    return [
      Text(
        'Pendonor yang bersedia (${_responses.length})',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      if (_responses.isEmpty)
        const _Hint('Belum ada pendonor yang menyatakan bersedia.')
      else
        for (final item in _responses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ResponseCard(
              item: item,
              busy: _busyId == item.id,
              onApprove: () => _act(
                item.id,
                () => _repo.approve(item.id),
                'Pendonor disetujui.',
              ),
              onReject: () => _act(
                item.id,
                () => _repo.reject(item.id),
                'Pendonor ditolak.',
              ),
              onComplete: () => _confirmComplete(item),
            ),
          ),
    ];
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, height: 1.4),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.request});

  final MyRequest request;

  @override
  Widget build(BuildContext context) {
    final showProgress =
        request.status == 'aktif' || request.status == 'terpenuhi';
    final ratio = request.unitsNeeded == 0
        ? 0.0
        : (request.unitsFulfilled / request.unitsNeeded).clamp(0.0, 1.0);

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
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  request.label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.hospitalName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${statusLabel(request.status)} · ${request.status == 'aktif' ? formatRemaining(request.neededUntil) : formatDateTime(request.neededUntil)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pasien: ${request.patientInitial}',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (request.hospitalAddress != null &&
              request.hospitalAddress!.isNotEmpty)
            Text(
              request.hospitalAddress!,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          if (showProgress) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kantong terpenuhi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${request.unitsFulfilled} dari ${request.unitsNeeded}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                color: AppColors.teal,
                backgroundColor: const Color(0xFFF0E6E3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  const _ResponseCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
  });

  final ResponseItem item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  (String, Color) get _statusInfo => switch (item.status) {
    'bersedia' => ('Menunggu persetujuan', AppColors.amber),
    'disetujui' => ('Disetujui', AppColors.teal),
    'selesai' => ('Selesai', AppColors.teal),
    'ditolak' => ('Ditolak', AppColors.muted),
    'dibatalkan' => ('Dibatalkan', AppColors.muted),
    _ => (item.status, AppColors.muted),
  };

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _statusInfo;
    final showContact = item.status == 'disetujui' || item.status == 'selesai';
    final phone = item.phone ?? '';
    final subtitle = [
      if (item.label != null) 'Pendonor ${item.label}',
      if (item.distanceKm != null) formatKm(item.distanceKm!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.tealSoft,
                child: Text(
                  item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (showContact) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.call, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Text(
                  phone.isEmpty ? 'Nomor telepon tidak tersedia' : phone,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
          if (item.status == 'bersedia') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: busy ? null : onApprove,
                    child: const Text('Setujui'),
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
          if (item.status == 'disetujui') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: phone.isEmpty
                        ? null
                        : () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    icon: const Icon(Icons.call),
                    label: const Text('Hubungi'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: busy ? null : onComplete,
                    child: const Text('Tandai selesai'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
