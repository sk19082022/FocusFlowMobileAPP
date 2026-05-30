import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/task_service.dart';
import '../widgets/app_header.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  
  const SettingsScreen({
    super.key,
    this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = "User";
  bool _notificationsEnabled = true;
  int _defaultFocusTime = 25;
  bool _isLoading = true;

  static const String _developerLink = 'https://github.com/sk19082022';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    final userName = await TaskService.getUserName();
    final notifications = await TaskService.getNotificationsEnabled();
    final defaultTime = await TaskService.getDefaultFocusTime();
    
    if (mounted) {
      setState(() {
        _userName = userName;
        _notificationsEnabled = notifications;
        _defaultFocusTime = defaultTime;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveUserName(String name) async {
    await TaskService.setUserName(name);
    if (mounted) {
      setState(() {
        _userName = name;
      });
      widget.onSettingsChanged?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _launchUrl() async {
    try {
      final Uri url = Uri.parse(_developerLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $_developerLink';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // Reusable Branded Header
          const SliverToBoxAdapter(
            child: AppHeader(),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Profile Section
                        _buildSection(
                          title: 'Profile',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person, color: Colors.blue),
                              title: const Text('Name'),
                              subtitle: Text(_userName),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditNameDialog(),
                              ),
                            ),
                          ],
                        ),
                        
                        // Preferences Section
                        _buildSection(
                          title: 'Preferences',
                          children: [
                            SwitchListTile(
                              secondary: const Icon(Icons.notifications, color: Colors.blue),
                              title: const Text('Enable Notifications'),
                              subtitle: const Text('Get reminders for focus sessions'),
                              value: _notificationsEnabled,
                              onChanged: (value) async {
                                setState(() => _notificationsEnabled = value);
                                await TaskService.setNotificationsEnabled(value);
                                widget.onSettingsChanged?.call();
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(value 
                                        ? 'Notifications enabled' 
                                        : 'Notifications disabled'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                            const Divider(color: Colors.grey, height: 1),
                            ListTile(
                              leading: const Icon(Icons.timer, color: Colors.blue),
                              title: const Text('Default Focus Time'),
                              subtitle: Text('$_defaultFocusTime minutes'),
                              trailing: DropdownButton<int>(
                                value: _defaultFocusTime,
                                dropdownColor: const Color(0xFF1E1E2E),
                                items: const [15, 25, 45, 60].map((minutes) {
                                  return DropdownMenuItem(
                                    value: minutes,
                                    child: Text('$minutes min'),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value != null) {
                                    setState(() => _defaultFocusTime = value);
                                    await TaskService.setDefaultFocusTime(value);
                                    widget.onSettingsChanged?.call();
                                    
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Default time set to $value minutes'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Developer Section
                        _buildSection(
                          title: 'Developer',
                          children: [
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: const Color(0xFF1E1E2E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _launchUrl,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: const Icon(
                                          Icons.code,
                                          color: Colors.blue,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Santhosh Kumar Mada',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Flutter Developer',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new,
                                        color: Colors.grey[500],
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Connect Section
                        _buildSection(
                          title: 'Connect',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.link, color: Colors.blue),
                              title: const Text('Visit Profile'),
                              subtitle: const Text('GitHub'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _launchUrl,
                            ),
                          ],
                        ),
                        
                        // About Section
                        _buildSection(
                          title: 'About',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info, color: Colors.blue),
                              title: const Text('About Focus Flow'),
                              subtitle: const Text('A productivity app to build better habits . This app is developed by Santhosh Kumar Mada.'),
                            ),
                          ],
                        ),
                        
                        // Data Section
                        _buildSection(
                          title: 'Data',
                          children: [
                            ListTile(
                              leading: const Icon(Icons.delete_sweep, color: Colors.red),
                              title: const Text('Clear All Data'),
                              subtitle: const Text('Delete all tasks and progress'),
                              onTap: _showClearDataDialog,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
        const Divider(color: Colors.grey, height: 32, thickness: 0.5),
      ],
    );
  }

  void _showEditNameDialog() {
    final controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.black,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveUserName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure? This will delete all your tasks and progress. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await TaskService.clearAllData();
              if (mounted) {
                Navigator.pop(context);
                widget.onSettingsChanged?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}