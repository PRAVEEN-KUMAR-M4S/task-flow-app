import 'dart:async';
import 'package:flutter/material.dart';

class TaskFilterBar extends StatefulWidget {
  final Function({
    String? status,
    String? priority,
    String? searchQuery,
  }) onFilterChanged;

  const TaskFilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends State<TaskFilterBar> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _selectedStatus;
  String? _selectedPriority;

  final List<String> _statuses = ['', 'todo', 'in_progress', 'review', 'done'];
  final List<String> _priorities = ['', 'low', 'medium', 'high', 'urgent'];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onFilterChanged(
        status: _selectedStatus,
        priority: _selectedPriority,
        searchQuery: query,
      );
    });
  }

  void _updateFilters() {
    widget.onFilterChanged(
      status: _selectedStatus,
      priority: _selectedPriority,
      searchQuery: _searchController.text,
    );
  }

  String _formatLabel(String value) {
    if (value.isEmpty) return 'ALL';
    return value.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {});
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Status:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ..._statuses.map((status) {
                  final isSelected = _selectedStatus == status || (status.isEmpty && _selectedStatus == null);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_formatLabel(status)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = status.isEmpty ? null : status;
                        });
                        _updateFilters();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Priority Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                ..._priorities.map((priority) {
                  final isSelected = _selectedPriority == priority || (priority.isEmpty && _selectedPriority == null);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_formatLabel(priority)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedPriority = priority.isEmpty ? null : priority;
                        });
                        _updateFilters();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
