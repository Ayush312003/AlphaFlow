import 'package:flutter/material.dart';
import 'package:alphaflow/data/models/custom_task.dart';
import 'package:alphaflow/data/models/task_priority.dart';
import 'package:alphaflow/data/models/task_target.dart';
import 'package:alphaflow/core/theme/alphaflow_theme.dart';
import 'package:intl/intl.dart';

/// Premium glassmorphic task card for custom tasks with flexible content
class PremiumCustomTaskCard extends StatelessWidget {
  final CustomTask task;
  final ValueChanged<bool>? onToggleCompletion;
  final VoidCallback? onNotesTap;
  final VoidCallback? onSubTasksTap;
  final VoidCallback? onTargetTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const PremiumCustomTaskCard({
    super.key,
    required this.task,
    this.onToggleCompletion,
    this.onNotesTap,
    this.onSubTasksTap,
    this.onTargetTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  bool get isCompleted {
    if (task.subTasks.isNotEmpty) {
      return task.subTasks.every((st) => st.isCompleted);
    }
    return task.isCompleted;
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AlphaFlowTheme.guidedGlassmorphismCardDecoration,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Always show the completion checkbox
                GestureDetector(
                  onTap: onToggleCompletion != null
                      ? () => onToggleCompletion!(!isCompleted)
                      : null,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isCompleted
                            ? AlphaFlowTheme.guidedAccentOrange
                            : AlphaFlowTheme.guidedTextSecondary.withOpacity(0.3),
                        width: 2,
                      ),
                      color: isCompleted
                          ? AlphaFlowTheme.guidedAccentOrange
                          : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AlphaFlowTheme.guidedTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? AlphaFlowTheme.guidedTextSecondary
                                : AlphaFlowTheme.guidedTextPrimary,
                          ),
                        ),
                      ),
                      ..._buildTrailingIcons(),
                    ],
                  ),
                ),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: _isOverdue(task.dueDate!) && !isCompleted 
                        ? Colors.red 
                        : AlphaFlowTheme.guidedTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOverdue(task.dueDate!) && !isCompleted
                        ? 'Overdue: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'
                        : 'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}',
                    style: AlphaFlowTheme.guidedTextStyle.copyWith(
                      fontSize: 12,
                      color: _isOverdue(task.dueDate!) && !isCompleted 
                          ? Colors.red 
                          : AlphaFlowTheme.guidedTextSecondary,
                      fontWeight: _isOverdue(task.dueDate!) && !isCompleted 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
            if ((task.notes != null && task.notes!.isNotEmpty) || task.subTasks.isNotEmpty || task.taskTarget != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (task.notes != null && task.notes!.isNotEmpty && onNotesTap != null)
                    _buildIndicator(
                      icon: Icons.note_outlined,
                      label: 'Notes',
                      onTap: onNotesTap!,
                    ),
                  if (task.subTasks.isNotEmpty && onSubTasksTap != null) ...[
                    if (task.notes != null && task.notes!.isNotEmpty && onNotesTap != null)
                      const SizedBox(width: 12),
                    _buildIndicator(
                      icon: Icons.checklist_outlined,
                      label: '${task.subTasks.where((st) => st.isCompleted).length}/${task.subTasks.length}',
                      onTap: onSubTasksTap!,
                    ),
                  ],
                  if (task.taskTarget != null && onTargetTap != null) ...[
                    if (((task.notes != null && task.notes!.isNotEmpty && onNotesTap != null) || (task.subTasks.isNotEmpty && onSubTasksTap != null)))
                      const SizedBox(width: 12),
                    _buildIndicator(
                      icon: Icons.track_changes_outlined,
                      label: '${task.taskTarget!.currentValue}/${task.taskTarget!.targetValue} ${task.taskTarget!.unit}',
                      onTap: onTargetTap!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      default:
        return AlphaFlowTheme.guidedTextSecondary;
    }
  }

  Widget _buildIndicator({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AlphaFlowTheme.guidedAccentOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AlphaFlowTheme.guidedAccentOrange.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: AlphaFlowTheme.guidedAccentOrange,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AlphaFlowTheme.guidedTextStyle.copyWith(
                fontSize: 10,
                color: AlphaFlowTheme.guidedAccentOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrailingIcons() {
    const double iconSpacing = 8.0;
    final List<Widget> icons = [];

    // Overdue indicator
    final showOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
        !isCompleted;
    if (showOverdue) {
      icons.add(
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: Colors.red,
          ),
        ),
      );
    }

    // Priority badge
    if (task.priority.name != 'none') {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: iconSpacing));
      icons.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getPriorityColor(task.priority).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            task.priority.name.toUpperCase(),
            style: AlphaFlowTheme.guidedTextStyle.copyWith(
              fontSize: 10,
              color: _getPriorityColor(task.priority),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Edit button
    if (onEditTap != null) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: iconSpacing));
      icons.add(
        GestureDetector(
          onTap: onEditTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AlphaFlowTheme.guidedTextSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.edit_outlined,
              size: 16,
              color: AlphaFlowTheme.guidedTextSecondary,
            ),
          ),
        ),
      );
    }

    // Delete button
    if (onDeleteTap != null) {
      if (icons.isNotEmpty) icons.add(const SizedBox(width: iconSpacing));
      icons.add(
        GestureDetector(
          onTap: onDeleteTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.red.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return icons;
  }
} 