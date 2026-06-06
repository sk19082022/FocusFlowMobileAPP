import 'package:flutter/material.dart';
import '../services/task_service.dart';
import '../services/todo_service.dart';
import '../models/achievement.dart';
import '../models/todo.dart';
import '../widgets/app_header.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<Achievement> _achievements = [];
  List<Todo> _completedTodos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final achievements = await TaskService.loadAchievements();
    final todos = await TodoService.loadTodos();
    // Get permanently completed one-time todos
    final completedTodos = todos.where((t) => 
      t.isPermanentlyCompleted && !t.isDaily
    ).toList();
    
    setState(() {
      _achievements = achievements.reversed.toList();
      _completedTodos = completedTodos.reversed.toList();
      _isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasAchievements = _achievements.isNotEmpty || _completedTodos.isNotEmpty;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        const Text(
                          'Achievements',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_achievements.length + _completedTodos.length} tasks completed',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (!hasAchievements)
                      _buildEmptyState()
                    else ...[
                      if (_achievements.isNotEmpty) ...[
                        const Text(
                          'Focus Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._achievements.map((achievement) => _buildAchievementCard(
                          name: achievement.taskName,
                          startDate: achievement.createdAt,
                          completeDate: achievement.completedAt,
                          details: '🎯 ${achievement.totalDaysTracked} days tracked • ⏱️ ${achievement.focusMinutes} min sessions',
                        )),
                        const SizedBox(height: 16),
                      ],
                      
                      if (_completedTodos.isNotEmpty) ...[
                        const Text(
                          'Completed Tasks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._completedTodos.map((todo) => _buildAchievementCard(
                          name: todo.name,
                          startDate: todo.createdAt,
                          completeDate: todo.completedDate ?? todo.dueDate,
                          details: 'One-time task • Completed on time',
                        )),
                      ],
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

  Widget _buildAchievementCard({
    required String name,
    required DateTime startDate,
    required DateTime completeDate,
    required String details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Started: ${_formatDate(startDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Completed: ${_formatDate(completeDate)}',
                      style: const TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            "No Achievements Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Complete tasks and maintain habits to earn achievements",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}