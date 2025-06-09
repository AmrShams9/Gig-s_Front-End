import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/questions_card.dart';
import '../widgets/offers_card.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
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
                    widget.task.taskPoster,
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
                    widget.task.additionalRequirements,
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
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                OffersCard(
                  profileImage: 'https://via.placeholder.com/50',
                  runnerName: 'Alex Morgan',
                  amount: 150.00,
                  message: 'I have extensive experience in similar tasks and can complete this efficiently. I\'m available immediately and can start right away.',
                  timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                  rating: 4.9,
                ),
                OffersCard(
                  profileImage: 'https://via.placeholder.com/50',
                  runnerName: 'David Wilson',
                  amount: 175.00,
                  message: 'I specialize in this type of work and have all the necessary tools. I can provide references from previous clients.',
                  timestamp: DateTime.now().subtract(const Duration(hours: 5)),
                  rating: 4.7,
                ),
                OffersCard(
                  profileImage: 'https://via.placeholder.com/50',
                  runnerName: 'Lisa Chen',
                  amount: 140.00,
                  message: 'I\'m very interested in this task and can complete it with high quality. I\'m flexible with timing and can work around your schedule.',
                  timestamp: DateTime.now().subtract(const Duration(days: 1)),
                  rating: 4.8,
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Handle Make an Offer button press
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