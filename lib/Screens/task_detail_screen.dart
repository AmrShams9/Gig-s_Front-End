import 'package:flutter/material.dart';
import '../models/task.dart';

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
            (widget.task.questions != null && widget.task.questions!.isNotEmpty)
                ? ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.task.questions!.length,
                    itemBuilder: (context, index) {
                      final question = widget.task.questions![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User: ${question.userId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                question.questionText,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${question.timestamp.toLocal().toString().split('.').first}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No questions yet.')),
            // Offers Tab Content
            (widget.task.offers != null && widget.task.offers!.isNotEmpty)
                ? ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.task.offers!.length,
                    itemBuilder: (context, index) {
                      final offer = widget.task.offers![index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Runner: ${offer.runnerId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Offer Amount: \$${offer.amount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF1DBF73)),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                offer.message,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${offer.timestamp.toLocal().toString().split('.').first}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('No offers yet.')),
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