import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';

class TaskFormScreen extends StatefulWidget {
  final bool isEditing;

  const TaskFormScreen({super.key, required this.isEditing});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final draft = context.read<TaskProvider>().draft;
    _titleController = TextEditingController(text: draft.title);
    _descController = TextEditingController(text: draft.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final draft = provider.draft;
    final isSaving = provider.isSaving;
    final allTasks = provider.allTasks;
    // Exclude: the task being edited, and any task that is already
    // blocked by this task (prevents A→B→A cycles).
    final editingId = draft.editingTaskId;
    final blockerOptions = allTasks.where((t) {
      if (t.id == editingId) return false;
      // Prevent cycle: don't allow selecting a task that already depends
      // on (is blocked by) the task being edited.
      if (editingId != null && t.blockedById == editingId) return false;
      return true;
    }).toList();

    return PopScope(
      canPop: true, // Draft is auto-saved on every change; always allow back
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          title: Text(
            widget.isEditing ? 'Edit Task' : 'New Task',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (draft.title.isNotEmpty && !isSaving)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () {
                    provider.clearDraft();
                    _titleController.clear();
                    _descController.clear();
                    setState(() {});
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Draft badge
                  if (!widget.isEditing && draft.title.isNotEmpty)
                    _buildDraftBadge().animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 4),

                  // Title
                  _buildLabel('Title', required: true),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'What needs to be done?',
                      counterStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    onChanged: (v) => _saveDraft(title: v),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildLabel('Description'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 3,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Add details... (optional)',
                      counterStyle:
                          TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                    onChanged: (v) => _saveDraft(description: v),
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  _buildLabel('Due Date', required: true),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _pickDate(context, provider),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: draft.dueDate != null
                              ? AppTheme.primaryColor.withOpacity(0.5)
                              : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: draft.dueDate != null
                                ? AppTheme.primaryColor
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              draft.dueDate != null
                                  ? DateFormat('EEEE, MMMM d, yyyy')
                                      .format(draft.dueDate!)
                                  : 'Select a due date',
                              style: TextStyle(
                                fontSize: 14,
                                color: draft.dueDate != null
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                              ),
                            ),
                          ),
                          if (draft.dueDate != null)
                            GestureDetector(
                              onTap: () =>
                                  provider.updateDraft(dueDate: DateTime.now()),
                              child: const Icon(Icons.close_rounded,
                                  size: 16, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (draft.dueDate == null && _formKey.currentState != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 12),
                      child: Text(
                        'Please select a due date',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentColor.withOpacity(0.8)),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Status
                  _buildLabel('Status'),
                  const SizedBox(height: 6),
                  _buildStatusSelector(provider, draft.statusIndex),
                  const SizedBox(height: 16),

                  // Blocked By
                  _buildLabel('Blocked By', optional: true),
                  const SizedBox(height: 6),
                  _buildBlockedByDropdown(context, provider, blockerOptions,
                      draft.blockedById),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(context, provider, draft),
                  const SizedBox(height: 60),
                ],
              ),
            ),
            if (isSaving) _buildSavingOverlay(),
          ],
        ),)
    );
  }

  Widget _buildDraftBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inProgressColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppTheme.inProgressColor.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.edit_note_rounded,
              size: 16, color: AppTheme.inProgressColor),
          SizedBox(width: 8),
          Text(
            'Draft restored — your progress was saved',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.inProgressColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, {bool required = false, bool optional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        if (optional)
          Text(' (optional)',
              style: TextStyle(
                  color: AppTheme.textMuted.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusSelector(TaskProvider provider, int currentIndex) {
    return Row(
      children: TaskStatus.values.asMap().entries.map((e) {
        final isSelected = e.key == currentIndex;
        final color = AppTheme.statusColor(e.value.label);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < 2 ? 8 : 0),
            child: GestureDetector(
              onTap: () =>
                  provider.updateDraft(statusIndex: e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? color.withOpacity(0.15) : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? color.withOpacity(0.6)
                        : AppTheme.borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      AppTheme.statusIcon(e.value.label),
                      size: 18,
                      color: isSelected ? color : AppTheme.textMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBlockedByDropdown(
    BuildContext context,
    TaskProvider provider,
    List<Task> options,
    String? selectedId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedId != null
              ? Colors.deepPurple.withOpacity(0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          dropdownColor: AppTheme.surfaceColor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textSecondary),
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          hint: const Text(
            'No dependency',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'No dependency',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            ...options.map((t) => DropdownMenuItem<String?>(
                  value: t.id,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.statusColor(t.status.label),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: (v) {
            if (v == null) {
              provider.updateDraft(clearBlockedBy: true);
            } else {
              provider.updateDraft(blockedById: v);
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton(
      BuildContext context, TaskProvider provider, dynamic draft) {
    final canSave = !provider.isSaving && draft.title.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSave ? () => _handleSave(context, provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canSave ? AppTheme.primaryColor : AppTheme.borderColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: provider.isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Saving...',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.isEditing ? 'Save Changes' : 'Create Task',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isEditing ? 'Updating task...' : 'Creating task...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Please wait a moment',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms),
    );
  }

  Future<void> _pickDate(BuildContext context, TaskProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.draft.dueDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            surface: AppTheme.surfaceColor,
            onSurface: AppTheme.textPrimary,
          ), dialogTheme: DialogThemeData(backgroundColor: AppTheme.surfaceColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      provider.updateDraft(dueDate: picked);
      setState(() {});
    }
  }

  void _saveDraft({String? title, String? description}) {
    context.read<TaskProvider>().updateDraft(
          title: title,
          description: description,
        );
  }

  Future<void> _handleSave(
      BuildContext context, TaskProvider provider) async {
    // Validate due date
    if (provider.draft.dueDate == null) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a due date'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    final success = await provider.saveTask();
    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.doneColor, size: 16),
              const SizedBox(width: 8),
              Text(widget.isEditing
                  ? 'Task updated successfully!'
                  : 'Task created successfully!'),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }
}