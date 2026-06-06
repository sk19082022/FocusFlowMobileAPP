import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/task_service.dart';
import '../services/todo_service.dart';
import '../models/task.dart';
import '../models/todo.dart';
import '../widgets/app_header.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Task> _tasks = [];
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tasks = await TaskService.loadTasks();
    final todos = await TodoService.loadTodos();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _todos = todos;
        _isLoading = false;
      });
    }
  }

  // Task Metrics
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.progressPercent >= 100).length;
  int get pausedTasks => 0; // Track paused tasks (can be extended later)
  int get activeTasks => _tasks.where((t) => t.progressPercent < 100 && t.progressPercent > 0).length;
  int get focusSessionCount => _tasks.fold(0, (sum, task) => sum + task.doneDays);
  
  double get averageCompletionPercentage {
    if (_tasks.isEmpty) return 0;
    return _tasks.map((t) => t.progressPercent).reduce((a, b) => a + b) / _tasks.length;
  }
  
  int get currentStreak {
    int maxStreak = 0;
    for (var task in _tasks) {
      if (task.currentStreak > maxStreak) maxStreak = task.currentStreak;
    }
    return maxStreak;
  }
  
  int get longestStreakValue {
    int maxStreak = 0;
    for (var task in _tasks) {
      if (task.currentStreak > maxStreak) maxStreak = task.currentStreak;
    }
    return maxStreak;
  }

  // Todo Metrics
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((t) => t.isCompleted && !t.isDaily).length;
  int get pendingTodos => _todos.where((t) => !t.isCompleted && !t.isDaily && !t.isOverdue).length;
  int get overdueTodos => _todos.where((t) => t.isOverdue).length;
  int get dailyTodos => _todos.where((t) => t.isDaily).length;
  
  double get dailyTodoSuccessRate {
    if (dailyTodos == 0) return 0;
    int totalCompletions = 0;
    for (var todo in _todos.where((t) => t.isDaily)) {
      totalCompletions += todo.completedDates.length;
    }
    // Calculate average success rate based on days since creation
    final avgDays = 30; // Default tracking period
    return (totalCompletions / (dailyTodos * avgDays)) * 100;
  }

  int get totalFocusMinutes {
    return _tasks.fold(0, (sum, task) => sum + task.totalFocusMinutes);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: AppHeader()),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: _tasks.isEmpty && _todos.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Focus Task Stats Section
                          const Text(
                            "Focus Statistics",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Row 1 - Basic Task Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Tasks',
                                  '$totalTasks',
                                  Icons.task_alt,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Active Tasks',
                                  '$activeTasks',
                                  Icons.play_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Completed',
                                  '$completedTasks',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Row 2 - Focus & Streak Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Focus Sessions',
                                  '$focusSessionCount',
                                  Icons.timer,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Total Focus',
                                  '${totalFocusMinutes ~/ 60}h ${totalFocusMinutes % 60}m',
                                  Icons.access_time,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Avg Progress',
                                  '${averageCompletionPercentage.toInt()}%',
                                  Icons.trending_up,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Row 3 - Streak Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Current Streak',
                                  '$currentStreak days',
                                  Icons.local_fire_department,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Longest Streak',
                                  '$longestStreakValue days',
                                  Icons.emoji_events,
                                  Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Paused Tasks',
                                  '$pausedTasks',
                                  Icons.pause_circle,
                                  Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 24),
                          
                          // Todo Statistics Section
                          const Text(
                            "Todo Statistics",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Row 4 - Todo Basic Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Todos',
                                  '$totalTodos',
                                  Icons.checklist,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Completed',
                                  '$completedTodos',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Pending',
                                  '$pendingTodos',
                                  Icons.pending_actions,
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Row 5 - Todo Status Stats
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Overdue',
                                  '$overdueTodos',
                                  Icons.warning_amber,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Daily Habits',
                                  '$dailyTodos',
                                  Icons.repeat,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Success Rate',
                                  '${dailyTodoSuccessRate.toInt()}%',
                                  Icons.analytics,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Divider(color: Colors.grey),
                          const SizedBox(height: 24),
                          
                          // Progress Chart
                          if (_tasks.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Task Completion Chart',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        maxY: 100,
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true, 
                                              reservedSize: 40,
                                              getTitlesWidget: (value, meta) {
                                                return Text(
                                                  '${value.toInt()}%',
                                                  style: const TextStyle(fontSize: 10),
                                                );
                                              },
                                            ),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 && index < _tasks.length) {
                                                  return Text(
                                                    _tasks[index].name.length > 6
                                                        ? '${_tasks[index].name.substring(0, 5)}..'
                                                        : _tasks[index].name,
                                                    style: const TextStyle(fontSize: 8),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                              reservedSize: 40,
                                            ),
                                          ),
                                        ),
                                        barGroups: _tasks.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final task = entry.value;
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: task.progressPercent,
                                                color: task.progressPercent >= 100 
                                                    ? Colors.green 
                                                    : Colors.blue,
                                                width: 20,
                                                borderRadius: BorderRadius.circular(4),
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
                            const SizedBox(height: 24),
                          ],
                          
                          // Task Progress Details
                          if (_tasks.isNotEmpty) ...[
                            const Text(
                              'Task Progress Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._tasks.map((task) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          task.name,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: task.progressPercent >= 100 
                                              ? Colors.green.withOpacity(0.2)
                                              : Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${task.progressPercent.toInt()}%',
                                          style: TextStyle(
                                            color: task.progressPercent >= 100 ? Colors.green : Colors.blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: task.progressPercent / 100,
                                    backgroundColor: Colors.grey[800],
                                    color: task.progressPercent >= 100 ? Colors.green : Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${task.doneDays} days completed',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${task.currentStreak} day streak',
                                            style: const TextStyle(fontSize: 12, color: Colors.orange),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                          ],
                          
                          if (_todos.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Todo Progress Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._todos.where((t) => !t.isDaily).take(5).map((todo) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(12),
                                border: todo.isOverdue
                                    ? Border.all(color: Colors.red.withOpacity(0.3))
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                        size: 20,
                                        color: todo.isCompleted 
                                            ? Colors.green 
                                            : (todo.isOverdue ? Colors.red : Colors.grey),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              todo.name,
                                              style: TextStyle(
                                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                                color: todo.isCompleted ? Colors.grey : Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Due: ${todo.dueDate.day}/${todo.dueDate.month}/${todo.dueDate.year}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: todo.isOverdue ? Colors.red : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        todo.isCompleted ? 'Done' : (todo.isOverdue ? 'Overdue' : 'Pending'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: todo.isCompleted 
                                              ? Colors.green 
                                              : (todo.isOverdue ? Colors.red : Colors.orange),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                            if (_todos.where((t) => !t.isDaily).length > 5)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: Text(
                                    'And ${_todos.where((t) => !t.isDaily).length - 5} more...',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "No Analytics Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Create tasks and todos to see your progress",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh,color: Colors.white,),
            label: const Text("Refresh",style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}