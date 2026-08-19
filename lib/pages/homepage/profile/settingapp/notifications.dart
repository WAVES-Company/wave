import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wave/generated/l10n.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const String PREF_NOTIFICATIONS_ENABLED = 'notifications_enabled';
const String PREF_SOUND_ENABLED = 'sound_enabled';
const String PREF_VIBRATION_ENABLED = 'vibration_enabled';
const String PREF_SHOW_TEXT_ENABLED = 'show_text_enabled';

const String _notificationChannelId = 'wave_notifications';

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_stat_name');
      
  const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

Future<bool> checkNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  if (Platform.isIOS) {
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final settings = await iosPlugin?.checkPermissions();

    if (settings == null) {
      return false;
    }

    return settings.isEnabled;
  }

  return false;
}

Future<bool> requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  if (Platform.isIOS) {
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    final result = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return result ?? false;
  }

  return false;
}

class NotificationPreferences {
  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_NOTIFICATIONS_ENABLED, value);
  }

  static Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_NOTIFICATIONS_ENABLED) ?? true;
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_SOUND_ENABLED, value);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_SOUND_ENABLED) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_VIBRATION_ENABLED, value);
  }

  static Future<bool> getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_VIBRATION_ENABLED) ?? true;
  }

  static Future<void> setShowTextEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_SHOW_TEXT_ENABLED, value);
  }

  static Future<bool> getShowTextEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_SHOW_TEXT_ENABLED) ?? true;
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PREF_NOTIFICATIONS_ENABLED);
    await prefs.remove(PREF_SOUND_ENABLED);
    await prefs.remove(PREF_VIBRATION_ENABLED);
    await prefs.remove(PREF_SHOW_TEXT_ENABLED);
  }
}

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = false;
  bool _soundEnabled = false;
  bool _vibrationEnabled = false;
  bool _showText = false;
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      bool notificationsEnabled = await NotificationPreferences.getNotificationsEnabled();
      final soundEnabled = await NotificationPreferences.getSoundEnabled();
      final vibrationEnabled = await NotificationPreferences.getVibrationEnabled();
      final showTextEnabled = await NotificationPreferences.getShowTextEnabled();

      final hasPermission = await checkNotificationPermission();

      if (hasPermission && !notificationsEnabled) {
        await NotificationPreferences.setNotificationsEnabled(true);
        notificationsEnabled = true;
      }
      if (!hasPermission && notificationsEnabled) {
        await NotificationPreferences.setNotificationsEnabled(false);
        notificationsEnabled = false;
      }

      if (mounted) {
        setState(() {
          _notificationsEnabled = notificationsEnabled;
          _soundEnabled = soundEnabled;
          _vibrationEnabled = vibrationEnabled;
          _showText = showTextEnabled;
          _isLoading = false;
          if (_notificationsEnabled) {
            _animController.forward();
          } else {
            _animController.reverse();
          }
        });
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final hasPermission = await requestNotificationPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).razuved)),
          );
        }
        return;
      }
      await NotificationPreferences.setNotificationsEnabled(true);
    } else {
      await NotificationPreferences.setNotificationsEnabled(false);
      await NotificationPreferences.setSoundEnabled(false);
      await NotificationPreferences.setVibrationEnabled(false);
      await NotificationPreferences.setShowTextEnabled(false);
    }

    setState(() {
      _notificationsEnabled = value;
      if (!value) {
        _soundEnabled = false;
        _vibrationEnabled = false;
        _showText = false;
        _animController.reverse();
      } else {
        _animController.forward();
      }
    });
  }

  Future<void> _updateSoundSetting(bool value) async {
    setState(() => _soundEnabled = value);
    await NotificationPreferences.setSoundEnabled(value);
  }

  Future<void> _updateVibrationSetting(bool value) async {
    setState(() => _vibrationEnabled = value);
    await NotificationPreferences.setVibrationEnabled(value);
  }

  Future<void> _updateShowTextSetting(bool value) async {
    setState(() => _showText = value);
    await NotificationPreferences.setShowTextEnabled(value);
  }
  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18))),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _buildBody(context),
    );
  }
  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Center(child: Text(S.of(context).uvedv, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
          const SizedBox(height: 80),
          Container(
            constraints: const BoxConstraints(minHeight: 60),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSwitchRow(
                  label: S.of(context).uvedv,
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  axisAlignment: -1,
                  child: Column(
                    children: [
                      Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
                      _buildSwitchRow(
                        label: S.of(context).zv,
                        value: _soundEnabled,
                        onChanged: _updateSoundSetting,
                      ),
                      Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
                      _buildSwitchRow(
                        label: S.of(context).vib,
                        value: _vibrationEnabled,
                        onChanged: _updateVibrationSetting,
                      ),
                      Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
                      _buildSwitchRow(
                        label: S.of(context).tx,
                        value: _showText,
                        onChanged: _updateShowTextSetting,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// this code was written by maksy