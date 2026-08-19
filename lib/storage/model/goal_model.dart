import 'package:uuid/uuid.dart';

class GoalModel {
  final String id;
  final String name;
  final String emoji;
  final String date;
  final double progress;
  final bool pinned;

  GoalModel({
    String? id,
    required this.name,
    required this.emoji,
    required this.date,
    this.progress = 0.0,
    this.pinned = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'date': date,
      'progress': progress,
      'pinned': pinned,
    };
  }

  Map<String, dynamic> toSupabaseJson(String userId, String username) {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'name': name,
      'emoji': emoji,
      'date': date,
      'progress': progress,
      'pinned': pinned,
    };
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? json['title'] ?? '') as String,
      emoji: (json['emoji'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      pinned: json['pinned'] as bool? ?? false,
    );
  }

  GoalModel copyWith({
    String? id,
    String? name,
    String? emoji,
    String? date,
    double? progress,
    bool? pinned,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      date: date ?? this.date,
      progress: progress ?? this.progress,
      pinned: pinned ?? this.pinned,
    );
  }
}

// this code was written by maksy