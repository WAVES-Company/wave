import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wave/storage/model/money_goal_model.dart';
import 'package:wave/storage/model/money_history_goal_model.dart';
import 'package:wave/storage/secure_key.dart';
import 'package:wave/services/data_sync_service.dart';

class SecureMoneyGoalsStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String moneyGoalsKey = SecureKeys.mgoals;

  static Future<void> saveGoal(MoneyGoalModel goal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      goals[index] = goal;
    } else {
      goals.add(goal);
    }
    
    await _storage.write(
      key: moneyGoalsKey, 
      value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()),
    );
    DataSyncService.sendAllDataToServer();
  }

  static Future<List<MoneyGoalModel>> getGoals() async {
    final data = await _storage.read(key: moneyGoalsKey);
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => MoneyGoalModel.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> updateGoal(MoneyGoalModel updatedGoal) async {
    final goals = await getGoals();
    final index = goals.indexWhere((g) => g.id == updatedGoal.id);
    if (index != -1) {
      goals[index] = updatedGoal;
      await _storage.write(key: moneyGoalsKey, value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()));
      DataSyncService.sendAllDataToServer();
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    final goals = await getGoals();
    goals.removeWhere((g) => g.id == goalId);
    await _storage.write(key: moneyGoalsKey, value: jsonEncode(goals.map((g) => jsonEncode(g.toJson())).toList()));
    await _storage.delete(key: 'money_history_$goalId');

    DataSyncService.deleteMoneyGoalFromServer(goalId);
  }

  static Future<List<MoneyHistoryEntry>> getHistory(String goalId) async {
    final data = await _storage.read(key: 'money_history_$goalId');
    if (data == null) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => MoneyHistoryEntry.fromJson(e)).toList();
  }

  static Future<void> addHistory(String goalId, MoneyHistoryEntry entry) async {
    final history = await getHistory(goalId);
    history.insert(0, entry);
    final trimmed = history.take(5).toList();
    await _storage.write(key: 'money_history_$goalId', value: jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    DataSyncService.sendAllDataToServer();
  }
}

// this code was written by maksy