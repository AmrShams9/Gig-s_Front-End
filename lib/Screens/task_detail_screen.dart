import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/questions_card.dart';
import '../widgets/offers_card.dart';
import '../services/task_service.dart';
import '../services/token_service.dart';
import '../models/offer.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();

  Future<List<Offer>> get _offersFuture => _taskService.getOffersForTask(int.parse(widget.task.taskId!));

  Future<void> _refreshOffers() async {
    setState(() {}); // Triggers rebuild and refetches offers
  }

  Future<void> _showMakeOfferDialog() async {
    final _amountController = TextEditingController();
    final _messageController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;
    String? successMessage;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Make an Offer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Offer Amount',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message),
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (successMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(successMessage!, style: const TextStyle(color: Colors.green)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final amount = double.tryParse(_amountController.text);
                          final message = _messageController.text.trim();
                          if (amount == null || amount <= 0) {
                            setState(() => errorMessage = 'Enter a valid amount.');
                            return;
                          }
                          if (message.isEmpty) {
                            setState(() => errorMessage = 'Enter a message.');
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                            successMessage = null;
                          });
                          final runnerIdStr = await TokenService.getUserId();
                          if (runnerIdStr == null) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'User not authenticated.';
                            });
                            return;
                          }
                          final runnerId = int.tryParse(runnerIdStr);
                          if (runnerId == null) {
                            setState(() {
                              isLoading = false;
                              errorMessage = 'Invalid user ID.';
                            });
                            return;
                          }
                          final result = await _taskService.postOffer(
                            taskId: int.parse(widget.task.taskId!),
                            runnerId: runnerId,
                            amount: amount,
                            message: message,
                          );
                          if (result['success']) {
                            setState(() {
                              isLoading = false;
                              successMessage = 'Offer sent successfully!';
                            });
                            await Future.delayed(const Duration(seconds: 1));
                            if (context.mounted) Navigator.of(context).pop();
                          } else {
                            setState(() {
                              isLoading = false;
                              errorMessage = result['error'] ?? 'Failed to send offer.';
                            });
                          }
                        },
                  child: const Text('Send Offer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text('Task'),
          actions: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                // Handle share/send action
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                // Handle add action
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Handle more options
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Questions'),
              Tab(text: 'Offers'),
            ],
            indicatorColor: Color(0xFF1DBF73),
            labelColor: Color(0xFF1DBF73),
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            // Info Tab Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Posted by',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    widget.task.taskPoster.toString(),
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF1DBF73)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Additional Requirements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Location Details: ${widget.task.additionalRequirements?['location'] ?? 'Not specified'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location: Lat: ${widget.task.latitude}, Lon: ${widget.task.longitude}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.category, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Type: ${widget.task.type}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Questions Tab Content
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: const [
                QuestionsCard(
                  profileImage: 'https://via.placeholder.com/50',
                  userName: 'Sarah Johnson',
                  rating: 4.8,
                  question: 'What is the expected duration of this task?',
                  answer: 'The task should take approximately 2-3 hours to complete.',
                ),
                QuestionsCard(
                  profileImage: 'https://via.placeholder.com/50',
                  userName: 'Mike Thompson',
                  rating: 4.5,
                  question: 'Are there any specific tools required?',
                  answer: 'Yes, you will need basic gardening tools. We can provide some if needed.',
                ),
                QuestionsCard(
                  profileImage: 'https://via.placeholder.com/50',
                  userName: 'Emily Davis',
                  rating: 4.9,
                  question: 'Is there parking available nearby?',
                  answer: 'Yes, there is street parking available and a parking lot within walking distance.',
                ),
              ],
            ),
            // Offers Tab Content
            RefreshIndicator(
              onRefresh: _refreshOffers,
              child: FutureBuilder<List<Offer>>(
                future: _offersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: \\n${snapshot.error}'));
                  }
                  final offers = snapshot.data ?? [];
                  if (offers.isEmpty) {
                    return const Center(child: Text('No offers yet for this task.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: offers.length,
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return OffersCard(
                        profileImage: 'https://via.placeholder.com/50',
                        runnerName: 'Runner #${offer.runnerId}',
                        amount: offer.amount,
                        message: offer.message,
                        timestamp: offer.timestamp,
                        rating: 4.5, // Placeholder
                        offerId: offer.id,
                        taskId: widget.task.taskId,
                        taskPosterId: widget.task.taskPoster,
                        status: offer.status,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              _showMakeOfferDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DBF73),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50), // full width
            ),
            child: const Text('Make an Offer', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
} 