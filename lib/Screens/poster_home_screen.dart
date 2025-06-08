import 'package:flutter/material.dart';
import '../widgets/task_poster_nav_bar.dart';
import 'post_task_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class PosterHomeScreen extends StatefulWidget {
  const PosterHomeScreen({super.key});

  @override
  State<PosterHomeScreen> createState() => _PosterHomeScreenState();
}

class _PosterHomeScreenState extends State<PosterHomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final TabController _tasksTabController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tasksTabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _tasksTabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMyTasksTab() {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: TabBar(
            controller: _tasksTabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Pending Approval'),
              Tab(text: 'Paused'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tasksTabController,
            children: [
              // Active Tasks Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5, // Example count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check_circle, color: Colors.white),
                      ),
                      title: Text('Active Task ${index + 1}'),
                      subtitle: const Text('In progress'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // Show task options
                        },
                      ),
                    ),
                  );
                },
              ),
              // Pending Approval Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3, // Example count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.pending, color: Colors.white),
                      ),
                      title: Text('Pending Task ${index + 1}'),
                      subtitle: const Text('Waiting for approval'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // Show task options
                        },
                      ),
                    ),
                  );
                },
              ),
              // Paused Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 2, // Example count
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.pause, color: Colors.white),
                      ),
                      title: Text('Paused Task ${index + 1}'),
                      subtitle: const Text('On hold'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          // Show task options
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMyTasksTab();
      case 1:
        return const PostTaskScreen();
      case 2:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Analytics Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildMetricCard(context, 'Total Tasks Posted', '150', Icons.assignment),
              _buildMetricCard(context, 'Total Hired', '85', Icons.people),
              _buildMetricCard(context, 'Total Spent', '\$12,500', Icons.attach_money),
              _buildMetricCard(context, 'Hiring Rate', '85%', Icons.trending_up),
              _buildMetricCard(context, 'Successful Jobs', '80', Icons.check_circle),
              _buildMetricCard(context, 'Average Rating', '4.7/5', Icons.star),
              const SizedBox(height: 20),
              // You can add charts or more detailed analytics here
              Text(
                'Detailed Insights',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              // Example: A simple progress bar for successful jobs
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Successful Jobs Progress', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: 0.8,
                        backgroundColor: Colors.grey.shade300,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('80% Completed', style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 3:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Chat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Communicate with runners',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        trailing: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Poster Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/placeholder_profile.jpg'), // Use your profile image here
            ),
            onSelected: (String result) async {
              if (result == 'logout') {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                }
              } else if (result == 'profile') {
                // Handle profile navigation
                print('Navigate to Profile Settings');
              } else if (result == 'settings') {
                // Handle settings navigation
                print('Navigate to Settings');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
} 