
import 'dart:async';

import 'package:flutter/services.dart';

class ScanDocument {
  static const MethodChannel _channel =
      const MethodChannel('scan_document');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
