import 'package:flutter_test/flutter_test.dart';
import 'package:ejari_mobile/utils/safe_parse.dart';

void main() {
  group('safeStr', () {
    test('returns fallback for null', () {
      expect(safeStr(null), '');
      expect(safeStr(null, '—'), '—');
    });

    test('stringifies non-null values', () {
      expect(safeStr('hello'), 'hello');
      expect(safeStr(42), '42');
    });
  });

  group('safeStrList', () {
    test('handles null and mixed lists', () {
      expect(safeStrList(null), isEmpty);
      expect(safeStrList([null, 'a', 1]), ['', 'a', '1']);
    });
  });
}
