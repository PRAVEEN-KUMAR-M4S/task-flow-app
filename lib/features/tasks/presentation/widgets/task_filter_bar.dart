import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_flow/features/users/domain/entities/org_member.dart';

/// A compact, single-row task filter bar.
///
/// Shows small filter chips that open bottom-sheet pickers when tapped.
/// Active filters are highlighted; a clear button resets all.
class TaskFilterBar extends StatelessWidget {
  final String? selectedStatus;
  final String? selectedPriority;
  final String? selectedAssigneeId;
  final DateTime? dueFrom;
  final DateTime? dueTo;
  final List<OrgMember> members;
  final Function({
    String? status,
    String? priority,
    String? assigneeId,
    DateTime? dueFrom,
    DateTime? dueTo,
  })
  onFilterChanged;

  const TaskFilterBar({
    super.key,
    this.selectedStatus,
    this.selectedPriority,
    this.selectedAssigneeId,
    this.dueFrom,
    this.dueTo,
    this.members = const [],
    required this.onFilterChanged,
  });

  int get _activeCount {
    int c = 0;
    if (selectedStatus != null) c++;
    if (selectedPriority != null) c++;
    if (selectedAssigneeId != null) c++;
    if (dueFrom != null || dueTo != null) c++;
    return c;
  }

  void _showPicker(
    BuildContext context, {
    required String title,
    required List<_FilterOption> options,
    required String? currentValue,
    required ValueChanged<String?> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        onSelected(null);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),
              ...options.map((opt) => ListTile(
                    dense: true,
                    title: Text(opt.label),
                    trailing: currentValue == opt.value
                        ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () {
                      onSelected(opt.value);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      initialDateRange: (dueFrom != null && dueTo != null)
          ? DateTimeRange(start: dueFrom!, end: dueTo!)
          : null,
    );
    if (picked != null) {
      onFilterChanged(
        status: selectedStatus,
        priority: selectedPriority,
        assigneeId: selectedAssigneeId,
        dueFrom: picked.start,
        dueTo: picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    String statusLabel = 'Status';
    if (selectedStatus != null) {
      statusLabel = selectedStatus!.replaceAll('_', ' ');
      statusLabel = statusLabel[0].toUpperCase() + statusLabel.substring(1);
    }

    String priorityLabel = 'Priority';
    if (selectedPriority != null) {
      priorityLabel = selectedPriority![0].toUpperCase() + selectedPriority!.substring(1);
    }

    String assigneeLabel = 'Assignee';
    if (selectedAssigneeId != null) {
      final member = members.where((m) => m.userId == selectedAssigneeId).firstOrNull;
      assigneeLabel = member?.name ?? 'Assigned';
    }

    String dateLabel = 'Due Date';
    if (dueFrom != null || dueTo != null) {
      final fmt = DateFormat('MMM d');
      if (dueFrom != null && dueTo != null) {
        dateLabel = '${fmt.format(dueFrom!)} – ${fmt.format(dueTo!)}';
      } else if (dueFrom != null) {
        dateLabel = 'From ${fmt.format(dueFrom!)}';
      } else {
        dateLabel = 'Until ${fmt.format(dueTo!)}';
      }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.filter_list_rounded, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: statusLabel,
                  isActive: selectedStatus != null,
                  onTap: () => _showPicker(
                    context,
                    title: 'Filter by Status',
                    currentValue: selectedStatus,
                    options: const [
                      _FilterOption(value: null, label: 'All'),
                      _FilterOption(value: 'todo', label: 'Todo'),
                      _FilterOption(value: 'in_progress', label: 'In Progress'),
                      _FilterOption(value: 'review', label: 'Review'),
                      _FilterOption(value: 'done', label: 'Done'),
                    ],
                    onSelected: (v) => onFilterChanged(
                      status: v, priority: selectedPriority,
                      assigneeId: selectedAssigneeId, dueFrom: dueFrom, dueTo: dueTo,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: priorityLabel,
                  isActive: selectedPriority != null,
                  onTap: () => _showPicker(
                    context,
                    title: 'Filter by Priority',
                    currentValue: selectedPriority,
                    options: const [
                      _FilterOption(value: null, label: 'All'),
                      _FilterOption(value: 'low', label: 'Low'),
                      _FilterOption(value: 'medium', label: 'Medium'),
                      _FilterOption(value: 'high', label: 'High'),
                      _FilterOption(value: 'urgent', label: 'Urgent'),
                    ],
                    onSelected: (v) => onFilterChanged(
                      status: selectedStatus, priority: v,
                      assigneeId: selectedAssigneeId, dueFrom: dueFrom, dueTo: dueTo,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: assigneeLabel,
                  isActive: selectedAssigneeId != null,
                  onTap: () {
                    final options = [
                      const _FilterOption(value: null, label: 'Anyone'),
                      const _FilterOption(value: '__unassigned__', label: 'Unassigned'),
                      ...members.map((m) => _FilterOption(value: m.userId, label: m.name)),
                    ];
                    _showPicker(
                      context,
                      title: 'Filter by Assignee',
                      currentValue: selectedAssigneeId,
                      options: options,
                      onSelected: (v) => onFilterChanged(
                        status: selectedStatus, priority: selectedPriority,
                        assigneeId: v, dueFrom: dueFrom, dueTo: dueTo,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: dateLabel,
                  isActive: dueFrom != null || dueTo != null,
                  onTap: () => _showDateRangePicker(context),
                ),
              ],
            ),
          ),
          if (_activeCount > 0) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onFilterChanged(
                status: null, priority: null, assigneeId: null,
                dueFrom: null, dueTo: null,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: cs.onErrorContainer),
                    const SizedBox(width: 2),
                    Text(
                      '$_activeCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? cs.primary.withOpacity(0.4) : cs.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterOption {
  final String? value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}
