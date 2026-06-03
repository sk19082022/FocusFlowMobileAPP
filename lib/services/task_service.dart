import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/achievement.dart';
import '../models/user.dart';

class TaskService {
  static const String _tasksKey = 'focusflow_tasks_v3';
  static const String _achievementsKey = 'focusflow_achievements';
  static const String _userKey = 'focusflow_user';
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

  // User Management
  static Future<User> getUser() async {
    try {
      final prefs = await _getPrefs();
      final String? userString = prefs.getString(_userKey);
      if (userString != null) {
        return User.fromJson(jsonDecode(userString));
      }
      return User(name: 'User', hasCompletedOnboarding: false);
    } catch (e) {
      return User(name: 'User', hasCompletedOnboarding: false);
    }
  }

  static Future<void> saveUser(User user) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user: $e');
    }
  }

  // Achievement Management
  static Future<List<Achievement>> loadAchievements() async {
    try {
      final prefs = await _getPrefs();
      final String? achievementsString = prefs.getString(_achievementsKey);
      if (achievementsString == null) return [];
      
      final List<dynamic> achievementsJson = jsonDecode(achievementsString);
      return achievementsJson.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      print('Error loading achievements: $e');
      return [];
    }
  }

  static Future<void> saveAchievements(List<Achievement> achievements) async {
    try {
      final prefs = await _getPrefs();
      final achievementsJson = achievements.map((a) => a.toJson()).toList();
      await prefs.setString(_achievementsKey, jsonEncode(achievementsJson));
    } catch (e) {
      print('Error saving achievements: $e');
    }
  }

  static Future<void> addAchievement(Achievement achievement) async {
    final achievements = await loadAchievements();
    achievements.add(achievement);
    await saveAchievements(achievements);
  }

  // Task Management
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

    // Try current version first
    String? tasksString = prefs.getString(_tasksKey);

    // If v4 not found, try old saved data
    if (tasksString == null) {
      final oldKeys = [
        'focusflow_tasks_v3',
        'focusflow_tasks_v2',
        'focusflow_tasks'
      ];

      for (final oldKey in oldKeys) {
        final oldTasksString = prefs.getString(oldKey);

        if (oldTasksString != null) {
          // Copy old data into new v4 key
          await prefs.setString(_tasksKey, oldTasksString);
          tasksString = oldTasksString;
          break;
        }
      }
    }

    if (tasksString == null) {
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

  // User Settings
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
      await prefs.remove(_achievementsKey);
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}