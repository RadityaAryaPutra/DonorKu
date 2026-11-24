import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'create_request_screen.dart';
import 'requester_models.dart';
import 'requester_provider.dart';

class RequesterHomeScreen extends StatefulWidget {
  const RequesterHomeScreen({super.key});

  @override
  State<RequesterHomeScreen> createState() => _RequesterHomeScreenState();
}

class _RequesterHomeScreenState extends State<RequesterHomeScreen> {
  bool _showClosed = false;

  void _openCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<RequesterProvider>(),
          child: const CreateRequestScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<RequesterProvider>();
    final list = _showClosed ? data.closed : data.open;

    return RefreshIndicator(
      onRefresh: () => context.read<RequesterProvider>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Permintaan saya',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Buat'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('Aktif (${data.open.length})'),
              ),
              ButtonSegment(
                value: true,
                label: Text('Selesai (${data.closed.length})'),
              ),
            ],
            selected: {_showClosed},
            onSelectionChanged: (s) => setState(() => _showClosed = s.first),
          ),
          const SizedBox(height: 14),
          if (!data.initialized)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (data.error != null)
            Text(data.error!, style: const TextStyle(color: AppColors.primary))
          else if (list.isEmpty)
            _Hint(
              _showClosed ? 'Belum ada permintaan yang selesai.' : 'Belum ada permintaan aktif. Klik Buat untuk membuat permintaan darah.',
            )
          else
            for (final item in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MyRequestCard(item: item),
              ),
        ],
      ),
    );
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

(Color, Color) _statusColors(String status) => switch (status) {
  'aktif' => (AppColors.tealSoft, AppColors.teal),
  'menunggu_verifikasi' => (AppColors.amberSoft, AppColors.amber),
  'terpenuhi' => (const Color(0xFFE4EAF5), const Color(0xFF1F3A6B)),
  'ditolak' => (AppColors.primarySoft, AppColors.primary),
  _ => (const Color(0xFFF0E6E3), AppColors.muted),
};

class _MyRequestCard extends StatelessWidget {
  const _MyRequestCard({required this.item});

  final MyRequest item;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _statusColors(item.status);
    final showProgress = item.status == 'aktif' || item.status == 'terpenuhi';
    final ratio = item.unitsNeeded == 0
        ? 0.0
        : (item.unitsFulfilled / item.unitsNeeded).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Detail dan persetujuan pendonor dikerjakan di langkah berikutnya.
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
                      item.label,
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
                          item.hospitalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusLabel(item.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: foreground,
                                ),
                              ),
                            ),
                            if (item.status == 'aktif')
                              Text(
                                formatRemaining(item.neededUntil),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showProgress) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kantong terpenuhi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${item.unitsFulfilled} dari ${item.unitsNeeded}',
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
              if (item.status == 'ditolak' && item.rejectionReason != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Alasan: ${item.rejectionReason}',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
