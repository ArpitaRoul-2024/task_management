import 'package:equatable/equatable.dart';

class TaskAttachment extends Equatable {
  final String id;
  final String taskId;
  final String fileUrl;
  final String fileName;

  const TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileUrl,
    required this.fileName,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      id: json['id'],
      taskId: json['task_id'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'file_url': fileUrl,
      'file_name': fileName,
    };
  }

  @override
  List<Object?> get props => [id, taskId, fileUrl, fileName];
}