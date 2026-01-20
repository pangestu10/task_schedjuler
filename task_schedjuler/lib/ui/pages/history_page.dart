// lib/ui/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../core/enums/task_status.dart';
import '../../ui/widgets/task_card.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final completedTasks = taskProvider.tasks
        .where((task) => task.status == TaskStatus.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: completedTasks.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: TaskCard(
                    task: task,
                    onStatusChange: (status) {
                      final updatedTask = task;
                      updatedTask.status = status;
                      taskProvider.updateTask(updatedTask);
                    },
                    onDelete: () => taskProvider.deleteTask(task.id!),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Completed on: ${task.updatedAt?.toLocal().toString().split(' ')[0] ?? "Unknown Date"}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded, size: 64, color: theme.disabledColor),
          ),
          const SizedBox(height: 20),
          Text(
            'No history yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first task to see it here!',
            style: TextStyle(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
