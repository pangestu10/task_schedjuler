
// ignore_for_file: deprecated_member_use

// lib/ui/pages/insight_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../../services/database_service.dart';
import 'package:intl/intl.dart';

class InsightPage extends StatefulWidget {
  const InsightPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InsightPageState createState() => _InsightPageState();
}

class _InsightPageState extends State<InsightPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
    });
  }

  Future<void> _loadInsights() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    await analyticsProvider.loadInsights(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    if (authProvider.user == null) {
      return const Center(child: Text('Please login to see insights'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _showDebugData,
          ),
        ],
      ),
      body: analyticsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score Card
                  _buildScoreCard(analyticsProvider),
                  const SizedBox(height: 20),
                  

                  // Charts Row
                  if (analyticsProvider.dailyCompletionData.isNotEmpty || analyticsProvider.sessionDistribution.isNotEmpty)
                    Column(
                      children: [
                        _buildCompletionChart(analyticsProvider.dailyCompletionData),
                        const SizedBox(height: 20),
                         _buildSessionDistributionChart(analyticsProvider.sessionDistribution),
                        const SizedBox(height: 20),
                      ],
                    ),
                  

                  
                  // AI Insights
                  if (analyticsProvider.aiInsights.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Insights',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            for (var insight in analyticsProvider.aiInsights)
                              ListTile(
                                leading: const Icon(Icons.lightbulb_outline),
                                title: Text(insight),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Habit Pattern
                  if (analyticsProvider.habitPattern != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habit Pattern',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(analyticsProvider.habitPattern!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Suggestion
                  if (analyticsProvider.suggestion != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gentle Suggestion',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(analyticsProvider.suggestion!),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadInsights,
        child: const Icon(Icons.refresh),
      ),

    );
  }

  Widget _buildScoreCard(AnalyticsProvider provider) {
    final analytics = provider.lastAnalyticsData;
    
    if (analytics == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Productivity',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          analytics.performanceEmoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          analytics.productivityScore.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    analytics.performanceLevel,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDebugData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    final db = DatabaseService();
    final records = await db.getAllTimerRecords(userId);
    final snapshots = await db.getAllDailySnapshots(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Timer Records: ${records.length}'),
              const SizedBox(height: 8),
              if (records.isNotEmpty) 
                Text('Last Record: ${records.last.startTime} (${records.last.durationSeconds}s)'),
              const Divider(),
              Text('Daily Snapshots: ${snapshots.length}'),
              const SizedBox(height: 8),
              if (snapshots.isNotEmpty)
                Text('Last Snapshot: ${snapshots.first.date}\nCompleted: ${snapshots.first.completedTaskCount}/${snapshots.first.totalTaskCount}\nPlanned: ${snapshots.first.totalPlannedMinutes}m\nActual: ${snapshots.first.totalActualMinutes}m'),
              const Divider(),
              if (Provider.of<AnalyticsProvider>(context, listen: false).error != null)
                Text('AI Error: ${Provider.of<AnalyticsProvider>(context, listen: false).error}', style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart(Map<String, double> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedKeys = data.keys.toList()..sort();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Completion Rate',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()}%',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value >= sortedKeys.length) return const Text('');
                          final dateStr = sortedKeys[value.toInt()];
                          final date = DateTime.parse(dateStr);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('E').format(date),
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: sortedKeys.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = data[entry.value]!;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          color: value >= 70 ? Colors.green : Colors.blue,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionDistributionChart(Map<String, int> data) {
    final total = data.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             const Text(
              'Session Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: data.entries.map((entry) {
                    final color = _getColorForStopReason(entry.key);
                    final value = entry.value.toDouble();
                    final percentage = (value / total * 100).toStringAsFixed(1);
                    
                    return PieChartSectionData(
                      color: color,
                      value: value,
                      title: '${entry.key}\n$percentage%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getColorForStopReason(entry.key),
                    ),
                    const SizedBox(width: 4),
                    Text('${entry.key}: ${entry.value}'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForStopReason(String reason) {
    switch (reason) {
      case 'Completed':
        return Colors.green;
      case 'Interrupted':
        return Colors.orange;
      case 'Lost Focus':
        return Colors.red;
      case 'Break Taken':
        return Colors.brown;
      case 'Manual Stop':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}