import 'package:flutter/material.dart';
import '../widgets/runner_nav_bar.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../widgets/task_card.dart';
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Explore
        return ListView.builder(
          itemCount: _availableTasks.length,
          itemBuilder: (context, index) {
            final task = _availableTasks[index];
            return TaskCard(
              task: task,
              onTap: () => _handleTaskTap(task),
            );
          },
        );
      case 1: // Assigned Tasks
        return const Center(
          child: Text('Assigned Tasks'),
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
      appBar: AppBar(
        title: const Text('Runner Dashboard'),
        actions: [
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
      body: _buildBody(),
      bottomNavigationBar: RunnerNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
} 