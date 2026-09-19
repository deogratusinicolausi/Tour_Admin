import 'package:flutter/material.dart';
import '../models/admin_settings_model.dart';
import '../services/admin_profile_service.dart';
import '../utils/colors.dart';
import 'package:provider/provider.dart';
import '../providers/app_theme_provider.dart';
import '../utils/theme_helper.dart';
import '../utils/translate_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = AdminProfileService();

  AdminSettingsModel _settings = AdminSettingsModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.getSettings();
    final themeProvider =
    Provider.of<AppThemeProvider>(context, listen: false);

    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoading = false;
      });

      // ⭐️ Sync na provider
      themeProvider.setDarkMode(settings.darkMode);
      themeProvider.setLanguage(settings.language);
    }
  }

  Future<void> _updateSetting(AdminSettingsModel newSettings) async {
    await _service.saveSettings(newSettings);
    setState(() => _settings = newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      appBar: AppBar(
        title: Text('⚙️ ${context.tr('settings')}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(width * 0.05),
        children: [
          // NOTIFICATIONS
          _sectionTitle('🔔 ${context.tr('notifications')}', width),
          SizedBox(height: height * 0.01),
          _buildSwitchTile(
            icon: Icons.email,
            title: context.tr('email_notifications'),
            subtitle: context.tr('email_notifications_desc'),
            value: _settings.emailNotifications,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(emailNotifications: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: context.tr('push_notifications'),
            subtitle: context.tr('push_notifications_desc'),
            value: _settings.pushNotifications,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(pushNotifications: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.calendar_today,
            title: context.tr('booking_alerts'),
            subtitle: context.tr('booking_alerts_desc'),
            value: _settings.bookingAlerts,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(bookingAlerts: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.person_add,
            title: context.tr('new_user_alerts'),
            subtitle: context.tr('new_user_alerts_desc'),
            value: _settings.newUserAlerts,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(newUserAlerts: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.star,
            title: context.tr('review_alerts'),
            subtitle: context.tr('review_alerts_desc'),
            value: _settings.reviewAlerts,
            onChanged: (v) =>
                _updateSetting(_settings.copyWith(reviewAlerts: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.chat,
            title: context.tr('chat_alerts'),
            subtitle: context.tr('chat_alerts_desc'),
            value: _settings.chatAlerts,
            onChanged: (v) =>
                _updateSetting(_settings.copyWith(chatAlerts: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.payments,
            title: context.tr('payment_alerts'),
            subtitle: context.tr('payment_alerts_desc'),
            value: _settings.paymentAlerts,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(paymentAlerts: v)),
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // SOUND
          _sectionTitle('🔊 ${context.tr('sound_vibration')}', width),
          SizedBox(height: height * 0.01),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: context.tr('sound_effects'),
            subtitle: context.tr('sound_effects_desc'),
            value: _settings.soundEnabled,
            onChanged: (v) =>
                _updateSetting(_settings.copyWith(soundEnabled: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: context.tr('vibration'),
            subtitle: context.tr('vibration_desc'),
            value: _settings.vibrationEnabled,
            onChanged: (v) => _updateSetting(
                _settings.copyWith(vibrationEnabled: v)),
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // APPEARANCE
          _sectionTitle('🎨 ${context.tr('appearance')}', width),
          SizedBox(height: height * 0.01),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: context.tr('dark_mode'),
            subtitle: context.tr('dark_theme_desc'),
            value: _settings.darkMode,
            onChanged: (v) => _updateDarkMode(v),
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // PREFERENCES
          _sectionTitle('⚙️ ${context.tr('preferences')}', width),
          SizedBox(height: height * 0.01),
          _buildDropdownTile(
            icon: Icons.language,
            title: context.tr('language'),
            value: _settings.language,
            options: ['English', 'Swahili', 'French', 'Spanish'],
            // Language dropdown is already updated to sync with AppThemeProvider
            onChanged: (v) => _updateLanguage(v),
            width: width,
          ),
          _buildDropdownTile(
            icon: Icons.attach_money,
            title: context.tr('default_currency'),
            value: _settings.currency,
            options: ['USD', 'TZS', 'EUR', 'GBP'],
            onChanged: (v) =>
                _updateSetting(_settings.copyWith(currency: v)),
            width: width,
          ),
          _buildSwitchTile(
            icon: Icons.refresh,
            title: context.tr('auto_refresh'),
            subtitle: context.tr('auto_refresh_desc'),
            value: _settings.autoRefresh,
            onChanged: (v) =>
                _updateSetting(_settings.copyWith(autoRefresh: v)),
            width: width,
          ),

          SizedBox(height: height * 0.025),

          // DATA
          _sectionTitle('📊 ${context.tr('data')}', width),
          SizedBox(height: height * 0.01),
          _buildActionTile(
            icon: Icons.cleaning_services,
            title: context.tr('clear_cache'),
            subtitle: context.tr('clear_cache_desc'),
            color: Colors.orange,
            onTap: _showClearCacheDialog,
            width: width,
          ),

          SizedBox(height: height * 0.05),

          // APP INFO
          Center(
            child: Column(
              children: [
                Icon(Icons.explore,
                    color: AppColors.primary, size: width * 0.15),
                SizedBox(height: height * 0.01),
                Text('TURIVA Admin',
                    style: TextStyle(
                        fontSize: width * 0.04,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                Text('${context.tr('version')} 1.0.0',
                    style: TextStyle(
                        fontSize: width * 0.03,
                        color: context.textSecondary)),
                SizedBox(height: height * 0.01),
                Text(context.tr('made_with_love_tanzania'),
                    style: TextStyle(
                        fontSize: width * 0.03,
                        color: Colors.grey.shade500)),
              ],
            ),
          ),

          SizedBox(height: height * 0.03),
        ],
      ),
    );
  }

  Future<void> _updateDarkMode(bool v) async {
    await _updateSetting(_settings.copyWith(darkMode: v));
    if (mounted) {
      Provider.of<AppThemeProvider>(context, listen: false)
          .setDarkMode(v);
    }
  }

  Future<void> _updateLanguage(String v) async {
    await _updateSetting(_settings.copyWith(language: v));
    if (mounted) {
      Provider.of<AppThemeProvider>(context, listen: false)
          .setLanguage(v);
    }
  }

  Widget _sectionTitle(String title, double width) {
    return Text(title,
        style: TextStyle(
            fontSize: width * 0.04,
            fontWeight: FontWeight.bold,
            color: context.textPrimary));
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required double width,
  }) {
    final isDark = context.isDark;

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.02),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: width * 0.04),
        secondary: Container(
          padding: EdgeInsets.all(width * 0.025),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: isDark ? AppColors.accentGold : AppColors.primary,
              size: width * 0.05),
        ),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: width * 0.038,
                color: context.textPrimary)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: width * 0.028,
                color: context.textSecondary)),
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
    final isDark = context.isDark;

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.02),
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: width * 0.025),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: isDark ? AppColors.accentGold : AppColors.primary,
                size: width * 0.05),
          ),
          SizedBox(width: width * 0.03),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.038,
                    color: context.textPrimary)),
          ),
          DropdownButton<String>(
            value: value,
            dropdownColor: context.cardBg,
            style: TextStyle(color: context.textPrimary),
            underline: const SizedBox(),
            items: options
                .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    style: TextStyle(color: context.textPrimary))))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    final isDark = context.isDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: width * 0.02),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: width * 0.05),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.038,
                          color: context.textPrimary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: width * 0.028,
                          color: context.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: width * 0.035, color: context.textMuted),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('clear_cache_title')),
        content: Text(context.tr('clear_cache_message')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('cache_cleared')),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(context.tr('clear')),
          ),
        ],
      ),
    );
  }
}