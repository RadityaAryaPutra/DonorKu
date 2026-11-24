import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import 'donor_models.dart';
import 'donor_provider.dart';

class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final donor = context.watch<DonorProvider>();
    final user = context.watch<AuthProvider>().user;
    final p = donor.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        const Text(
          'Profil donor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${user?.name ?? ''} · ${user?.email ?? ''}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        if (!donor.initialized)
          const Center(child: CircularProgressIndicator())
        else
          _ProfileForm(
            key: ValueKey(
              '${p?.label}-${p?.latitude}-${p?.longitude}-${p?.lastDonationDate}-${p?.isAvailable}',
            ),
            profile: p,
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => context.read<AuthProvider>().logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
        ),
      ],
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({super.key, required this.profile});

  final DonorProfileData? profile;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  late String _bloodType;
  late String _rhesus;
  late bool _available;
  DateTime? _lastDonation;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bloodType = p?.bloodType ?? 'O';
    _rhesus = p?.rhesus ?? '+';
    _available = p?.isAvailable ?? true;
    _lastDonation = p?.lastDonationDate;
    _lat.text = p?.latitude?.toString() ?? '';
    _lng.text = p?.longitude?.toString() ?? '';
  }

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String? _coord(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Isi angka yang valid';
    if (n < min || n > max) return 'Harus antara $min dan $max';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = (_lastDonation != null && !_lastDonation!.isAfter(now))
        ? _lastDonation!
        : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastDonation = picked);
  }

  Future<void> _useMyLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak. Isi manual.')),
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _lat.text = pos.latitude.toStringAsFixed(6);
      _lng.text = pos.longitude.toStringAsFixed(6);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat mengambil lokasi. Isi manual.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final data = DonorProfileData(
      bloodType: _bloodType,
      rhesus: _rhesus,
      latitude: double.parse(_lat.text.trim().replaceAll(',', '.')),
      longitude: double.parse(_lng.text.trim().replaceAll(',', '.')),
      lastDonationDate: _lastDonation,
      isAvailable: _available,
    );

    final error = await context.read<DonorProvider>().saveProfile(data);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Profil tersimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<DonorProvider>().saving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Golongan darah',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'A', label: Text('A')),
              ButtonSegment(value: 'B', label: Text('B')),
              ButtonSegment(value: 'AB', label: Text('AB')),
              ButtonSegment(value: 'O', label: Text('O')),
            ],
            selected: {_bloodType},
            onSelectionChanged: (s) => setState(() => _bloodType = s.first),
          ),
          const SizedBox(height: 16),
          const Text('Rhesus', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '+', label: Text('Positif (+)')),
              ButtonSegment(value: '-', label: Text('Negatif (-)')),
            ],
            selected: {_rhesus},
            onSelectionChanged: (s) => setState(() => _rhesus = s.first),
          ),
          const SizedBox(height: 16),
          const Text(
            'Donor terakhir',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _lastDonation == null
                        ? 'Belum pernah mendonor'
                        : formatDate(_lastDonation!),
                  ),
                ),
              ),
              if (_lastDonation != null)
                IconButton(
                  tooltip: 'Hapus tanggal',
                  onPressed: () => setState(() => _lastDonation = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Lokasi', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  validator: (v) => _coord(v, -90, 90),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  validator: (v) => _coord(v, -180, 180),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _locating ? null : _useMyLocation,
            icon: const Icon(Icons.my_location),
            label: Text(
              _locating ? 'Mencari lokasi...' : 'Gunakan lokasi saya',
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Bersedia dihubungi'),
            value: _available,
            onChanged: (v) => setState(() => _available = v),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan profil'),
          ),
        ],
      ),
    );
  }
}
