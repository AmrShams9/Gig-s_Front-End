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
  final double? amount;
  final List<Question>? questions;
  final List<Offer>? offers;
  final double? price;
  final String? duration;
  final DateTime? startTime;
  final DateTime? endTime;
  final double? fixedPay;
  final int? requiredPeople;
  final String? location;
  final String? startDate;
  final String? endDate;
  final int? numberOfDays;
  final List<dynamic>? runnerIds;

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
    this.amount,
    this.questions,
    this.offers,
    this.price,
    this.duration,
    this.startTime,
    this.endTime,
    this.fixedPay,
    this.requiredPeople,
    this.location,
    this.startDate,
    this.endDate,
    this.numberOfDays,
    this.runnerIds,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    print('Parsing fixedPay: \\${json['fixedPay']}');
    print('Parsing amount: \\${json['amount']}');
    print('Parsing requiredPeople: \\${json['requiredPeople']}');
    print('Parsing numberOfDays: \\${json['numberOfDays']}');
    print('Parsing longitude: \\${json['longitude']}');
    print('Parsing latitude: \\${json['latitude']}');
    return Task(
      taskId: json['taskId']?.toString(),
      taskPoster: json['taskPoster'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      taskType: json['task_type'] as String? ?? 'REGULAR',
      status: json['status'] as String?,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      additionalRequirements: json['additionalRequirements'] as Map<String, dynamic>?,
      additionalAttributes: json['additionalAttributes'] as Map<String, dynamic>?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      fixedPay: json['fixedPay'] != null ? (json['fixedPay'] as num).toDouble() : null,
      requiredPeople: json['requiredPeople'] != null ? json['requiredPeople'] as int : null,
      location: json['location'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      numberOfDays: json['numberOfDays'] != null ? json['numberOfDays'] as int : null,
      runnerIds: json['runnerIds'] != null ? List<dynamic>.from(json['runnerIds']) : [],
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
      'fixedPay': fixedPay,
      'requiredPeople': requiredPeople,
      'location': location,
      'startDate': startDate,
      'endDate': endDate,
      'numberOfDays': numberOfDays,
      'runnerIds': runnerIds,
    };
  }
} 