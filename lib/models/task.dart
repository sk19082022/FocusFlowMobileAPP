class Task {
  String id;
  String name;
  int focusMinutes;
  DateTime createdAt;
  List<DateTime> completedDates;
  TaskStatus status;
  DateTime? completedDate;
  
  // Store completed sessions with their actual focus minutes
  List<FocusSession> focusSessions;
  
  // Store edit history
  List<TaskEditRecord> editHistory;

  // Store sub-tasks
  List<SubTask> subTasks;
  TimerState? timerState;
  Task({
    required this.id,
    required this.name,
    required this.focusMinutes,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    this.status = TaskStatus.active,
    this.completedDate,
    List<FocusSession>? focusSessions,
    List<TaskEditRecord>? editHistory,
    List<SubTask>? subTasks,
    this.timerState,
  })  : createdAt = createdAt ?? DateTime.now(),
        completedDates = completedDates ?? [],
        focusSessions = focusSessions ?? [],
        editHistory = editHistory ?? [],
        subTasks = subTasks ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'focusMinutes': focusMinutes,
    'createdAt': createdAt.toIso8601String(),
    'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
    'status': status.index,
    'completedDate': completedDate?.toIso8601String(),
    'focusSessions': focusSessions.map((s) => s.toJson()).toList(),
    'editHistory': editHistory.map((e) => e.toJson()).toList(),
    'subTasks': subTasks.map((s) => s.toJson()).toList(),
    'timerState': timerState?.toJson(),
    
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
    focusSessions: (json['focusSessions'] as List?)
        ?.map((s) => FocusSession.fromJson(s))
        .toList() ?? [],
    editHistory: (json['editHistory'] as List?)
        ?.map((e) => TaskEditRecord.fromJson(e))
        .toList() ?? [],
    subTasks: (json['subTasks'] as List?)
        ?.map((s) => SubTask.fromJson(s))
        .toList() ?? [],
    
    timerState: json['timerState'] != null 
        ? TimerState.fromJson(json['timerState'])
        : null,
  );

  // ============ SUB-TASK MANAGEMENT METHODS ============
   void saveTimerState(int remainingSeconds, bool isRunning, bool isPaused, DateTime lastTickTime) {
    timerState = TimerState(
      remainingSeconds: remainingSeconds,
      isRunning: isRunning,
      isPaused: isPaused,
      lastTickTime: lastTickTime,
    );
  }

   void clearTimerState() {
    timerState = null;
  }

    int getElapsedSecondsSinceLastTick() {
    if (timerState == null || !timerState!.isRunning) return 0;
    final now = DateTime.now();
    final difference = now.difference(timerState!.lastTickTime);
    return difference.inSeconds;
  }

   int getCurrentRemainingSeconds() {
    if (timerState == null) return focusMinutes * 60;
    
    if (timerState!.isRunning) {
      final elapsed = getElapsedSecondsSinceLastTick();
      return (timerState!.remainingSeconds - elapsed).clamp(0, timerState!.remainingSeconds);
    }
    
    return timerState!.remainingSeconds;
  }

    void updateLastTickTime() {
    if (timerState != null) {
      timerState!.lastTickTime = DateTime.now();
    }
  }



  void addSubTask(String name) {
    if (name.trim().isNotEmpty) {
      subTasks.add(SubTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        createdAt: DateTime.now(),
      ));
    }
  }

  void updateSubTask(String subTaskId, String newName) {
    final index = subTasks.indexWhere((s) => s.id == subTaskId);
    if (index != -1 && newName.trim().isNotEmpty) {
      subTasks[index].name = newName.trim();
      subTasks[index].updatedAt = DateTime.now();
    }
  }

  void toggleSubTask(String subTaskId) {
    final index = subTasks.indexWhere((s) => s.id == subTaskId);
    if (index != -1) {
      subTasks[index].isCompleted = !subTasks[index].isCompleted;
      if (subTasks[index].isCompleted) {
        subTasks[index].completedAt = DateTime.now();
      } else {
        subTasks[index].completedAt = null;
      }
    }
  }

  void deleteSubTask(String subTaskId) {
    subTasks.removeWhere((s) => s.id == subTaskId);
  }

  int get completedSubTasksCount => subTasks.where((s) => s.isCompleted).length;
  int get totalSubTasksCount => subTasks.length;
  double get subTaskCompletionPercentage => totalSubTasksCount == 0 ? 0 : (completedSubTasksCount / totalSubTasksCount) * 100;

  // ============ TASK COMPLETION METHODS ============
  
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
      // Also remove the focus session for today
      focusSessions.removeWhere((session) => 
        session.date.year == today.year &&
        session.date.month == today.month &&
        session.date.day == today.day
      );
    } else {
      completedDates.add(today);
      // Add focus session with current focus minutes (historical preservation)
      focusSessions.add(FocusSession(
        date: today,
        minutesCompleted: focusMinutes,
      ));
    }
  }
  
  void completeFocusSession() {
    final today = DateTime.now();
    if (!isCompletedForToday) {
      completedDates.add(today);
      focusSessions.add(FocusSession(
        date: today,
        minutesCompleted: focusMinutes,
      ));
    }
  }

  // ============ TASK EDIT METHODS WITH HISTORY ============
  
  void editName(String newName) {
    if (name != newName && newName.isNotEmpty) {
      editHistory.add(TaskEditRecord(
        dateTime: DateTime.now(),
        editType: EditType.rename,
        oldValue: name,
        newValue: newName,
      ));
      name = newName;
    }
  }
  
  void editFocusMinutes(int newMinutes) {
    if (focusMinutes != newMinutes && newMinutes > 0) {
      editHistory.add(TaskEditRecord(
        dateTime: DateTime.now(),
        editType: EditType.duration,
        oldValue: focusMinutes.toString(),
        newValue: newMinutes.toString(),
      ));
      focusMinutes = newMinutes;
    }
  }
  
  // ============ FOCUS SESSION HISTORICAL DATA ============
  
  int get totalFocusMinutes {
    return focusSessions.fold(0, (sum, session) => sum + session.minutesCompleted);
  }
  
  int getFocusMinutesForDate(DateTime date) {
    final session = focusSessions.firstWhere(
      (s) => s.date.year == date.year && 
             s.date.month == date.month && 
             s.date.day == date.day,
      orElse: () => FocusSession(date: date, minutesCompleted: 0),
    );
    return session.minutesCompleted;
  }

  // ============ TASK STATUS MANAGEMENT ============
  
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

  // ============ PROGRESS & STATS ============
  
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

  // ============ CALENDAR STATUS ============
  
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
  
  // ============ EDIT HISTORY ============
  
  List<TaskEditRecord> getRecentEditHistory() {
    final history = List<TaskEditRecord>.from(editHistory);
    history.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return history;
  }
}

