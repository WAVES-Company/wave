import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wave/storage/model/goal_model.dart';
import 'package:wave/pages/homepage/goals/regulargoal/regulargoalPage.dart';
import 'package:wave/storage/secure_key.dart';
import 'package:wave/services/data_sync_service.dart';

class SecureGoalsStorageService {
  static const _storage = FlutterSecureStorage();
  static const String goalsKey = SecureKeys.goals;

  static Future<void> saveGoal(GoalModel goal) async {
    final goals = await getGoals();

    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    
    await _storage.write(
      key: goalsKey, 
      value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()),
    );
    DataSyncService.sendAllDataToServer();
  }

  static Future<void> updateGoal(GoalModel updatedGoal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == updatedGoal.id);
    if (index != -1) {
      goals[index] = updatedGoal;
      await _storage.write(key: goalsKey, value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()));
      DataSyncService.sendAllDataToServer();
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == goalId);
    await _storage.write(key: goalsKey, value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()));
    await _clearGoalTasks(goalId);
    
    DataSyncService.deleteRegularGoalFromServer(goalId);
  }

  static Future<void> _clearGoalTasks(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('goal_tasks_$goalId');
  }

  static Future<List<GoalModel>> getGoals() async {
    final data = await _storage.read(key: goalsKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => GoalModel.fromJson(jsonDecode(e))).toList();
  }

  static Future<List<TaskModel>> getGoalTasks(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('goal_tasks_$goalId') ?? [];
    return tasksJson.map((t) => TaskModel.fromJson(jsonDecode(t))).toList();
  }

  static Future<void> saveGoalTask(String goalId, TaskModel task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('goal_tasks_$goalId') ?? [];
    tasksJson.add(jsonEncode(task.toJson()));
    await prefs.setStringList('goal_tasks_$goalId', tasksJson);
    DataSyncService.sendAllDataToServer();
  }

  static Future<void> replaceGoalTasks(String goalId, List<TaskModel> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList('goal_tasks_$goalId', tasksJson);
  }

  static Future<void> updateGoalTask(String goalId, TaskModel task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('goal_tasks_$goalId') ?? [];
    final index = tasksJson.indexWhere((t) => jsonDecode(t)['id'] == task.id);
    if (index != -1) {
      tasksJson[index] = jsonEncode(task.toJson());
      await prefs.setStringList('goal_tasks_$goalId', tasksJson);
      DataSyncService.sendAllDataToServer(); 
    }
  }

  static Future<void> deleteGoalTask(String goalId, String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('goal_tasks_$goalId') ?? [];
    tasksJson.removeWhere((t) => jsonDecode(t)['id'] == taskId);
    await prefs.setStringList('goal_tasks_$goalId', tasksJson);
    DataSyncService.sendAllDataToServer(); 
  }
}

// this code was written by maksy