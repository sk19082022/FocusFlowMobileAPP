import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/app_header.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos().then((_) {
      _checkAndResetDailyHabits();  // ← Add this line
    });
  }
  
  Future<void> _loadTodos() async {
    final todos = await TodoService.loadTodos();
    setState(() {
      _todos = todos;
      _isLoading = false;
    });
  }

    void _checkAndResetDailyHabits() {
    for (var todo in _todos) {
      if (todo.isDaily) {
        todo.resetDailyIfNeeded();
      }
    }
    _saveTodos();
  }

  Future<void> _saveTodos() async {
    await TodoService.saveTodos(_todos);
  }

  Future<void> _addTodo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );
    
    if (result != null && result is Todo && mounted) {
      setState(() {
        _todos.add(result);
      });
      await _saveTodos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todo added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleTodo(Todo todo) async {
    setState(() {
      todo.toggleComplete();
    });
    await _saveTodos();
  }

  Future<void> _deleteTodo(Todo todo) async {
    setState(() {
      _todos.removeWhere((t) => t.id == todo.id);
    });
    await _saveTodos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todo deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _getTodoStatus(Todo todo) {
    if (todo.isPermanentlyCompleted) return 'completed';
    if (todo.isDaily) return 'daily';
    if (todo.isCompleted && !todo.isDaily) return 'completed';

    if (!todo.isDaily && !todo.isCompleted) {
      final today = DateTime.now();
      final dueDate = DateTime(todo.dueDate.year, todo.dueDate.month, todo.dueDate.day);
      final normalizedToday = DateTime(today.year, today.month, today.day);

      if (normalizedToday.isAfter(dueDate)) {
        return 'overdue';
      }
      return 'pending';
    }
    return 'pending';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'pending':
        return Colors.amber;
      case 'daily':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'overdue':
        return 'Overdue';
      case 'pending':
        return 'Pending';
      case 'daily':
        return 'Daily';
      default:
        return '';
    }
  }

  List<Todo> get _pendingTodos => _todos.where((t) => 
    _getTodoStatus(t) == 'pending' && !t.isDaily).toList();
  
  List<Todo> get _dailyTodos => _todos.where((t) => 
    t.isDaily).toList();
  
  List<Todo> get _completedTodos => _todos.where((t) => 
    _getTodoStatus(t) == 'completed' && !t.isDaily).toList();
  
  List<Todo> get _overdueTodos => _todos.where((t) => 
    _getTodoStatus(t) == 'overdue').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadTodos,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: AppHeader()),
            
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "My Tasks",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addTodo,
                          icon: const Icon(Icons.add, color: Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_todos.isEmpty)
                      _buildEmptyState()
                    else ...[
                      if (_overdueTodos.isNotEmpty) ...[
                        _buildSection("Overdue", Colors.red, _overdueTodos.length),
                        ..._overdueTodos.map((todo) => _buildTodoCard(todo)),
                      ],
                      
                      if (_pendingTodos.isNotEmpty) ...[
                        _buildSection("Pending", Colors.amber, _pendingTodos.length),
                        ..._pendingTodos.map((todo) => _buildTodoCard(todo)),
                      ],
                      
                      if (_dailyTodos.isNotEmpty) ...[
                        _buildSection("Daily Habits", Colors.blue, _dailyTodos.length),
                        ..._dailyTodos.map((todo) => _buildTodoCard(todo)),
                      ],
                      
                      if (_completedTodos.isNotEmpty) ...[
                        _buildSection("Completed", Colors.green, _completedTodos.length),
                        ..._completedTodos.map((todo) => _buildTodoCard(todo)),
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
        onPressed: _addTodo,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSection(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildTodoCard(Todo todo) {
  final status = _getTodoStatus(todo);
  final statusColor = _getStatusColor(status);
  final statusLabel = _getStatusLabel(status);
  final isCompleted = status == 'completed';
  final isOverdue = status == 'overdue';
  final isDaily = todo.isDaily;
  final isPermanentlyCompleted = todo.isPermanentlyCompleted;
  final isTodayCompleted = todo.isCompletedForToday();
  
  // For daily habits, check if already completed today
  final canToggle = isDaily ? !isTodayCompleted : !isPermanentlyCompleted;
  
  return GestureDetector(
    onLongPress: isPermanentlyCompleted ? null : () => _showDeleteDialog(todo),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue ? Colors.red.withOpacity(0.3) : Colors.grey[800]!,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: canToggle ? () => _toggleTodo(todo) : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isCompleted || (isDaily && isTodayCompleted)) 
                    ? Colors.green 
                    : Colors.transparent,
                border: Border.all(
                  color: (isCompleted || (isDaily && isTodayCompleted)) 
                      ? Colors.green 
                      : Colors.grey,
                  width: 2,
                ),
              ),
              child: (isCompleted || (isDaily && isTodayCompleted))
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: (isCompleted || (isDaily && isTodayCompleted)) 
                        ? TextDecoration.lineThrough 
                        : null,
                    color: (isCompleted || (isDaily && isTodayCompleted)) 
                        ? Colors.grey 
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isDaily ? Icons.repeat : Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDaily ? "Daily" : _formatDate(todo.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (isDaily && isTodayCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Completed Today ✓",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (isPermanentlyCompleted && todo.completedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Completed on: ${_formatDate(todo.completedDate!)}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: statusColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              isDaily ? "${todo.completedDates.length} days" : statusLabel,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.bold,
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
          Icon(Icons.checklist_outlined, size: 80, color: Colors.grey[600]),
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
            "Tap the + button to add your first task",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Delete Task"),
        content: Text("Delete '${todo.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTodo(todo);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedToday = DateTime(now.year, now.month, now.day);
    
    if (normalizedDate == normalizedToday) {
      return "Today";
    }
    return "${date.day}/${date.month}/${date.year}";
  }
}

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _nameController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _isDaily = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add Task"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Task Name",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: "e.g., Complete project, Call mom...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            const Text(
              "Task Type",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text("One-Time"),
                    selected: !_isDaily,
                    onSelected: (selected) {
                      setState(() {
                        _isDaily = false;
                      });
                    },
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey[900],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilterChip(
                    label: const Text("Daily Habit"),
                    selected: _isDaily,
                    onSelected: (selected) {
                      setState(() {
                        _isDaily = true;
                      });
                    },
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey[900],
                  ),
                ),
              ],
            ),

            if (!_isDaily) ...[
              const SizedBox(height: 24),
              const Text(
                "Due Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_dueDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create Task",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _addTodo() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task name'), backgroundColor: Colors.red),
      );
      return;
    }

    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dueDate: _dueDate,
      createdAt: DateTime.now(),
      isCompleted: false,
      isDaily: _isDaily,
    );

    Navigator.pop(context, todo);
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}