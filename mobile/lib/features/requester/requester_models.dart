class MyRequest {
  const MyRequest({
    required this.id,
    required this.patientInitial,
    required this.bloodType,
    required this.rhesus,
    required this.unitsNeeded,
    required this.unitsFulfilled,
    required this.hospitalName,
    this.hospitalAddress,
    required this.neededUntil,
    required this.status,
    this.rejectionReason,
  });

  final int id;
  final String patientInitial;
  final String bloodType;
  final String rhesus;
  final int unitsNeeded;
  final int unitsFulfilled;
  final String hospitalName;
  final String? hospitalAddress;
  final DateTime neededUntil;
  final String status;
  final String? rejectionReason;

  String get label => '$bloodType$rhesus';
  bool get isOpen => status == 'menunggu_verifikasi' || status == 'aktif';

  factory MyRequest.fromJson(Map<String, dynamic> json) => MyRequest(
    id: json['id'] as int,
    patientInitial: json['patient_initial'] as String,
    bloodType: json['blood_type'] as String,
    rhesus: json['rhesus'] as String,
    unitsNeeded: json['units_needed'] as int,
    unitsFulfilled: json['units_fulfilled'] as int,
    hospitalName: json['hospital_name'] as String,
    hospitalAddress: json['hospital_address'] as String?,
    neededUntil: DateTime.parse(json['needed_until'] as String).toLocal(),
    status: json['status'] as String,
    rejectionReason: json['rejection_reason'] as String?,
  );
}

String statusLabel(String status) => switch (status) {
  'menunggu_verifikasi' => 'Menunggu verifikasi admin',
  'aktif' => 'Aktif · terverifikasi',
  'terpenuhi' => 'Terpenuhi',
  'ditolak' => 'Ditolak',
  'kedaluwarsa' => 'Kedaluwarsa',
  _ => status,
};
