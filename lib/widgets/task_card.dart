import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import 'highlighted_text.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final allTasks = provider.allTasks;
    final isBlocked = task.isBlocked(allTasks);
    final blocker = task.getBlocker(allTasks);
    final searchQuery = provider.searchQuery;
    final isOverdue = task.dueDate.isBefore(DateTime.now()) &&
        task.status != TaskStatus.done;

    return Animate(
      effects: [
        FadeEffect(duration: 250.ms, delay: (index * 40).ms),
        SlideEffect(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
          duration: 300.ms,
          delay: (index * 40).ms,
          curve: Curves.easeOut,
        ),
      ],
      child: Slidable(
        key: ValueKey(task.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.55,
          children: [
            SlidableAction(
              onPressed: (_) => _showStatusBottomSheet(context, provider),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
              foregroundColor: AppTheme.primaryColor,
              icon: Icons.swap_horiz_rounded,
              label: 'Status',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppTheme.accentColor.withOpacity(0.15),
              foregroundColor: AppTheme.accentColor,
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isBlocked ? AppTheme.blockedBg : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isBlocked
                    ? AppTheme.blockedBorder
                    : (isOverdue
                        ? AppTheme.accentColor.withOpacity(0.4)
                        : AppTheme.borderColor),
                width: isBlocked || isOverdue ? 1.5 : 1,
              ),
              boxShadow: isBlocked
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusDot(task.status),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HighlightedText(
                          text: task.title,
                          query: searchQuery,
                          baseStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isBlocked
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            decoration: task.status == TaskStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppTheme.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(task.status),
                    ],
                  ),

                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isBlocked
                              ? AppTheme.textMuted.withOpacity(0.6)
                              : AppTheme.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Row(
                      children: [
                        _buildDateChip(task.dueDate, isOverdue, isBlocked),
                        if (isBlocked && blocker != null) ...[
                          const SizedBox(width: 8),
                          _buildBlockedChip(blocker),
                        ],
                        const Spacer(),
                        if (task.status != TaskStatus.done)
                          _buildQuickDoneButton(context, provider),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(TaskStatus status) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.statusColor(status.label),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusColor(status.label).withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status.label),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.statusColor(status.label).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.statusIcon(status.label),
            size: 11,
            color: AppTheme.statusColor(status.label),
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.statusColor(status.label),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(DateTime date, bool isOverdue, bool isBlocked) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(date.year, date.month, date.day);
    final diff = taskDay.difference(today).inDays;

    String label;
    if (diff == 0) {
      label = 'Today';
    } else if (diff == 1) {
      label = 'Tomorrow';
    } else if (diff == -1) {
      label = 'Yesterday';
    } else if (diff < 0) {
      label = '${-diff}d overdue';
    } else {
      label = DateFormat('MMM d').format(date);
    }

    final color = isBlocked
        ? AppTheme.textMuted
        : (isOverdue ? AppTheme.accentColor : AppTheme.textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue && !isBlocked
              ? Icons.warning_amber_rounded
              : Icons.calendar_today_rounded,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedChip(Task blocker) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 11,
            color: Colors.deepPurpleAccent,
          ),
          const SizedBox(width: 4),
          Text(
            'Blocked',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurpleAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDoneButton(BuildContext context, TaskProvider provider) {
    return GestureDetector(
      onTap: () => provider.quickUpdateStatus(task.id, TaskStatus.done),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.doneColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.doneColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_rounded,
              size: 12,
              color: AppTheme.doneColor,
            ),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.doneColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusBottomSheet(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...TaskStatus.values.map((s) => ListTile(
                  leading: Icon(
                    AppTheme.statusIcon(s.label),
                    color: AppTheme.statusColor(s.label),
                  ),
                  title: Text(s.label,
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: task.status == s
                      ? const Icon(Icons.check_rounded,
                          color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    provider.quickUpdateStatus(task.id, s);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}