import 'package:intl/intl.dart';

import '../models/app_region.dart';
import '../services/region_service.dart';

/// Central RTL-safe money formatting for the active (or override) region.
class CurrencyFormatter {
  CurrencyFormatter._();

  static AppRegion get _region => RegionService.current;

  /// Active-region symbol (getter so UI can use `CurrencyFormatter.symbol`).
  static String get symbol => _region.currencySymbol;

  static String symbolOf([AppRegion? region]) =>
      (region ?? _region).currencySymbol;

  static String get code => _region.currencyCode;

  static String codeOf([AppRegion? region]) =>
      (region ?? _region).currencyCode;

  static int get decimals => _region.currencyDecimals;

  static int decimalsOf([AppRegion? region]) =>
      (region ?? _region).currencyDecimals;

  /// Formats [amount] with grouping and the regional symbol.
  ///
  /// Example (Egypt): `15,000 ج.م`
  /// Example (KSA): `1,500.00 ر.س`
  static String format(
    num? amount, {
    AppRegion? region,
    int? fractionDigits,
    bool withSymbol = true,
    bool useGrouping = true,
  }) {
    final r = region ?? _region;
    final value = amount ?? 0;
    final digits = fractionDigits ?? r.currencyDecimals;
    final pattern = useGrouping
        ? (digits <= 0 ? '#,##0' : '#,##0.${'0' * digits}')
        : (digits <= 0 ? '0' : '0.${'0' * digits}');
    final number = NumberFormat(pattern).format(value);
    if (!withSymbol) return number;
    // Symbol after amount — natural for ar-EG / ar-SA / ar-AE UIs.
    return '$number ${r.currencySymbol}';
  }

  /// Compact helper for suffix-only UI (`ج.م`, `ر.س`, `د.إ`).
  static String unit([AppRegion? region]) => symbolOf(region);

  /// e.g. `من 800 ج.م / يوم`
  static String formatWithUnit(
    num? amount, {
    required String unitLabel,
    AppRegion? region,
    String prefix = '',
  }) {
    final body = format(amount, region: region);
    if (prefix.isEmpty) return '$body / $unitLabel';
    return '$prefix$body / $unitLabel';
  }

  /// Parse loose UI strings that may still contain a currency suffix.
  static double? tryParse(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'[^\d.,-]'), '')
        .replaceAll(',', '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}

/// Short alias used widely in widgets: `money(1500)`.
String money(num? amount, {AppRegion? region, int? fractionDigits}) =>
    CurrencyFormatter.format(
      amount,
      region: region,
      fractionDigits: fractionDigits,
    );
