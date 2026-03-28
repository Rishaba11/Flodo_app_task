import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_overview.dart';
import '../widgets/empty_state.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.filteredTasks;
    final hasFilter =
        provider.filterStatus != null || provider.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, provider),
          SliverToBoxAdapter(
            child: StatsOverview(
              total: provider.totalCount,
              todo: provider.todoCount,
              inProgress: provider.inProgressCount,
              done: provider.doneCount,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSearchAndFilter(context, provider),
          ),
          if (tasks.isEmpty)
            SliverFillRemaining(
              child: EmptyState(isFiltered: hasFilter),
            )
          else
            SliverReorderableList(
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                provider.reorderTasks(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final task = tasks[index];
                return ReorderableDelayedDragStartListener(
                  key: ValueKey(task.id),
                  index: index,
                  child: TaskCard(
                    task: task,
                    index: index,
                    onTap: () => showTaskDetail(context, task),
                    onDelete: () => _confirmDelete(context, task, provider),
                  ),
                );
              },
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: _buildFAB(context, provider),
    );
  }
void showTaskDetail(BuildContext context, Task task) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(task.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text("Description: ${task.description}"),
          const SizedBox(height: 8),
          Text("Due: ${task.dueDate.toString()}"),
          const SizedBox(height: 8),
          Text("Status: ${task.status}"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Close"),
        ),
      ],
    ),
  );
}
  Widget _buildAppBar(BuildContext context, TaskProvider provider) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: AppTheme.surfaceColor,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.task_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Flodo Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        if (provider.filterStatus != null || provider.searchQuery.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              provider.setFilter(null);
              provider.clearSearch();
              _searchController.clear();
            },
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, TaskProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _searchController.text.isNotEmpty
                    ? AppTheme.primaryColor.withOpacity(0.5)
                    : AppTheme.borderColor,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                provider.onSearchChanged(v);
                setState(() {}); // update border color
              },
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(
                  label: 'All',
                  isSelected: provider.filterStatus == null,
                  onTap: () => provider.setFilter(null),
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                ...TaskStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: s.label,
                        isSelected: provider.filterStatus == s,
                        onTap: () => provider.setFilter(
                            provider.filterStatus == s ? null : s),
                        color: AppTheme.statusColor(s.label),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : AppTheme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.5) : AppTheme.borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context, TaskProvider provider) {
    return FloatingActionButton.extended(
      onPressed: () {
        provider.clearDraft();
        Navigator.push(
          context,
          _pageRoute(const TaskFormScreen(isEditing: false)),
        );
      },
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Task',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    )
        .animate()
        .scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut);
  }

  void _confirmDelete(
      BuildContext context, Task task, TaskProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This cannot be undone.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.accentColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_rounded,
                    color: AppTheme.accentColor, size: 16),
                const SizedBox(width: 8),
                Text('"${task.title}" deleted'),
              ],
            ),
          ),
        );
      }
    }
  }

  PageRoute _pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}