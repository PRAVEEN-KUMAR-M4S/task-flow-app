import 'package:flutter/material.dart';
import 'package:task_flow/core/theme/app_theme.dart';
import 'package:task_flow/features/projects/domain/entities/project.dart';

class TaskSummaryRow extends StatelessWidget {
  final Project project;

  const TaskSummaryRow({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryCard(
          label: 'TODO',
          count: project.todoTasks,
          color: AppTheme.statusColor('todo'),
        ),
        const SizedBox(width: 8),
        _SummaryCard(
          label: 'ACTIVE',
          count: project.inProgressTasks,
          color: AppTheme.statusColor('in_progress'),
        ),
        const SizedBox(width: 8),
        _SummaryCard(
          label: 'REVIEW',
          count: project.reviewTasks,
          color: AppTheme.statusColor('review'),
        ),
        const SizedBox(width: 8),
        _SummaryCard(
          label: 'DONE',
          count: project.completedTasks,
          color: AppTheme.statusColor('done'),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
