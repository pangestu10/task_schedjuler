
// lib/ui/pages/routine_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_provider.dart';
import '../../services/alarm_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class RoutineSettingsPage extends StatefulWidget {
  const RoutineSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RoutineSettingsPageState createState() => _RoutineSettingsPageState();
}

class _RoutineSettingsPageState extends State<RoutineSettingsPage> {
  late TimeOfDay _wakeTime;
  late TimeOfDay _sleepTime;
  final TextEditingController _workTargetController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _wakeTime = const TimeOfDay(hour: 7, minute: 0);
    _sleepTime = const TimeOfDay(hour: 23, minute: 0);
    _workTargetController.text = '480'; // 8 hours
    _loadSettings();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // For Android 13+
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    await androidPlugin?.requestNotificationsPermission();
    
    // Check Exact Alarm Permission
    try {
      final status = await Permission.scheduleExactAlarm.status;
      debugPrint('Permission: Schedule Exact Alarm status: $status');
      if (status.isDenied || status.isPermanentlyDenied) {
        await Permission.scheduleExactAlarm.request();
      }
    } catch (e) {
      debugPrint('Permission: Error checking exact alarm: $e');
      await androidPlugin?.requestExactAlarmsPermission();
    }
        
    // For iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _loadSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final provider = Provider.of<RoutineProvider>(context, listen: false);
    await provider.loadSettings(user.uid);
    
    final settings = provider.routineSettings;
    if (settings != null) {
      _wakeTime = TimeOfDay.fromDateTime(settings.wakeTime);
      _sleepTime = TimeOfDay.fromDateTime(settings.sleepTime);
      _workTargetController.text = settings.dailyWorkTargetMinutes.toString();
      setState(() {});
    }
  }

  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
    );
    if (picked != null) {
      setState(() {
        _wakeTime = picked;
      });
    }
  }

  Future<void> _selectSleepTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _sleepTime,
    );
    if (picked != null) {
      setState(() {
        _sleepTime = picked;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;
      
      final provider = Provider.of<RoutineProvider>(context, listen: false);
      final workTarget = int.tryParse(_workTargetController.text) ?? 480;
      
      final wakeDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _wakeTime.hour,
        _wakeTime.minute,
      );
      
      final sleepDateTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _sleepTime.hour,
        _sleepTime.minute,
      );
      
      await provider.saveSettings(
        userId: user.uid,
        wakeTime: wakeDateTime,
        sleepTime: sleepDateTime,
        dailyWorkTargetMinutes: workTarget,
      );
      
      // Set alarm for wake time
      final scheduledTime = await AlarmService.setDailyAlarm(wakeDateTime);
      
      // ignore: use_build_context_synchronously
      if (!mounted) return;
      
      final String timeStr = DateFormat('HH:mm').format(scheduledTime);
      final bool isTomorrow = scheduledTime.day != DateTime.now().day;
      final String dayStr = isTomorrow ? 'Besok (Pagi)' : 'Hari ini';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings disimpan! Alarm diset untuk $dayStr jam $timeStr ⏰'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving settings: $e');
      String message = 'Failed to save settings: $e';
      if (e.toString().contains('exact_alarms_not_permitted')) {
        message = 'Please allow "Alarms & Reminders" permission in system settings for exact alerts.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: user?.photoURL != null 
                          ? NetworkImage(user!.photoURL!) 
                          : null,
                      child: user?.photoURL == null 
                          ? Text(
                              (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? 'No Email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Routine Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.wb_sunny),
                      title: const Text('Wake Time'),
                      subtitle: Text(_wakeTime.format(context)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectWakeTime,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight),
                      title: const Text('Sleep Time'),
                      subtitle: Text(_sleepTime.format(context)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _selectSleepTime,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _workTargetController,
                        decoration: const InputDecoration(
                          labelText: 'Daily Work Target (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tips:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            const Text('• Set realistic work targets'),
            const Text('• Ensure 7-9 hours of sleep'),
            const Text('• Align wake time with natural rhythm'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await AlarmService.testAlarm();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifikasi dijadwalkan (Exact)! Tunggu 5 detik... ⏳')),
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              icon: const Icon(Icons.timer),
              label: const Text('Test Jadwal (5 Detik)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                foregroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await AlarmService.checkBatteryOptimization();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PILIH "Unrestricted" atau "Don\'t Optimize" untuk aplikasi ini.')),
                );
              },
              icon: const Icon(Icons.battery_alert),
              label: const Text('Solusi Jika Masih Belum Muncul'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // ignore: use_build_context_synchronously
                    final navigator = Navigator.of(context);
                    await authProvider.logout();
                    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
