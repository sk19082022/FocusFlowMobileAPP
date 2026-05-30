import 'package:flutter/material.dart';
import '../models/task.dart';
import 'package:flutter/services.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompletedToday = widget.task.isCompletedForToday;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isCompletedToday
                            ? [
                                Colors.green.shade900.withOpacity(0.3),
                                Colors.green.shade800.withOpacity(0.2),
                              ]
                            : [
                                Colors.grey.shade900,
                                Colors.grey.shade800,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompletedToday
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.shade700.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Animated Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Transform.scale(
                                scale: isCompletedToday ? 1.1 : 1.0,
                                child: Checkbox(
                                  value: isCompletedToday,
                                  onChanged: (value) {
                                    HapticFeedback.lightImpact();
                                    widget.onComplete();
                                  },
                                  activeColor: Colors.green,
                                  checkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  side: const BorderSide(color: Colors.grey, width: 1.5),
                                ),
                              ),
                            ),
                            
                            // Task Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      decoration: isCompletedToday
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      decorationColor: Colors.grey,
                                      color: isCompletedToday
                                          ? Colors.grey
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      widget.task.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${widget.task.focusMinutes} min focus",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.local_fire_department,
                                        size: 12,
                                        color: Colors.orange.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${widget.task.currentStreak} day streak",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Progress Percentage
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    "${widget.task.progressPercent.toInt()}%",
                                    key: ValueKey(widget.task.progressPercent.toInt()),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getProgressColor(widget.task.progressPercent),
                                      shadows: [
                                        Shadow(
                                          color: _getProgressColor(widget.task.progressPercent).withOpacity(0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${widget.task.doneDays} days completed",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Animated Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.task.progressPercent / 100,
                            backgroundColor: Colors.grey.shade800,
                            color: _getProgressColor(widget.task.progressPercent),
                            minHeight: 8,
                          ),
                        ),
                        
                        // Completion indicator with animation
                        if (isCompletedToday)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Completed today! 🎉",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 100) return Colors.green;
    if (progress >= 75) return Colors.lightGreen;
    if (progress >= 50) return Colors.blue;
    if (progress >= 25) return Colors.orange;
    return Colors.grey;
  }
}