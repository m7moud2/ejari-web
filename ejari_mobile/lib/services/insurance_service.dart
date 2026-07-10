import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class InsuranceService {
  static const String _insurancesKey = 'insurances';

  // Insurance Types
  static const Map<String, Map<String, dynamic>> insuranceTypes = {
    'property_damage': {
      'name': 'تأمين ضد الأضرار',
      'description': 'يغطي الأضرار التي قد تلحق بالعقار',
      'percentage': 5, // 5% من قيمة الإيجار
      'coverage': 50000, // تغطية حتى 50,000 ج.م
    },
    'theft': {
      'name': 'تأمين ضد السرقة',
      'description': 'يغطي السرقة والفقدان',
      'percentage': 3,
      'coverage': 30000,
    },
    'liability': {
      'name': 'تأمين المسؤولية',
      'description': 'يغطي الأضرار التي قد تلحق بالغير',
      'percentage': 4,
      'coverage': 40000,
    },
    'comprehensive': {
      'name': 'تأمين شامل',
      'description': 'يغطي جميع المخاطر (الأضرار، السرقة، المسؤولية)',
      'percentage': 10,
      'coverage': 100000,
    },
  };

  // Calculate insurance cost
  static double calculateInsuranceCost(
      String insuranceType, double rentalPrice) {
    final insurance = insuranceTypes[insuranceType];
    if (insurance == null) return 0;

    return (rentalPrice * insurance['percentage']) / 100;
  }

  // Create insurance policy
  static Future<String> createInsurance({
    required String bookingId,
    required String insuranceType,
    required double rentalPrice,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final insurances = await getAllInsurances();

    final insuranceId = 'INS${DateTime.now().millisecondsSinceEpoch}';
    final cost = calculateInsuranceCost(insuranceType, rentalPrice);

    final insurance = {
      'id': insuranceId,
      'bookingId': bookingId,
      'userId': userId,
      'type': insuranceType,
      'cost': cost,
      'coverage': insuranceTypes[insuranceType]!['coverage'],
      'status': 'active',
      'startDate': DateTime.now().toIso8601String(),
      'endDate':
          DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'claims': [],
    };

    insurances.add(insurance);
    await prefs.setString(_insurancesKey, jsonEncode(insurances));

    return insuranceId;
  }

  // Get all insurances
  static Future<List<Map<String, dynamic>>> getAllInsurances() async {
    final prefs = await SharedPreferences.getInstance();
    final String? insurancesJson = prefs.getString(_insurancesKey);

    if (insurancesJson != null) {
      final List<dynamic> decoded = jsonDecode(insurancesJson);
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // Get user insurances
  static Future<List<Map<String, dynamic>>> getUserInsurances(
      String userId) async {
    final allInsurances = await getAllInsurances();
    return allInsurances.where((ins) => ins['userId'] == userId).toList();
  }

  // File a claim
  static Future<bool> fileClaim({
    required String insuranceId,
    required String description,
    required double amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final insurances = await getAllInsurances();

    final index = insurances.indexWhere((ins) => ins['id'] == insuranceId);
    if (index == -1) return false;

    final insurance = insurances[index];
    final claims = List<Map<String, dynamic>>.from(insurance['claims'] ?? []);

    claims.add({
      'id': 'CLM${DateTime.now().millisecondsSinceEpoch}',
      'description': description,
      'amount': amount,
      'status': 'pending',
      'date': DateTime.now().toIso8601String(),
    });

    insurance['claims'] = claims;
    insurances[index] = insurance;

    await prefs.setString(_insurancesKey, jsonEncode(insurances));
    return true;
  }

  // Get insurance details
  static Future<Map<String, dynamic>?> getInsurance(String insuranceId) async {
    final insurances = await getAllInsurances();
    try {
      return insurances.firstWhere((ins) => ins['id'] == insuranceId);
    } catch (e) {
      return null;
    }
  }
}
