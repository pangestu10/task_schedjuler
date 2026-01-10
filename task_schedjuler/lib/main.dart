// lib/main.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/alarm_service.dart';
import 'services/ai_service.dart';
import 'core/constants/api_keys.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/analytics_provider.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/register_page.dart';
import 'ui/pages/routine_settings_page.dart';
import 'ui/pages/timer_page.dart';
import 'ui/pages/daily_task_page.dart';
import 'ui/pages/insight_page.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  try {
    debugPrint('Main: Initializing AlarmService...');
    await AlarmService.initialize();
    debugPrint('Main: AlarmService initialized.');
  } catch (e) {
    debugPrint('Main: Failed to initialize AlarmService: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        Provider(create: (_) {
          final aiService = AIService();
          aiService.setApiKey(ApiKeys.groqApiKey);
          return aiService;
        }),
      ],
      child: MaterialApp(
        title: 'Daily Task Insight',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/settings': (context) => const RoutineSettingsPage(),
          '/tasks': (context) => const DailyTaskPage(),
          '/timer': (context) => const TimerPage(),
          '/insights': (context) => const InsightPage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return StreamBuilder(
      stream: authProvider.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const MainApp();
        }

        return const LoginPage();
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DailyTaskPage(),
    TimerPage(),
    const InsightPage(),
    const RoutineSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) => setState(() => _selectedIndex = index),
          surfaceTintColor: Colors.transparent, // Let container color show
          backgroundColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.task_outlined),
              selectedIcon: Icon(Icons.task),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.timer_outlined),
              selectedIcon: Icon(Icons.timer),
              label: 'Timer',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

