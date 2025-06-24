import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/token_service.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  final TaskService _taskService = TaskService();
  Future<List<Task>>? _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final userId = await TokenService.getUserId();
    if (userId != null) {
      setState(() {
        _tasksFuture = _taskService.getTasksByPoster(userId);
      });
    }
  }

  Future<void> _cancelTask(Task task) async {
    final userId = await TokenService.getUserId();
    if (task.taskId == null || userId == null) return;

    final result =
        await _taskService.updateTaskStatus(int.parse(task.taskId!), 'CANCELLED', userId);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task cancelled successfully!')),
        );
        _loadTasks(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel task: ${result['error']}')),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    final userIdStr = await TokenService.getUserId();
    if (task.taskId == null || userIdStr == null) return;
    final userId = int.tryParse(userIdStr);
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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
    if (confirm != true) return;

    final result = await _taskService.deleteTask(int.parse(task.taskId!), userId);
    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully!')),
        );
        _loadTasks();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: ${result['error']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posted Tasks'),
      ),
      body: FutureBuilder<List<Task>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have not posted any tasks yet.'));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return MyTaskCard(
                task: tasks[index],
                onCancel: () => _cancelTask(tasks[index]),
                onDelete: () => _deleteTask(tasks[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class MyTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const MyTaskCard({super.key, required this.task, required this.onCancel, required this.onDelete});

  @override
  State<MyTaskCard> createState() => _MyTaskCardState();
}

class _MyTaskCardState extends State<MyTaskCard> {
  late String _selectedStatus;
  final List<String> _statusOptions = ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.task.status ?? 'OPEN';
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (newStatus == null || newStatus == _selectedStatus) return;
    setState(() { _isUpdating = true; });
    final userIdStr = await TokenService.getUserId();
    if (widget.task.taskId == null || userIdStr == null) return;
    final userId = userIdStr;
    final result = await TaskService().updateTaskStatus(
      int.parse(widget.task.taskId!),
      newStatus,
      userId,
    );
    setState(() { _isUpdating = false; });
    if (result['success']) {
      setState(() { _selectedStatus = newStatus; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task status updated to $newStatus.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: ${result['error']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: _statusColor(_selectedStatus),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        items: _statusOptions.map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Row(
                              children: [
                                Icon(_statusIcon(status), color: _statusColor(status), size: 18),
                                const SizedBox(width: 6),
                                Text(_statusLabel(status)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _isUpdating ? null : _updateStatus,
                        style: TextStyle(
                          color: _statusColor(_selectedStatus),
                          fontWeight: FontWeight.bold,
                        ),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.task.description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.attach_money, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      widget.task.amount.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.location_on, color: Colors.red.shade300, size: 18),
                    Text(
                      widget.task.additionalRequirements?['location'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete Task',
                    ),
                    TextButton(
                      onPressed: widget.onCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'OPEN':
        return 'Open';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.radio_button_unchecked;
      case 'IN_PROGRESS':
        return Icons.timelapse;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }
} 