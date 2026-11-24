import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'donor_models.dart';
import 'donor_provider.dart';

class DonorHomeScreen extends StatelessWidget {
  const DonorHomeScreen({super.key, required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    final user = context.watch<AuthProvider>().user;

    return RefreshIndicator(
      onRefresh: () => context.read<DonorProvider>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Selamat datang',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          Text(
            'Halo, ${user?.name ?? ''}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          _StatusCard(onOpenProfile: onOpenProfile),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Permintaan di dekatmu',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              _RadiusChip(
                radius: donor.radius,
                onSelected: context.read<DonorProvider>().setRadius,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildList(donor),
        ],
      ),
    );
  }

  List<Widget> _buildList(DonorProvider donor) {
    if (!donor.initialized) return const [];
    if (donor.error != null) {
      return [
        Text(donor.error!, style: const TextStyle(color: AppColors.primary)),
      ];
    }

    final nearby = donor.nearby;
    if (nearby == null) {
      return const [
        _Hint('Lengkapi profil donor untuk melihat permintaan di dekatmu.'),
      ];
    }
    if (!nearby.eligible) {
      return [_Hint(nearby.reason ?? 'Kamu belum dapat mendonor saat ini.')];
    }
    if (nearby.items.isEmpty) {
      return const [
        _Hint(
          'Belum ada permintaan yang cocok dalam radius ini. Coba perbesar radius.',
        ),
      ];
    }

    return [
      for (final item in nearby.items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _RequestCard(item: item),
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

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({required this.radius, required this.onSelected});

  final double radius;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      onSelected: onSelected,
      itemBuilder: (_) => [1.0, 3.0, 5.0, 10.0, 20.0]
          .map(
            (r) =>
                PopupMenuItem(value: r, child: Text('Radius ${r.toInt()} km')),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Radius ${radius.toInt()} km',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.onOpenProfile});

  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    final profile = donor.profile;
    final nearby = donor.nearby;

    if (!donor.initialized) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (profile == null || !profile.hasLocation) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lengkapi profil donor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Isi golongan darah dan lokasimu agar kami bisa mencocokkan permintaan di dekatmu.',
              style: TextStyle(color: AppColors.amber, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onOpenProfile,
              child: const Text('Lengkapi sekarang'),
            ),
          ],
        ),
      );
    }

    final eligible = nearby?.eligible ?? true;
    final color = eligible ? AppColors.teal : AppColors.amber;
    final subtitle = eligible
        ? (profile.lastDonationDate == null
              ? 'Belum pernah mendonor'
              : 'Donor terakhir: ${formatDate(profile.lastDonationDate!)}')
        : (nearby?.reason ?? 'Belum dapat mendonor saat ini.');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STATUS KELAYAKAN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eligible ? 'Layak mendonor' : 'Belum layak donor',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  profile.label,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bersedia dihubungi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Switch(
                value: profile.isAvailable,
                activeTrackColor: Colors.white,
                activeThumbColor: color,
                onChanged: donor.saving
                    ? null
                    : (value) async {
                        final messenger = ScaffoldMessenger.of(context);
                        final error = await context
                            .read<DonorProvider>()
                            .toggleAvailable(value);
                        if (error != null) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.item});

  final NearbyRequest item;

  @override
  Widget build(BuildContext context) {
    final urgent = item.neededUntil.difference(DateTime.now()).inHours < 6;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        // Layar detail dikerjakan di langkah berikutnya.
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (urgent)
                          const _Badge(
                            'MENDESAK',
                            AppColors.primary,
                            Colors.white,
                          ),
                        const _Badge(
                          'Cocok untukmu',
                          AppColors.tealSoft,
                          AppColors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.hospitalName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatKm(item.distanceKm)} · ${item.unitsLeft} kantong · ${formatRemaining(item.neededUntil)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.background, this.foreground);

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
