import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'donor_models.dart';
import 'donor_provider.dart';

class DonorDetailScreen extends StatefulWidget {
  const DonorDetailScreen({super.key, required this.item});

  final NearbyRequest item;

  @override
  State<DonorDetailScreen> createState() => _DonorDetailScreenState();
}

class _DonorDetailScreenState extends State<DonorDetailScreen> {
  bool _sending = false;
  RespondResult? _result;

  Future<void> _respond() async {
    setState(() => _sending = true);
    final result = await context.read<DonorProvider>().respond(widget.item.id);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final urgent = item.neededUntil.difference(DateTime.now()).inHours < 6;
    final remaining = formatRemaining(item.neededUntil);
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail permintaan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (urgent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'MENDESAK',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          remaining[0].toUpperCase() + remaining.substring(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF5A1710),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 16,
                              color: AppColors.teal,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Terverifikasi admin',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _InfoRow('Rumah sakit', item.hospitalName),
                  if (item.hospitalAddress != null &&
                      item.hospitalAddress!.isNotEmpty)
                    _InfoRow('Alamat', item.hospitalAddress!),
                  _InfoRow(
                    'Jarak',
                    '${formatKm(item.distanceKm)} dari lokasimu',
                  ),
                  _InfoRow('Kebutuhan', '${item.unitsLeft} kantong'),
                  _InfoRow(
                    'Batas waktu',
                    formatDateTime(item.neededUntil),
                    last: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KECOCOKAN DENGANMU',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF0B5A4D),
                    ),
                  ),
                  SizedBox(height: 10),
                  _Check('Golongan darahmu cocok dengan permintaan ini'),
                  _Check('Status kelayakan: layak mendonor'),
                  _Check('Berada dalam radius pencarianmu'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nomor kontak pemohon baru tampil setelah kamu menyatakan bersedia.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._buildActions(result),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(RespondResult? result) {
    if (result != null && result.error == null && !result.alreadyResponded) {
      return [_ContactCard(result: result)];
    }

    return [
      if (result != null && result.alreadyResponded)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Kamu sudah menyatakan bersedia untuk permintaan ini. Pemohon akan menghubungimu setelah menyetujui.',
            style: TextStyle(color: AppColors.amber, height: 1.4),
          ),
        ),
      if (result != null && result.error != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            result.error!,
            style: const TextStyle(color: AppColors.primary),
          ),
        ),
      FilledButton(
        onPressed: _sending ? null : _respond,
        child: _sending
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Saya bersedia mendonor'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Tidak bisa saat ini'),
      ),
    ];
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0E6E3))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check, size: 18, color: AppColors.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10312B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.result});

  final RespondResult result;

  @override
  Widget build(BuildContext context) {
    final phone = result.phone ?? '';
    final hasPhone = phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terima kasih, kesediaanmu sudah dicatat.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Hubungi pemohon untuk berkoordinasi:'),
          const SizedBox(height: 8),
          Text(
            result.name ?? 'Pemohon',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            hasPhone ? phone : 'Nomor telepon tidak tersedia',
            style: const TextStyle(color: AppColors.muted),
          ),
          if (hasPhone) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    icon: const Icon(Icons.call),
                    label: const Text('Hubungi'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await Clipboard.setData(ClipboardData(text: phone));
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Nomor disalin.')),
                    );
                  },
                  child: const Text('Salin'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
