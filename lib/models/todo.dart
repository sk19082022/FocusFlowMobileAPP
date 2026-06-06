class Todo {
  String id;
  String name;
  DateTime dueDate;
  DateTime createdAt;
  bool isCompleted;
  bool isDaily;
  List<DateTime> completedDates;
  DateTime? completedDate; // NEW: Store permanent completion date
  bool isPermanentlyCompleted; // NEW: For one-time todos

  Todo({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.createdAt,
    this.isCompleted = false,
    this.isDaily = false,
    List<DateTime>? completedDates,
    this.completedDate,
    this.isPermanentlyCompleted = false,
  }) : completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'isDaily': isDaily,
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'completedDate': completedDate?.toIso8601String(),
    'isPermanentlyCompleted': isPermanentlyCompleted,
  };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    name: json['name'],
    dueDate: DateTime.parse(json['dueDate']),
    createdAt: DateTime.parse(json['createdAt']),
    isCompleted: json['isCompleted'],
    isDaily: json['isDaily'],
    completedDates: (json['completedDates'] as List?)
        ?.map((d) => DateTime.parse(d))
        .toList() ?? [],
    completedDate: json['completedDate'] != null 
        ? DateTime.parse(json['completedDate'])
        : null,
    isPermanentlyCompleted: json['isPermanentlyCompleted'] ?? false,
  );

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool get isOverdue {
    if (isPermanentlyCompleted) return false;
    if (isCompleted && !isDaily) return false;
    if (isDaily) return false;
    
    final today = _normalizeDate(DateTime.now());
    final due = _normalizeDate(dueDate);
    
    return today.isAfter(due) && !isCompleted;
  }

  bool get isPending {
    if (isPermanentlyCompleted) return false;
    if (isCompleted && !isDaily) return false;
    if (isDaily) return false;
    if (isOverdue) return false;
    return true;
  }

  String get status {
    if (isPermanentlyCompleted) return 'completed';
    if (isDaily) return 'daily';
    if (isCompleted && !isDaily) return 'completed';
    if (isOverdue) return 'overdue';
    return 'pending';
  }

  void toggleComplete() {
    if (isDaily) {
      final today = _normalizeDate(DateTime.now());
      final isTodayCompleted = completedDates.any((date) =>
          _normalizeDate(date) == today);
      
      // For daily habits, only allow completion if not already completed today
      if (!isTodayCompleted) {
        completedDates.add(today);
        isCompleted = true;
      }
      // Do NOT allow unchecking for daily habits
    } else {
      // For one-time todos, permanent completion
      if (!isCompleted && !isPermanentlyCompleted) {
        isCompleted = true;
        isPermanentlyCompleted = true;
        completedDate = DateTime.now();
      }
      // Do NOT allow unchecking for one-time todos
    }
  }
  
  // Check if daily habit is completed for today
  bool isCompletedForToday() {
    if (!isDaily) return isCompleted;
    final today = _normalizeDate(DateTime.now());
    return completedDates.any((date) => _normalizeDate(date) == today);
  }
  
  // Check if daily habit was completed on a specific date
  bool isCompletedOnDate(DateTime date) {
    final normalized = _normalizeDate(date);
    
    if (isDaily) {
      return completedDates.any((completedDate) =>
          _normalizeDate(completedDate) == normalized);
    }
    return isPermanentlyCompleted;
  }
  
  // Reset daily habit for new day (called when app checks date change)
  void resetDailyIfNeeded() {
    if (!isDaily) return;
    
    final today = _normalizeDate(DateTime.now());
    final isTodayCompleted = completedDates.any((date) =>
        _normalizeDate(date) == today);
    
    isCompleted = isTodayCompleted;
  }
}