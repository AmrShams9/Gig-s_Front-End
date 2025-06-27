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
  String? _selectedTaskIdForOffers;
  final AuthService _authService = AuthService();
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  late Future<List<Task>> _tasksFuture;
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

  Future<List<Task>> _loadTasks() async {
    final userId = await TokenService.getUserId();
    if (userId == null) throw Exception('User not authenticated');
    return _taskService.getTasksByPoster(userId);
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
                        task.type.isNotEmpty ? task.type : 'Other',
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
                        Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                    onTap: () {
                      // TODO: Navigate to task detail
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Offers'),
                        content: FutureBuilder<List<Offer>>(
                          future: _taskService.getOffersForTask(int.parse(task.taskId ?? '0')),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Error: \n${snapshot.error}');
                            }
                            final offers = snapshot.data ?? [];
                            if (offers.isEmpty) {
                              return const Text('No offers for this task.');
                            }
                            return SizedBox(
                              width: 250,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: offers.length,
                                itemBuilder: (context, i) {
                                  final offer = offers[i];
                                  final user = _userMap[offer.runnerId];
                                  final runnerName = user != null ? '${user.firstName} ${user.lastName}'.trim() : 'Runner #${offer.runnerId}';
                                  return ListTile(
                                    leading: const CircleAvatar(
                                      backgroundImage: AssetImage('assets/images/placeholder_profile.jpg'),
                                    ),
                                    title: Text(runnerName),
                                    subtitle: Text(offer.message),
                                    trailing: Text('${offer.amount.toStringAsFixed(2)}'),
                                  );
                                },
                    ),
                  );
                },
              ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                    ),
                  );
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Show Offers'),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildHomeTab() {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tasks = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
            _buildSummaryCards(tasks),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Quick Categories', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            _buildCategories(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Unassigned Tasks', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ...tasks.map(_buildTaskCard).toList(),
          ],
        );
      },
    );
  }

  Widget _buildOffersTab() {
    if (_selectedTaskIdForOffers == null) {
      return const Center(child: Text('Select a task to view offers.'));
    }
    return FutureBuilder<List<Offer>>(
      key: ValueKey(_selectedTaskIdForOffers),
      future: _taskService.getOffersForTask(int.parse(_selectedTaskIdForOffers!)),
      builder: (context, snapshot) {
        print('[DEBUG] FutureBuilder rebuilding for taskId: $_selectedTaskIdForOffers');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: \n${snapshot.error}'));
        }
        final offers = snapshot.data ?? [];
        print('Offers received: ' + offers.toString());
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
              onAccept: () async {
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offer accepted!')),
                  );
                  // TODO: Call backend to accept the offer
                }
              },
            );
          },
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
                return ListTile(
                  title: Text('User $otherUserId'),
                  subtitle: Text(lastMessage),
                  trailing: lastTimestamp != null
                      ? Text('${lastTimestamp.hour}:${lastTimestamp.minute}')
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          otherUserId: otherUserId,
                          otherUserName: 'User $otherUserId',
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
  }

  Widget _buildProfileTab() {
    // Simple profile tab with logout
    return FutureBuilder<String?>(
      future: TokenService.getUserId(),
      builder: (context, snapshot) {
        final userId = snapshot.data ?? '';
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage('assets/images/placeholder_profile.jpg'),
              ),
              const SizedBox(height: 16),
              Text('User ID: $userId', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () async {
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/auth');
                  }
                },
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
        return _buildOffersTab();
      case 3:
        return _buildMessagesTab();
      case 4:
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
      _selectedTaskIdForOffers = taskId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Poster Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/placeholder_profile.jpg'),
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
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
              icon: const Icon(Icons.add),
              label: const Text('Post a Task'),
              backgroundColor: const Color(0xFF1DBF73),
            )
          : null,
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
              );
            },
          );
        },
      ),
    );
  }
}

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Returns the chat document ID for two users, creating it if needed
  Future<String> getOrCreateChatId(String userId1, String userId2) async {
    final users = [userId1, userId2]..sort();
    final chatQuery = await _db
        .collection('chat')
        .where('users', isEqualTo: users)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      return chatQuery.docs.first.id;
    } else {
      final doc = await _db.collection('chat').add({
        'users': users,
        'lastMessage': '',
        'lastTimestamp': FieldValue.serverTimestamp(),
      });
      return doc.id;
    }
  }

  // Stream messages for a chat
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _db
        .collection('chat')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(String chatId, String senderId, String text) async {
    await _db.collection('chat').doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Update last message in chat doc
    await _db.collection('chat').doc(chatId).update({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // Stream all chats for a user
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _db
        .collection('chat')
        .where('users', arrayContains: userId)
        .orderBy('lastTimestamp', descending: true)
        .snapshots();
  }
} 