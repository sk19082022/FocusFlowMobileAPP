import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../widgets/stats_card.dart';
import '../widgets/task_card.dart';
import '../widgets/app_header.dart';
import '../services/task_service.dart';
import 'add_task_screen.dart';
import 'task_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueNotifier<int>? refreshTrigger;
  
  const HomeScreen({
    super.key,
    this.refreshTrigger,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Task> _tasks = [];
  String _userName = "User";
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
    widget.refreshTrigger?.addListener(_onRefreshTriggered);
  }

  @override
  void dispose() {
    widget.refreshTrigger?.removeListener(_onRefreshTriggered);
    super.dispose();
  }

  void _onRefreshTriggered() {
    _loadData();
  }

  Future<void> _initialize() async {
    await _loadUserName();
    await _loadData();
  }

  Future<void> _loadUserName() async {
    try {
      final name = await TaskService.getUserName();
      if (mounted) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      print('Error loading username: $e');
    }
  }

  Future<void> _loadData() async {
    if (_isRefreshing) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final savedTasks = await TaskService.loadTasks();
      
      if (!mounted) return;
      
      setState(() {
        _tasks = savedTasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load tasks. Please restart the app.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTasksToStorage() async {
    try {
      await TaskService.saveTasks(_tasks);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }
    await _loadData();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  int get activeTasks => _tasks.where((t) => !t.isCompletedForToday).length;
  
  int get doneToday => _tasks.where((t) => t.isCompletedForToday).length;
  
  double get avgProgress => _tasks.isEmpty 
      ? 0 
      : _tasks.map((t) => t.progressPercent).reduce((a, b) => a + b) / _tasks.length;

  Future<void> _addNewTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTaskScreen()),
    );
    
    if (result != null && result is Task && mounted) {
      setState(() {
        _tasks.add(result);
      });
      await _saveTasksToStorage();
      
      widget.refreshTrigger?.value++;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${result.name}" added successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openTaskDetail(Task task) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task, 
          onUpdate: _updateTask,
        ),
      ),
    );
    
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _toggleTaskComplete(Task task) async {
    HapticFeedback.lightImpact();
    setState(() {
      task.toggleTodayCompletion();
    });
    await _saveTasksToStorage();
    widget.refreshTrigger?.value++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.isCompletedForToday 
                ? '✅ Great job! Task completed for today!' 
                : '🔄 Task marked as incomplete',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: task.isCompletedForToday ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateTask(Task updatedTask) async {
    if (!mounted) return;
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
    });
    await _saveTasksToStorage();
    
    widget.refreshTrigger?.value++;
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "morning";
    if (hour < 17) return "afternoon";
    return "evening";
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return "${_getDayOfWeek(now.weekday)}, ${_getMonth(now.month)} ${now.day}";
  }

  String _getDayOfWeek(int weekday) {
    const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    return days[weekday - 1];
  }

  String _getMonth(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Reusable Branded Header
            const SliverToBoxAdapter(
              child: AppHeader(),
            ),
            
            // Welcome Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, $_userName 👋",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getFormattedDate(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_error!)),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    
                    if (_error == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: "Active Tasks",
                              value: activeTasks,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: "Done Today",
                              value: doneToday,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: "Avg Progress",
                              value: "${avgProgress.toInt()}%",
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      const Text(
                        "Your Tasks",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      TextButton.icon(
                        onPressed: _addNewTask,
                        icon: const Icon(Icons.add, size: 20, color: Colors.blue),
                        label: const Text(
                          "New task",
                          style: TextStyle(color: Colors.blue),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_isLoading) ...[
                        const SizedBox(height: 100),
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: Colors.blue),
                              SizedBox(height: 16),
                              Text("Loading your tasks...", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ] else if (_tasks.isEmpty) ...[
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[600]),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No Tasks Yet",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Tap the + button to create your first task",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _addNewTask,
                                    icon: const Icon(Icons.add, color: Colors.white),
                                    label: const Text(
                                      "Create First Task",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        ..._tasks.map((task) => TaskCard(
                          task: task,
                          onTap: () => _openTaskDetail(task),
                          onComplete: () => _toggleTaskComplete(task),
                        )),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}