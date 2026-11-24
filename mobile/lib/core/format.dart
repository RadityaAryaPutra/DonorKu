const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String formatKm(double km) =>
    '${km.toStringAsFixed(1).replaceAll('.', ',')} km';

String formatRemaining(DateTime until) {
  final diff = until.difference(DateTime.now());
  if (diff.isNegative) return 'sudah lewat';
  if (diff.inHours < 1) return 'sisa ${diff.inMinutes} menit';
  if (diff.inHours < 48) return 'sisa ${diff.inHours} jam';
  return 'sisa ${diff.inDays} hari';
}
