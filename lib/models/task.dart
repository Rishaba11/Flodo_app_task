import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  done,
}

extension TaskStatusExtension on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To-Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  TaskStatus status;

  @HiveField(5)
  String? blockedById; // ID of the task that blocks this one

  @HiveField(6)
  int sortOrder;

  @HiveField(7)
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    required this.sortOrder,
    required this.createdAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskStatus? status,
    String? blockedById,
    bool clearBlockedBy = false,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: clearBlockedBy ? null : (blockedById ?? this.blockedById),
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool isBlocked(List<Task> allTasks) {
    if (blockedById == null) return false;
    try {
      final blocker = allTasks.firstWhere((t) => t.id == blockedById);
      return blocker.status != TaskStatus.done;
    } catch (_) {
      return false;
    }
  }

  Task? getBlocker(List<Task> allTasks) {
    if (blockedById == null) return null;
    try {
      return allTasks.firstWhere((t) => t.id == blockedById);
    } catch (_) {
      return null;
    }
  }
}