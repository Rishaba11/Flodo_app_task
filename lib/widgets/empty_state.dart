import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final bool isFiltered;

  const EmptyState({super.key, this.isFiltered = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
            ),
            child: Icon(
              isFiltered
                  ? Icons.filter_list_off_rounded
                  : Icons.task_alt_rounded,
              size: 36,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 20),
          Text(
            isFiltered ? 'No matching tasks' : 'No tasks yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'Try adjusting your filters or search'
                : 'Tap the + button to create your first task',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }
}