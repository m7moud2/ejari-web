import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';

/// إدارة شجرة الشقة → الغرف → الأسرّة للإقامة المشتركة.
class BedHierarchyService {
  BedHierarchyService._();

  static const String _hierarchyKey = 'bed_hierarchy_v1';

  /// بناء شجرة من بيانات العقار.
  static Map<String, dynamic> buildTree(Map<String, dynamic> property) {
    final rooms = List<Map<String, dynamic>>.from(
      property['roomUnits'] as List? ?? [],
    );
    final beds = List<Map<String, dynamic>>.from(
      property['bedUnits'] as List? ?? [],
    );

    final treeRooms = rooms.map((room) {
      final roomId = room['id']?.toString() ?? '';
      final roomBeds = beds
          .where((b) => b['roomId']?.toString() == roomId)
          .map((b) => {
                'id': b['id'],
                'label': b['label'] ?? 'سرير',
                'status': b['status'] ?? 'vacant',
                'tenantEmail': b['tenantEmail'],
                'tenantName': b['tenantName'],
                'leaseStart': b['leaseStart'],
                'leaseEnd': b['leaseEnd'],
              })
          .toList();
      return {
        'id': roomId,
        'label': room['label'] ?? 'غرفة',
        'status': room['status'] ?? 'vacant',
        'occupiedBeds': room['occupiedBeds'] ?? 0,
        'totalBeds': roomBeds.length,
        'beds': roomBeds,
      };
    }).toList();

    final unassigned = beds
        .where((b) =>
            b['roomId'] == null ||
            !rooms.any((r) => r['id']?.toString() == b['roomId']?.toString()))
        .map((b) => {
              'id': b['id'],
              'label': b['label'] ?? 'سرير',
              'status': b['status'] ?? 'vacant',
              'tenantEmail': b['tenantEmail'],
            })
        .toList();

    return {
      'propertyId': property['id'],
      'propertyTitle': property['title'],
      'accommodationType': property['accommodationType'] ?? 'bed',
      'totalRooms': treeRooms.length,
      'totalBeds': beds.length,
      'vacantBeds': beds.where((b) => b['status'] == 'vacant').length,
      'occupiedBeds': beds.where((b) => b['status'] == 'occupied').length,
      'rooms': treeRooms,
      'unassignedBeds': unassigned,
    };
  }

  /// جلب شجرة عقار بالمعرّف.
  static Future<Map<String, dynamic>?> getTreeForProperty(
    String propertyId,
  ) async {
    final property = await DataService.findPropertyById(propertyId);
    if (property == null) return null;
    return buildTree(property);
  }

  /// جلب كل أشجار عقارات المالك.
  static Future<List<Map<String, dynamic>>> getOwnerTrees(String ownerId) async {
    final properties = await DataService.getOwnerProperties(ownerId);
    return properties
        .where((p) {
          final t = p['accommodationType']?.toString() ?? 'full_unit';
          return t == 'bed' || t == 'shared_room';
        })
        .map(buildTree)
        .toList();
  }

