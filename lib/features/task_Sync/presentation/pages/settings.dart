import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // optional - for openAppSettings()
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/colors.dart'; // optional - for support link

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Replace these with real values if needed
  final String appVersion = '9.0.5, v25';
  final String companyCode = '1895779';
  final String kioskPin = '9323';

  bool _notificationsEnabled = true;
  bool _loading = true;

  static const String _prefsKeyNotifications = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadNotificationPref();
  }

  Future<void> _loadNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKeyNotifications);
    // default to true (match your app's sensible default)
    setState(() {
      _notificationsEnabled = enabled ?? true;
      _loading = false;
    });
  }

  Future<void> _setNotificationPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyNotifications, enabled);
    setState(() => _notificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme:   IconThemeData(color: AppColors.appblue),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon:   Icon(Icons.arrow_back_ios_new, color: AppColors.appblue),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Notifications - tappable + trailing switch
                _buildNotificationTile(),

                // Check for updates
                _buildTile(
                  title: 'Check for updates',
                  onTap: () {
                    // implement update check
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checked for updates')),
                    );
                  },
                ),

                // Divider spacer
                const SizedBox(height: 8),
                Container(height: 8, color: const Color(0xFFF5F5F7)),

                // App version
                _buildTile(
                  title: 'Mobile app version',
                  trailingText: appVersion,
                ),

                // Company code
                _buildTile(
                  title: 'Company code',
                  trailingText: companyCode,
                ),

                // Kiosk PIN
                _buildTile(
                  title: 'Kiosk PIN code',
                  trailingText: kioskPin,
                ),

                // Divider spacer
                const SizedBox(height: 8),
                Container(height: 8, color: const Color(0xFFF5F5F7)),

                // Terms of Use
                _buildTile(
                  title: 'Terms of Use',
                  onTap: () {
                    // Navigate to terms page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open Terms of Use')),
                    );
                  },
                ),

                // Privacy Policy
                _buildTile(
                  title: 'Privacy Policy',
                  onTap: () {
                    // Navigate to privacy page
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Open Privacy Policy')),
                    );
                  },
                ),

                const SizedBox(height: 28),
                // Footer text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        const TextSpan(text: 'To delete your account '),
                        TextSpan(
                          text: 'press here',
                          style:  TextStyle(
                            color: AppColors.appblue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _showConfirmDeleteDialog(context);
                            },
                        ),
                        const TextSpan(text: ' or '),
                        TextSpan(
                          text: 'contact support',
                          style:   TextStyle(
                            color: AppColors.appblue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              _launchSupport();
                            },
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile() {
    return Column(
      children: [
        ListTile(
          title: const Text('Notifications', style: TextStyle(fontSize: 16)),
          subtitle: Text(_notificationsEnabled ? 'Enabled' : 'Disabled', style: const TextStyle(color: Colors.grey)),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (val) async {
              // If turning ON, optionally ask the user to grant OS permission or show details
              if (val) {
                // Optionally open a small dialog to explain
                final granted = await _confirmEnableNotifications();
                if (!granted) return;
              }
              await _setNotificationPref(val);
            },
            activeColor: AppColors.appblue,
          ),
          onTap: () {
            if (_notificationsEnabled) {
              // Navigate to a settings page for notifications (can be extended)
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationDetailPage()));
            } else {
              // If disabled, ask to enable
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Enable notifications?'),
                  content: const Text('Turn on notifications to receive important updates and reminders.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _setNotificationPref(true);
                      },
                      child: const Text('Enable'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildTile({
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: trailingWidget ??
              (trailingText != null
                  ? Text(trailingText, style: const TextStyle(color: Colors.grey))
                  : const Icon(Icons.chevron_right, color: Colors.grey)),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Future<bool> _confirmEnableNotifications() async {
    // Optional: you can show more explanation to the user before enabling.
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Allow notifications?'),
        content: const Text('We use notifications to remind you about tasks and updates. Would you like to enable them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _launchSupport() async {
    // Example: open mailto or support page. Requires url_launcher in pubspec
    const url = 'mailto:support@example.com?subject=Support%20Request';
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open mail app')),
        );
      }
    }
  }

  void _showConfirmDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // implement deletion
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion requested')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

/// Small placeholder screen where you can add channel-level toggles, preview, etc.
class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({super.key});

  Future<void> _openSystemNotificationSettings(BuildContext context) async {
    // Opens OS app settings so the user can grant system-level permission
    final opened = await openAppSettings(); // from permission_handler
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open system settings')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Allow push notifications'),
            subtitle: const Text('System permission and app channels'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openSystemNotificationSettings(context),
          ),
          const Divider(),
          ListTile(
            title: const Text('Task reminders'),
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          const Divider(),
          ListTile(
            title: const Text('Marketing & offers'),
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
        ],
      ),
    );
  }
}
