import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/draft.dart';

class TaskProvider extends ChangeNotifier {
  late Box<Task> _taskBox;
  late Box<TaskDraft> _draftBox;
  final _uuid = const Uuid();

  // UI State
  String _searchQuery = '';
  TaskStatus? _filterStatus;
  Timer? _debounceTimer;
  bool _isSaving = false;

  // Getters
  String get searchQuery => _searchQuery;
  TaskStatus? get filterStatus => _filterStatus;
  bool get isSaving => _isSaving;

  List<Task> get allTasks {
    final tasks = _taskBox.values.toList();
    tasks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return tasks;
  }

  List<Task> get filteredTasks {
    var tasks = allTasks;

    if (_filterStatus != null) {
      tasks = tasks.where((t) => t.status == _filterStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
    }

    return tasks;
  }

  TaskDraft get draft {
    return _draftBox.get('current_draft') ?? TaskDraft();
  }

  // Initialize Hive boxes
  Future<void> init() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    _draftBox = await Hive.openBox<TaskDraft>('drafts');
    notifyListeners();
  }

  // Search with debounce
  void onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    notifyListeners();
  }

  void setFilter(TaskStatus? status) {
    _filterStatus = status;
    notifyListeners();
  }

  // Draft management
  void updateDraft({
    String? title,
    String? description,
    DateTime? dueDate,
    String? blockedById,
    bool clearBlockedBy = false,
    int? statusIndex,
    String? editingTaskId,
    bool clearEditingId = false,
  }) {
    final current = draft;
    final updated = TaskDraft(
      title: title ?? current.title,
      description: description ?? current.description,
      dueDate: dueDate ?? current.dueDate,
      blockedById: clearBlockedBy ? null : (blockedById ?? current.blockedById),
      statusIndex: statusIndex ?? current.statusIndex,
      editingTaskId: clearEditingId ? null : (editingTaskId ?? current.editingTaskId),
    );
    _draftBox.put('current_draft', updated);
  }

  void clearDraft() {
    _draftBox.put('current_draft', TaskDraft());
  }

  void loadTaskIntoDraft(Task task) {
    _draftBox.put(
      'current_draft',
      TaskDraft(
        title: task.title,
        description: task.description,
        dueDate: task.dueDate,
        blockedById: task.blockedById,
        statusIndex: task.status.index,
        editingTaskId: task.id,
      ),
    );
  }

  // CRUD Operations
  Future<bool> saveTask() async {
    if (_isSaving) return false;
    final d = draft;

    _isSaving = true;
    notifyListeners();

    // Simulate 2-second network/db delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final isEditing = d.editingTaskId != null;
      final status = TaskStatus.values[d.statusIndex];

      if (isEditing) {
        // Update existing task
        final existing = _taskBox.values.firstWhere(
          (t) => t.id == d.editingTaskId,
        );
        final updated = existing.copyWith(
          title: d.title,
          description: d.description,
          dueDate: d.dueDate,
          status: status,
          blockedById: d.blockedById,
          clearBlockedBy: d.blockedById == null,
        );
        await existing.delete();
        await _taskBox.put(updated.id, updated);
      } else {
        // Create new task
        final task = Task(
          id: _uuid.v4(),
          title: d.title,
          description: d.description,
          dueDate: d.dueDate!,
          status: status,
          blockedById: d.blockedById,
          sortOrder: _taskBox.length,
          createdAt: DateTime.now(),
        );
        await _taskBox.put(task.id, task);
      }

      clearDraft();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    // Snapshot values first — mutating _taskBox while iterating it is unsafe.
    final dependents = _taskBox.values
        .where((t) => t.blockedById == id)
        .toList();
    for (final task in dependents) {
      final updated = task.copyWith(clearBlockedBy: true);
      await task.delete();
      await _taskBox.put(updated.id, updated);
    }
    final task = _taskBox.get(id);
    await task?.delete();
    notifyListeners();
  }

  Future<void> quickUpdateStatus(String id, TaskStatus newStatus) async {
    final task = _taskBox.get(id);
    if (task == null) return;
    final updated = task.copyWith(status: newStatus);
    await task.delete();
    await _taskBox.put(updated.id, updated);
    notifyListeners();
  }

  // Reorder tasks for drag-and-drop.
  // Operates on the full allTasks list so sort orders stay globally consistent
  // even when a search/filter subset is shown.
  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    final filtered = filteredTasks;
    final full = allTasks;
    if (oldIndex == newIndex) return;

    // Map filtered-view indices to full-list indices
    final fullOldIndex = full.indexWhere((t) => t.id == filtered[oldIndex].id);
    final fullNewIndex = full.indexWhere((t) => t.id == filtered[newIndex].id);
    if (fullOldIndex == -1 || fullNewIndex == -1) return;

    final item = full.removeAt(fullOldIndex);
    full.insert(fullNewIndex, item);

    // Only write tasks whose sort order actually changed
    for (int i = 0; i < full.length; i++) {
      final t = full[i];
      if (t.sortOrder != i) {
        final updated = t.copyWith(sortOrder: i);
        await t.delete();
        await _taskBox.put(updated.id, updated);
      }
    }
    notifyListeners();
  }

  // Stats
  int get totalCount => _taskBox.length;
  int get todoCount => _taskBox.values.where((t) => t.status == TaskStatus.todo).length;
  int get inProgressCount => _taskBox.values.where((t) => t.status == TaskStatus.inProgress).length;
  int get doneCount => _taskBox.values.where((t) => t.status == TaskStatus.done).length;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}