  /// تحديث حالة سرير.
  static Future<bool> updateBedStatus({
    required String propertyId,
    required String bedId,
    required String status,
    String? tenantEmail,
    String? tenantName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final props = prefs.getStringList('properties') ?? [];
    var updated = false;

    final newProps = props.map((p) {
      final data = Map<String, dynamic>.from(jsonDecode(p) as Map);
      if (data['id']?.toString() != propertyId) return p;

      final beds = List<Map<String, dynamic>>.from(
        data['bedUnits'] as List? ?? [],
      );
      for (var i = 0; i < beds.length; i++) {
        if (beds[i]['id']?.toString() == bedId) {
          beds[i]['status'] = status;
          if (tenantEmail != null) beds[i]['tenantEmail'] = tenantEmail;
          if (tenantName != null) beds[i]['tenantName'] = tenantName;
          if (status == 'vacant') {
            beds[i].remove('tenantEmail');
            beds[i].remove('tenantName');
            beds[i].remove('leaseStart');
            beds[i].remove('leaseEnd');
          }
          updated = true;
        }
      }
      data['bedUnits'] = beds;
      _syncRoomOccupancy(data);
      return jsonEncode(data);
    }).toList();

    if (updated) {
      await prefs.setStringList('properties', newProps);
    }
    return updated;
  }

  static void _syncRoomOccupancy(Map<String, dynamic> property) {
    final beds = List<Map<String, dynamic>>.from(
      property['bedUnits'] as List? ?? [],
    );
    final rooms = List<Map<String, dynamic>>.from(
      property['roomUnits'] as List? ?? [],
    );
    for (var i = 0; i < rooms.length; i++) {
      final roomId = rooms[i]['id']?.toString() ?? '';
      final roomBeds = beds.where((b) => b['roomId']?.toString() == roomId);
      final occupied =
          roomBeds.where((b) => b['status'] == 'occupied').length;
      final total = roomBeds.length;
      rooms[i]['occupiedBeds'] = occupied;
      if (occupied == 0) {
        rooms[i]['status'] = 'vacant';
      } else if (occupied >= total) {
        rooms[i]['status'] = 'full';
      } else {
        rooms[i]['status'] = 'partial';
      }
    }
    property['roomUnits'] = rooms;
  }

  /// الأسرّة الشاغرة غداً (للتخفيض التلقائي).
  static Future<List<Map<String, dynamic>>> getVacantBedsTomorrow(
    String ownerId,
  ) async {
    final trees = await getOwnerTrees(ownerId);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final results = <Map<String, dynamic>>[];

    for (final tree in trees) {
      for (final room in tree['rooms'] as List? ?? []) {
        for (final bed in room['beds'] as List? ?? []) {
          if (bed['status'] == 'vacant') {
            final leaseEnd = bed['leaseEnd']?.toString();
            if (leaseEnd != null) {
              final end = DateTime.tryParse(leaseEnd);
              if (end != null && end.isBefore(tomorrow)) continue;
            }
            results.add({
              'propertyId': tree['propertyId'],
              'propertyTitle': tree['propertyTitle'],
              'roomId': room['id'],
              'roomLabel': room['label'],
              'bedId': bed['id'],
              'bedLabel': bed['label'],
            });
          }
        }
      }
    }
    return results;
  }

  /// أسرّة شاغرة منذ N أيام (للتنبيهات).
  static Future<List<Map<String, dynamic>>> getVacantBedsSinceDays(
    String ownerId,
    int days,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hierarchyKey);
    final vacantSince = <String, String>{};
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          vacantSince[e.key] = e.value.toString();
        }
      } catch (_) {}
    }

    final trees = await getOwnerTrees(ownerId);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final results = <Map<String, dynamic>>[];

    for (final tree in trees) {
      for (final room in tree['rooms'] as List? ?? []) {
        for (final bed in room['beds'] as List? ?? []) {
          if (bed['status'] != 'vacant') {
            vacantSince.remove('${tree['propertyId']}_${bed['id']}');
            continue;
          }
          final key = '${tree['propertyId']}_${bed['id']}';
          vacantSince.putIfAbsent(key, () => DateTime.now().toIso8601String());
          final since = DateTime.tryParse(vacantSince[key] ?? '');
          if (since != null && since.isBefore(cutoff)) {
            results.add({
              'propertyId': tree['propertyId'],
              'propertyTitle': tree['propertyTitle'],
              'bedId': bed['id'],
              'bedLabel': bed['label'],
              'vacantSince': vacantSince[key],
              'vacantDays': DateTime.now().difference(since).inDays,
            });
          }
        }
      }
    }

    await prefs.setString(_hierarchyKey, jsonEncode(vacantSince));
    return results;
  }

  /// بذر تواريخ شغور قديمة للعرض التجريبي (3+ أيام).
  static Future<void> seedDemoVacancyTracking(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hierarchyKey);
    final vacantSince = <String, String>{};
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final e in map.entries) {
          vacantSince[e.key] = e.value.toString();
        }
      } catch (_) {}
    }

    final fourDaysAgo =
        DateTime.now().subtract(const Duration(days: 4)).toIso8601String();
    final trees = await getOwnerTrees(ownerId);
    for (final tree in trees) {
      for (final room in tree['rooms'] as List? ?? []) {
        for (final bed in room['beds'] as List? ?? []) {
          if (bed['status'] == 'vacant') {
            final key = '${tree['propertyId']}_${bed['id']}';
            vacantSince.putIfAbsent(key, () => fourDaysAgo);
          }
        }
      }
    }
    await prefs.setString(_hierarchyKey, jsonEncode(vacantSince));
  }
}
