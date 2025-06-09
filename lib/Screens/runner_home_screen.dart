import 'package:flutter/material.dart';
import '../widgets/runner_nav_bar.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
import '../widgets/my_tasks_card.dart';
import '../models/task.dart';
import 'task_detail_screen.dart';

class RunnerHomeScreen extends StatefulWidget {
  final String profileImagePath;

  const RunnerHomeScreen({
    Key? key,
    required this.profileImagePath,
  }) : super(key: key);

  @override
  State<RunnerHomeScreen> createState() => _RunnerHomeScreenState();
}

class _RunnerHomeScreenState extends State<RunnerHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  List<Task> _availableTasks = [];
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.all_inclusive},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Event Staffing', 'icon': Icons.people},
    {'name': 'Delivery', 'icon': Icons.delivery_dining},
    {'name': 'Handyman', 'icon': Icons.handyman},
    {'name': 'Moving', 'icon': Icons.local_shipping},
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Gardening', 'icon': Icons.landscape},
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _availableTasks = _taskService.getDummyTasks();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleTaskTap(Task task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => TaskDetailScreen(task: task),
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1DBF73) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      category['icon'],
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF1DBF73) : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Explore
        return Column(
          children: [
            _buildCategoryButtons(),
            Expanded(
              child: ListView.builder(
                itemCount: _availableTasks.length,
                itemBuilder: (context, index) {
                  final task = _availableTasks[index];
                  if (_selectedCategory == 'All' || task.type == _selectedCategory) {
                    return TaskCard(
                      task: task,
                      onTap: () => _handleTaskTap(task),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        );
      case 1: // Assigned Tasks
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            MyTasksCard(
              taskTitle: 'Garden Maintenance',
              taskType: 'Gardening',
              status: 'In Progress',
              deadline: DateTime.now().add(const Duration(days: 2)),
              offerAmount: 150.00,
              taskPoster: 'John Smith',
              taskPosterImage: 'https://via.placeholder.com/50',
              onTap: () {
                // Handle task tap
              },
            ),
            MyTasksCard(
              taskTitle: 'Computer Setup',
              taskType: 'Technology',
              status: 'Pending',
              deadline: DateTime.now().add(const Duration(days: 5)),
              offerAmount: 200.00,
              taskPoster: 'Emma Wilson',
              taskPosterImage: 'https://via.placeholder.com/50',
              onTap: () {
                // Handle task tap
              },
            ),
            MyTasksCard(
              taskTitle: 'Moving Help',
              taskType: 'Moving',
              status: 'Completed',
              deadline: DateTime.now().subtract(const Duration(days: 1)),
              offerAmount: 300.00,
              taskPoster: 'Michael Brown',
              taskPosterImage: 'https://via.placeholder.com/50',
              onTap: () {
                // Handle task tap
              },
            ),
          ],
        );
      case 2: // Stats
        return const Center(
          child: Text('Stats'),
        );
      case 3: // Notifications
        return const Center(
          child: Text('Notifications'),
        );
      case 4: // Chat
        return const Center(
          child: Text('Chat'),
        );
      default:
        return const Center(
          child: Text('Unknown Tab'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    backgroundImage: FileImage(File(widget.profileImagePath)),
                    radius: 16,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        try {
                          await _authService.signOut();
                          if (mounted) {
                            Navigator.of(context).pushReplacementNamed('/auth');
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error signing out: ${e.toString()}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        }
                      } else if (value == 'profile') {
                        // Handle profile navigation
                        print('Navigate to Profile');
                      } else if (value == 'settings') {
                        // Handle settings navigation
                        print('Navigate to Settings');
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Text('Profile'),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RunnerNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
} 