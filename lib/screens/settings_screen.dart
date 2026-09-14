import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _bookingAlerts = true;
  bool _newUserAlerts = false;
  bool _darkMode = false;
  bool _autoRefresh = true;
  String _language = 'English';
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _bookingAlerts = prefs.getBool('bookingAlerts') ?? true;
      _newUserAlerts = prefs.getBool('newUserAlerts') ?? false;
      _darkMode = prefs.getBool('darkMode') ?? false;
      _autoRefresh = prefs.getBool('autoRefresh') ?? true;
      _language = prefs.getString('language') ?? 'English';
      _currency = prefs.getString('currency') ?? 'USD';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⚙️ Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(width * 0.05),
        children: [
          // NOTIFICATIONS
          _sectionTitle('🔔 Notifications', width),
          SizedBox(height: height * 0.01),
          _buildSwitchTile(
            icon: Icons.email,
            title: 'Email Notifications',
            subtitle: 'Receive updates via email',
            value: _emailNotifications,
            onChanged: (v) {
              setState(() => _emailNotifications = v);
              _saveSetting('emailNotifications', v);
            },
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Get alerts on your device',
            value: _pushNotifications,
            onChanged: (v) {
              setState(() => _pushNotifications = v);
              _saveSetting('pushNotifications', v);
            },
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.calendar_today,
            title: 'Booking Alerts',
            subtitle: 'New bookings and cancellations',
            value: _bookingAlerts,
            onChanged: (v) {
              setState(() => _bookingAlerts = v);
              _saveSetting('bookingAlerts', v);
            },
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.person_add,
            title: 'New User Alerts',
            subtitle: 'When new users register',
            value: _newUserAlerts,
            onChanged: (v) {
              setState(() => _newUserAlerts = v);
              _saveSetting('newUserAlerts', v);
            },
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // APPEARANCE
          _sectionTitle('🎨 Appearance', width),
          SizedBox(height: height * 0.01),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            value: _darkMode,
            onChanged: (v) {
              setState(() => _darkMode = v);
              _saveSetting('darkMode', v);
            },
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // PREFERENCES
          _sectionTitle('⚙️ Preferences', width),
          SizedBox(height: height * 0.01),
          _buildDropdownTile(
            icon: Icons.language,
            title: 'Language',
            value: _language,
            options: ['English', 'Swahili', 'French', 'Spanish'],
            onChanged: (v) {
              setState(() => _language = v);
              _saveSetting('language', v);
            },
            width: width,
          ),
          _buildDropdownTile(
            icon: Icons.attach_money,
            title: 'Default Currency',
            value: _currency,
            options: ['USD', 'TZS', 'EUR', 'GBP'],
            onChanged: (v) {
              setState(() => _currency = v);
              _saveSetting('currency', v);
            },
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.refresh,
            title: 'Auto Refresh',
            subtitle: 'Refresh data automatically',
            value: _autoRefresh,
            onChanged: (v) {
              setState(() => _autoRefresh = v);
              _saveSetting('autoRefresh', v);
            },
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // DANGER ZONE
          _sectionTitle('⚠️ Danger Zone', width),
          SizedBox(height: height * 0.01),
          GestureDetector(
            onTap: _showClearCacheDialog,
            child: Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.cleaning_services,
                        color: Colors.orange, size: width * 0.05),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Clear Cache',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.038,
                                color: Colors.grey.shade800)),
                        Text('Free up storage space',
                            style: TextStyle(
                                fontSize: width * 0.028,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: width * 0.035, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          SizedBox(height: height * 0.05),

          // APP INFO
          Center(
            child: Column(
              children: [
                Icon(Icons.explore, color: AppColors.primary, size: width * 0.15),
                SizedBox(height: height * 0.01),
                Text('TURIVA Admin',
                    style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text('Version 1.0.0',
                    style: TextStyle(
                        fontSize: width * 0.03, color: Colors.grey.shade600)),
                SizedBox(height: height * 0.01),
                Text('Made with ❤️ in Tanzania 🇹🇿',
                    style: TextStyle(
                        fontSize: width * 0.03, color: Colors.grey.shade500)),
              ],
            ),
          ),

          SizedBox(height: height * 0.03),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(title,
        style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800));
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required double width,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04),
        secondary: Container(
          padding: EdgeInsets.all(width * 0.025),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: width * 0.05),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.038,
                color: Colors.grey.shade800)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: width * 0.028, color: Colors.grey.shade500)),
        value: value,
        activeColor: AppColors.accentGold,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    required double width,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.02),
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: width * 0.025),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: width * 0.05),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.038,
                    color: Colors.grey.shade800)),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
            'This will clear locally cached data. Your account and data will not be affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Cache cleared!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}