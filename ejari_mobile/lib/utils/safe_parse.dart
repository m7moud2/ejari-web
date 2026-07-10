/// Safe parsing helpers for demo data and JSON maps.
String safeStr(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

List<String> safeStrList(dynamic value) {
  if (value is! List) return const [];
  return value.map((e) => safeStr(e)).toList();
}
