import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import 'requester_provider.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _hospital = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _notes = TextEditingController();

  String _bloodType = 'O';
  String _rhesus = '+';
  int _units = 1;
  DateTime? _neededUntil;
  String? _dateError;
  bool _locating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _patient.dispose();
    _hospital.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  String? _coord(String? v, double min, double max) {
    final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (n == null) return 'Isi angka yang valid';
    if (n < min || n > max) return 'Harus antara $min dan $max';
    return null;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = (_neededUntil != null && _neededUntil!.isAfter(now))
        ? _neededUntil!
        : now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    setState(() {
      _neededUntil = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateError = null;
    });
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

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    final dateOk =
        _neededUntil != null && _neededUntil!.isAfter(DateTime.now());
    setState(
      () => _dateError = dateOk ? null : 'Pilih batas waktu di masa depan',
    );
    if (!valid || !dateOk) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _submitting = true);

    final error = await context.read<RequesterProvider>().create({
      'patient_initial': _patient.text.trim(),
      'blood_type': _bloodType,
      'rhesus': _rhesus,
      'units_needed': _units,
      'hospital_name': _hospital.text.trim(),
      if (_address.text.trim().isNotEmpty)
        'hospital_address': _address.text.trim(),
      'latitude': double.parse(_lat.text.trim().replaceAll(',', '.')),
      'longitude': double.parse(_lng.text.trim().replaceAll(',', '.')),
      'needed_until': DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(_neededUntil!.toUtc()),
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
    });

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error == null) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Permintaan dikirim, menunggu verifikasi admin.'),
        ),
      );
    } else {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat permintaan darah')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              TextFormField(
                controller: _patient,
                decoration: const InputDecoration(
                  labelText: 'Inisial pasien',
                  hintText: 'Contoh: Bpk. S.',
                ),
                validator: (v) => _required(v, 'Inisial pasien wajib diisi'),
              ),
              const SizedBox(height: 16),
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
              const Text(
                'Rhesus',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
                'Jumlah kantong',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _units > 1
                        ? () => setState(() => _units--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_units kantong',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: _units < 10
                        ? () => setState(() => _units++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hospital,
                decoration: const InputDecoration(
                  labelText: 'Nama rumah sakit',
                ),
                validator: (v) => _required(v, 'Nama rumah sakit wajib diisi'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Alamat rumah sakit (opsional)',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lokasi rumah sakit',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
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
              TextButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _locating ? 'Mencari lokasi...' : 'Gunakan lokasi saya',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dibutuhkan paling lambat',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _pickDeadline,
                icon: const Icon(Icons.event),
                label: Text(
                  _neededUntil == null
                      ? 'Pilih tanggal dan jam'
                      : formatDateTime(_neededUntil!),
                ),
              ),
              if (_dateError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _dateError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Permintaan diperiksa admin lebih dulu sebelum tampil ke pendonor.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kirim permintaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
