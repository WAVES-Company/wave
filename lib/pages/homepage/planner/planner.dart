import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide Importance;
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln show Importance;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:wave/generated/l10n.dart';
import 'package:wave/pages/homepage/goals/regulargoal/regulargoalPage.dart';
import 'package:wave/storage/model/planner_model.dart';
import 'package:wave/storage/secure_goals.dart';
import 'package:wave/storage/secure_planner.dart';

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

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => PlannerPageState();
}

class PlannerPageState extends State<PlannerPage> {
  final Set<Importance> _activeFilters = {};
  List<PlannerTask> _tasks = [];
  List<TaskModel> _goalTasks = [];
  late DateTime _weekStart;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _initializeAndLoadTasks();
  }

  Future<void> refresh() async {
    await _loadTasks();
  }

  DateTime get _minAllowedWeekStart =>
      _mondayOf(DateTime.now()).subtract(const Duration(days: 7));

  Future<void> _showPermissionIntroIfNeeded() async {
    if (!Platform.isAndroid) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('permission_intro_shown_planner') ?? false;
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

    await prefs.setBool('permission_intro_shown_planner', true);
  }

  Future<void> _initializeAndLoadTasks() async {
    try {
      await _showPermissionIntroIfNeeded();
      await TaskNotificationService.initialize();
      await _loadTasks();
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

  Future<void> _loadTasks() async {
    _tasks = await SecurePlannerStorageService.getTasks();
    for (final task in _tasks) {
      if (!task.completed) {
        await TaskNotificationService.scheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          reminderTime: DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
            task.time.hour,
            task.time.minute,
          ),
        );
      }
    }

    _goalTasks = [];
    final goals = await SecureGoalsStorageService.getGoals();
    for (final goal in goals) {
    final goalTasksList =
        await SecureGoalsStorageService.getGoalTasks(goal.id);

      for (final task in goalTasksList) {
        _goalTasks.add(
          task.copyWith(
            goalId: goal.id,
            emoji: goal.emoji,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveTask(PlannerTask task) async {
    await SecurePlannerStorageService.saveTask(task);

    await TaskNotificationService.scheduleTaskReminder(
      taskId: task.id,
      taskTitle: task.title,
      reminderTime: DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      ),
    );

    await _loadTasks();
  }

  Future<void> _updateTask(PlannerTask task) async {
    await SecurePlannerStorageService.updateTask(task);
    await _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await TaskNotificationService.cancelTaskReminder(id);
    await SecurePlannerStorageService.deleteTask(id);
    await _loadTasks();
  }

  void _toggleFilter(Importance importance) {
    setState(() {
      if (_activeFilters.contains(importance)) {
        _activeFilters.remove(importance);
      } else {
        _activeFilters.add(importance);
      }
    });
  }

  Future<void> _toggleCompleted(PlannerTask task) async {
    final updated = task.copyWith(
      completed: !task.completed,
    );

    if (updated.completed) {
      await TaskNotificationService.cancelTaskReminder(updated.id);
    } else {
      await TaskNotificationService.scheduleTaskReminder(
        taskId: updated.id,
        taskTitle: updated.title,
        reminderTime: DateTime(
          updated.date.year,
          updated.date.month,
          updated.date.day,
          updated.time.hour,
          updated.time.minute,
        ),
      );
    }

    await SecurePlannerStorageService.updateTask(updated);
    await _loadTasks();
  }

  void _shiftWeek(int weeks) {
    setState(() {
      final newStart = _weekStart.add(Duration(days: weeks * 7));
      final minStart = _minAllowedWeekStart;
      _weekStart = newStart.isBefore(minStart) ? minStart : newStart;
    });
  }

  void openAddTaskSheet({DateTime? presetDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddTaskSheet(
          presetDate: presetDate,
          onAdd: _saveTask,
        );
      },
    );
  }

  void _openEditTaskSheet(PlannerTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddTaskSheet(
          existingTask: task,
          onAdd: _saveTask,
        );
      },
    );
  }

  void _shareTask(PlannerTask task, BuildContext context) {
    final dateStr =
        '${task.date.day.toString().padLeft(2, '0')}.${task.date.month.toString().padLeft(2, '0')}.${task.date.year}';
    final timeStr = _formatTime(task.time);

    final text = '${S.of(context).zadach} ${task.title}\n${S.of(context).dat} $dateStr\n${S.of(context).vrem} $timeStr';

    Share.share(text);
  }

  Future<void> _duplicatePlannerTask(PlannerTask task, {required bool toNextDay}) async {
    DateTime? newDate = task.date; 
    if (toNextDay && newDate != null) {
      newDate = newDate.add(const Duration(days: 1));
    }
    final duplicatedTask = task.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: newDate,
      completed: false,
    );
    await SecurePlannerStorageService.saveTask(duplicatedTask); 
    if (newDate != null) {
      await TaskNotificationService.scheduleTaskReminder(
        taskId: duplicatedTask.id,
        taskTitle: duplicatedTask.title,
        reminderTime: newDate,
      );
    }
    await _loadTasks();
  }

  Future<void> _showTaskMenu({
    required BuildContext context,
    required Offset globalPosition,
    required PlannerTask task,
  }) async {

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
          value: 'duplicate',
          child: Text(
            S.of(context).dup,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        PopupMenuItem(
          value: 'duptonextday',
          child: Text(
            S.of(context).duptond,
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
      _openEditTaskSheet(task);
    } else if (selected == 'duplicate') {
      await _duplicatePlannerTask(task, toNextDay: false);
    } else if (selected == 'duptonextday') {
      await _duplicatePlannerTask(task, toNextDay: true);
    } else if (selected == 'share') {
      _shareTask(task, context);
    } else if (selected == 'delete') {
      await _deleteTask(task.id);
    }
  }

  void _openEditGoalTaskSheet(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditGoalTaskSheet(
          existingTask: task,
          onSave: (title, reminderTime, importance) async {
            if (task.goalId == null) return;
            final updated = task.copyWith(
              title: title,
              reminderTime: reminderTime,
              importance: importance,
            );
            if (reminderTime != null && !updated.isCompleted) {
              await TaskNotificationService.scheduleTaskReminder(
                taskId: updated.id,
                taskTitle: updated.title,
                reminderTime: reminderTime,
              );
            } else {
              await TaskNotificationService.cancelTaskReminder(updated.id);
            }
            await SecureGoalsStorageService.updateGoalTask(
              task.goalId!,
              updated,
            );
            await _loadTasks();
          },
        );
      },
    );
  }

  Future<void> _deleteGoalTask(TaskModel task) async {
    if (task.goalId == null) return;
    await TaskNotificationService.cancelTaskReminder(task.id);
    await SecureGoalsStorageService.deleteGoalTask(task.goalId!, task.id);
    await _loadTasks();
  }

  void _shareGoalTask(TaskModel task, BuildContext context) {

    String dateTimeStr = '';
    if (task.reminderTime != null) {
      final d = task.reminderTime!;
      final dateStr =
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      final timeStr = _formatTime(TimeOfDay.fromDateTime(d));
      dateTimeStr = '\n${S.of(context).dat} $dateStr\n${S.of(context).vrem} $timeStr';
    }

    final text = '${S.of(context).zadach} ${task.title}$dateTimeStr';

    Share.share(text);
  }

  Future<void> _duplicateGoalTask(TaskModel task, {required bool toNextDay}) async {
    if (task.goalId == null) return;
    DateTime? newReminderTime = task.reminderTime;
    if (toNextDay && newReminderTime != null) {
      newReminderTime = newReminderTime.add(const Duration(days: 1));
    }
    final duplicatedTask = task.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      reminderTime: newReminderTime,
      isCompleted: false,
    );

    await SecureGoalsStorageService.saveGoalTask(
      task.goalId!,
      duplicatedTask,
    );

    if (newReminderTime != null) {
      await TaskNotificationService.scheduleTaskReminder(
        taskId: duplicatedTask.id,
        taskTitle: duplicatedTask.title,
        reminderTime: newReminderTime,
      );
    }

    await _loadTasks();
  }

  Future<void> _showGoalTaskMenu({
    required BuildContext context,
    required Offset globalPosition,
    required TaskModel task,
  }) async {
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
          value: 'duplicate',
          child: Text(
            S.of(context).dup,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        PopupMenuItem(
          value: 'duptonextday',
          child: Text(
            S.of(context).duptond,
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
      _openEditGoalTaskSheet(task);
    } else if (selected == 'duplicate') {
      await _duplicateGoalTask(task, toNextDay: false);
    } else if (selected == 'duptonextday') {
      await _duplicateGoalTask(task, toNextDay: true);
    } else if (selected == 'share') {
      _shareGoalTask(task, context);
    } else if (selected == 'delete') {
      await _deleteGoalTask(task);
    }
  }

  DateTime _fullDateTime(dynamic item) {
    final taskItem = item['task'];
    if (item['type'] == 'planner') {
      final task = taskItem as PlannerTask;
      return DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );
    }
    return (taskItem as TaskModel).reminderTime!;
  }

  Map<DateTime, List<dynamic>> _groupedTasksForWeek() {
    final weekEnd = _weekStart.add(const Duration(days: 6));

    List<dynamic> allTasks = [];

    for (var task in _tasks) {
      allTasks.add({'type': 'planner', 'task': task});
    }

    // Add goal tasks with type marker
    for (var task in _goalTasks) {
      if (task.reminderTime != null) {
        allTasks.add({'type': 'goal', 'task': task});
      }
    }

    final filtered = allTasks.where((item) {
      final taskItem = item['task'];
      final taskDate = item['type'] == 'planner'
          ? _dateOnly((taskItem as PlannerTask).date)
          : _dateOnly((taskItem as TaskModel).reminderTime!);

      final inWeek = (taskDate.isAtSameMomentAs(_weekStart) || taskDate.isAfter(_weekStart)) &&
          (taskDate.isAtSameMomentAs(weekEnd) || taskDate.isBefore(weekEnd));

      if (!inWeek) return false;
      if (_activeFilters.isEmpty) return true;

      if (item['type'] == 'planner') {
        final task = taskItem as PlannerTask;

        return task.importance != null &&
            _activeFilters.contains(task.importance);
      }

      if (item['type'] == 'goal') {
        final task = taskItem as TaskModel;

        return task.importance != null &&
            _activeFilters.contains(task.importance);
      }

      return false;
    }).toList();

    filtered.sort((a, b) => _fullDateTime(a).compareTo(_fullDateTime(b)));

    final grouped = <DateTime, List<dynamic>>{};
    for (final item in filtered) {
      final taskItem = item['task'];
      final key = item['type'] == 'planner'
          ? _dateOnly((taskItem as PlannerTask).date)
          : _dateOnly((taskItem as TaskModel).reminderTime!);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final grouped = _groupedTasksForWeek();
    final sortedDates = grouped.keys.toList()..sort();
    final today = _dateOnly(DateTime.now());
    final canGoPrevious = _weekStart.isAfter(_minAllowedWeekStart);

    final isCurrentWeek = _weekStart.isAtSameMomentAs(_mondayOf(DateTime.now()));

    List<DateTime> upcomingDates = sortedDates;
    List<DateTime> pastDates = [];

    if (isCurrentWeek) {
      upcomingDates = sortedDates.where((d) => !d.isBefore(today)).toList();
      pastDates = sortedDates.where((d) => d.isBefore(today)).toList();
    }

    final hasPastSection = pastDates.isNotEmpty;
    final totalItems =
        upcomingDates.length + (hasPastSection ? 1 : 0) + pastDates.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ImportanceFilterBar(
                activeFilters: _activeFilters,
                onToggle: _toggleFilter,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: WeekSwitcher(
                label: _weekRangeLabel(_weekStart, context),
                canGoPrevious: canGoPrevious,
                onPrevious: canGoPrevious ? () => _shiftWeek(-1) : null,
                onNext: () => _shiftWeek(1),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: totalItems == 0
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Text(
                                S.of(context).noTasks,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 110, 110, 110),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        itemCount: totalItems,
                        itemBuilder: (context, index) {
                          if (hasPastSection && index == upcomingDates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 30, bottom: 10),
                              child: Row(
                                children: [
                                  Text(
                                    S.of(context).prochl,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,

                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.45),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.15),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final bool inPastSection =
                              hasPastSection && index > upcomingDates.length;
                          final date = inPastSection
                              ? pastDates[index - upcomingDates.length - 1]
                              : upcomingDates[index];
                          final dayTasks = grouped[date]!;
                          final isPastDay = date.isBefore(today);
                          final isLast = index == totalItems - 1;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dayLabel(date, context),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    if (!isPastDay)
                                      RoundIconButton(
                                        small: true,
                                        icon: Icons.add,
                                        onTap: () => openAddTaskSheet(presetDate: date),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                for (final taskItem in dayTasks)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: taskItem['type'] == 'planner'
                                        ? TaskTile(
                                            task: taskItem['task'] as PlannerTask,
                                            onToggle: () =>
                                                _toggleCompleted(taskItem['task']),
                                            onDelete: () =>
                                                _deleteTask((taskItem['task'] as PlannerTask).id),
                                            onLongPressStart: (details) => _showTaskMenu(
                                              context: context,
                                              globalPosition: details.globalPosition,
                                              task: taskItem['task'] as PlannerTask,
                                            ),
                                          )
                                        : GoalTaskTile(
                                            task: taskItem['task'] as TaskModel,
                                            onToggle: () async {
                                              final task = taskItem['task'] as TaskModel;

                                              final updated = task.copyWith(
                                                isCompleted: !task.isCompleted,
                                              );

                                              await SecureGoalsStorageService.updateGoalTask(
                                                task.goalId!,
                                                updated,
                                              );

                                              await _loadTasks();
                                            },
                                            onLongPressStart: (details) => _showGoalTaskMenu(
                                              context: context,
                                              globalPosition: details.globalPosition,
                                              task: taskItem['task'] as TaskModel,
                                            ),
                                          )
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _mondayOf(DateTime date) {
    final d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }
}

bool _isPlannerTaskExpired(PlannerTask task) {
  if (task.completed) return false;

  final taskDateTime = DateTime(
    task.date.year,
    task.date.month,
    task.date.day,
    task.time.hour,
    task.time.minute,
  );

  return taskDateTime.isBefore(DateTime.now());
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

bool _isTaskExpired(TaskModel task) {
  if (task.reminderTime == null) return false;

  if (task.isCompleted) return false;

  return task.reminderTime!.isBefore(DateTime.now());
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

List<String> _getMonths(BuildContext context) {
  return [
    '',
    S.of(context).jan,
    S.of(context).feb,
    S.of(context).mar,
    S.of(context).apr,
    S.of(context).may,
    S.of(context).jun,
    S.of(context).jul,
    S.of(context).aug,
    S.of(context).sep,
    S.of(context).oct,
    S.of(context).nov,
    S.of(context).dec,
  ];
}

String _dayLabel(DateTime date, BuildContext context) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final tomorrow = today.add(const Duration(days: 1));
  final d = DateTime(date.year, date.month, date.day);

  if (d == today) return S.of(context).seg;
  if (d == tomorrow) return S.of(context).tomorrow;

  final months = _getMonths(context);
  final locale = Localizations.localeOf(context).languageCode;

  if (locale == 'en') {
    return '${months[d.month]} ${d.day}';
  }
  return '${d.day} ${months[d.month]}';
}

String _weekRangeLabel(DateTime weekStart, BuildContext context) {
  final locale = Localizations.localeOf(context).languageCode;
  final weekEnd = weekStart.add(const Duration(days: 6));
  final months = _getMonths(context);

  if (locale == 'en') {
    if (weekStart.month == weekEnd.month) {
      return '${months[weekStart.month]} ${weekStart.day} - ${weekEnd.day}';
    }
    return '${months[weekStart.month]} ${weekStart.day} - ${months[weekEnd.month]} ${weekEnd.day}';
  }

  if (weekStart.month == weekEnd.month) {
    return '${weekStart.day} - ${weekEnd.day} ${months[weekEnd.month]}';
  }
  return '${weekStart.day} ${months[weekStart.month]} - ${weekEnd.day} ${months[weekEnd.month]}';
}

class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: small ? 20 : 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class ImportanceFilterBar extends StatelessWidget {
  final Set<Importance> activeFilters;
  final Function(Importance) onToggle;

  const ImportanceFilterBar({
    super.key,
    required this.activeFilters,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 15),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            S.of(context).importance,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: Importance.values.map((importance) {
              final active = activeFilters.contains(importance);

              return GestureDetector(
                onTap: () => onToggle(importance),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _importanceColor(importance),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _importanceLabel(context, importance),
                      style: TextStyle(
                        fontSize: 16,
                        color: active
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class WeekSwitcher extends StatelessWidget {
  final String label;
  final bool canGoPrevious;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;

  const WeekSwitcher({
    super.key,
    required this.label,
    required this.canGoPrevious,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: Row(
        children: [
          _WeekArrowButton(
            icon: Icons.chevron_left,
            onTap: onPrevious,
            enabled: canGoPrevious,
          ),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          _WeekArrowButton(
            icon: Icons.chevron_right,
            onTap: onNext,
            enabled: true,
          ),
        ],
      ),
    );
  }
}

class _WeekArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _WeekArrowButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3);

    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class TaskTile extends StatelessWidget {
  final PlannerTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final void Function(LongPressStartDetails details)? onLongPressStart;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onLongPressStart,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder = isDark ? const Color(0xFF4A4A4D) : Colors.grey[300]!;
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : const Color.fromARGB(89, 217, 217, 217),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(34),
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed
                      ? const Color.fromARGB(255, 117, 117, 117)
                      : Colors.white,
                  border: task.completed
                      ? null
                      : Border.all(
                          color: const Color.fromARGB(255, 117, 117, 117)),
                ),
                child: task.completed
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
                      color: task.completed ? Colors.grey : onSurface,
                      decoration:
                          task.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    _formatTime(task.time),
                    style: TextStyle(
                      fontSize: 15,
                      color: _isPlannerTaskExpired(task)
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

class GoalTaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final void Function(LongPressStartDetails details)? onLongPressStart;

  const GoalTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onLongPressStart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final cardBorder = isDark ? const Color(0xFF4A4A4D) : Colors.grey[300]!;
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : const Color.fromARGB(89, 217, 217, 217),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onToggle,
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
                          color: const Color.fromARGB(255, 117, 117, 117),
                        ),
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
                  if (task.reminderTime != null)
                    Text(
                      _formatTime(TimeOfDay.fromDateTime(task.reminderTime!)),
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
            if (task.emoji != null && task.emoji!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  task.emoji!,
                  style: const TextStyle(fontSize: 18),
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

class AddTaskSheet extends StatefulWidget {
  final DateTime? presetDate;
  final PlannerTask? existingTask;
  final Future<void> Function(PlannerTask task) onAdd;

  const AddTaskSheet({
    super.key,
    this.presetDate,
    this.existingTask,
    required this.onAdd,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  Importance? _selectedImportance;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task.title;
      _selectedDate = task.date;
      _selectedTime = task.time;
      _selectedImportance = task.importance;
    } else {
      _selectedDate = widget.presetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDateTime() async {
    if (widget.presetDate != null && !_isEditing) {
      final isToday = _dateOnlyEquals(widget.presetDate!, _today);
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (time != null) {
        if (isToday) {
          final now = TimeOfDay.now();
          final pickedMinutes = time.hour * 60 + time.minute;
          final nowMinutes = now.hour * 60 + now.minute;
          if (pickedMinutes < nowMinutes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).selectTime)),
              );
            }
            return;
          }
        }
        setState(() {
          _selectedTime = time;
        });
      }
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && _selectedDate!.isAfter(_today)
          ? _selectedDate!
          : _today,
      firstDate: _today,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  bool _dateOnlyEquals(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateTimeText() {
    if (widget.presetDate != null && !_isEditing) {
      return _selectedTime == null
          ? S.of(context).selectTime
          : _formatTime(_selectedTime!);
    }

    if (_selectedDate == null || _selectedTime == null) {
      return S.of(context).selectTime;
    }

    final d = _selectedDate!;
    return "${d.day}.${d.month}.${d.year} ${_formatTime(_selectedTime!)}";
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    if (_selectedDate == null) return;
    if (_selectedTime == null) return;

    final task = PlannerTask(
      id: widget.existingTask?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      date: _selectedDate!,
      time: _selectedTime!,
      importance: _selectedImportance,
      completed: widget.existingTask?.completed ?? false,
    );

    await widget.onAdd(task);

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
        : S.of(context).dob;
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _dateTimeText(),
                    style: TextStyle(
                      fontSize: 18,
                      color: _selectedTime == null
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
              const SizedBox(height: 10),
              Text(
                S.of(context).noImportanceHint,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 110, 110, 110),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
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

class _EditGoalTaskSheet extends StatefulWidget {
  final TaskModel existingTask;
  final Future<void> Function(
    String title,
    DateTime? reminderTime,
    Importance? importance,
  ) onSave;

  const _EditGoalTaskSheet({
    required this.existingTask,
    required this.onSave,
  });

  @override
  State<_EditGoalTaskSheet> createState() => _EditGoalTaskSheetState();
}

class _EditGoalTaskSheetState extends State<_EditGoalTaskSheet> {
  late final TextEditingController _titleController;
  DateTime? _selectedReminderTime;
  Importance? _selectedImportance;
  bool _isFormValid = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask.title);
    _selectedReminderTime = widget.existingTask.reminderTime;
    _selectedImportance = widget.existingTask.importance;
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
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedReminderTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

    await widget.onSave(
      _titleController.text.trim(),
      _selectedReminderTime,
      _selectedImportance,
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
    final headerText = S.of(context).izmenzad;
    final buttonText = S.of(context).sox;

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
                        : '${_selectedReminderTime!.day}.${_selectedReminderTime!.month}.${_selectedReminderTime!.year} ${_selectedReminderTime!.hour.toString().padLeft(2, '0')}:${_selectedReminderTime!.minute.toString().padLeft(2, '0')}',
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

// this code was written by maksy