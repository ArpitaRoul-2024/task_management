import 'package:equatable/equatable.dart';

import '../model/user_model.dart';
import '../task_attachment.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final String? priority;
  final String? status;
  final AppUser? createdBy;
  final AppUser? assignedTo;
  final List<TaskAttachment> attachments;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority,
    this.status,
    this.createdBy,
    this.assignedTo,
    this.attachments = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      priority: json['priority'] as String?,
      status: json['status'] as String?,
      createdBy: json['created_by'] != null && json['created_by'] is Map
          ? AppUser.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
      assignedTo: json['assigned_to'] != null && json['assigned_to'] is Map
          ? AppUser.fromJson(json['assigned_to'] as Map<String, dynamic>)
          : null,
      attachments: json['task_attachments'] != null
          ? (json['task_attachments'] as List).map((e) => TaskAttachment.fromJson(e as Map<String, dynamic>)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'status': status,
      'created_by': createdBy?.id, // Send only the ID as a string
      'assigned_to': assignedTo?.id, // Send only the ID as a string
      'task_attachments': attachments.map((a) => a?.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, title, description, dueDate, priority, status, createdBy, assignedTo, attachments];
}