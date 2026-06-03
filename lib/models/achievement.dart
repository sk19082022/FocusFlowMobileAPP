class Achievement {
  String taskId;
  String taskName;
  DateTime createdAt;
  DateTime completedAt;
  int focusMinutes;
  int totalDaysTracked;

  Achievement({
    required this.taskId,
    required this.taskName,
    required this.createdAt,
    required this.completedAt,
    required this.focusMinutes,
    required this.totalDaysTracked,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'taskName': taskName,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt.toIso8601String(),
    'focusMinutes': focusMinutes,
    'totalDaysTracked': totalDaysTracked,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    taskId: json['taskId'],
    taskName: json['taskName'],
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: DateTime.parse(json['completedAt']),
    focusMinutes: json['focusMinutes'],
    totalDaysTracked: json['totalDaysTracked'],
  );
}