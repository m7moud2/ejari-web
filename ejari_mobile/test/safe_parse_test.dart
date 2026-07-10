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

  group('safeDouble', () {
    test('parses strings and numbers', () {
      expect(safeDouble('3000'), 3000);
      expect(safeDouble(42.5), 42.5);
      expect(safeDouble(null), 0);
      expect(safeDouble('abc', 9), 9);
    });
  });

  group('safeInt', () {
    test('parses strings and numbers', () {
      expect(safeInt('12'), 12);
      expect(safeInt(3.9), 3);
      expect(safeInt(null, 1), 1);
    });
  });
}
