import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/task_repo.dart';
import 'package:task_management/auth_cubit.dart';
import 'package:task_management/model/user_model.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TaskRepo _taskRepo = TaskRepo();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUserId;
  List<AppUser> _users = [];
  final ScrollController _scrollController = ScrollController();
  late Timer _refreshTimer;
  final String _initialUserId = 'b307a592-7db7-491d-a887-96573698d3e6';

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_selectedUserId != null) setState(() {});
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      print('Fetching users with token: $token'); // Debug token
      final users = await _taskRepo.fetchUsers(token);
      if (mounted) {
        setState(() {
          _users = users;
          print('Fetched users: ${_users.map((u) => u.id).toList()}'); // Debug user IDs
          if (_selectedUserId == null && _users.any((user) => user.id == _initialUserId)) {
            _selectedUserId = _initialUserId;
          } else if (_selectedUserId == null && _users.isNotEmpty) {
            _selectedUserId = _users.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error in _loadUsers: $e'); // Debug error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    try {
      final cubit = context.read<AuthCubit>();
      final senderId = cubit.currentUser?.id ?? '';
      final token = cubit.token ?? '';
      print('Fetching messages for sender: $senderId, receiver: $_selectedUserId with token: $token');
      return await _taskRepo.fetchMessages(senderId, _selectedUserId!, token);
    } catch (e) {
      if (mounted) {
        print('Error in _fetchMessages: $e'); // Debug error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching messages: $e'), backgroundColor: Colors.red),
        );
      }
      return [];
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty && _selectedUserId != null) {
      try {
        final cubit = context.read<AuthCubit>();
        final senderId = cubit.currentUser?.id ?? '';
        final token = cubit.token ?? '';
        print('Sending message from $senderId to $_selectedUserId with token: $token');
        await _taskRepo.sendMessage(senderId, _selectedUserId!, _messageController.text, token);
        _messageController.clear();
        setState(() {});
      } catch (e) {
        if (mounted) {
          print('Error in _sendMessage: $e'); // Debug error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final senderId = cubit.currentUser?.id ?? '';
    final currentTime = DateTime.now().toLocal(); // 03:42 PM IST, July 22, 2025

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF007AFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            color: Colors.white,
          ),
        ],
      ),
      body: Row(
        children: [
          // Contact List (Left Panel - Skype-like)
          Container(
            width: 250,
            color: const Color(0xFFE5E5EA),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF007AFF),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(user.email ?? 'Unknown', style: const TextStyle(fontSize: 16)),
                        selected: _selectedUserId == user.id,
                        onTap: () {
                          setState(() {
                            _selectedUserId = user.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Chat Area (Right Panel - Skype-like)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchMessages(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      final messages = snapshot.data ?? [];
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSentByMe = message['sender_id'] == senderId;
                          final time = DateTime.parse(message['created_at']).toLocal();
                          return Align(
                            alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSentByMe ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message['message'],
                                    style: TextStyle(
                                      color: isSentByMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${time.hour}:${time.minute} ${time.day}-${time.month}-${time.year}',
                                    style: TextStyle(
                                      color: isSentByMe ? Colors.white70 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF007AFF)),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}