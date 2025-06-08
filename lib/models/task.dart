import 'question.dart';
import 'offer.dart';

class Task {
  final String taskId;
  final String taskPoster;
  final String title;
  final String description;
  final String type;
  final String status;
  final double longitude;
  final double latitude;
  final String additionalRequirements;
  final List<Question>? questions;
  final List<Offer>? offers;

  Task({
    required this.taskId,
    required this.taskPoster,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.longitude,
    required this.latitude,
    required this.additionalRequirements,
    this.questions,
    this.offers,
  });
} 