import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/task.dart';
import 'model/user_model.dart';

class TaskRepo {
  final String baseUrl = 'http://localhost:3000/api';

  Future<List<Task>> fetchTasks(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch tasks');
    }
  }

  Future<String?> addTask(Task task, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body)['id'];
    }
    return null;
  }

  Future<void> updateTask(Task task, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/${task.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(task.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(String taskId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  Future<void> addAttachment(String taskId, String fileUrl, String fileName, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/attachments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'file_url': fileUrl,
        'file_name': fileName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add attachment');
    }
  }

  Future<List<AppUser>> fetchUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> updateTaskAssignedTo(String taskId, String newAssigneeId, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/assignee'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'assigned_to': newAssigneeId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task assignee');
    }
  }

  // Chat-related methods
  Future<void> sendMessage(String senderId, String receiverId, String message, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String userId, String otherUserId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat?sender_id=$userId&receiver_id=$otherUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch messages');
    }
  }
}