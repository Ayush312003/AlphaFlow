import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.blackmere.alphaflow.widget');
  
  /// Notifies the Android widget to update when custom tasks change
  static Future<void> updateWidget() async {
    try {
      await _channel.invokeMethod('updateWidget');
      print('WidgetService: Successfully notified widget to update');
    } catch (e) {
      print('WidgetService: Error updating widget: $e');
    }
  }
  
  /// Sends data to the widget (if needed in the future)
  static Future<void> sendDataToWidget(Map<String, dynamic> data) async {
    try {
      await _channel.invokeMethod('sendDataToWidget', data);
    } catch (e) {
      print('WidgetService: Error sending data to widget: $e');
    }
  }
} 