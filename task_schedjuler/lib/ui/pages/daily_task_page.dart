// lib/ui/pages/daily_task_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart'; // Import NotificationProvider
import '../../core/models/task.dart';
import '../../core/enums/task_priority.dart';
import '../../core/enums/task_status.dart';
import '../../ui/widgets/task_card.dart';
import '../../core/models/task_step.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'history_page.dart';


class DailyTaskPage extends StatefulWidget {
  const DailyTaskPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DailyTaskPageState createState() => _DailyTaskPageState();
}

class _DailyTaskPageState extends State<DailyTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTimeRange? _selectedDateRange;
  final List<TaskStep> _steps = [];
  final TextEditingController _stepController = TextEditingController();

  bool _isGeneratingSteps = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(); // Fetch notifications
    });
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.loadUserTasks(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Daily Tasks'),
          actions: [
            // Notification Icon
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, child) {
                // Determine if we need to fetch initial notifications
                // Ideally do this in initState, but okay for now or use bool check
                if (notifProvider.notifications.isEmpty && !notifProvider.isLoading) {
                   // Initial fetch? Be careful of infinite loops in build. 
                   // Better to fetch in initState.
                }
                
                return IconButton(
                  icon: Badge(
                    label: Text('${notifProvider.unreadCount}'),
                    isLabelVisible: notifProvider.unreadCount > 0,
                    child: const Icon(Icons.notifications),
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'History Pengerjaan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),

          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today\'s Tasks'),
              Tab(text: 'All Tasks'),
              Tab(text: 'Add Task'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Today's Tasks Tab
            _buildTodayTasksTab(taskProvider),
            // All Tasks Tab
            _buildAllTasksTab(taskProvider),
            // Add Task Tab
            _buildAddTaskTab(authProvider.user?.uid ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTasksTab(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final todayTasks = taskProvider.todayTasks;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Dashboard Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello there!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You have ${todayTasks.length} tasks for today',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Mini progress or date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: todayTasks.isEmpty 
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                itemCount: todayTasks.length,
                itemBuilder: (context, index) {
                  final task = todayTasks[index];
                  return TaskCard(
                    task: task,
                    onStatusChange: (status) {
                      final updatedTask = task;
                      updatedTask.status = status;
                      taskProvider.updateTask(updatedTask);
                    },
                    onDelete: () => taskProvider.deleteTask(task.id!),
                    onTap: () => _showTaskDetails(context, task, taskProvider),
                  );
                },
              ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt_rounded, size: 80, color: Theme.of(context).disabledColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No tasks for today',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Tap "Add Task" to start your day!'),
        ],
      ),
    );
  }

  Widget _buildAllTasksTab(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final pendingTasks = taskProvider.tasks
        .where((t) => t.status != TaskStatus.completed)
        .toList();
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Tasks',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pendingTasks.length} Pending',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: pendingTasks.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: pendingTasks.length,
                  itemBuilder: (context, index) {
                    final task = pendingTasks[index];
                    return TaskCard(
                      task: task,
                      leading: Checkbox(
                        value: task.isSelectedForToday,
                        activeColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (value) {
                          if (value == true) {
                            taskProvider.selectTaskForToday(task.id!);
                          }
                        },
                      ),
                      onStatusChange: (status) {
                        final updatedTask = task;
                        updatedTask.status = status;
                        taskProvider.updateTask(updatedTask);
                      },
                      onDelete: () => taskProvider.deleteTask(task.id!),
                      onTap: () => _showTaskDetails(context, task, taskProvider),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddTaskTab(String userId) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Task',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildInputField(
            controller: _titleController,
            label: 'Task Title',
            icon: Icons.title_rounded,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            controller: _minutesController,
            label: 'Estimated Minutes',
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<TaskPriority>(
            initialValue: _selectedPriority,
            decoration: InputDecoration(
              labelText: 'Priority',
              prefixIcon: const Icon(Icons.flag_outlined),
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: TaskPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPriority = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Date Range Picker
          InkWell(
            onTap: () async {
              final dateRange = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: theme.colorScheme.copyWith(
                        primary: AppTheme.primaryColor,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (dateRange != null) {
                setState(() {
                  _selectedDateRange = dateRange;
                });
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, color: theme.hintColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateRange == null
                          ? 'Select Duration (Start - End)'
                          : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                      style: TextStyle(
                        color: _selectedDateRange == null ? theme.hintColor : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.hintColor),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Checklist Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sub-Tasks / Steps',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_isGeneratingSteps)
                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Row(
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : AppTheme.primaryColor),
                      onPressed: _listenToSpeech,
                    ),
                    TextButton.icon(
                      onPressed: _generateAISteps,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('AI Suggest'),
                      style: TextButton.styleFrom(foregroundColor: Colors.purple),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stepController,
                  decoration: InputDecoration(
                    hintText: 'Add a new step...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    if (_stepController.text.isNotEmpty) {
                      setState(() {
                        _steps.add(TaskStep(
                          id: const Uuid().v4(),
                          title: _stepController.text,
                        ));
                        _stepController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          
          if (_steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle_outlined, size: 18),
                    title: Text(step.title),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                      onPressed: () => setState(() => _steps.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          ],
          
          const SizedBox(height: 48),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _addTask(userId),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              child: const Text(
                'Create Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }

  void _addTask(String userId) {
    if (_titleController.text.isEmpty) return;

    final task = Task(
      userId: userId,
      title: _titleController.text,

      priority: _selectedPriority,
      deadline: _selectedDateRange?.end,
      startDate: _selectedDateRange?.start,
      estimatedMinutes: int.tryParse(_minutesController.text) ?? 30,
      status: TaskStatus.todo,
      createdAt: DateTime.now(),
      isSelectedForToday: _selectedDateRange != null && 
                          DateTime.now().isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                          DateTime.now().isBefore(_selectedDateRange!.end.add(const Duration(days: 1))),
      selectedDate: (_selectedDateRange != null && 
                          DateTime.now().isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                          DateTime.now().isBefore(_selectedDateRange!.end.add(const Duration(days: 1)))) 
                          ? DateTime.now() : null,
      steps: List.from(_steps),
    );

    Provider.of<TaskProvider>(context, listen: false).addTask(task);
    
    _titleController.clear();
    _minutesController.clear();
    _selectedDateRange = null;
    setState(() {
      _steps.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task added')),
    );
  }


  void _showTaskDetails(BuildContext context, Task task, TaskProvider taskProvider) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              Text(
                'Sub-Tasks',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (task.steps.isEmpty)
                Text('No sub-tasks defined.', style: TextStyle(color: theme.hintColor))
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: task.steps.length,
                    itemBuilder: (context, index) {
                      final step = task.steps[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              step.isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                              color: step.isCompleted ? AppTheme.accentColor : theme.hintColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                step.title,
                                style: TextStyle(
                                  decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                                  color: step.isCompleted ? theme.disabledColor : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Collaborators',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showInviteDialog(context, task, taskProvider),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                  // ownerId is the definitive owner, task.userId is a fallback
                  final ownerId = task.ownerId ?? task.userId;
                  final allTeamIds = {ownerId, ...task.collaborators};
                  final others = allTeamIds.where((id) => id != currentUserId).toList();
                  
                  if (others.isEmpty) {
                    return Text('No other members in this project.', style: TextStyle(color: theme.hintColor));
                  }
                  
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: others.length,
                      itemBuilder: (context, index) {
                        final memberId = others[index];
                        final isMemberOwner = memberId == ownerId;
                        
                        return FutureBuilder<Map<String, dynamic>>(
                          future: taskProvider.getCollaboratorInfo(memberId),
                          builder: (context, snapshot) {
                            String name = 'Loading...';
                            String? photoUrl;
                            if (snapshot.hasData) {
                              final data = snapshot.data!;
                              name = data['email'] ?? data['displayName'] ?? 'Unknown User';
                              photoUrl = data['photoURL'];
                            }
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                backgroundColor: isMemberOwner ? AppTheme.accentColor.withValues(alpha: 0.1) : AppTheme.primaryColor.withValues(alpha: 0.1),
                                child: photoUrl == null ? Icon(isMemberOwner ? Icons.star_rounded : Icons.person, size: 18, color: isMemberOwner ? AppTheme.accentColor : null) : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  if (isMemberOwner)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
                                      ),
                                      child: const Text('OWNER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                                    ),
                                ],
                              ),
                              trailing: (currentUserId == ownerId && !isMemberOwner) 
                                ? IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                                    onPressed: () async {
                                      await taskProvider.removeCollaborator(task.id!, memberId);
                                      // Refresh list after removal
                                      Navigator.pop(context);
                                    },
                                    tooltip: 'Remove Collaborator',
                                  )
                                : null,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              if (task.status != TaskStatus.completed)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to Timer and select this task
                      // This part requires access to the TabController or a way to switch tabs
                      // For now, we'll just show the feedback
                    },
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Focus on This Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(BuildContext context, TaskPriority priority) {
    final color = _getPriorityColor(context, priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TaskStatus status) {
    final color = _getStatusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return Colors.green;
      case TaskPriority.medium: return Colors.blue;
      case TaskPriority.high: return Colors.orange;
      case TaskPriority.critical: return Colors.red;
    }
  }

  Color _getStatusColor(BuildContext context, TaskStatus status) {
    switch (status) {
      case TaskStatus.completed: return AppTheme.accentColor;
      case TaskStatus.inProgress: return Colors.amber;
      case TaskStatus.todo:
      default: return AppTheme.primaryColor;
    }
  }

  Future<void> _generateAISteps() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Task Title first')),
      );
      return;
    }

    setState(() {
      _isGeneratingSteps = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final suggestions = await taskProvider.generateSteps(_titleController.text);
      
      setState(() {
        for (var stepTitle in suggestions) {
          _steps.add(TaskStep(
            id: const Uuid().v4(),
            title: stepTitle,
          ));
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate steps: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSteps = false;
        });
      }
    }
  }


  Future<void> _listenToSpeech() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (val.hasConfidenceRating && val.confidence > 0) {
              // Wait for final result
            }
            if (val.finalResult) {
              setState(() {
                _titleController.text = val.recognizedWords;
                _isListening = false;
              });
              // Automatically trigger AI suggestion after speaking
              _generateAISteps();
            }
          },
          localeId: 'id_ID', // Indonesian locale
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition not available')),
        );
      }
    } else {
      _speech.stop();
    }
  }

  void _showInviteDialog(BuildContext context, Task task, TaskProvider taskProvider) {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite Collaborator'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Enter user email'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await taskProvider.inviteUser(task.id!, email);
                    navigator.pop(); // Close Dialog
                    navigator.pop(); // Close BottomSheet
                    messenger.showSnackBar(
                      SnackBar(content: Text('Invitation sent to $email')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to invite: $e')),
                    );
                  }
                }
              },
              child: const Text('Invite'),
            ),
          ],
        );
      },
    );
  }
}