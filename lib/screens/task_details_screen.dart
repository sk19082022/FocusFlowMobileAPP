import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task.dart';
import '../widgets/streak_calendar.dart';
import '../services/task_service.dart';
import '../models/achievement.dart';

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

class _TaskDetailScreenState extends State<TaskDetailScreen> with WidgetsBindingObserver {
  late Task task;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _isCompleted = false;
  bool _isPaused = false;
  bool _isPermanentlyCompleted = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    task = widget.task;
    _restoreTimerState();
    _checkTodayCompletion();
    _checkTaskStatus();
    _isInitialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App going to background - save timer state
      _saveCurrentTimerState();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground - restore timer state
      _restoreTimerState();
    }
  }

  void _restoreTimerState() {
    if (task.timerState != null) {
      // Restore from saved state
      final elapsed = task.getElapsedSecondsSinceLastTick();
      _remainingSeconds = (task.timerState!.remainingSeconds - elapsed).clamp(0, task.timerState!.remainingSeconds);
      _isTimerRunning = task.timerState!.isRunning;
      _isPaused = task.timerState!.isPaused;
      
      if (_isTimerRunning && _remainingSeconds > 0) {
        // Timer was running, resume it
        _startTimer(fromRestore: true);
      }
    } else {
      // No saved state, use default
      _remainingSeconds = task.focusMinutes * 60;
      _isTimerRunning = false;
      _isPaused = false;
    }
  }

  void _saveCurrentTimerState() {
    if (_isTimerRunning || _isPaused) {
      task.saveTimerState(_remainingSeconds, _isTimerRunning, _isPaused, DateTime.now());
      widget.onUpdate(task);
    } else {
      task.clearTimerState();
      widget.onUpdate(task);
    }
  }

  @override
  void dispose() {
    _saveCurrentTimerState();
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _checkTodayCompletion() {
    if (!mounted) return;
    setState(() {
      _isCompleted = task.isCompletedForToday;
    });
  }

  void _checkTaskStatus() {
    if (task.status == TaskStatus.completed) {
      setState(() {
        _isPermanentlyCompleted = true;
      });
    } else if (task.status == TaskStatus.paused) {
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _startTimer({bool fromRestore = false}) {
    if (_remainingSeconds <= 0) {
      _remainingSeconds = task.focusMinutes * 60;
    }

    if (!mounted) return;
    
    if (!fromRestore) {
      setState(() {
        _isTimerRunning = true;
        _isPaused = false;
      });
      _saveCurrentTimerState();
    } else {
      setState(() {
        _isTimerRunning = true;
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          // Save state every 5 seconds to avoid excessive writes
          if (_remainingSeconds % 5 == 0) {
            _saveCurrentTimerState();
          }
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
      _isTimerRunning = false;
      _isPaused = false;
    });
    task.clearTimerState();
    widget.onUpdate(task);
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
      _isPaused = true;
    });
    _saveCurrentTimerState();
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _resumeTimer() {
    setState(() {
      _isTimerRunning = true;
      _isPaused = false;
    });
    _startTimer();
  }

  Future<void> _completeFocusSession() async {
    final today = DateTime.now();
    
    if (!task.completedDates.any((d) => _isSameDay(d, today))) {
      if (!mounted) return;
      setState(() {
        task.completeFocusSession();
        _isCompleted = true;
        _isTimerRunning = false;
      });
      
      task.clearTimerState();
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

  void _addSubTask() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Add Sub-Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter sub-task name",
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  task.addSubTask(name);
                });
                widget.onUpdate(task);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sub-task added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _editSubTask(SubTask subTask) {
    final controller = TextEditingController(text: subTask.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Edit Sub-Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Edit sub-task name",
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != subTask.name) {
                setState(() {
                  task.updateSubTask(subTask.id, newName);
                });
                widget.onUpdate(task);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sub-task updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteSubTask(SubTask subTask) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Delete Sub-Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Delete '${subTask.name}'?",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                task.deleteSubTask(subTask.id);
              });
              widget.onUpdate(task);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sub-task deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editTask() {
    final nameController = TextEditingController(text: task.name);
    final minutesController = TextEditingController(text: task.focusMinutes.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Edit Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Task Name",
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: minutesController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Focus Minutes",
                labelStyle: TextStyle(color: Colors.grey),
                helperText: "Note: Changing duration won't affect previous sessions",
                helperStyle: TextStyle(color: Colors.orange, fontSize: 10),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newMinutes = int.tryParse(minutesController.text.trim());
              
              if (newName.isNotEmpty && newName != task.name) {
                task.editName(newName);
              }
              
              if (newMinutes != null && newMinutes > 0 && newMinutes != task.focusMinutes) {
                task.editFocusMinutes(newMinutes);
                _remainingSeconds = newMinutes * 60;
              }
              
              widget.onUpdate(task);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _permanentlyCompleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Complete Task Permanently",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure? This task will be marked as completed and moved to Achievements. You won't be able to edit or use the timer for this task again.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final achievement = Achievement(
                taskId: task.id,
                taskName: task.name,
                createdAt: task.createdAt,
                completedAt: DateTime.now(),
                focusMinutes: task.focusMinutes,
                totalDaysTracked: task.completedDates.length,
              );
              
              await TaskService.addAchievement(achievement);
              
              task.permanentlyComplete();
              widget.onUpdate(task);
              
              if (mounted) {
                setState(() {
                  _isPermanentlyCompleted = true;
                  _isPaused = false;
                  _isCompleted = true;
                  _stopTimer();
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task completed! 🎉 Moved to Achievements'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Complete Task"),
          ),
        ],
      ),
    );
  }

  void _pauseTask() {
    if (_isTimerRunning) {
      _pauseTimer();
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Pause Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Pause this task?\n\nYou can resume it later from the menu.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isPaused = true;
                _isTimerRunning = false;
                _stopTimer();
              });
              task.pauseTask();
              widget.onUpdate(task);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task paused'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text("Pause"),
          ),
        ],
      ),
    );
  }

  void _resumeTask() {
    setState(() {
      _isPaused = false;
    });
    task.resumeTask();
    widget.onUpdate(task);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task resumed! Ready to focus.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTaskStatusText() {
    if (_isPermanentlyCompleted) return "Completed";
    if (_isPaused) return "Paused";
    if (_isCompleted) return "Done Today";
    return "Active";
  }

  Color _getTaskStatusColor() {
    if (_isPermanentlyCompleted) return Colors.green;
    if (_isPaused) return Colors.orange;
    if (_isCompleted) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final canStartTimer = !_isPaused && !_isPermanentlyCompleted && !_isCompleted;
    final editHistory = task.getRecentEditHistory();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _saveCurrentTimerState();
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
              const PopupMenuItem(value: 'add_subtask', child: Text('📋 Add Sub-Task')),
              const PopupMenuItem(value: 'edit', child: Text('✏️ Edit Task')),
              if (!_isPermanentlyCompleted && task.status != TaskStatus.completed)
                const PopupMenuItem(value: 'complete', child: Text('✅ Complete Task Permanently')),
              if (!_isPaused && !_isPermanentlyCompleted && !_isCompleted && task.status != TaskStatus.paused)
                const PopupMenuItem(value: 'pause', child: Text('⏸️ Pause Task')),
              if (_isPaused || task.status == TaskStatus.paused)
                const PopupMenuItem(value: 'resume', child: Text('▶️ Resume Task')),
              const PopupMenuItem(value: 'reset', child: Text('🔄 Reset Progress')),
              const PopupMenuItem(value: 'delete', child: Text('🗑️ Delete Task')),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              } else if (value == 'reset') {
                _showResetDialog();
              } else if (value == 'edit') {
                _editTask();
              } else if (value == 'complete') {
                _permanentlyCompleteTask();
              } else if (value == 'pause') {
                _pauseTask();
              } else if (value == 'resume') {
                _resumeTask();
              } else if (value == 'add_subtask') {
                _addSubTask();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Task Name and Status Badge
              const SizedBox(height: 8),
              Text(
                task.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  decoration: _isPermanentlyCompleted 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: _isPermanentlyCompleted ? Colors.grey : Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Status Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTaskStatusColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getTaskStatusColor()),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPermanentlyCompleted ? Icons.check_circle :
                        _isPaused ? Icons.pause_circle :
                        _isCompleted ? Icons.check_circle :
                        Icons.play_circle,
                        color: _getTaskStatusColor(),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTaskStatusText(),
                        style: TextStyle(
                          color: _getTaskStatusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Timer Section (only show if not permanently completed)
              if (!_isPermanentlyCompleted)
                Column(
                  children: [
                    // Timer Circle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(20),
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
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Timer Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isTimerRunning || _remainingSeconds != task.focusMinutes * 60)
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            child: IconButton(
                              onPressed: _resetTimer,
                              icon: const Icon(Icons.refresh, color: Colors.grey),
                              tooltip: 'Reset',
                              iconSize: 32,
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: canStartTimer 
                              ? (_isTimerRunning ? _pauseTimer : _startTimer)
                              : null,
                          icon: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                          label: Text(_isTimerRunning ? "Pause" : "Start Focus"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !canStartTimer 
                                ? Colors.grey 
                                : (_isTimerRunning ? Colors.orange : Colors.blue),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                // Completed Task Message
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Task Completed! 🎉",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "You've successfully completed this task.\n${task.doneDays} days of focus achieved!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
              StreakCalendar(
                task: task,
                onDateSelected: () {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              
              // Edit History Section
              Row(
                children: [
                  const Icon(Icons.history, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${editHistory.length} changes',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (editHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No edit history yet',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                )
              else
                ...editHistory.map((record) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: record.editType == EditType.rename 
                              ? Colors.orange.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          record.editType == EditType.rename 
                              ? Icons.edit_note
                              : Icons.timer,
                          color: record.editType == EditType.rename 
                              ? Colors.orange
                              : Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.getEditTypeDisplay(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${record.oldValue} → ${record.newValue}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatDateTime(record.dateTime),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
              const SizedBox(height: 24),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              
              // Sub-Tasks Section
              Row(
                children: [
                  const Icon(Icons.checklist, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Sub-Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (task.totalSubTasksCount > 0)
                    Text(
                      '${task.completedSubTasksCount}/${task.totalSubTasksCount} completed',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (task.subTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.checklist_outlined, size: 40, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        'No sub-tasks yet',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _addSubTask,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sub-Task'),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    ...task.subTasks.map((subTask) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: subTask.isCompleted 
                              ? Colors.green.withOpacity(0.3)
                              : Colors.grey[800]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                task.toggleSubTask(subTask.id);
                              });
                              widget.onUpdate(task);
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: subTask.isCompleted ? Colors.green : Colors.transparent,
                                border: Border.all(
                                  color: subTask.isCompleted ? Colors.green : Colors.grey,
                                  width: 2,
                                ),
                              ),
                              child: subTask.isCompleted
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subTask.name,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
                                color: subTask.isCompleted ? Colors.grey : Colors.white,
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editSubTask(subTask);
                              } else if (value == 'delete') {
                                _deleteSubTask(subTask);
                              }
                            },
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addSubTask,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Another Sub-Task'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
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
        title: const Text(
          "Delete Task",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this task? This action cannot be undone.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
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
        title: const Text(
          "Reset Progress",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to reset progress for '${task.name}'?\n\nAll completed dates will be cleared.",
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              setState(() {
                task.completedDates.clear();
                task.focusSessions.clear();
                _isCompleted = false;
                _isPaused = false;
                _isPermanentlyCompleted = false;
                _stopTimer();
                _remainingSeconds = task.focusMinutes * 60;
              });
              task.clearTimerState();
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