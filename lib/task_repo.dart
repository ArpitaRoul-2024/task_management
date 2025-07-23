import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../entities/task.dart';
import 'model/message.dart';
import 'model/user_model.dart';

class TaskRepo {
  final String baseUrl = 'https://task-management-9gaz.onrender.com/api'; // Ensure WebSocket support
  late IO.Socket _socket;

  TaskRepo() {
    _initializeSocket();
  }

  void _initializeSocket() {
    _socket = IO.io('$baseUrl', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();

    // Authenticate socket (to be called with token when needed)
    // This will be handled in ChatScreen or a higher-level manager
  }

  // Task-related methods
  Future<List<Task>> fetchTasks(String userId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch tasks: ${response.statusCode} - ${response.body}');
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
      return jsonDecode(response.body)['id'] as String?;
    } else {
      throw Exception('Failed to add task: ${response.statusCode} - ${response.body}');
    }
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
      throw Exception('Failed to update task: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteTask(String taskId, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode} - ${response.body}');
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
      throw Exception('Failed to add attachment: ${response.statusCode} - ${response.body}');
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
      throw Exception('Failed to fetch users: ${response.statusCode} - ${response.body}');
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
      throw Exception('Failed to update task assignee: ${response.statusCode} - ${response.body}');
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
        'receiver_id': receiverId,
        'message': message,
      }), // Corrected to match server expectation
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Message>> fetchMessages(String userId, String otherUserId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/chat?sender_id=$userId&receiver_id=$otherUserId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch messages: ${response.statusCode} - ${response.body}');
    }
  }

  // Socket.IO methods
  void connectSocket(String token) {
    if (!_socket.connected) {
      _socket.emit('authenticate', token);
    }
  }

  void disconnectSocket() {
    if (_socket.connected) {
      _socket.disconnect();
    }
  }

  void listenForMessages(void Function(Message) onMessage) {
    _socket.on('newMessage', (data) {
      final message = Message.fromJson(data);
      onMessage(message);
    });
  }
}