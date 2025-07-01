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
import 'accepted_task_detail_screen.dart';
import 'auth.dart';
import '../models/offer.dart';
import '../services/token_service.dart';
import '../Screens/chat_page.dart';
import '../services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../Widgets/chat_card.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'poster_home_screen.dart';

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
  Future<List<Map<String, dynamic>>>? _acceptedOffersFuture;

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
      _acceptedOffersFuture = _fetchAcceptedOffersWithTasks(runnerId);
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

  Future<List<Map<String, dynamic>>> _fetchAcceptedOffersWithTasks(String runnerId) async {
    final offers = await _taskService.getOffersByRunner(runnerId);
    List<Map<String, dynamic>> result = [];
    for (final offer in offers) {
      // Only include accepted offers
      if (offer.status == OfferStatus.ACCEPTED) {
        try {
          final task = await _taskService.getTaskById(offer.taskId ?? offer.id);
          result.add({'offer': offer, 'task': task});
        } catch (_) {
          result.add({'offer': offer, 'task': null});
        }
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

  void _handleAcceptedTaskTap(Task task, Offer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => AcceptedTaskDetailScreen(
          task: task,
          acceptedOffer: offer,
        ),
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
                      color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      category['icon'],
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary.withOpacity(0.7),
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

  Widget _buildHomeGreeting() {
    return FutureBuilder<String?>(
      future: TokenService.getToken(),
      builder: (context, snapshot) {
        String name = '';
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          try {
            final user = JwtDecoder.decode(snapshot.data!);
            name = user['firstName'] ?? user['username'] ?? user['name'] ?? user['sub'] ?? 'User';
          } catch (_) {}
        }
        // Time-based greeting
        String greeting = 'Good Morning';
        final hour = DateTime.now().hour;
        if (hour >= 12 && hour < 17) {
          greeting = 'Good Afternoon';
        } else if (hour >= 17 || hour < 4) {
          greeting = 'Good Evening';
        }
        return Container(
          width: double.infinity,
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 12, right: 12, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                    Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                    Stack(
                      children: [
                        Icon(Icons.notifications_none_rounded, size: 28, color: Theme.of(context).colorScheme.primary),
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 8, bottom: 2),
                child: Text(
                  'Hi ${name.isNotEmpty ? name : 'User'}!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 22, bottom: 16),
                child: Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileScreen() {
    return FutureBuilder<String?>(
      future: TokenService.getToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
          return Center(
            child: Text('Not logged in. Please log in again.'),
          );
        }
        final token = snapshot.data!;
        Map<String, dynamic> user;
        try {
          user = JwtDecoder.decode(token);
          print('Decoded JWT: ' + user.toString());
        } catch (e) {
          return Center(
            child: Text('Invalid session. Please log in again.'),
          );
        }
        final String name =
          user['firstName'] != null && user['lastName'] != null
            ? '${user['firstName']} ${user['lastName']}'
            : user['firstName'] ?? user['username'] ?? user['name'] ?? user['sub'] ?? 'No Name';
        final String email = user['email'] ?? '';
        final String role = (user['roles'] is List && user['roles'].isNotEmpty) ? user['roles'][0] : (user['role'] ?? '');
        final String initial = (user['firstName'] ?? user['username'] ?? 'U').toString().substring(0, 1).toUpperCase();
        final int tasksDone = user['completedTasks'] ?? 0;
        final double earnings = (user['earnings'] is num) ? user['earnings'].toDouble() : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 6,
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFEBF1FD), // soft blue
                        Color(0xFFE3E6EA), // light silver
                        Color(0xFFB0C4DE), // light steel blue
                        Color(0xFFF8F8F8), // white
                        Color(0xFFC0C0C0), // classic silver
                        Color(0xFFB3D0F7), // blue-silver
                        Color(0xFF11366A).withOpacity(0.08), // subtle brand blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.18),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          child: Text(initial, style: TextStyle(fontSize: 36, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        Text(name, style: const TextStyle(fontSize: 22, color: Color(0xFF11366A), fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(role, style: TextStyle(fontSize: 16, color: Color(0xFF11366A).withOpacity(0.8))),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text('$tasksDone', style: const TextStyle(fontSize: 18, color: Color(0xFF11366A), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Tasks Done', style: TextStyle(fontSize: 13, color: Color(0xFF11366A).withOpacity(0.8))),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Column(
                              children: [
                                Text('\u000024${earnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Color(0xFF11366A), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Earnings', style: TextStyle(fontSize: 13, color: Color(0xFF11366A).withOpacity(0.8))),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const PosterHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to Poster'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Edit Profile'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.payment, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Payment History'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.support_agent, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Support'),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () async {
                        await TokenService.clearAuthData();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Home (was Explore)
        return Column(
          children: [
            _buildHomeGreeting(),
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
                      return Center(child: Text('An error occurred: \\${snapshot.error}'));
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
      case 1: // Offers (was My Offers)
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _myOffersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            }
            final data = snapshot.data ?? [];
            if (data.isEmpty) {
              return const Center(child: Text('You have not made any offers yet.'));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Text(
                    'My Proposals',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Never send payment or share sensitive info outside the app. All communication should stay within the platform for your safety.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                            onEdit: () async {
                              final amountController = TextEditingController(text: offer.amount.toString());
                              final messageController = TextEditingController(text: offer.message);
                              await showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Theme.of(context).colorScheme.background,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).viewInsets.bottom,
                                      left: 24,
                                      right: 24,
                                      top: 24,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 40,
                                            height: 4,
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        Text('Edit Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                                        const SizedBox(height: 18),
                                        TextField(
                                          controller: amountController,
                                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                                          decoration: InputDecoration(
                                            labelText: 'Offer Amount',
                                            prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        TextField(
                                          controller: messageController,
                                          maxLines: 2,
                                          decoration: InputDecoration(
                                            labelText: 'Message',
                                            prefixIcon: Icon(Icons.message, color: Theme.of(context).colorScheme.primary),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: () => Navigator.of(context).pop(),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Theme.of(context).colorScheme.primary,
                                                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: const Text('Cancel'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Dummy: just close the sheet
                                                  Navigator.of(context).pop();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                child: const Text('Save Changes'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      case 2: // My Tasks (was Assigned Tasks)
        return RefreshIndicator(
          onRefresh: () async {
            await _loadMyOffers();
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _acceptedOffersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final data = snapshot.data ?? [];
              if (data.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_turned_in,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No assigned tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your accepted offers will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              // Split tasks by status
              final inProgress = data.where((item) {
                final status = (item['task'] as Task?)?.status?.toLowerCase();
                return status == 'in progress' || status == 'accepted';
              }).toList();
              final completed = data.where((item) => (item['task'] as Task?)?.status?.toLowerCase() == 'completed').toList();
              final cancelled = data.where((item) => (item['task'] as Task?)?.status?.toLowerCase() == 'cancelled').toList();
              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (inProgress.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        'Assigned Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ...inProgress.map((item) {
                      final offer = item['offer'] as Offer;
                      final task = item['task'] as Task;
                      return MyTasksCard(
                        taskTitle: task.title,
                        taskType: task.type,
                        status: 'In Progress',
                        deadline: task.startTime ?? DateTime.now().add(const Duration(days: 7)),
                        offerAmount: offer.amount,
                        taskPoster: 'Task Poster #${task.taskPoster}',
                        taskPosterImage: 'https://via.placeholder.com/50',
                        onTap: () {
                          _handleAcceptedTaskTap(task, offer);
                        },
                      );
                    }).toList(),
                  ],
                  if (completed.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
                      child: Text(
                        'Completed Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ...completed.map((item) {
                      final offer = item['offer'] as Offer;
                      final task = item['task'] as Task;
                      return MyTasksCard(
                        taskTitle: task.title,
                        taskType: task.type,
                        status: 'Completed',
                        deadline: task.startTime ?? DateTime.now().add(const Duration(days: 7)),
                        offerAmount: offer.amount,
                        taskPoster: 'Task Poster #${task.taskPoster}',
                        taskPosterImage: 'https://via.placeholder.com/50',
                        onTap: () {
                          _handleAcceptedTaskTap(task, offer);
                        },
                      );
                    }).toList(),
                  ],
                  if (cancelled.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
                      child: Text(
                        'Cancelled Tasks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    ...cancelled.map((item) {
                      final offer = item['offer'] as Offer;
                      final task = item['task'] as Task;
                      return Row(
                        children: [
                          Expanded(
                            child: MyTasksCard(
                              taskTitle: task.title,
                              taskType: task.type,
                              status: 'Cancelled',
                              deadline: task.startTime ?? DateTime.now().add(const Duration(days: 7)),
                              offerAmount: offer.amount,
                              taskPoster: 'Task Poster #${task.taskPoster}',
                              taskPosterImage: 'https://via.placeholder.com/50',
                              onTap: () {
                                _handleAcceptedTaskTap(task, offer);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Implement raise dispute action
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Raise Dispute clicked!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Raise Dispute'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                  if (inProgress.isEmpty && completed.isEmpty && cancelled.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 32),
                      child: Center(child: Text('No assigned, completed, or cancelled tasks yet.')),
                    ),
                ],
              );
            },
          ),
        );
      case 3: // Chat (was Chat, previously index 5)
        final myUserIdFuture = TokenService.getUserId();
        return FutureBuilder<String?>(
          future: myUserIdFuture,
          builder: (context, snapshot) {
            final myUserId = snapshot.data;
            if (myUserId == null) return const Center(child: CircularProgressIndicator());
            return _ChatTabWithSearchAndSettings(myUserId: myUserId);
          },
        );
      case 4: // Profile
        return _buildProfileScreen();
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
        child: _buildBody(),
      ),
      bottomNavigationBar: RunnerNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class _ChatTabWithSearchAndSettings extends StatefulWidget {
  final String myUserId;
  const _ChatTabWithSearchAndSettings({required this.myUserId});

  @override
  State<_ChatTabWithSearchAndSettings> createState() => _ChatTabWithSearchAndSettingsState();
}

class _ChatTabWithSearchAndSettingsState extends State<_ChatTabWithSearchAndSettings> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search message',
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: Implement settings action
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => ListView(
                      shrinkWrap: true,
                      children: const [
                        ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                        ),
                        ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ChatService().getUserChats(widget.myUserId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Center(child: Text('No chats yet.'));
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final lastMessage = (data['lastMessage'] ?? '').toString().toLowerCase();
                final users = List<String>.from(data['users']);
                final otherUserId = users.firstWhere((id) => id != widget.myUserId, orElse: () => '');
                // For name, we need to fetch user data, so filter by lastMessage only here
                return lastMessage.contains(_searchQuery.toLowerCase());
              }).toList();
              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, i) {
                  final data = filteredDocs[i].data() as Map<String, dynamic>;
                  final users = List<String>.from(data['users']);
                  final otherUserId = users.firstWhere((id) => id != widget.myUserId, orElse: () => '');
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
                      // Also filter by name if needed
                      if (_searchQuery.isNotEmpty &&
                          !fullName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                          !lastMessage.toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
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
          ),
        ),
      ],
    );
  }
} 
