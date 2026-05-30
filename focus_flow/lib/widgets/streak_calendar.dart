import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task.dart';

class StreakCalendar extends StatefulWidget {
  final Task task;
  final VoidCallback? onDateSelected;

  const StreakCalendar({
    super.key,
    required this.task,
    this.onDateSelected,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  late Map<DateTime, List<dynamic>> _events;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = null;
    _updateEvents();
  }

  @override
  void didUpdateWidget(StreakCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.completedDates != widget.task.completedDates ||
        oldWidget.task.createdAt != widget.task.createdAt) {
      _updateEvents();
    }
  }

  void _updateEvents() {
    _events = {};
    for (var date in widget.task.completedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _events[normalizedDate] = [];
    }
    if (mounted) {
      setState(() {});
    }
  }

  // Fixed: Priority order - Completed > Created > Missed > Future > Disabled
  Color _getDayColor(DateTime day) {
    final status = widget.task.getDayStatus(day);
    final isCompleted = widget.task.isCompletedOnDate(day);
    final createdDate = DateTime(
      widget.task.createdAt.year,
      widget.task.createdAt.month,
      widget.task.createdAt.day,
    );
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    // COMPLETED takes highest priority (Green)
    if (isCompleted) {
      return Colors.green;
    }
    
    // CREATED day (only if not completed)
    if (normalizedDay.isAtSameMomentAs(createdDate)) {
      return Colors.purple;
    }
    
    // Then check other statuses
    switch (status) {
      case CalendarDayStatus.disabled:
        return Colors.grey.withOpacity(0.1);
      case CalendarDayStatus.missed:
        return Colors.red.withOpacity(0.3);
      case CalendarDayStatus.future:
        return Colors.transparent;
      default:
        return Colors.transparent;
    }
  }

  Color _getTextColor(DateTime day) {
    final isCompleted = widget.task.isCompletedOnDate(day);
    final createdDate = DateTime(
      widget.task.createdAt.year,
      widget.task.createdAt.month,
      widget.task.createdAt.day,
    );
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    if (isCompleted || normalizedDay.isAtSameMomentAs(createdDate)) {
      return Colors.white;
    }
    
    final status = widget.task.getDayStatus(day);
    switch (status) {
      case CalendarDayStatus.disabled:
        return Colors.grey.withOpacity(0.3);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final createdDate = DateTime(
      widget.task.createdAt.year,
      widget.task.createdAt.month,
      widget.task.createdAt.day,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ACTIVITY CALENDAR",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Colors.grey,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Started: ${createdDate.day}/${createdDate.month}/${createdDate.year}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.all,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              widget.onDateSelected?.call();
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              defaultDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              weekendDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerDecoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(color: Colors.grey),
              weekendStyle: const TextStyle(color: Colors.grey),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.blue),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.blue),
            ),
            eventLoader: (day) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              return _events[normalizedDay] ?? [];
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isCompleted = widget.task.isCompletedOnDate(day);
                final status = widget.task.getDayStatus(day);
                final isToday = DateTime(day.year, day.month, day.day) == normalizedToday;
                final color = _getDayColor(day);
                final textColor = _getTextColor(day);
                final createdDate = DateTime(
                  widget.task.createdAt.year,
                  widget.task.createdAt.month,
                  widget.task.createdAt.day,
                );
                final isCreatedDay = DateTime(day.year, day.month, day.day) == createdDate;
                
                // Don't show days before task creation
                if (status == CalendarDayStatus.disabled) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }
                
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    // Show purple border ONLY if it's creation day AND not completed
                    border: (isCreatedDay && !isCompleted)
                        ? Border.all(color: Colors.purple, width: 2)
                        : (isToday && status != CalendarDayStatus.completed
                            ? Border.all(color: Colors.yellow, width: 2)
                            : null),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green, "Completed"),
              const SizedBox(width: 16),
              _buildLegend(Colors.purple, "Created"),
              const SizedBox(width: 16),
              _buildLegend(Colors.red.withOpacity(0.3), "Missed"),
              const SizedBox(width: 16),
              _buildLegend(Colors.yellow, "Today"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}