import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskService {
  static const String _tasksKey = 'focusflow_tasks_v3'; // New version
  static const String _userNameKey = 'user_name';
  static const String _notificationsKey = 'notifications';
  static const String _defaultFocusTimeKey = 'default_focus_time';

  static Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      print('Error getting SharedPreferences: $e');
      rethrow;
    }
  }

  // Migration for old task format (ensuring createdAt exists)
  static Future<List<Task>> _migrateOldTasks(List<dynamic> oldTasksJson) async {
    final migratedTasks = <Task>[];
    for (var json in oldTasksJson) {
      try {
        // Ensure createdAt exists, if not, use first completed date or now
        DateTime? createdAt;
        if (json['createdAt'] != null) {
          createdAt = DateTime.parse(json['createdAt']);
        } else {
          // Try to get from completed dates
          final completedDates = (json['completedDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [];
          if (completedDates.isNotEmpty) {
            completedDates.sort();
            createdAt = completedDates.first;
          } else {
            createdAt = DateTime.now();
          }
        }
        
        final task = Task(
          id: json['id'],
          name: json['name'],
          focusMinutes: json['focusMinutes'],
          createdAt: createdAt,
          completedDates: (json['completedDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
        );
        migratedTasks.add(task);
      } catch (e) {
        print('Error migrating task: $e');
        // Create a safe fallback task
        migratedTasks.add(Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Migrated Task',
          focusMinutes: 25,
          createdAt: DateTime.now(),
          completedDates: [],
        ));
      }
    }
    return migratedTasks;
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await _getPrefs();
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  static Future<List<Task>> loadTasks() async {
    try {
      final prefs = await _getPrefs();
      final String? tasksString = prefs.getString(_tasksKey);
      
      if (tasksString == null) {
        // Try to load old format and migrate
        final oldKeys = ['focusflow_tasks_v2', 'focusflow_tasks'];
        for (final oldKey in oldKeys) {
          final oldTasksString = prefs.getString(oldKey);
          if (oldTasksString != null) {
            final oldTasksJson = jsonDecode(oldTasksString);
            final migratedTasks = await _migrateOldTasks(oldTasksJson);
            await saveTasks(migratedTasks);
            await prefs.remove(oldKey);
            return migratedTasks;
          }
        }
        return [];
      }
      
      final List<dynamic> tasksJson = jsonDecode(tasksString);
      return tasksJson.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  static Future<void> deleteTask(String taskId) async {
    final tasks = await loadTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  static Future<void> updateTask(Task updatedTask) async {
    final tasks = await loadTasks();
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  static Future<String> getUserName() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getString(_userNameKey) ?? 'User';
    } catch (e) {
      return 'User';
    }
  }

  static Future<void> setUserName(String name) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userNameKey, name);
    } catch (e) {
      print('Error setting username: $e');
    }
  }

  static Future<bool> getNotificationsEnabled() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_notificationsKey) ?? true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_notificationsKey, enabled);
    } catch (e) {
      print('Error setting notifications: $e');
    }
  }

  static Future<int> getDefaultFocusTime() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getInt(_defaultFocusTimeKey) ?? 25;
    } catch (e) {
      return 25;
    }
  }

  static Future<void> setDefaultFocusTime(int minutes) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setInt(_defaultFocusTimeKey, minutes);
    } catch (e) {
      print('Error setting default focus time: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_tasksKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}