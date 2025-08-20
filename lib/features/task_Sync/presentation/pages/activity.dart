import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:task_management/features/task_Sync/presentation/pages/profile.dart';

import '../../../../core/constants/colors.dart'; // Import ProfileScreen

// Activity logging manager
class ActivityManager {
  static const String _activityKey = 'user_activity';

  static Future<void> logActivity(String event) async {
    final prefs = await SharedPreferences.getInstance();
    final activityList =
        prefs
            .getStringList(_activityKey)
            ?.map((e) => ActivityLog.fromJson(jsonDecode(e)))
            .toList() ??
        [];
    activityList.add(ActivityLog(event, DateTime.now()));
    await prefs.setStringList(
      _activityKey,
      activityList.map((e) => jsonEncode(e.toJson())).toList(),
    );
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

class Activity extends StatefulWidget {
  const Activity({super.key});

  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity> {
  List<ActivityLog> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final activityList =
        prefs
            .getStringList(ActivityManager._activityKey)
            ?.map((e) => ActivityLog.fromJson(jsonDecode(e)))
            .toList() ??
        [];
    setState(() {
      _activities = activityList;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.appblue),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.appblue,
                ),
              ),
              automaticallyImplyLeading: false, // Disable default back button
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Scaffold(
                    body: Center(
                      child: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/c/c7/Loading_2.gif',
                        width: 100,
                        height: 100,
                      ),
                    ),
                  )
                : _activities.isEmpty
                ? const Center(
                    child: Text(
                      'No activity recorded yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Column(
                    children: _activities.map((activity) {
                      return Hero(
                            tag: 'activity-card-${activity.timestamp}',
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(
                                        color: Colors.white30,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        child: Icon(
                                          Icons.history,
                                          color: AppColors.appblue,
                                        ),
                                      ),
                                      title: Text(
                                        activity.event,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${activity.timestamp.toLocal()}',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.chevron_right,
                                        color: AppColors.appblue,
                                        size: 16,
                                      ),
                                      onTap: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Details for ${activity.event}',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .scale(duration: 500.ms);
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
