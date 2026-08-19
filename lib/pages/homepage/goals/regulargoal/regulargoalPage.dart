import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wave/generated/l10n.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart' as inset;
import 'package:wave/storage/secure_goals.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Importance;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln show Importance;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:wave/storage/model/planner_model.dart';

class TaskModel {
  final String id;
  final String title;
  final DateTime? reminderTime;
  final bool isCompleted;
  final DateTime createdAt;
  final Importance? importance;
  final String? emoji;
  final String? goalId;

  TaskModel({
    String? id,
    required this.title,
    this.reminderTime,
    this.isCompleted = false,
    DateTime? createdAt,
    this.importance,
    this.emoji,
    this.goalId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'reminderTime': reminderTime?.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'importance': importance?.name,
      'emoji': emoji,
      'goalId': goalId,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      importance: json['importance'] == null
          ? null
          : Importance.values.firstWhere(
              (e) => e.name == json['importance'],
              orElse: () => Importance.low,
            ),
      emoji: json['emoji'] as String?,
      goalId: json['goalId'] as String?,
    );
  }

  TaskModel copyWith({
    String? id,
    String? title,
    DateTime? reminderTime,
    bool? isCompleted,
    DateTime? createdAt,
    Importance? importance,
    String? emoji,
    String? goalId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      importance: importance ?? this.importance,
      emoji: emoji ?? this.emoji,
      goalId: goalId ?? this.goalId,
    );
  }
}

// notifications
class TaskNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static const String _channelId = 'wave_notifications';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    try {
      final String tzName = await _getSystemTimeZone();
      tz.setLocalLocation(tz.getLocation(tzName));
      print('The time zone has been set: $tzName');
    } catch (e) {
      print('Unable to determine time zone, leaving UTC');
    }

    const androidInit = AndroidInitializationSettings('ic_stat_name');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);
    await _notificationsPlugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final notifStatus = await Permission.notification.request();
      print('Notifications: $notifStatus');

      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      print('Accurate alarm clocks: $exactAlarmStatus');

      final batteryOptStatus =
          await Permission.ignoreBatteryOptimizations.request();
      print('Battery optimization: $batteryOptStatus');

      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('notifications_enabled')) {
        await prefs.setBool('notifications_enabled', true);
      }
      if (!prefs.containsKey('sound_enabled')) {
        await prefs.setBool('sound_enabled', true);
      }
      if (!prefs.containsKey('vibration_enabled')) {
        await prefs.setBool('vibration_enabled', true);
      }
      if (!prefs.containsKey('show_text_enabled')) {
        await prefs.setBool('show_text_enabled', true);
      }

      await _createNotificationChannel();
    }

    _isInitialized = true;
  }

  static Future<String> _getSystemTimeZone() async {
    try {
      final dynamic tzInfo = await FlutterTimezone.getLocalTimezone();

      if (tzInfo is String) {
        return tzInfo;
      }

      final String info = tzInfo.toString();

      try {
        final dynamic name = tzInfo.name;
        if (name is String && name.isNotEmpty) {
          return name;
        }
      } catch (_) {}

      final match = RegExp(r'\(([^)]+)\)').firstMatch(info);
      if (match != null && match.group(1)!.isNotEmpty) {
        return match.group(1)!;
      }
    } catch (e) {
      print('Unable to determine system time zone: $e');
    }

    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;

    if (hours == 0) {
      return 'Etc/GMT';
    }

    return 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
  }

  static Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation
            <AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    final channel = AndroidNotificationChannel(
      _channelId,
      S.current.nap,
      description: S.current.uvedozad,
      importance: fln.Importance.max,
      enableVibration: true,
      playSound: true,
      enableLights: false,
    );
    await androidPlugin.createNotificationChannel(channel);
  }

  static Future<bool> _getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  static Future<bool> _getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sound_enabled') ?? true;
  }

  static Future<bool> _getVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('vibration_enabled') ?? true;
  }

  static Future<bool> _getShowTextEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('show_text_enabled') ?? false;
  }

  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    await initialize();

    final notificationsEnabled = await _getNotificationsEnabled();
    if (!notificationsEnabled) {
      print('Notifications are disabled in the settings.');
      return;
    }

    if (reminderTime.isBefore(DateTime.now())) {
      print('The reminder time has already passed.: $reminderTime');
      return;
    }

    final soundEnabled = await _getSoundEnabled();
    final vibrationEnabled = await _getVibrationEnabled();
    final showTextEnabled = await _getShowTextEnabled();

    final scheduledDate = tz.TZDateTime(
      tz.local,
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      reminderTime.hour,
      reminderTime.minute,
      reminderTime.second,
    );

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print('TZDateTime in the past: $scheduledDate');
      return;
    }
    final notificationBody =
        showTextEnabled ? taskTitle : S.current.srttkst;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      S.current.nap,
      channelDescription: S.current.uvedozad,
      importance: fln.Importance.max,
      priority: Priority.high,
      enableVibration: vibrationEnabled,
      playSound: soundEnabled,
      enableLights: false,
      visibility: showTextEnabled
          ? NotificationVisibility.public
          : NotificationVisibility.secret,
      styleInformation:
          showTextEnabled ? const BigTextStyleInformation('') : null,
    );

    final iosDetails = DarwinNotificationDetails(
      sound: soundEnabled ? 'default' : null,
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );

    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notificationsPlugin.zonedSchedule(
      taskId.hashCode,
      S.current.napozad,
      notificationBody,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId,
    );

    print('Notification SCHEDULED: "$taskTitle" on $scheduledDate');
  }

  static Future<void> cancelTaskReminder(String taskId) async {
    await _notificationsPlugin.cancel(taskId.hashCode);
    print('The notification has been cancelled.: $taskId');
  }

  static Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    print('All notifications canceled');
  }
}

