class Todo {
  String id;
  String name;
  DateTime dueDate;
  DateTime createdAt;
  bool isCompleted;
  bool isDaily;
  List<DateTime> completedDates;

  Todo({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.createdAt,
    this.isCompleted = false,
    this.isDaily = false,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dueDate': dueDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'isCompleted': isCompleted,
    'isDaily': isDaily,
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
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
  );

  // Normalize date to compare only year/month/day
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool get isOverdue {
    if (isCompleted) return false;
    if (isDaily) return false;
    
    final today = _normalizeDate(DateTime.now());
    final due = _normalizeDate(dueDate);
    
    return today.isAfter(due);
  }

  bool get isPending {
    if (isCompleted) return false;
    if (isDaily) return false;
    if (isOverdue) return false;
    return true;
  }

  String get status {
    if (isDaily) return 'daily';
    if (isCompleted) return 'completed';
    if (isOverdue) return 'overdue';
    return 'pending';
  }

  void toggleComplete() {
    if (isDaily) {
      final today = _normalizeDate(DateTime.now());
      final isTodayCompleted = completedDates.any((date) =>
          _normalizeDate(date) == today);
      
      if (isTodayCompleted) {
        completedDates.removeWhere((date) =>
            _normalizeDate(date) == today);
      } else {
        completedDates.add(today);
      }
      isCompleted = completedDates.isNotEmpty;
    } else {
      isCompleted = !isCompleted;
    }
  }

  bool isCompletedOnDate(DateTime date) {
    final normalized = _normalizeDate(date);
    
    if (isDaily) {
      return completedDates.any((completedDate) =>
          _normalizeDate(completedDate) == normalized);
    }
    return isCompleted;
  }
}