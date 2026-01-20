// lib/ui/widgets/timer_widget.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timer_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/enums/timer_status.dart';

class TimerWidget extends StatelessWidget {
  final String? taskId; // Changed from int? to String?
  final String taskTitle;

  const TimerWidget({
    super.key,
    this.taskId,
    required this.taskTitle,
  });

  @override
  Widget build(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              taskTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              timerProvider.getFormattedTime(),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (timerProvider.status == TimerStatus.idle)
                  ElevatedButton.icon(
                    onPressed: () {
                      timerProvider.startTimer(
                        userId: authProvider.user!.uid,
                        taskId: taskId,
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                if (timerProvider.status == TimerStatus.running)
                  ElevatedButton.icon(
                    onPressed: () {
                      timerProvider.pauseTimer();
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                if (timerProvider.status == TimerStatus.paused)
                  ElevatedButton.icon(
                    onPressed: () {
                      timerProvider.resumeTimer();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                if (timerProvider.status != TimerStatus.idle)
                  ElevatedButton.icon(
                    onPressed: () {
                      _showStopReasonDialog(context, timerProvider);
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStopReasonDialog(BuildContext context, TimerProvider timerProvider) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedReason = 'completed';
        
        return AlertDialog(
          title: const Text('Stop Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Why are you stopping?'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: const [
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Task Completed'),
                  ),
                  DropdownMenuItem(
                    value: 'paused',
                    child: Text('Taking a Break'),
                  ),
                  DropdownMenuItem(
                    value: 'interrupted',
                    child: Text('Interrupted'),
                  ),
                  DropdownMenuItem(
                    value: 'lostFocus',
                    child: Text('Lost Focus'),
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
                await timerProvider.stopTimer(stopReason: selectedReason);
                Navigator.pop(context);
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }
}