class RegularGoalPage extends StatefulWidget {
  final GoalModel goal;

  const RegularGoalPage({super.key, required this.goal});

  @override
  State<RegularGoalPage> createState() => _RegularGoalPageState();
}

class _RegularGoalPageState extends State<RegularGoalPage> {
  late GoalModel goal;
  List<TaskModel> tasks = [];
  bool _isInitialized = false;
  late ScrollController _tasksScrollController;

  bool _isDateExpired(String dateStr) {
    try {
      final parts = dateStr.split('.');
      if (parts.length != 3) return false;
      final date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return date.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));
    } catch (_) {
      return false;
    }
  }

  bool _isTaskExpired(TaskModel task) {
    if (task.reminderTime == null) return false;

    if (task.isCompleted) return false;

    return task.reminderTime!.isBefore(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    goal = widget.goal;
    _tasksScrollController = ScrollController();

    if (goal.id.isEmpty) {
      print('ERROR: GoalModel do not have id!');
    }
    _initializeAndLoadTasks();
  }

  @override
  void dispose() {
    _tasksScrollController.dispose();
    super.dispose();
  }

  Future<void> _showPermissionIntroIfNeeded() async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('permission_intro_shown') ?? false;
    if (shown) return;
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.4),
            width: 1,
          ),
        ),
        title: Text(
          S.of(context).permIntroTitle,
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.of(context).permIntroDesc),
              const SizedBox(height: 12),
              Text('1. ${S.of(context).permIntroNotif}'),
              const SizedBox(height: 8),
              Text('2. ${S.of(context).permIntroAlarm}'),
              const SizedBox(height: 8),
              Text('3. ${S.of(context).permIntroBattery}'),
              const SizedBox(height: 12),
              Text(S.of(context).permIntroFooter),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              S.of(context).permIntroOk,
                style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );

    await prefs.setBool('permission_intro_shown', true);
  }

  Future<void> _initializeAndLoadTasks() async {
    try {
      await _showPermissionIntroIfNeeded();
      await TaskNotificationService.initialize();
      await loadTasks();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error during initialization: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).err)),
        );
      }
    }
  }

  Future<void> loadTasks() async {
    try {
      final loadedTasks =
          await SecureGoalsStorageService.getGoalTasks(goal.id);
      loadedTasks.sort((a, b) {
        if (a.reminderTime == null && b.reminderTime == null) {
          return 0;
        }

        if (a.reminderTime == null) {
          return 1;
        }

        if (b.reminderTime == null) {
          return -1;
        }

        return a.reminderTime!.compareTo(b.reminderTime!);
      });

      if (!mounted) return;

      setState(() {
        tasks = loadedTasks;
      });

      for (final task in loadedTasks) {
        if (task.reminderTime != null && !task.isCompleted) {
          unawaited(
            TaskNotificationService.scheduleTaskReminder(
              taskId: task.id,
              taskTitle: task.title,
              reminderTime: task.reminderTime!,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading tasks: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).err)),
        );
      }
    }
  }

  String _formatReminderTime(TaskModel task) {
    if (task.reminderTime == null) return S.of(context).bznp;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final reminderDate = DateTime(
      task.reminderTime!.year,
      task.reminderTime!.month,
      task.reminderTime!.day,
    );

    final time =
        '${task.reminderTime!.hour.toString().padLeft(2, '0')}:${task.reminderTime!.minute.toString().padLeft(2, '0')}';

    if (reminderDate == today) {
      return '${S.of(context).tdy} $time';
    } else if (reminderDate == tomorrow) {
      return '${S.of(context).tmrw} $time';
    } else {
      return '${reminderDate.day.toString().padLeft(2, '0')}.'
    '${reminderDate.month.toString().padLeft(2, '0')} $time';
    }
  }

  void increaseProgress() async {
    if (goal.progress < 1.0) {
      if (!mounted) return;
      setState(() {
        goal = goal.copyWith(
          progress: (goal.progress + 0.1).clamp(0.0, 1.0),
        );
      });
      try {
        await SecureGoalsStorageService.updateGoal(goal);
      } catch (e) {
        print('Error updating goal: $e');
      }
    }
  }

  void decreaseProgress() async {
    if (goal.progress > 0.0) {
      if (!mounted) return;
      setState(() {
        goal = goal.copyWith(
          progress: (goal.progress - 0.1).clamp(0.0, 1.0),
        );
      });
      try {
        await SecureGoalsStorageService.updateGoal(goal);
      } catch (e) {
        print('Error updating goal: $e');
      }
    }
  }

  void addTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddGoalTaskSheet(
          goalEmoji: goal.emoji,
          onAddTask: (title, reminderTime, importance, emoji) async {
            if (goal.id.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).err)),
                );
              }
              return;
            }
            final newTask = TaskModel(
              title: title,
              reminderTime: reminderTime,
              importance: importance,
              emoji: emoji,
            );
            try {
              await SecureGoalsStorageService.saveGoalTask(goal.id, newTask);
              if (!mounted) return;
              if (reminderTime != null) {
                await TaskNotificationService.scheduleTaskReminder(
                  taskId: newTask.id,
                  taskTitle: newTask.title,
                  reminderTime: reminderTime,
                );
              }
              if (!mounted) return;
              await loadTasks();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).add)),
              );
            } catch (e) {
              print('Error adding task: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).err)),
                );
              }
            }
          },
        );
      },
    );
  }

  void openEditTaskSheet(int index) {
    if (index >= tasks.length) return;
    final task = tasks[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _AddGoalTaskSheet(
          goalEmoji: goal.emoji,
          existingTask: task,
          onAddTask: (title, reminderTime, importance, emoji) async {
            final updated = task.copyWith(
              title: title,
              reminderTime: reminderTime,
              importance: importance,
              emoji: emoji,
            );
            try {
              if (updated.isCompleted) {
                await TaskNotificationService.cancelTaskReminder(updated.id);
              } else if (reminderTime != null) {
                await TaskNotificationService.scheduleTaskReminder(
                  taskId: updated.id,
                  taskTitle: updated.title,
                  reminderTime: reminderTime,
                );
              } else {
                await TaskNotificationService.cancelTaskReminder(updated.id);
              }
              await SecureGoalsStorageService.updateGoalTask(goal.id, updated);
              if (!mounted) return;
              await loadTasks();
            } catch (e) {
              print('Error updating task: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).err)),
                );
              }
            }
          },
        );
      },
    );
  }

  void _shareTask(TaskModel task) {

    String dateTimeStr = '';
    if (task.reminderTime != null) {
      final d = task.reminderTime!;
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      final timeStr =
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      dateTimeStr = '\n${S.of(context).dat} $dateStr\n${S.of(context).vrem} $timeStr';
    }

    final text = S.of(context).zadach;

    Share.share(text);
  }

  Future<void> _showTaskMenu({
    required BuildContext context,
    required Offset globalPosition,
    required int index,
  }) async {
    if (index >= tasks.length) return;
    final task = tasks[index];
    final selected = await showMenu(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(34),
      ),
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Text(
            S.of(context).izmen,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        PopupMenuItem(
          value: 'share',
          child: Text(
            S.of(context).pod,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            S.of(context).udalit,
            style: const TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (selected == 'edit') {
      openEditTaskSheet(index);
    } else if (selected == 'share') {
      _shareTask(task);
    } else if (selected == 'delete') {
      deleteTask(index);
    }
  }

  void toggleTaskCompletion(int index) async {
    if (index >= tasks.length) {
      print('ERROR: index $index out of range');
      return;
    }
    final task = tasks[index];
    if (!mounted) return;
    setState(() {
      tasks[index] = task.copyWith(isCompleted: !task.isCompleted);
    });
    try {
      if (tasks[index].isCompleted) {
        await TaskNotificationService.cancelTaskReminder(task.id);
      } else if (task.reminderTime != null) {
        await TaskNotificationService.scheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          reminderTime: task.reminderTime!,
        );
      }
      if (!mounted) return;
      await SecureGoalsStorageService.updateGoalTask(goal.id, tasks[index]);
    } catch (e) {
      print('Error toggling task completion: $e');
    }
  }

  void deleteTask(int index) async {
    if (index >= tasks.length) {
      print('ERROR: index $index out of range');
      return;
    }
    final taskId = tasks[index].id;
    try {
      await TaskNotificationService.cancelTaskReminder(taskId);
      if (!mounted) return;
      setState(() {
        tasks.removeAt(index);
      });
      await SecureGoalsStorageService.deleteGoalTask(goal.id, taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).delete)),
        );
      }
    } catch (e) {
      print('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).err)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDone = goal.progress >= 1.0;
    return Scaffold(
      appBar: AppBar(),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    decoration: inset.BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        inset.BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                          inset: true,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 5),
                              Text(
                                goal.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: decreaseProgress,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Theme.of(context).cardColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .shadowColor,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '−',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      child: LinearProgressIndicator(
                                        value: goal.progress,
                                        minHeight: 6,
                                        backgroundColor:
                                            Colors.grey.withOpacity(0.2),
                                        valueColor:
                                            const AlwaysStoppedAnimation
                                                <Color>(
                                          Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: increaseProgress,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            Theme.of(context).cardColor,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .shadowColor,
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(goal.progress * 100).toStringAsFixed(0)}%',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(
                                          255, 110, 110, 110),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    "•",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(
                                          255, 110, 110, 110),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    S.of(context).dd,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _isDateExpired(goal.date)
                                          ? Colors.red
                                          : const Color.fromARGB(
                                              255, 110, 110, 110),
                                    ),
                                  ),
                                  Text(
                                    goal.date,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _isDateExpired(goal.date)
                                          ? Colors.red
                                          : const Color.fromARGB(
                                              255, 110, 110, 110),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 500),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          S.of(context).zad,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(
                          color: Colors.grey.withOpacity(0.3),
                          thickness: 1,
                          height: 25,
                        ),
                        Expanded(
                          child: tasks.isEmpty
                              ? _buildEmptyState()
                              : _buildTasksList(),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: addTask,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(34),
                              ),
                            ),
                            child: Text(
                              S.of(context).dob,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).nz,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 110, 110, 110),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            S.of(context).dobpz,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 110, 110, 110),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList() {
    return RawScrollbar(
      controller: _tasksScrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(10),
      child: ListView.builder(
        controller: _tasksScrollController,
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          if (index >= tasks.length) return const SizedBox.shrink();
          final task = tasks[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTaskCard(task, index),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF3A3A3D) : Colors.grey[100];
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardBorder = isDark ? const Color(0xFF4A4A4D) : Colors.grey[300]!;
    return GestureDetector(
      onLongPressStart: (details) => _showTaskMenu(
        context: context,
        globalPosition: details.globalPosition,
        index: index,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => toggleTaskCompletion(index),
              borderRadius: BorderRadius.circular(34),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? const Color.fromARGB(255, 117, 117, 117)
                      : Colors.white,
                  border: task.isCompleted
                      ? null
                      : Border.all(
                          color: const Color.fromARGB(255, 117, 117, 117)),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 35)
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted ? Colors.grey : onSurface,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  Text(
                    _formatReminderTime(task),
                    style: TextStyle(
                      fontSize: 15,
                      color: _isTaskExpired(task)
                          ? Colors.red
                          : const Color.fromARGB(255, 110, 110, 110),
                    ),
                  ),
                ],
              ),
            ),
            if (task.importance != null)
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _importanceColor(task.importance!),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddGoalTaskSheet extends StatefulWidget {
  final String goalEmoji;
  final TaskModel? existingTask;
  final Function(String title, DateTime? reminderTime, Importance? importance,
      String? emoji) onAddTask;

  const _AddGoalTaskSheet({
    required this.goalEmoji,
    this.existingTask,
    required this.onAddTask,
  });

  @override
  State<_AddGoalTaskSheet> createState() => _AddGoalTaskSheetState();
}

class _AddGoalTaskSheetState extends State<_AddGoalTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedReminderTime;
  Importance? _selectedImportance;
  bool _isFormValid = false;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _selectedReminderTime = task.reminderTime;
      _selectedImportance = task.importance;
      _isFormValid = task.title.trim().isNotEmpty;
    }
    _titleController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateFormValidity);
    _titleController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      _isFormValid = _titleController.text.trim().isNotEmpty;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedReminderTime != null &&
              !_selectedReminderTime!.isBefore(today)
          ? _selectedReminderTime!
          : today,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedReminderTime != null
          ? TimeOfDay.fromDateTime(_selectedReminderTime!)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedReminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    widget.onAddTask(
      _titleController.text.trim(),
      _selectedReminderTime,
      _selectedImportance,
      widget.goalEmoji,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final surfaceVariant = theme.brightness == Brightness.dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFF5F5F7);
    final headerText = _isEditing
        ? S.of(context).izmenzad
        : S.of(context).nvzad;
    final buttonText = _isEditing
        ? S.of(context).sox
        : S.of(context).dob;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          border: Border.all(
            color: Colors.grey.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _titleController,
                style: TextStyle(color: onSurface),
                decoration: InputDecoration(
                  hintText: S.of(context).nzzad,
                  hintStyle: const TextStyle(
                    color: Color.fromARGB(255, 110, 110, 110),
                    overflow: TextOverflow.ellipsis,
                    fontSize: 18,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(34),
                    borderSide: BorderSide(
                      color: Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(34),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _selectedReminderTime == null
                        ? S.of(context).vvnap
                        : '${_selectedReminderTime!.day.toString().padLeft(2, '0')}.'
                          '${_selectedReminderTime!.month.toString().padLeft(2, '0')}.'
                          '${_selectedReminderTime!.year} '
                          '${_selectedReminderTime!.hour.toString().padLeft(2, '0')}:'
                          '${_selectedReminderTime!.minute.toString().padLeft(2, '0')}',                    
                    style: TextStyle(
                      fontSize: 18,
                      color: _selectedReminderTime == null
                          ? const Color.fromARGB(255, 110, 110, 110)
                          : onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                S.of(context).selectImportance,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: Importance.values.map((importance) {
                  final selected = _selectedImportance == importance;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImportance = selected ? null : importance;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? _importanceColor(importance)
                            : surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : _importanceColor(importance),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _importanceLabel(context, importance),
                            style: TextStyle(
                              fontSize: 16,
                              color: selected ? Colors.white : onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(34),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _importanceColor(Importance importance) {
  switch (importance) {
    case Importance.high:
      return Colors.red;
    case Importance.medium:
      return Colors.orange;
    case Importance.low:
      return Colors.green;
  }
}

String _importanceLabel(BuildContext context, Importance importance) {
  switch (importance) {
    case Importance.high:
      return S.of(context).high;
    case Importance.medium:
      return S.of(context).medium;
    case Importance.low:
      return S.of(context).low;
  }
}

// this code was written by maksy