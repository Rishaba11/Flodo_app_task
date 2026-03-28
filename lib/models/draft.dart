import 'package:hive/hive.dart';

part 'draft.g.dart';

@HiveType(typeId: 2)
class TaskDraft extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  DateTime? dueDate;

  @HiveField(3)
  String? blockedById;

  @HiveField(4)
  int statusIndex;

  @HiveField(5)
  String? editingTaskId; // null means new task, non-null means editing

  TaskDraft({
    this.title = '',
    this.description = '',
    this.dueDate,
    this.blockedById,
    this.statusIndex = 0,
    this.editingTaskId,
  });

  bool get isEmpty =>
      title.isEmpty && description.isEmpty && dueDate == null;
}