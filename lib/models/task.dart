import 'question.dart';
import 'offer.dart';
import 'package:flutter/material.dart';

class Task {
  final String? taskId;
  final int taskPoster;
  final String title;
  final String description;
  final String type;
  final String taskType;
  final String? status;
  final double? longitude;
  final double? latitude;
  final Map<String, dynamic>? additionalRequirements;
  final Map<String, dynamic>? additionalAttributes;
  final double amount;
  final List<Question>? questions;
  final List<Offer>? offers;
  final double? price;
  final String? duration;
  final DateTime? startTime;
  final DateTime? endTime;

  Task({
    this.taskId,
    required this.taskPoster,
    required this.title,
    required this.description,
    required this.type,
    this.taskType = 'REGULAR',
    this.status,
    this.longitude,
    this.latitude,
    this.additionalRequirements,
    this.additionalAttributes,
    required this.amount,
    this.questions,
    this.offers,
    this.price,
    this.duration,
    this.startTime,
    this.endTime,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['taskId']?.toString(),
      taskPoster: json['taskPoster'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      taskType: json['task_type'] as String? ?? 'REGULAR',
      status: json['status'] as String?,
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      additionalRequirements: json['additionalRequirements'] as Map<String, dynamic>?,
      additionalAttributes: json['additionalAttributes'] as Map<String, dynamic>?,
      amount: (json['amount'] as num).toDouble(),
      // 'questions' and 'offers' are not in the provided JSON, so they can be null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'taskPoster': taskPoster,
      'title': title,
      'description': description,
      'type': type,
      'task_type': taskType,
      'status': status,
      'longitude': longitude,
      'latitude': latitude,
      'additionalRequirements': additionalRequirements,
      'additionalAttributes': additionalAttributes,
      'amount': amount,
    };
  }
} 