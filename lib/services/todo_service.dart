import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todosKey = 'focusflow_todos';

  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await _getPrefs();
      final todosJson = todos.map((todo) => todo.toJson()).toList();
      await prefs.setString(_todosKey, jsonEncode(todosJson));
    } catch (e) {
      print('Error saving todos: $e');
    }
  }

  static Future<List<Todo>> loadTodos() async {
    try {
      final prefs = await _getPrefs();
      final String? todosString = prefs.getString(_todosKey);
      if (todosString == null) return [];
      
      final List<dynamic> todosJson = jsonDecode(todosString);
      return todosJson.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }
}