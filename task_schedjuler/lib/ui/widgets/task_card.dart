// lib/ui/widgets/task_card.dart
import 'package:flutter/material.dart';
import '../../core/models/task.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(TaskStatus) onStatusChange;
  final VoidCallback onDelete;
  final VoidCallback onTap;



  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChange,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getStatusColor(task.status),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4), // Match card default radius usually, or take from theme if applied. 
        // Card doesn't have radius explicit here?
        // Default card radius is usually 4 or 12 depending on M2/M3.
        // Let's assume standard.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<dynamic>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value is TaskStatus) {
                      onStatusChange(value);
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: TaskStatus.todo,
                      child: Row(
                        children: [
                          Icon(Icons.assignment_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('To Do'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_empty, size: 20),
                          SizedBox(width: 8),
                          Text('In Progress'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.completed,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Completed'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    task.priority.toString().split('.').last,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getPriorityColor(task.priority),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('${task.estimatedMinutes} min'),
                ),
              ],
            ),
            if (task.deadline != null) ...[
              const SizedBox(height: 8),
              Text(
                'Deadline: ${task.deadline!.toString().split(' ')[0]}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green[100]!;
      case TaskPriority.medium:
        return Colors.blue[100]!;
      case TaskPriority.high:
        return Colors.orange[100]!;
      case TaskPriority.critical:
        return Colors.red[100]!;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green.shade50;
      case TaskStatus.inProgress:
        return Colors.yellow.shade50;
      case TaskStatus.todo:
      default:
        return Colors.red.shade50;
    }
  }
}