// ============ FOCUS SESSION MODEL ============
class TimerState {
  int remainingSeconds;
  bool isRunning;
  bool isPaused;
  DateTime lastTickTime;

  TimerState({
    required this.remainingSeconds,
    required this.isRunning,
    required this.isPaused,
    required this.lastTickTime,
  });

  Map<String, dynamic> toJson() => {
    'remainingSeconds': remainingSeconds,
    'isRunning': isRunning,
    'isPaused': isPaused,
    'lastTickTime': lastTickTime.toIso8601String(),
  };

  factory TimerState.fromJson(Map<String, dynamic> json) => TimerState(
    remainingSeconds: json['remainingSeconds'],
    isRunning: json['isRunning'],
    isPaused: json['isPaused'],
    lastTickTime: DateTime.parse(json['lastTickTime']),
  );
}
class FocusSession {
  DateTime date;
  int minutesCompleted;
  
  FocusSession({
    required this.date,
    required this.minutesCompleted,
  });
  
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'minutesCompleted': minutesCompleted,
  };
  
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
    date: DateTime.parse(json['date']),
    minutesCompleted: json['minutesCompleted'],
  );
}

// ============ TASK EDIT RECORD MODEL ============

class TaskEditRecord {
  DateTime dateTime;
  EditType editType;
  String oldValue;
  String newValue;
  
  TaskEditRecord({
    required this.dateTime,
    required this.editType,
    required this.oldValue,
    required this.newValue,
  });
  
  Map<String, dynamic> toJson() => {
    'dateTime': dateTime.toIso8601String(),
    'editType': editType.index,
    'oldValue': oldValue,
    'newValue': newValue,
  };
  
  factory TaskEditRecord.fromJson(Map<String, dynamic> json) => TaskEditRecord(
    dateTime: DateTime.parse(json['dateTime']),
    editType: EditType.values[json['editType']],
    oldValue: json['oldValue'],
    newValue: json['newValue'],
  );
  
  String getEditTypeDisplay() {
    switch (editType) {
      case EditType.rename:
        return 'Task Renamed';
      case EditType.duration:
        return 'Focus Duration Changed';
    }
  }
}

// ============ SUB-TASK MODEL ============

class SubTask {
  String id;
  String name;
  bool isCompleted;
  DateTime createdAt;
  DateTime? updatedAt;
  DateTime? completedAt;

  SubTask({
    required this.id,
    required this.name,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
    id: json['id'],
    name: json['name'],
    isCompleted: json['isCompleted'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
  );
}

// ============ ENUMS ============

enum EditType {
  rename,
  duration,
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