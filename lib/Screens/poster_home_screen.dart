import 'package:flutter/material.dart';
import '../widgets/task_poster_nav_bar.dart';
import 'post_task_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'my_tasks_screen.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../models/offer.dart';
import 'package:intl/intl.dart';
import '../services/token_service.dart';
import 'task_form_screen.dart';
import 'Chat_messages.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../widgets/offers_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../Screens/chat_page.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'auth.dart';
import 'runner_home_screen.dart';
import '../models/event_task.dart';

class PosterHomeScreen extends StatefulWidget {
  const PosterHomeScreen({super.key});

  static void showOffersForTask(BuildContext context, String taskId) {
    final state = context.findAncestorStateOfType<_PosterHomeScreenState>();
    state?._showOffersForTask(taskId);
  }

  @override
  State<PosterHomeScreen> createState() => _PosterHomeScreenState();
}

class _PosterHomeScreenState extends State<PosterHomeScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  late Future<List<Map<String, dynamic>>> _tasksFuture;
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Moving', 'icon': Icons.local_shipping},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Grocery', 'icon': Icons.shopping_cart},
    {'name': 'Delivery', 'icon': Icons.delivery_dining},
    {'name': 'Event', 'icon': Icons.event},
    {'name': 'Handyman', 'icon': Icons.handyman},
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Gardening', 'icon': Icons.grass},
  ];
  Map<String, UserModel> _userMap = {};
  bool _usersLoaded = false;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _loadTasks();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _userMap = {for (var u in users) u.id: u};
        _usersLoaded = true;
      });
    } catch (_) {
      setState(() { _usersLoaded = true; });
    }
  }

  Future<List<Map<String, dynamic>>> _loadTasks() async {
    final userId = await TokenService.getUserId();
    if (userId == null) throw Exception('User not authenticated');
    return _taskService.getTasksByPosterRaw(userId);
  }

  Future<int> _getOffersCount(String taskId) async {
    final offers = await _taskService.getOffersForTask(int.parse(taskId));
    return offers.length;
  }

  Widget _buildSummaryCards(List<Task> tasks) {
    final statusCounts = {
      'OPEN': 0,
      'IN_PROGRESS': 0,
      'COMPLETED': 0,
      'CANCELLED': 0,
    };
    for (final t in tasks) {
      final s = t.status?.toUpperCase() ?? 'OPEN';
      if (statusCounts.containsKey(s)) statusCounts[s] = statusCounts[s]! + 1;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusCard('Open', statusCounts['OPEN']!, Colors.blue),
        _buildStatusCard('In Progress', statusCounts['IN_PROGRESS']!, Colors.orange),
        _buildStatusCard('Completed', statusCounts['COMPLETED']!, Colors.green),
        _buildStatusCard('Cancelled', statusCounts['CANCELLED']!, Colors.red),
      ],
    );
  }

  Widget _buildStatusCard(String label, int count, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = _categories[i];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TaskFormScreen(category: cat['name']),
                ),
              );
            },
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: Icon(cat['icon'], color: Colors.grey.shade700),
                  radius: 22,
                ),
                const SizedBox(height: 4),
                Text(cat['name'], style: const TextStyle(fontSize: 12)),
              ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildTaskCard(Task task) {
    return FutureBuilder<int>(
      future: _getOffersCount(task.taskId ?? '0'),
      builder: (context, snapshot) {
        final offersCount = snapshot.data ?? 0;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.type?.isNotEmpty == true ? task.type : 'Other',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('$offersCount offers received', style: TextStyle(color: Colors.green.shade700, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(task.description?.isNotEmpty == true ? task.description : '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to task detail
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        // TODO: Edit task
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit functionality coming soon')),
                        );
                      },
                      icon: Icon(Icons.edit, size: 20, color: Theme.of(context).colorScheme.primary),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          final userIdStr = await TokenService.getUserId();
                          if (userIdStr == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User not authenticated.')),
                            );
                            return;
                          }
                          final result = await _taskService.deleteTask(int.parse(task.taskId ?? '0'), int.parse(userIdStr));
                          if (result['success']) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task deleted successfully!')),
                            );
                            setState(() {
                              _tasksFuture = _loadTasks();
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete task: \\${result['error']}')),
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.delete, size: 20, color: Colors.red),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \\${snapshot.error}'));
        }
        final tasks = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 0),
          children: [
            // Modern header
            FutureBuilder<String?>(
              future: TokenService.getToken(),
              builder: (context, snapshot) {
                String name = '';
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                  try {
                    final user = JwtDecoder.decode(snapshot.data!);
                    name = user['firstName'] ?? user['username'] ?? user['name'] ?? user['sub'] ?? 'User';
                  } catch (_) {}
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
                          'Hi \\${name.isNotEmpty ? name : 'User'}!',
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
                          'Welcome back!',
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
            ),
            const SizedBox(height: 8),
            _buildSummaryCards(tasks.map((t) => Task.fromJson(t)).toList()),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('My Tasks', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ),
            const SizedBox(height: 8),
            ...tasks.map((taskJson) {
              if (taskJson['type'] == 'EVENT_STAFFING') {
                final eventTask = EventTask.fromJson(taskJson);
                return EventTaskCard(eventTask: eventTask);
              } else {
                final task = Task.fromJson(taskJson);
                return _buildTaskCard(task);
              }
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildMessagesTab() {
    final myUserIdFuture = TokenService.getUserId();
    return FutureBuilder<String?>(
      future: myUserIdFuture,
      builder: (context, snapshot) {
        final myUserId = snapshot.data;
        if (myUserId == null) return const Center(child: CircularProgressIndicator());
        return _PosterChatTabWithSearchAndSettings(myUserId: myUserId);
      },
    );
  }

  Widget _buildProfileTab() {
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
        final int tasksPosted = user['tasksPosted'] ?? 0;
        final double totalSpent = (user['totalSpent'] is num) ? user['totalSpent'].toDouble() : 0.0;
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
                                Text('$tasksPosted', style: const TextStyle(fontSize: 18, color: Color(0xFF11366A), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Tasks Posted', style: TextStyle(fontSize: 13, color: Color(0xFF11366A).withOpacity(0.8))),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Column(
                              children: [
                                Text('\u000024${totalSpent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, color: Color(0xFF11366A), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Total Spent', style: TextStyle(fontSize: 13, color: Color(0xFF11366A).withOpacity(0.8))),
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
                      MaterialPageRoute(builder: (context) => const RunnerHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Switch to Runner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 18),
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
      case 0:
        return _buildHomeTab();
      case 1:
        return const MyTasksScreen();
      case 2:
        return _buildMessagesTab();
      case 3:
        return _buildProfileTab();
      default:
        return const Center(child: Text('Unknown tab'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showOffersForTask(String taskId) {
    print('[DEBUG] _showOffersForTask called with taskId: $taskId');
    setState(() {
      _selectedIndex = 2; // Offers tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PostTaskScreen(),
            ),
          );
          setState(() {
            _tasksFuture = _loadTasks();
          });
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 36),
        elevation: 4,
        shape: const CircleBorder(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class OffersListScreen extends StatelessWidget {
  final String taskId;
  const OffersListScreen({Key? key, required this.taskId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TaskService _taskService = TaskService();
    return Scaffold(
      appBar: AppBar(title: const Text('Offers for Task')),
      body: FutureBuilder<List<Offer>>(
        future: _taskService.getOffersForTask(int.parse(taskId)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\n${snapshot.error}'));
          }
          final offers = snapshot.data ?? [];
          if (offers.isEmpty) {
            return const Center(child: Text('No offers for this task.'));
          }
          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, i) {
              final offer = offers[i];
              final runnerName = offer is Offer ? 'Runner #${offer.runnerId}' : 'Unknown Runner';
              final amount = offer is Offer ? offer.amount : 0.0;
              final message = offer is Offer ? offer.message : '';
              final timestamp = offer is Offer ? offer.timestamp : DateTime.now();
              return OffersCard(
                runnerName: runnerName,
                runnerId: offer is Offer ? offer.runnerId : null,
                amount: amount,
                message: message,
                timestamp: timestamp,
                offerId: offer is Offer ? offer.id : null,
                taskId: taskId,
                taskPosterId: null,
                status: offer is Offer ? offer.status : null,
                onAccept: () async {
                  final taskPosterId = int.tryParse(await TokenService.getUserId() ?? '');
                  if (taskPosterId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not authenticated')),
                    );
                    return;
                  }
                  
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Accept Offer'),
                      content: const Text('Are you sure you want to accept this offer?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final taskService = TaskService();
                    
                    // First, accept the offer
                    final acceptResult = await taskService.acceptOffer(
                      offerId: offer is Offer ? offer.id : '',
                      taskId: int.parse(taskId),
                      taskPosterId: taskPosterId,
                    );
                    
                    if (acceptResult['success']) {
                      // Then update task status to IN_PROGRESS
                      final statusResult = await taskService.updateTaskStatusToInProgress(
                        int.parse(taskId),
                      );
                      
                      if (statusResult['success']) {
                        // Finally, delete all other offers for this task
                        final deleteResult = await taskService.deleteAllOffersForTask(
                          int.parse(taskId),
                        );
                        
                        if (deleteResult['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Offer accepted successfully! Task status updated to IN_PROGRESS.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Offer accepted but failed to clean up other offers: ${deleteResult['error']}'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Offer accepted but failed to update task status: ${statusResult['error']}'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to accept offer: ${acceptResult['error']}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PosterChatTabWithSearchAndSettings extends StatefulWidget {
  final String myUserId;
  const _PosterChatTabWithSearchAndSettings({required this.myUserId});

  @override
  State<_PosterChatTabWithSearchAndSettings> createState() => _PosterChatTabWithSearchAndSettingsState();
}

class _PosterChatTabWithSearchAndSettingsState extends State<_PosterChatTabWithSearchAndSettings> {
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
                      if (_searchQuery.isNotEmpty &&
                          !fullName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                          !lastMessage.toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
                        return const SizedBox.shrink();
                      }
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

class EventTaskCard extends StatelessWidget {
  final EventTask eventTask;
  const EventTaskCard({Key? key, required this.eventTask}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Posted: \\${eventTask.createdDate?.toString() ?? ''}',
              style: TextStyle(fontSize: 13, color: theme.colorScheme.primary.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              eventTask.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      eventTask.type?.isNotEmpty == true ? eventTask.type : '',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.attach_money, size: 16, color: theme.colorScheme.primary),
                      Text(
                        eventTask.fixedPay.toStringAsFixed(0),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('People: \\${eventTask.requiredPeople}', style: TextStyle(fontSize: 13, color: theme.colorScheme.primary.withOpacity(0.7)), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              eventTask.description?.isNotEmpty == true ? eventTask.description : '',
              style: TextStyle(fontSize: 15, color: theme.colorScheme.primary.withOpacity(0.85)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text(eventTask.location?.isNotEmpty == true ? eventTask.location : '', style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
                const SizedBox(width: 4),
                Text('From: \\${eventTask.startDate?.toString() ?? ''} To: \\${eventTask.endDate?.toString() ?? ''}', style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 