// lib/ui/pages/daily_task_page.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks for ${DateFormat('MMM d').format(DateTime.now())}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Chip(
                label: Text('${todayTasks.length} tasks'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
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

  Widget _buildAllTasksTab(TaskProvider taskProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Chip(
                label: Text('${taskProvider.tasks.length} tasks'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: taskProvider.tasks.where((t) => t.status != TaskStatus.completed).length,
            itemBuilder: (context, index) {
              final task = taskProvider.tasks.where((t) => t.status != TaskStatus.completed).toList()[index];
              return ListTile(
                leading: Checkbox(
                  value: task.isSelectedForToday,
                  onChanged: (value) {
                    if (value == true) {
                      taskProvider.selectTaskForToday(task.id!);
                    } else if (value == false) {
                       // Optional: Unselect logic if needed, but currently not requested.
                       // Just keeping existing logic which was only for selecting.
                    }
                  },
                ),
                title: Text(task.title),
                subtitle: Text(
                  '${task.priority.toString().split('.').last} • ${task.status.displayName}',
                ),
                trailing: PopupMenuButton<dynamic>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value is TaskStatus) {
                      final updatedTask = task;
                      updatedTask.status = value;
                      taskProvider.updateTask(updatedTask);
                    } else if (value == 'delete') {
                      taskProvider.deleteTask(task.id!);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: TaskStatus.todo,
                      child: Text('To Do'),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.inProgress,
                      child: Text('In Progress'),
                    ),
                    const PopupMenuItem(
                      value: TaskStatus.completed,
                      child: Text('Completed'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                onTap: () => _showTaskDetails(context, task, taskProvider),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddTaskTab(String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _minutesController,
            decoration: const InputDecoration(
              labelText: 'Estimated Minutes',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _selectedPriority,
            decoration: const InputDecoration(
              labelText: 'Priority',
            ),
            items: TaskPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Text(priority.toString().split('.').last),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedPriority = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final dateRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (dateRange != null) {
                      setState(() {
                        _selectedDateRange = dateRange;
                      });
                    }
                  },
                  child: Text(
                    _selectedDateRange == null
                        ? 'Select Duration (Start - End)'
                        : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Checklist / Steps (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isGeneratingSteps)
                  const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                else

                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                        color: _isListening ? Colors.red : Colors.grey,
                        onPressed: _listenToSpeech,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('AI Suggest'),
                        onPressed: _generateAISteps,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stepController,
                  decoration: const InputDecoration(
                    labelText: 'Add a step',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue),
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
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              final step = _steps[index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.check_box_outline_blank, size: 20),
                title: Text(step.title),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _steps.removeAt(index);
                    });
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              _addTask(userId);
            },
            child: const Text('Add Task'),
          ),
        ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text('${task.status.displayName} • ${task.priority.name}'),
                  const Divider(height: 30),
                  const Text('Checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (task.steps.isEmpty)
                    const Text('No steps defined for this task.', style: TextStyle(color: Colors.grey))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: task.steps.length,
                        itemBuilder: (context, index) {
                          final step = task.steps[index];
                          return CheckboxListTile(
                            title: Text(
                              step.title,
                              style: TextStyle(
                                decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                                color: step.isCompleted ? Colors.grey : null,
                              ),
                            ),
                            value: step.isCompleted,
                            onChanged: (value) async {
                              step.isCompleted = value ?? false;
                              await taskProvider.updateTask(task);
                              setModalState(() {});
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
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
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
}