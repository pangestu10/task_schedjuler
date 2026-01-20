// lib/ui/widgets/task_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onTap;



  final Widget? leading;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChange,
    required this.onDelete,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(context, task.status).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Lateral Status Indicator
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(
                  color: _getStatusColor(context, task.status),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: leading!,
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(leading == null ? 22 : 10, 16, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        decoration: task.status == TaskStatus.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: task.status == TaskStatus.completed
                                            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.timer_outlined, size: 14, color: theme.colorScheme.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${task.estimatedMinutes} mins',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.primary.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (task.deadline != null) ...[
                                          const SizedBox(width: 12),
                                          const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.deadline!.toString().split(' ')[0],
                                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<dynamic>(
                                icon: Icon(Icons.more_vert_rounded, color: theme.hintColor.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onSelected: (value) {
                                  if (value is TaskStatus) {
                                    onStatusChange(value);
                                  } else if (value == 'delete') {
                                    onDelete();
                                  }
                                },
                                itemBuilder: (context) => [
                                  _buildMenuItem(context, TaskStatus.todo, Icons.assignment_outlined, 'To Do'),
                                  _buildMenuItem(context, TaskStatus.inProgress, Icons.bolt_rounded, 'In Progress'),
                                  _buildMenuItem(context, TaskStatus.completed, Icons.check_circle_outline, 'Completed'),
                                  const PopupMenuDivider(),
                                  _buildMenuItem(context, 'delete', Icons.delete_outline_rounded, 'Delete', color: Colors.red),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPriorityBadge(context, task.priority),
                              const SizedBox(width: 8),
                              _buildStatusBadge(context, task.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem _buildMenuItem(BuildContext context, dynamic value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(BuildContext context, TaskPriority priority) {
    final color = _getPriorityColor(context, priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        priority.toString().split('.').last.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TaskStatus status) {
    final color = _getStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.critical:
        return Colors.red;
    }
  }

  Color _getStatusColor(BuildContext context, TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return const Color(0xFF10B981); // Emerald
      case TaskStatus.inProgress:
        return const Color(0xFFF59E0B); // Amber
      case TaskStatus.todo:
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}
