import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:wave/storage/model/planner_model.dart';
import 'package:wave/storage/secure_key.dart';
import 'package:wave/services/data_sync_service.dart';

class SecurePlannerStorageService {
  static const _storage = FlutterSecureStorage();

  static const String plannerKey = SecureKeys.plannerTasks;

  static Future<List<PlannerTask>> getTasks() async {
    final data = await _storage.read(
      key: plannerKey,
    );

    if (data == null) {
      return [];
    }

    final List decoded = jsonDecode(data);

    return decoded
        .map(
          (e) => PlannerTask.fromJson(
            jsonDecode(e),
          ),
        )
        .toList();
  }

  static Future<void> saveTask(
    PlannerTask task,
  ) async {
    final tasks = await getTasks();

    final index = tasks.indexWhere(
      (t) => t.id == task.id,
    );

    if (index != -1) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }

    await _save(tasks);
  }

  static Future<void> updateTask(
    PlannerTask task,
  ) async {
    final tasks = await getTasks();

    final index = tasks.indexWhere(
      (t) => t.id == task.id,
    );

    if (index == -1) {
      return;
    }

    tasks[index] = task;

    await _save(tasks);
  }

  static Future<void> deleteTask(
    String id,
  ) async {
    final tasks = await getTasks();

    tasks.removeWhere(
      (t) => t.id == id,
    );

    await _save(tasks);
  }

  static Future<void> clearTasks() async {
    await _storage.delete(
      key: plannerKey,
    );

    DataSyncService.sendAllDataToServer();
  }

  static Future<void> deleteExpiredTasks() async {
    final tasks = await getTasks();

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    tasks.removeWhere((task) {
      final taskDate = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
      );

      return taskDate.isBefore(today);
    });

    await _save(tasks);
  }

  static Future<void> replaceAllTasks(
    List<PlannerTask> tasks,
  ) async {
    await _storage.write(
      key: plannerKey,
      value: jsonEncode(
        tasks
            .map(
              (e) => jsonEncode(
                e.toJson(),
              ),
            )
            .toList(),
      ),
    );
  }

  static Future<void> _save(
    List<PlannerTask> tasks,
  ) async {
    await _storage.write(
      key: plannerKey,
      value: jsonEncode(
        tasks
            .map(
              (e) => jsonEncode(
                e.toJson(),
              ),
            )
            .toList(),
      ),
    );

    DataSyncService.sendAllDataToServer();
  }
}

// this code was written by maksy