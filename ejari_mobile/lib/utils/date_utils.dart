import 'package:intl/intl.dart';

class DateParsing {
  static DateTime? parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw);
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    final candidates = <String>{
      text,
      text.replaceAll('T', ' ').replaceAll('Z', ''),
      text.replaceAll('/', '-'),
      text.split(' - ').first.trim(),
    }.where((value) => value.isNotEmpty);

    const formats = <String>[
      'yyyy-MM-dd',
      'yyyy/MM/dd',
      'yyyy-MM-dd HH:mm',
      'yyyy/MM/dd HH:mm',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy/MM/dd HH:mm:ss',
      'yyyy-MM-dd hh:mm a',
      'yyyy/MM/dd hh:mm a',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm',
      'dd MMM yyyy',
      'dd MMM yyyy, hh:mm a',
      'dd MMM yyyy HH:mm',
    ];

    for (final candidate in candidates) {
      final direct = DateTime.tryParse(candidate);
      if (direct != null) return direct;

      for (final format in formats) {
        try {
          return DateFormat(format).parseLoose(candidate);
        } catch (_) {
          // Try next format.
        }
      }
    }

    return null;
  }

  static String display(dynamic raw, {String fallback = '', String pattern = 'yyyy-MM-dd'}) {
    final parsed = parse(raw);
    if (parsed == null) return fallback;
    return DateFormat(pattern).format(parsed);
  }
}
