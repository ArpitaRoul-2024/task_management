import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../domain/entities/task.dart';
import '../models/message.dart' as model;
import '../models/user_model.dart';

class TaskRepo {
  final String baseUrl = 'https://task-management-9gaz.onrender.com/api';
  late IO.Socket _socket;
  bool _isSocketInitialized = false;

  TaskRepo() {
    _initializeSocket();
  }

  void _initializeSocket() {
    if (_isSocketInitialized) return;
    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _isSocketInitialized = true;

    _socket.on('connect_error', (error) {
      print('Socket connection error: $error');
    });
  }

  void connectSocket(String token) {
    if (!_socket.connected) {
      _socket.connect();
      _socket.emit('authenticate', token);
    }
  }

  void disconnectSocket() {
    if (_socket.connected) {
      _socket.disconnect();
    }
    _socket.clearListeners();
  }

  void listenForMessages(void Function(model.Message) onMessage) {
    _socket.on('newMessage', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final message = model.Message.fromJson(data);
          onMessage(message);
        } else {
          print('Invalid message data received: $data');
        }
      } catch (e) {
        print('Error processing newMessage event: $e');
      }
    });
  }

  Future<List<Task>> fetchTasks(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('fetchTasks response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        final error = _parseError(response);
        throw Exception('Failed to fetch tasks: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('fetchTasks error: $e');
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  Future<String?> addTask(Task task, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      print('addTask response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['id'] as String?;
      } else {
        final error = _parseError(response);
        throw Exception('Failed to add task: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('addTask error: $e');
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task task, String token) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(task.toJson()),
      );

      print('updateTask response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        final error = _parseError(response);
        throw Exception('Failed to update task: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('updateTask error: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(String taskId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('deleteTask response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        final error = _parseError(response);
        throw Exception('Failed to delete task: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('deleteTask error: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> addAttachment(String taskId, String fileUrl, String fileName, String token) async {
    try {
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

      print('addAttachment response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 201) {
        final error = _parseError(response);
        throw Exception('Failed to add attachment: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('addAttachment error: $e');
      throw Exception('Failed to add attachment: $e');
    }
  }

  Future<List<AppUser>> fetchUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('fetchUsers response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AppUser.fromJson(json)).toList();
      } else {
        final error = _parseError(response);
        throw Exception('Failed to fetch users: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('fetchUsers error: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> markMessagesAsRead(String receiverId, String senderId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'sender_id': senderId, 'receiver_id': receiverId}),
      );

      print('markMessagesAsRead response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        final error = _parseError(response);
        throw Exception('Failed to mark messages as read: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('markMessagesAsRead error: $e');
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<int> getUnreadMessageCount(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('getUnreadMessageCount response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int;
      } else {
        final error = _parseError(response);
        throw Exception('Failed to fetch unread message count: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('getUnreadMessageCount error: $e');
      throw Exception('Failed to fetch unread message count: $e');
    }
  }

  Future<List<model.Message>> fetchMessages(String userId, String otherUserId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat?sender_id=$userId&receiver_id=$otherUserId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('fetchMessages response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => model.Message.fromJson(json)).toList();
      } else {
        final error = _parseError(response);
        throw Exception('Failed to fetch messages: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('fetchMessages error: $e');
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<void> sendMessage(String senderId, String receiverId, String message, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'receiver_id': receiverId,
          'message': message,
        }),
      );

      print('sendMessage response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 201) {
        final error = _parseError(response);
        throw Exception('Failed to send message: ${response.statusCode} - $error');
      }
    } catch (e) {
      print('sendMessage error: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  String _parseError(http.Response response) {
    try {
      final body = response.body;
      if (body.startsWith('<!DOCTYPE html') || body.contains('<html')) {
        return 'Server returned HTML instead of JSON. Possible incorrect endpoint or server error.';
      }
      final json = jsonDecode(body);
      return json['error'] ?? 'Unknown error';
    } catch (e) {
      return 'Failed to parse error: ${response.body}';
    }
  }
}