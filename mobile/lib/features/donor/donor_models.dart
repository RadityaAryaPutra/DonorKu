import 'package:intl/intl.dart';

double? _toDouble(dynamic v) =>
    v == null ? null : double.tryParse(v.toString());

class DonorProfileData {
  const DonorProfileData({
    required this.bloodType,
    required this.rhesus,
    this.latitude,
    this.longitude,
    this.lastDonationDate,
    this.isAvailable = true,
  });

  final String bloodType;
  final String rhesus;
  final double? latitude;
  final double? longitude;
  final DateTime? lastDonationDate;
  final bool isAvailable;

  String get label => '$bloodType$rhesus';
  bool get hasLocation => latitude != null && longitude != null;

  DonorProfileData copyWith({bool? isAvailable}) => DonorProfileData(
    bloodType: bloodType,
    rhesus: rhesus,
    latitude: latitude,
    longitude: longitude,
    lastDonationDate: lastDonationDate,
    isAvailable: isAvailable ?? this.isAvailable,
  );

  factory DonorProfileData.fromJson(Map<String, dynamic> json) {
    final date = json['last_donation_date'];
    final available = json['is_available'];
    return DonorProfileData(
      bloodType: json['blood_type'] as String,
      rhesus: json['rhesus'] as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      lastDonationDate: date == null ? null : DateTime.parse(date as String),
      isAvailable: available == null
          ? true
          : (available == true || available == 1),
    );
  }

  Map<String, dynamic> toJson() => {
    'blood_type': bloodType,
    'rhesus': rhesus,
    'latitude': latitude,
    'longitude': longitude,
    'last_donation_date': lastDonationDate == null
        ? null
        : DateFormat('yyyy-MM-dd').format(lastDonationDate!),
    'is_available': isAvailable,
  };
}

class NearbyRequest {
  const NearbyRequest({
    required this.id,
    required this.bloodType,
    required this.rhesus,
    required this.unitsNeeded,
    required this.unitsFulfilled,
    required this.hospitalName,
    this.hospitalAddress,
    required this.neededUntil,
    required this.distanceKm,
  });

  final int id;
  final String bloodType;
  final String rhesus;
  final int unitsNeeded;
  final int unitsFulfilled;
  final String hospitalName;
  final String? hospitalAddress;
  final DateTime neededUntil;
  final double distanceKm;

  String get label => '$bloodType$rhesus';
  int get unitsLeft => unitsNeeded - unitsFulfilled;

  factory NearbyRequest.fromJson(Map<String, dynamic> json) => NearbyRequest(
    id: json['id'] as int,
    bloodType: json['blood_type'] as String,
    rhesus: json['rhesus'] as String,
    unitsNeeded: json['units_needed'] as int,
    unitsFulfilled: json['units_fulfilled'] as int,
    hospitalName: json['hospital_name'] as String,
    hospitalAddress: json['hospital_address'] as String?,
    neededUntil: DateTime.parse(json['needed_until'] as String).toLocal(),
    distanceKm: _toDouble(json['distance_km']) ?? 0,
  );
}

class NearbyResult {
  const NearbyResult({
    required this.eligible,
    this.reason,
    this.needsProfile = false,
    this.items = const [],
  });

  final bool eligible;
  final String? reason;
  final bool needsProfile;
  final List<NearbyRequest> items;
}

class RespondResult {
  const RespondResult({
    this.name,
    this.phone,
    this.alreadyResponded = false,
    this.error,
  });

  final String? name;
  final String? phone;
  final bool alreadyResponded;
  final String? error;
}
