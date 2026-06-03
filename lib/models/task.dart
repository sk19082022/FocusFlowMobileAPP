class Task {
  String id;
  String name;
  int focusMinutes;
  DateTime createdAt;
  List<DateTime> completedDates;
  TaskStatus status;
  DateTime? completedDate;

  Task({
    required this.id,
    required this.name,
    required this.focusMinutes,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    this.status = TaskStatus.active,
    this.completedDate,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focusMinutes': focusMinutes,
    'createdAt': createdAt.toIso8601String(),
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'status': status.index,
    'completedDate': completedDate?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    name: json['name'],
    focusMinutes: json['focusMinutes'],
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    completedDates: (json['completedDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
    status: json['status'] != null 
        ? TaskStatus.values[json['status']]
        : TaskStatus.active,
    completedDate: json['completedDate'] != null 
        ? DateTime.parse(json['completedDate'])
        : null,
  );

  bool get isCompletedForToday {
    final today = DateTime.now();
    return completedDates.any((completedDate) => 
      completedDate.year == today.year && 
      completedDate.month == today.month && 
      completedDate.day == today.day
    );
  }

  void toggleTodayCompletion() {
    final today = DateTime.now();
    if (isCompletedForToday) {
      completedDates.removeWhere((date) => 
        date.year == today.year && 
        date.month == today.month && 
        date.day == today.day
      );
    } else {
      completedDates.add(today);
    }
  }

  void permanentlyComplete() {
    status = TaskStatus.completed;
    completedDate = DateTime.now();
  }

  void pauseTask() {
    status = TaskStatus.paused;
  }

  void resumeTask() {
    status = TaskStatus.active;
  }

  double get progressPercent {
    if (completedDates.isEmpty) return 0;
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays + 1;
    if (daysSinceCreation <= 0) return 0;
    return (completedDates.length / daysSinceCreation) * 100;
  }

  int get doneDays => completedDates.length;
  
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final sorted = List<DateTime>.from(completedDates)..sort();
    int streak = 1;
    DateTime current = DateTime(sorted.last.year, sorted.last.month, sorted.last.day);
    
    final startDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    for (int i = sorted.length - 2; i >= 0; i--) {
      final prevDate = DateTime(sorted[i].year, sorted[i].month, sorted[i].day);
      final diff = current.difference(prevDate).inDays;
      
      if (diff == 1 && prevDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
        streak++;
        current = prevDate;
      } else {
        break;
      }
    }
    
    return streak;
  }

  CalendarDayStatus getDayStatus(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedCreatedAt = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final normalizedToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    if (normalizedDate.isBefore(normalizedCreatedAt)) {
      return CalendarDayStatus.disabled;
    }
    
    if (normalizedDate.isAtSameMomentAs(normalizedCreatedAt)) {
      return CalendarDayStatus.created;
    }
    
    if (isCompletedOnDate(date)) {
      return CalendarDayStatus.completed;
    }
    
    if (normalizedDate.isAfter(normalizedToday)) {
      return CalendarDayStatus.future;
    }
    
    if (normalizedDate.isBefore(normalizedToday)) {
      return CalendarDayStatus.missed;
    }
    
    return CalendarDayStatus.future;
  }

  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((completedDate) => 
      completedDate.year == date.year && 
      completedDate.month == date.month && 
      completedDate.day == date.day
    );
  }
}

enum TaskStatus {
  active,
  paused,
  completed,
}

enum CalendarDayStatus {
  disabled,
  created,
  completed,
  missed,
  future,
}