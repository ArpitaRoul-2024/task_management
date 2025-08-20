import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ActivityManager {
  static const String _activityKey = 'user_activity';

  static Future<void> logActivity(String event) async {
    final prefs = await SharedPreferences.getInstance();
    final activityList = prefs.getStringList(_activityKey)?.map((e) => ActivityLog.fromJson(jsonDecode(e))).toList() ?? [];
    activityList.add(ActivityLog(event, DateTime.now()));
    await prefs.setStringList(_activityKey, activityList.map((e) => jsonEncode(e.toJson())).toList());
  }
}

class ActivityLog {
  final String event;
  final DateTime timestamp;

  ActivityLog(this.event, this.timestamp);

  Map<String, dynamic> toJson() => {
    'event': event,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    json['event'] as String,
    DateTime.parse(json['timestamp'] as String),
  );
}