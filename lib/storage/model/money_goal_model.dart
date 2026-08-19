import 'package:uuid/uuid.dart';
import 'package:wave/storage/model/money_history_goal_model.dart';

class MoneyGoalModel {
  final String id;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final String targetDate;
  final double progress;
  final bool pinned;

  MoneyGoalModel({
    String? id,
    required this.targetAmount,
    required this.currentAmount,
    required this.currency,
    required this.targetDate,
    this.progress = 0.0,
    this.pinned = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'targetDate': targetDate,
      'progress': progress,
      'pinned': pinned,
    };
  }

  Map<String, dynamic> toSupabaseJson(String userId, String username, List<MoneyHistoryEntry> historyList) {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'currency': currency,
      'target_date': targetDate,
      'progress': progress,
      'pinned': pinned,
      'history': historyList.map((e) => e.toJson()).toList(),
    };
  }

  factory MoneyGoalModel.fromJson(Map<String, dynamic> json) {
    return MoneyGoalModel(
      id: json['id'] as String,
      targetAmount: (json['target_amount'] ?? json['targetAmount'] as num).toDouble(),
      currentAmount: (json['current_amount'] ?? json['currentAmount'] as num).toDouble(),
      currency: (json['currency'] ?? '') as String,
      targetDate: (json['target_date'] ?? json['targetDate'] ?? '') as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  MoneyGoalModel copyWith({
    String? id,
    double? targetAmount,
    double? currentAmount,
    String? currency,
    String? targetDate,
    double? progress,
    bool? pinned,
  }) {
    return MoneyGoalModel(
      id: id ?? this.id,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      pinned: pinned ?? this.pinned,
    );
  }
}

// this code was written by maksy