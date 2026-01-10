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
    final completedTasks = taskProvider.tasks
        .where((task) => task.status == TaskStatus.completed)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History Pengerjaan'),
      ),
      body: completedTasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada tugas selesai',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: completedTasks.length,
              itemBuilder: (context, index) {
                final task = completedTasks[index];
                return TaskCard(
                  task: task,
                  onStatusChange: (status) {
                    // Allow moving back to In Progress/Todo if needed
                    final updatedTask = task;
                    updatedTask.status = status;
                    taskProvider.updateTask(updatedTask);
                  },
                  onDelete: () => taskProvider.deleteTask(task.id!),
                  onTap: () {
                    // Show details if needed, or simple snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Completed on: ${task.deadline ?? "No Date"}')),
                    );
                  },
                );
              },
            ),
    );
  }
}
