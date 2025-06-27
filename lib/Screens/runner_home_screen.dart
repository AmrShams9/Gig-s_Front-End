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
import 'auth.dart';
import '../models/offer.dart';
import '../services/token_service.dart';
import '../Screens/chat_page.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../Widgets/chat_card.dart';

class RunnerHomeScreen extends StatefulWidget {
  const RunnerHomeScreen({super.key});

  @override
  State<RunnerHomeScreen> createState() => _RunnerHomeScreenState();
}

class _RunnerHomeScreenState extends State<RunnerHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  late Future<List<Task>> _tasksFuture;
  String _selectedCategory = 'All';
  Future<List<Map<String, dynamic>>>? _myOffersFuture;

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
    _tasksFuture = _taskService.getAllTasks();
    _loadMyOffers();
  }

  Future<void> _loadMyOffers() async {
    final runnerId = await TokenService.getUserId();
    if (runnerId == null) return;
    setState(() {
      _myOffersFuture = _fetchOffersWithTasks(runnerId);
    });
  }

  Future<List<Map<String, dynamic>>> _fetchOffersWithTasks(String runnerId) async {
    final offers = await _taskService.getOffersByRunner(runnerId);
    List<Map<String, dynamic>> result = [];
    for (final offer in offers) {
      try {
        final task = await _taskService.getTaskById(offer.taskId ?? offer.id);
        result.add({'offer': offer, 'task': task});
      } catch (_) {
        result.add({'offer': offer, 'task': null});
      }
    }
    return result;
  }

  Future<void> _deleteOffer(String offerId) async {
    final result = await _taskService.deleteOffer(offerId);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer deleted.')));
      _loadMyOffers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete offer: ${result['error']}')));
    }
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

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (Route<dynamic> route) => false,
      );
    }
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
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _tasksFuture = _taskService.getAllTasks();
                  });
                },
                child: FutureBuilder<List<Task>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('An error occurred: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('No tasks available at the moment.'));
                    }

                    final tasks = snapshot.data!;
                    return ListView.builder(
                      itemCount: tasks.length,
                itemBuilder: (context, index) {
                        final task = tasks[index];
                  if (_selectedCategory == 'All' || task.type == _selectedCategory) {
                    return TaskCard(
                      task: task,
                      onTap: () => _handleTaskTap(task),
                    );
                  }
                  return const SizedBox.shrink();
                },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      case 1: // My Offers
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _myOffersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return const Center(child: Text('You have not made any offers yet.'));
            }
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final offer = data[index]['offer'] as Offer;
                final task = data[index]['task'] as Task?;
                if (task == null) {
                  return ListTile(title: Text('Task not found for offer \\${offer.id}'));
                }
                return Column(
                  children: [
                    MyTasksCard(
                      taskTitle: task.title,
                      taskType: task.type,
                      status: offer.message, // You may want to map offer.status here
                      deadline: task.startTime ?? DateTime.now(),
                      offerAmount: offer.amount,
                      taskPoster: task.taskPoster.toString(),
                      onTap: () {},
                      taskPosterImage: 'https://via.placeholder.com/50',
                      onCancel: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancel Offer'),
                            content: const Text('Are you sure you want to cancel this offer?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Yes, Cancel'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _deleteOffer(offer.id);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
        );
      case 2: // Assigned Tasks
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
      case 3: // Stats
        return const Center(
          child: Text('Stats'),
        );
      case 4: // Notifications
        final myUserIdFuture = TokenService.getUserId();
        return FutureBuilder<String?>(
          future: myUserIdFuture,
          builder: (context, snapshot) {
            final myUserId = snapshot.data;
            if (myUserId == null) return const Center(child: CircularProgressIndicator());
            return StreamBuilder<QuerySnapshot>(
              stream: ChatService().getUserChats(myUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No chats yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final users = List<String>.from(data['users']);
                    final otherUserId = users.firstWhere((id) => id != myUserId, orElse: () => '');
                    final lastMessage = data['lastMessage'] ?? '';
                    final lastTimestamp = data['lastTimestamp'] != null
                        ? (data['lastTimestamp'] as Timestamp).toDate()
                        : null;
                    return FutureBuilder<UserModel?>(
                      future: AuthService().getUserData(otherUserId),
                      builder: (context, userSnapshot) {
                        final user = userSnapshot.data;
                        final fullName = user != null
                            ? '${user.firstName} ${user.lastName}'
                            : 'User $otherUserId';
                        final avatarUrl = user?.profileImageUrl ?? 'https://via.placeholder.com/50';
                        final timeStr = lastTimestamp != null
                            ? '${lastTimestamp.hour}:${lastTimestamp.minute.toString().padLeft(2, '0')}'
                            : '';
                        return ChatCard(
                          name: fullName,
                          lastMessage: lastMessage,
                          time: timeStr,
                          avatarUrl: avatarUrl,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  otherUserId: otherUserId,
                                  otherUserName: fullName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      case 5: // Chat (Messages)
        final myUserIdFuture = TokenService.getUserId();
        return FutureBuilder<String?>(
          future: myUserIdFuture,
          builder: (context, snapshot) {
            final myUserId = snapshot.data;
            if (myUserId == null) return const Center(child: CircularProgressIndicator());
            return StreamBuilder<QuerySnapshot>(
              stream: ChatService().getUserChats(myUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No chats yet.'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final users = List<String>.from(data['users']);
                    final otherUserId = users.firstWhere((id) => id != myUserId, orElse: () => '');
                    final lastMessage = data['lastMessage'] ?? '';
                    final lastTimestamp = data['lastTimestamp'] != null
                        ? (data['lastTimestamp'] as Timestamp).toDate()
                        : null;
                    return FutureBuilder<UserModel?>(
                      future: AuthService().getUserData(otherUserId),
                      builder: (context, userSnapshot) {
                        final user = userSnapshot.data;
                        final fullName = user != null
                            ? '${user.firstName} ${user.lastName}'
                            : 'User $otherUserId';
                        final avatarUrl = user?.profileImageUrl ?? 'https://via.placeholder.com/50';
                        final timeStr = lastTimestamp != null
                            ? '${lastTimestamp.hour}:${lastTimestamp.minute.toString().padLeft(2, '0')}'
                            : '';
                        return ChatCard(
                          name: fullName,
                          lastMessage: lastMessage,
                          time: timeStr,
                          avatarUrl: avatarUrl,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatPage(
                                  otherUserId: otherUserId,
                                  otherUserName: fullName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
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
        title: const Text('Available Tasks'),
        actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                await _logout();
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
            child: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person),
            ),
                  ),
          const SizedBox(width: 16),
                ],
              ),
      body: SafeArea(
        child: Column(
          children: [
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