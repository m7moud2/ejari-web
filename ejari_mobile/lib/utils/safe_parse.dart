/// Safe parsing helpers for demo data and JSON maps.
String safeStr(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

List<String> safeStrList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => safeStr(e)).toList();
}

double safeDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  final cleaned = value.toString().replaceAll(RegExp(r'[^0-9.\-]'), '');
  return double.tryParse(cleaned) ?? fallback;
}

int safeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9\-]'), '')) ??
      fallback;
}
