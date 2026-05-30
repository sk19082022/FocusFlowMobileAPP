import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/streak_calendar.dart';
import '../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onUpdate;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.onUpdate,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task task;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _remainingSeconds = task.focusMinutes * 60;
    _checkTodayCompletion();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _checkTodayCompletion() {
    if (!mounted) return;
    setState(() {
      _isCompleted = task.isCompletedForToday;
    });
  }

  void _startTimer() {
    if (_remainingSeconds <= 0) {
      _remainingSeconds = task.focusMinutes * 60;
    }

    if (!mounted) return;
    setState(() {
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        }

        if (_remainingSeconds == 0) {
          _stopTimer();
          _completeFocusSession();
        }
      });
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
    if (!mounted) return;
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    if (!mounted) return;
    setState(() {
      _remainingSeconds = task.focusMinutes * 60;
    });
  }

  Future<void> _completeFocusSession() async {
    final today = DateTime.now();
    
    if (!task.completedDates.any((d) => _isSameDay(d, today))) {
      if (!mounted) return;
      setState(() {
        task.completedDates.add(today);
        _isCompleted = true;
      });
      
      widget.onUpdate(task);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 12),
                Text('Great focus session completed! 🎉'),
              ],
            ),
            backgroundColor: Colors.green[800],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already completed this task today!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _stopTimer();
            Navigator.pop(context);
          },
        ),
        title: const Text("Task Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset Progress'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Task'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              } else if (value == 'reset') {
                _showResetDialog();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                task.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        "Completed Today",
                        style: TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              
              // Timer Section
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  shape: BoxShape.circle,
                ),
                child: Column(
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${task.focusMinutes}m focus session",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isTimerRunning || _remainingSeconds != task.focusMinutes * 60)
                          IconButton(
                            onPressed: _resetTimer,
                            icon: const Icon(Icons.refresh, color: Colors.grey),
                            tooltip: 'Reset',
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isCompleted ? null : (_isTimerRunning ? _stopTimer : _startTimer),
                          icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(_isTimerRunning ? "Pause" : "Start Focus"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCompleted ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "${task.progressPercent.toInt()}%",
                      "Completion",
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      "${task.doneDays}",
                      "Done Days",
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      "${task.currentStreak}",
                      "Current Streak",
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Calendar
              StreakCalendar(task: task,  // Pass the full task object instead of just completedDates
                onDateSelected: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _stopTimer();
              
              final tasks = await TaskService.loadTasks();
              tasks.removeWhere((t) => t.id == task.id);
              await TaskService.saveTasks(tasks);
              
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Reset Progress"),
        content: Text(
          "Are you sure you want to reset progress for '${task.name}'? All completed dates will be cleared.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() {
                task.completedDates.clear();
                _isCompleted = false;
                _stopTimer();
                _remainingSeconds = task.focusMinutes * 60;
              });
              widget.onUpdate(task);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Progress has been reset'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }
}