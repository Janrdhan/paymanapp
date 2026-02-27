import 'package:flutter/foundation.dart';

class Analytics {
  static void track(String event, {Map<String, dynamic>? params}) {
    debugPrint("📊 $event | $params");
  }
}
