import 'package:flutter/material.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customMinutesController = TextEditingController();
  int _selectedMinutes = 25;
  bool _useCustomMinutes = false;
  
  final List<int> _presetMinutes = [15, 25, 45, 60];

  @override
  void dispose() {
    _nameController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Create New Task"),
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
            // Task Name Section
            const Text(
              "Task Name",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: "e.g., Read philosophy, Morning run...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: const Icon(Icons.edit_note, color: Colors.blue, size: 20),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 24),

            // Focus Duration Section
            const Text(
              "Focus Duration (minutes)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            
            // Preset minutes chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presetMinutes.map((minutes) {
                  return FilterChip(
                    label: Text("${minutes}m"),
                    selected: !_useCustomMinutes && _selectedMinutes == minutes,
                    onSelected: (selected) {
                      setState(() {
                        _useCustomMinutes = false;
                        _selectedMinutes = minutes;
                        _customMinutesController.clear();
                      });
                    },
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey[900],
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: !_useCustomMinutes && _selectedMinutes == minutes 
                          ? Colors.white 
                          : Colors.grey[400],
                      fontWeight: !_useCustomMinutes && _selectedMinutes == minutes 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  );
                }),
                // Custom minutes chip
                FilterChip(
                  label: _useCustomMinutes 
                      ? const Text("Custom ✓")
                      : const Text("➕ Custom"),
                  selected: _useCustomMinutes,
                  onSelected: (selected) {
                    setState(() {
                      _useCustomMinutes = true;
                      if (!selected) {
                        _useCustomMinutes = false;
                        _customMinutesController.clear();
                      }
                    });
                  },
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[900],
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: _useCustomMinutes ? Colors.white : Colors.grey[400],
                    fontWeight: _useCustomMinutes ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            
            // Custom minutes input field
            if (_useCustomMinutes) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _customMinutesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter custom minutes (1-1440)",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.timer, color: Colors.blue, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    suffixText: "min",
                    suffixStyle: const TextStyle(color: Colors.grey),
                  ),
                  onChanged: (value) {
                    final minutes = int.tryParse(value);
                    if (minutes != null && minutes >= 1 && minutes <= 1440) {
                      setState(() {
                        _selectedMinutes = minutes;
                      });
                    }
                  },
                ),
              ),
            ],

            const Spacer(),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
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
                    onPressed: _addTask,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (name.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task name must be less than 50 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate custom minutes
    if (_useCustomMinutes) {
      final customMinutes = int.tryParse(_customMinutesController.text.trim());
      if (customMinutes == null || customMinutes < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid number of minutes (1-1440)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (customMinutes > 1440) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum focus time is 1440 minutes (24 hours)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _selectedMinutes = customMinutes;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      focusMinutes: _selectedMinutes,
      createdAt: DateTime.now(),
      completedDates: [],
    );

    Navigator.pop(context, task);
  }
}