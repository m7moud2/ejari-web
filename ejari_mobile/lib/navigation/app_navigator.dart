import 'package:flutter/material.dart';

/// مفتاح تنقّل عام — للروابط العميقة ونقرات الإشعارات.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class AppNavigator {
  AppNavigator._();

  static BuildContext? get context => rootNavigatorKey.currentContext;

  static Future<T?> push<T>(Route<T> route) {
    return rootNavigatorKey.currentState?.push(route) ?? Future.value(null);
  }

  static void pop<T>([T? result]) {
    rootNavigatorKey.currentState?.pop(result);
  }
}
