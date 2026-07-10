import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists saved cards and last-used payment method for checkout flows.
class PaymentMethodsService {
  static const _cardsKey = 'payment_methods_cards_v1';
  static const _selectedKey = 'selected_payment_method_v1';

  static List<Map<String, dynamic>> _defaultCards() => [
        {
          'id': '1',
          'number': '**** **** **** 1234',
          'expiry': '12/25',
          'holder': 'MAHMOUD ABDELKAWY',
          'type': 'visa',
          'isDefault': true,
        },
        {
          'id': '2',
          'number': '**** **** **** 5678',
          'expiry': '09/24',
          'holder': 'MAHMOUD ABDELKAWY',
          'type': 'mastercard',
          'isDefault': false,
        },
      ];

  static Future<List<Map<String, dynamic>>> getCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cardsKey);
    if (raw == null) return _defaultCards();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return _defaultCards();
    }
  }

  static Future<void> saveCards(List<Map<String, dynamic>> cards) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cardsKey, jsonEncode(cards));
  }

  static Future<void> setDefaultCard(String id) async {
    final cards = await getCards();
    for (final card in cards) {
      card['isDefault'] = card['id']?.toString() == id;
    }
    await saveCards(cards);
  }

  static Future<Map<String, String>> getSelectedMethod() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selectedKey);
    if (raw == null) {
      return {'category': 'cards', 'subMethod': 'visa'};
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {
        'category': map['category']?.toString() ?? 'cards',
        'subMethod': map['subMethod']?.toString() ?? 'visa',
      };
    } catch (_) {
      return {'category': 'cards', 'subMethod': 'visa'};
    }
  }

  static Future<void> saveSelectedMethod({
    required String category,
    required String subMethod,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _selectedKey,
      jsonEncode({'category': category, 'subMethod': subMethod}),
    );
  }

  static Future<Map<String, dynamic>?> getDefaultCard() async {
    final cards = await getCards();
    try {
      return cards.firstWhere((c) => c['isDefault'] == true);
    } catch (_) {
      return cards.isNotEmpty ? cards.first : null;
    }
  }
}
