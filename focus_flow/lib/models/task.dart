class Task {
  String id;
  String name;
  int focusMinutes;
  DateTime createdAt;
  List<DateTime> completedDates;

  Task({
    required this.id,
    required this.name,
    required this.focusMinutes,
    DateTime? createdAt,
    List<DateTime>? completedDates,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focusMinutes': focusMinutes,
    'createdAt': createdAt.toIso8601String(),
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    name: json['name'],
    focusMinutes: json['focusMinutes'],
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(), // Safe fallback
    completedDates: (json['completedDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
  );

  // Check if completed on a specific date
  bool isCompletedOnDate(DateTime date) {
    return completedDates.any((completedDate) => 
      completedDate.year == date.year && 
      completedDate.month == date.month && 
      completedDate.day == date.day
    );
  }

  // Check if completed today
  bool get isCompletedForToday {
    final today = DateTime.now();
    return isCompletedOnDate(today);
  }

  // Toggle today's completion
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

  // Get completion status for calendar display
  CalendarDayStatus getDayStatus(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedCreatedAt = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final normalizedToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    // Days before task creation - neutral/disabled
    if (normalizedDate.isBefore(normalizedCreatedAt)) {
      return CalendarDayStatus.disabled;
    }
    
    // Task creation day
    if (normalizedDate.isAtSameMomentAs(normalizedCreatedAt)) {
      return CalendarDayStatus.created;
    }
    
    // Completed days
    if (isCompletedOnDate(date)) {
      return CalendarDayStatus.completed;
    }
    
    // Future days
    if (normalizedDate.isAfter(normalizedToday)) {
      return CalendarDayStatus.future;
    }
    
    // Missed days (only after creation date and before today)
    if (normalizedDate.isBefore(normalizedToday)) {
      return CalendarDayStatus.missed;
    }
    
    return CalendarDayStatus.future;
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
    
    // Get task creation date (day only)
    final startDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    for (int i = sorted.length - 2; i >= 0; i--) {
      final prevDate = DateTime(sorted[i].year, sorted[i].month, sorted[i].day);
      final diff = current.difference(prevDate).inDays;
      
      // Only count consecutive days after creation date
      if (diff == 1 && prevDate.isAfter(startDate.subtract(const Duration(days: 1)))) {
        streak++;
        current = prevDate;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

enum CalendarDayStatus {
  disabled,   // Days before task creation
  created,    // Task creation day
  completed,  // Completed days
  missed,     // Missed days (after creation, before today, not completed)
  future,     // Future days
}