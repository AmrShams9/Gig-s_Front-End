class Offer {
  final String id;
  final String runnerId;
  final double amount;
  final String message;
  final DateTime timestamp;

  Offer({
    required this.id,
    required this.runnerId,
    required this.amount,
    required this.message,
    required this.timestamp,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    String id = json['id']?.toString() ?? json['offerId']?.toString() ?? '';
    String runnerId = json['runnerId']?.toString() ?? '';
    double amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    String message = json['comment'] ?? json['message'] ?? '';
    DateTime timestamp;
    try {
      timestamp = json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now();
    } catch (_) {
      timestamp = DateTime.now();
    }
    return Offer(
      id: id,
      runnerId: runnerId,
      amount: amount,
      message: message,
      timestamp: timestamp,
    );
  }
} 