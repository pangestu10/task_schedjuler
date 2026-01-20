// lib/ui/pages/timer_page.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/timer_provider.dart';
import '../../core/models/task.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/timer_status.dart';
import '../../core/enums/task_status.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (authProvider.user != null && taskProvider.tasks.isEmpty) {
        taskProvider.loadUserTasks(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final timerProvider = Provider.of<TimerProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Focus Timer'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Atmospheric Gradient Background
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
          ),
          
          SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Immersive Timer Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark 
                        ? Colors.black.withValues(alpha: 0.3) 
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _selectedTask?.title ?? 'Ready to focus?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_selectedTask != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ESTIMATED: ${_selectedTask!.estimatedMinutes} MIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      // The Time Display
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          timerProvider.getFormattedTime(),
                          style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.w200, // Light and elegant
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTimerControls(timerProvider, authProvider),
                      if (_selectedTask != null && _selectedTask!.steps.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        _buildTaskSteps(taskProvider, timerProvider),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Task Selection Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Up Next',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${taskProvider.tasks.length}',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Task Selection List (Simplified)
                _buildTaskSelectionList(taskProvider, timerProvider),
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSelectionList(TaskProvider taskProvider, TimerProvider timerProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }

    final availableTasks = taskProvider.tasks
        .where((task) => task.status.index < 2) // pending or inProgress
        .toList();

    if (availableTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Opacity(
            opacity: 0.5,
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, size: 64),
                const SizedBox(height: 16),
                const Text('No tasks available'),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: availableTasks.length,
      itemBuilder: (context, index) {
        final task = availableTasks[index];
        return _buildTaskTile(
          task,
          timerProvider,
          task == _selectedTask,
        );
      },
    );
  }

  Widget _buildTimerControls(TimerProvider timerProvider, AuthProvider authProvider) {
    final canStartTimer = _selectedTask != null && timerProvider.status == TimerStatus.idle;
    final isCurrentTaskRunning = timerProvider.currentTaskId == _selectedTask?.id;

    return Column(
      children: [
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(timerProvider.status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(timerProvider.status).withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getStatusText(timerProvider.status).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Start/Resume button
            if (canStartTimer || (timerProvider.status == TimerStatus.paused && isCurrentTaskRunning))
              _buildControlButton(
                onPressed: () {
                  if (timerProvider.status == TimerStatus.paused && isCurrentTaskRunning) {
                    timerProvider.resumeTimer();
                  } else if (canStartTimer) {
                    if (_selectedTask != null && _selectedTask!.status == TaskStatus.todo) {
                      _selectedTask!.status = TaskStatus.inProgress;
                      Provider.of<TaskProvider>(context, listen: false).updateTask(_selectedTask!);
                    }
                    timerProvider.startTimer(
                      userId: authProvider.user!.uid,
                      taskId: _selectedTask!.id,
                    );
                  }
                },
                icon: Icons.play_arrow_rounded,
                label: timerProvider.status == TimerStatus.paused && isCurrentTaskRunning ? 'Resume' : 'Start Focus',
                color: Colors.white,
                textColor: AppTheme.primaryColor,
              ),
            
            // Pause button
            if (timerProvider.status == TimerStatus.running && isCurrentTaskRunning)
              _buildControlButton(
                onPressed: () => timerProvider.pauseTimer(),
                icon: Icons.pause_rounded,
                label: 'Pause',
                color: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
              ),
            
            if (timerProvider.status != TimerStatus.idle && isCurrentTaskRunning) ...[
              const SizedBox(width: 16),
              // Stop button
              _buildControlButton(
                onPressed: () => _showStopReasonDialog(context, timerProvider),
                icon: Icons.stop_rounded,
                label: 'Stop',
                color: Colors.white.withValues(alpha: 0.2),
                textColor: Colors.white,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildTaskTile(Task task, TimerProvider timerProvider, bool isSelected) {
    final isCurrentlyRunning = timerProvider.currentTaskId == task.id;
    final canSelect = timerProvider.status == TimerStatus.idle || (timerProvider.currentTaskId == task.id);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected 
          ? theme.colorScheme.primary.withValues(alpha: 0.08) 
          : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected 
            ? theme.colorScheme.primary.withValues(alpha: 0.5) 
            : theme.dividerColor.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        enabled: canSelect,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority).withAlpha(0x1A), // 0.1 * 255 = 25.5, so 0x1A
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.task_alt_rounded,
              color: _getPriorityColor(task.priority),
              size: 20,
            ),
          ),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: canSelect ? null : theme.disabledColor,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${task.estimatedMinutes} mins • ${task.priority.name.toUpperCase()}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: isCurrentlyRunning
            ? Icon(Icons.bolt_rounded, color: Colors.amber, size: 28)
            : isSelected
                ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 28)
                : Icon(Icons.play_circle_outline_rounded, color: theme.hintColor.withAlpha(0x4D), size: 28), // 0.3 * 255 = 76.5, so 0x4D
        onTap: canSelect
            ? () {
                setState(() => _selectedTask = task);
                Provider.of<TimerProvider>(context, listen: false).selectTask(task.id!);
              }
            : null,
      ),
    );
  }



  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.critical:
        return Colors.purple;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  Color _getStatusColor(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return Colors.grey;
      case TimerStatus.running:
        return Colors.green;
      case TimerStatus.paused:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(TimerStatus status) {
    switch (status) {
      case TimerStatus.idle:
        return 'Ready to Start';
      case TimerStatus.running:
        return 'Timer Running';
      case TimerStatus.paused:
        return 'Timer Paused';
      default:
        return 'Unknown Status';
    }
  }

  void _showStopReasonDialog(BuildContext context, TimerProvider timerProvider) {
    String selectedReason = 'completed';
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stop Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you stopping the timer?'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Task Completed'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'paused',
                    child: Row(
                      children: [
                        Icon(Icons.coffee, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Taking a Break'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'interrupted',
                    child: Row(
                      children: [
                        Icon(Icons.notifications_off, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Interrupted'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'lostFocus',
                    child: Row(
                      children: [
                        Icon(Icons.phonelink_erase, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Lost Focus'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  selectedReason = value!;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final shouldReset = selectedReason == 'completed';
                if (shouldReset && _selectedTask != null) {
                   // Create a copy with updated status to avoid reference issues
                   final updatedTask = _selectedTask!.copyWith(status: TaskStatus.completed);
                   await Provider.of<TaskProvider>(context, listen: false).updateTask(updatedTask);
                   
                   if (mounted) {
                     setState(() {
                       _selectedTask = null; // Clear selection to prevent confusion
                     });
                   }
                }

                await timerProvider.stopTimer(
                  stopReason: selectedReason, 
                );
                Navigator.pop(context);
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(shouldReset 
                          ? 'Timer completed! Data sent to AI for analysis. 🤖' 
                          : 'Timer accumulated (Reason: $selectedReason)'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop Timer'),
            ),
          ],
        );
      },
    );
  }


  Widget _buildTaskSteps(TaskProvider taskProvider, TimerProvider timerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Checklist - Step History', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _selectedTask!.steps.length,
          itemBuilder: (context, index) {
            final step = _selectedTask!.steps[index];
            return CheckboxListTile(
              dense: true,
              value: step.isCompleted,
              title: Text(
                step.title,
                style: TextStyle(
                  decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                  color: step.isCompleted ? Colors.grey : null,
                ),
              ),
              subtitle: step.isCompleted && step.durationSeconds > 0
                  ? Text(
                      'Completed in: ${_formatDuration(step.durationSeconds)}',
                      style: const TextStyle(
                        color: Colors.green, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
              onChanged: (value) async {
                if (_selectedTask == null) return;
                
                // Logic: 
                // IF Checking:
                //   Duration = CurrentTimerElapsed - Sum(OtherCompletedSteps)
                //   If Duration < 0, default to 0. (Can happen if user stops/resets timer)
                // IF Unchecking:
                //   Duration = 0
                
                int newDuration = 0;
                if (value == true) {
                   final currentTotalElapsed = timerProvider.elapsedSeconds;
                   final alreadyAccountedSeconds = _selectedTask!.steps
                       .where((s) => s.isCompleted && s.id != step.id)
                       .fold(0, (sum, s) => sum + s.durationSeconds);
                   
                   newDuration = currentTotalElapsed - alreadyAccountedSeconds;
                   if (newDuration < 0) newDuration = 0;
                }

                step.isCompleted = value ?? false;
                step.durationSeconds = newDuration;
                
                // Update in Provider/DB
                await taskProvider.updateTask(_selectedTask!);
                setState(() {});
              },
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}  
