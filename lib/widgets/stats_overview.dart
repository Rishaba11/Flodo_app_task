import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StatsOverview extends StatelessWidget {
  final int total;
  final int todo;
  final int inProgress;
  final int done;

  const StatsOverview({
    super.key,
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            AppTheme.cardColor,
          ],
        ),
      ),
      child: Row(
        children: [
          _buildStat('Total', total, AppTheme.primaryColor, 0),
          _buildDivider(),
          _buildStat('To-Do', todo, AppTheme.todoColor, 1),
          _buildDivider(),
          _buildStat('Active', inProgress, AppTheme.inProgressColor, 2),
          _buildDivider(),
          _buildStat('Done', done, AppTheme.doneColor, 3),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildStat(String label, int count, Color color, int index) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          )
              .animate(
                onPlay: (c) => c.forward(),
              )
              .fadeIn(delay: (index * 80).ms, duration: 300.ms),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.borderColor,
    );
  }
}