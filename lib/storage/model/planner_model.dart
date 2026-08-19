import 'package:flutter/material.dart';

enum Importance {
  high,
  medium,
  low,
}

class PlannerTask {
  String id;
  String title;
  DateTime date;
  TimeOfDay time;
  Importance? importance;
  bool completed;

  PlannerTask({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.importance,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'importance': importance?.name,
      'completed': completed,
    };
  }

  factory PlannerTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlannerTask(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      time: TimeOfDay(
        hour: json['hour'],
        minute: json['minute'],
      ),
      importance: json['importance'] == null
          ? null
          : Importance.values.firstWhere(
              (e) => e.name == json['importance'],
            ),
      completed: json['completed'] ?? false,
    );
  }

  PlannerTask copyWith({
    String? id,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    Importance? importance,
    bool? completed,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      importance: importance ?? this.importance,
      completed: completed ?? this.completed,
    );
  }
}