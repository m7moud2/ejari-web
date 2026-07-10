import 'data_service.dart';
import 'bed_hierarchy_service.dart';

/// تلميحات تسعير ذكية — مقارنة بالمنطقة + تخفيض تلقائي.
class SmartPricingService {
  SmartPricingService._();

  /// تحليل سعر العقار مقارنة بمتوسط المنطقة.
  static Future<Map<String, dynamic>> analyzePrice({
    required String propertyId,
    required double listedPrice,
    String? location,
  }) async {
    final property = await DataService.findPropertyById(propertyId);
    final loc = location ?? property?['location']?.toString() ?? 'القاهرة';
    final trendList = await DataService.getMarketTrends(loc);
    final values = trendList
        .map((e) => (e['value'] as num?)?.toDouble() ?? 0)
        .where((v) => v > 0)
        .toList();
    final areaAvg = values.isEmpty
        ? listedPrice * 0.95
        : values.reduce((a, b) => a + b) / values.length;
    final diff = listedPrice - areaAvg;
    final diffPct = areaAvg > 0 ? (diff / areaAvg * 100) : 0;

    String verdict;
    String verdictAr;
    String color;
    if (diffPct > 15) {
      verdict = 'high';
      verdictAr = 'السعر ده عالي — أعلى ${diffPct.toStringAsFixed(0)}% من متوسط المنطقة';
      color = 'red';
    } else if (diffPct > 5) {
      verdict = 'slightly_high';
      verdictAr = 'السعر أعلى قليلاً من متوسط $loc';
      color = 'orange';
    } else if (diffPct < -15) {
      verdict = 'low';
      verdictAr = 'السعر ده قليل — أقل ${(-diffPct).toStringAsFixed(0)}% من المتوسط';
      color = 'green';
    } else if (diffPct < -5) {
      verdict = 'slightly_low';
      verdictAr = 'السعر أقل قليلاً — فرصة جذب مستأجرين';
      color = 'teal';
    } else {
      verdict = 'fair';
      verdictAr = 'السعر مناسب لمتوسط $loc ✓';
      color = 'blue';
    }

    final suggestedPrice = _suggestedPrice(listedPrice, areaAvg, verdict);

    return {
      'propertyId': propertyId,
      'listedPrice': listedPrice,
      'areaAverage': areaAvg.roundToDouble(),
      'difference': diff.roundToDouble(),
      'differencePercent': diffPct,
      'verdict': verdict,
      'verdictAr': verdictAr,
      'color': color,
      'suggestedPrice': suggestedPrice,
      'location': loc,
      'trends': trendList,
    };
  }

  /// اقتراح تخفيض لسرير/غرفة شاغرة غداً.
  static Future<Map<String, dynamic>?> suggestVacancyDiscount(
    String ownerId,
  ) async {
    final vacant = await BedHierarchyService.getVacantBedsTomorrow(ownerId);
    if (vacant.isEmpty) return null;

    final bed = vacant.first;
    final property =
        await DataService.findPropertyById(bed['propertyId']?.toString() ?? '');
    if (property == null) return null;

    final basePrice = (property['perBedPricing']?['daily'] as num?)?.toDouble() ??
        (property['dynamicPricing']?['daily'] as num?)?.toDouble() ??
        150.0;
    const discountPct = 15.0;
    final discounted = (basePrice * (1 - discountPct / 100)).roundToDouble();

    return {
      'bedId': bed['bedId'],
      'bedLabel': bed['bedLabel'],
      'propertyTitle': bed['propertyTitle'],
      'originalPrice': basePrice,
      'discountedPrice': discounted,
      'discountPercent': discountPct,
      'reason': 'سرير شاغر غداً — اقتراح تخفيض ${discountPct.toStringAsFixed(0)}%',
      'autoApply': false,
    };
  }

  /// تطبيق تخفيض تلقائي على سرير شاغر.
  static Future<bool> applyAutoDiscount({
    required String propertyId,
    required double discountPercent,
  }) async {
    final property = await DataService.findPropertyById(propertyId);
    if (property == null) return false;

    final pricingMap = property['dynamicPricing'] as Map<String, dynamic>? ??
        property['perBedPricing'] as Map<String, dynamic>? ??
        {};
    final daily = (pricingMap['daily'] as num?)?.toDouble() ?? 150;
    final weekly = (pricingMap['weekly'] as num?)?.toDouble() ?? daily * 6;
    final monthly = (pricingMap['monthly'] as num?)?.toDouble() ?? daily * 25;

    final factor = 1 - (discountPercent / 100);
    await DataService.setDynamicPricing(
      propertyId,
      daily: (daily * factor).roundToDouble(),
      weekly: (weekly * factor).roundToDouble(),
      monthly: (monthly * factor).roundToDouble(),
      seasonalLabel: 'تخفيض تلقائي — شاغر',
    );
    return true;
  }

  /// اقتراح AI rule-based للمالك.
  static Future<String> occupancySuggestion(String ownerId) async {
    final trees = await BedHierarchyService.getOwnerTrees(ownerId);
    if (trees.isEmpty) {
      return 'لا توجد وحدات مشتركة — أضف عقاراً بأسرّة لرؤية اقتراحات الإشغال.';
    }

    var totalBeds = 0;
    var vacantBeds = 0;
    for (final tree in trees) {
      totalBeds += (tree['totalBeds'] as num?)?.toInt() ?? 0;
      vacantBeds += (tree['vacantBeds'] as num?)?.toInt() ?? 0;
    }

    final occupancy =
        totalBeds > 0 ? ((totalBeds - vacantBeds) / totalBeds * 100) : 0;

    if (vacantBeds == 0) {
      return 'إشغالك 100% 🎉 — فكّر برفع السعر 5-10% للأسرّة الجديدة.';
    }

    if (occupancy < 50) {
      final discount = await suggestVacancyDiscount(ownerId);
      if (discount != null) {
        return 'عندك $vacantBeds سرير فاضي — ${discount['reason']}. '
            'اقترح ${discount['discountedPrice']} ج.م/يوم بدلاً من ${discount['originalPrice']} ج.م.';
      }
    }

    if (vacantBeds >= 1) {
      return 'عندك سرير فاضي بكرة — خفّض السعر 10-15% لملء الفراغ بسرعة.';
    }

    return 'نسبة إشغالك ${occupancy.toStringAsFixed(0)}% — السعر الحالي مناسب.';
  }

  static double _suggestedPrice(
    double listed,
    double avg,
    String verdict,
  ) {
    switch (verdict) {
      case 'high':
      case 'slightly_high':
        return (avg * 1.05).roundToDouble();
      case 'low':
      case 'slightly_low':
        return (avg * 0.95).roundToDouble();
      default:
        return listed;
    }
  }
}
