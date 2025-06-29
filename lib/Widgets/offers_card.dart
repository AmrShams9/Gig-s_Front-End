import 'package:flutter/material.dart';
import '../Screens/Chat_messages.dart';
import '../Screens/chat_page.dart';
import '../services/token_service.dart';
import '../services/task_service.dart';
import '../models/offer.dart';

// OffersCard widget for displaying offer information
class OffersCard extends StatelessWidget {
  final String profileImage;
  final String runnerName;
  final String? runnerId;
  final double amount;
  final String message;
  final DateTime timestamp;
  final double rating;
  final VoidCallback? onAccept;
  final String? offerId;
  final String? taskId;
  final int? taskPosterId;
  final OfferStatus? status;

  const OffersCard({
    Key? key,
    this.profileImage = 'https://via.placeholder.com/50',
    this.runnerName = 'John Doe',
    this.runnerId,
    this.amount = 0.0,
    this.message = '',
    required this.timestamp,
    this.rating = 4.5,
    this.onAccept,
    this.offerId,
    this.taskId,
    this.taskPosterId,
    this.status,
  }) : super(key: key);

  bool get _canAcceptOffer {
    return status == null || status == OfferStatus.PENDING;
  }

  Color _getStatusColor() {
    switch (status) {
      case OfferStatus.ACCEPTED:
        return Colors.green;
      case OfferStatus.CANCELLED:
        return Colors.red;
      case OfferStatus.AWAITING_PAYMENT:
        return Colors.orange;
      case OfferStatus.PENDING:
      default:
        return Colors.blue;
    }
  }

  String _getStatusText() {
    switch (status) {
      case OfferStatus.ACCEPTED:
        return 'Accepted';
      case OfferStatus.CANCELLED:
        return 'Cancelled';
      case OfferStatus.AWAITING_PAYMENT:
        return 'Awaiting Payment';
      case OfferStatus.PENDING:
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(profileImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              runnerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(), width: 1),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DBF73).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF1DBF73),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(
                        _canAcceptOffer ? Icons.check_circle : Icons.info,
                        size: 18,
                        color: Colors.white
                      ),
                      label: Text(_canAcceptOffer ? 'Accept Offer' : _getStatusText()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canAcceptOffer ? Color(0xFF1DBF73) : _getStatusColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _canAcceptOffer ? (onAccept ?? (offerId != null && taskId != null && taskPosterId != null
                          ? () async {
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
                                  offerId: offerId!,
                                  taskId: int.parse(taskId!),
                                  taskPosterId: taskPosterId!,
                                );
                                
                                if (acceptResult['success']) {
                                  // Then update task status to IN_PROGRESS
                                  final statusResult = await taskService.updateTaskStatusToInProgress(
                                    int.parse(taskId!),
                                  );
                                  
                                  if (statusResult['success']) {
                                    // Finally, delete all other offers for this task
                                    final deleteResult = await taskService.deleteAllOffersForTask(
                                      int.parse(taskId!),
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
                            }
                          : null)) : null,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                      label: const Text('Send Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF25D366), // WhatsApp green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (runnerId != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                otherUserId: runnerId!,
                                otherUserName: runnerName,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(timestamp),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
