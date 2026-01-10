// lib/ui/pages/timer_page.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Timer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Widget
            Card(
              elevation: 8,
              shadowColor: Colors.blue.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade50,
                      Colors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _selectedTask?.title ?? 'No Task Selected',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (_selectedTask != null)
                        Text(
                          'Estimated: ${_selectedTask!.estimatedMinutes} min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          timerProvider.getFormattedTime(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Colors.blue.shade900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 20),
                      if (_selectedTask != null && _selectedTask!.steps.isNotEmpty)
                         _buildTaskSteps(taskProvider, timerProvider),
                      if (_selectedTask != null && _selectedTask!.steps.isNotEmpty)
                        const SizedBox(height: 20),
                      _buildTimerControls(timerProvider, authProvider),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Task Selection Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Select Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        if (taskProvider.isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }



                        final availableTasks = taskProvider.tasks
                            .where((task) => task.status.index < 2) // pending or inProgress
                            .toList();

                        if (availableTasks.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No available tasks',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create some tasks first',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Current selected task
                            if (_selectedTask != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Current: ${_selectedTask!.title}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (timerProvider.status == TimerStatus.idle)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _selectedTask = null;
                                          });
                                        },
                                        color: Colors.red.shade600,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            // Available tasks list
                            ...availableTasks.map((task) => _buildTaskTile(
                              task,
                              timerProvider,
                              task == _selectedTask,
                            )),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            color: _getStatusColor(timerProvider.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(timerProvider.status).withOpacity(0.3),
            ),
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
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(timerProvider.status),
                style: TextStyle(
                  color: _getStatusColor(timerProvider.status),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Start/Resume button
            if (canStartTimer || (timerProvider.status == TimerStatus.paused && isCurrentTaskRunning))
              ElevatedButton.icon(
                onPressed: () {
                  if (timerProvider.status == TimerStatus.paused && isCurrentTaskRunning) {
                    timerProvider.resumeTimer();
                  } else if (canStartTimer) {
                    // Update status to In Progress if it's Todo
                    if (_selectedTask != null && _selectedTask!.status == TaskStatus.todo) {
                      _selectedTask!.status = TaskStatus.inProgress;
                      // We need to access TaskProvider here, assume it's available or use context
                      Provider.of<TaskProvider>(context, listen: false).updateTask(_selectedTask!);
                    }

                    timerProvider.startTimer(
                      userId: authProvider.user!.uid,
                      taskId: _selectedTask!.id,
                    );
                  }
                },
                icon: Icon(
                  timerProvider.status == TimerStatus.paused && isCurrentTaskRunning
                      ? Icons.play_arrow
                      : Icons.play_arrow,
                ),
                label: Text(
                  timerProvider.status == TimerStatus.paused && isCurrentTaskRunning
                      ? 'Resume'
                      : 'Start',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            
            // Pause button
            if (timerProvider.status == TimerStatus.running && isCurrentTaskRunning)
              ElevatedButton.icon(
                onPressed: () {
                  timerProvider.pauseTimer();
                },
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            
            // Stop button
            if (timerProvider.status != TimerStatus.idle && isCurrentTaskRunning)
              ElevatedButton.icon(
                onPressed: () {
                  _showStopReasonDialog(context, timerProvider);
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskTile(Task task, TimerProvider timerProvider, bool isSelected) {
    final isCurrentlyRunning = timerProvider.currentTaskId == task.id;
    final canSelect = timerProvider.status == TimerStatus.idle || 
                     (timerProvider.currentTaskId == task.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? Colors.blue.shade400 
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
            ? Colors.blue.shade50 
            : isCurrentlyRunning 
                ? Colors.orange.shade50
                : Colors.white,
      ),
      child: ListTile(
        enabled: canSelect,
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(task.priority),
          child: Text(
            task.title.isNotEmpty ? task.title[0].toUpperCase() : 'T',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: canSelect ? Colors.black87 : Colors.grey.shade500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated: ${task.estimatedMinutes} min',
              style: TextStyle(
                color: canSelect ? Colors.grey.shade600 : Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
            if (isCurrentlyRunning)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Currently Running',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Colors.blue.shade600,
                size: 24,
              )
            : canSelect
                ? Icon(
                    Icons.play_circle_outline,
                    color: Colors.blue.shade600,
                    size: 24,
                  )
                : Icon(
                    Icons.lock_outline,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
        onTap: canSelect
            ? () {
                setState(() {
                  _selectedTask = task;
                });
                // Update timer display to show this task's total accumulated time
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
