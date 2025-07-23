import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/task_repo.dart';
import 'package:task_management/auth_cubit.dart';
import 'package:task_management/model/user_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'home_screen.dart';
import 'model/message.dart';

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
  List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late Timer _refreshTimer;
  final String _initialUserId = 'b307a592-7db7-491d-a887-96573698d3e6';
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _loadUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_selectedUserId != null) _loadMessages();
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _socket.disconnect();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    _socket.connect();

    final cubit = context.read<AuthCubit>();
    final token = cubit.token ?? '';
    _socket.emit('authenticate', token);

    _socket.on('newMessage', (data) {
      if (mounted) {
        setState(() {
          final message = Message.fromJson(data);
          if ((message.senderId == cubit.currentUser?.id || message.receiverId == cubit.currentUser?.id) &&
              (message.receiverId == _selectedUserId || message.senderId == _selectedUserId)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
      }
    });

    _socket.on('connect_error', (error) {
      print('Socket connection error: $error');
    });
  }

  Future<void> _loadUsers() async {
    try {
      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      final users = await _taskRepo.fetchUsers(token);
      if (mounted) {
        setState(() {
          _users = users;
          _selectedUserId = _users.isNotEmpty && _users.any((user) => user.id == _initialUserId)
              ? _initialUserId
              : _users.isNotEmpty
              ? _users.first.id
              : null;
          if (_selectedUserId != null) _loadMessages();
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error in _loadUsers: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final cubit = context.read<AuthCubit>();
      final senderId = cubit.currentUser?.id ?? '';
      final token = cubit.token ?? '';
      final messages = await _taskRepo.fetchMessages(senderId, _selectedUserId!, token);
      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        print('Error in _loadMessages: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e'), backgroundColor: Colors.red),
        );
      }
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
        await _taskRepo.sendMessage(senderId, _selectedUserId!, _messageController.text, token);
        _messageController.clear();
        setState(() {});
      } catch (e) {
        if (mounted) {
          print('Error in _sendMessage: $e');
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
    final currentTime = DateTime.now().toLocal(); // 02:44 PM IST, July 23, 2025

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),

        title: Text(
          'Chat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {
              _loadUsers();
              if (_selectedUserId != null) _loadMessages();
            }),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // Contact List (Adaptive width for mobile)
              Container(
                width: constraints.maxWidth > 600 ? 250 : constraints.maxWidth * 0.4,
                color: Colors.grey[200],
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Contacts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[700],
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                            title: Text(
                              user.name ?? 'Unknown', // Display name instead of email
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            selected: _selectedUserId == user.id,
                            selectedTileColor: Colors.blue[100],
                            onTap: () {
                              setState(() {
                                _selectedUserId = user.id;
                                _loadMessages();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Chat Area (Expands for mobile)
              Expanded(
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.blue[700],
                      child: Text(
                        _selectedUserId != null
                            ? _users.firstWhere((user) => user.id == _selectedUserId, orElse: () => AppUser(id: '', name: 'Unknown', email: '', role: '')).name ?? 'Unknown'
                            : 'Select a Contact',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    // Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isSentByMe = message.senderId == senderId;
                          final senderName = _users.firstWhere(
                                (user) => user.id == message.senderId,
                            orElse: () => AppUser(id: '', name: 'Unknown', email: '', role: ''),
                          ).name ?? 'Unknown';
                          return Align(
                            alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                              decoration: BoxDecoration(
                                color: isSentByMe ? Colors.blue[700] : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.message,
                                    style: TextStyle(
                                      color: isSentByMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      color: isSentByMe ? Colors.white70 : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${message.createdAt.hour}:${message.createdAt.minute}',
                                    style: TextStyle(
                                      color: isSentByMe ? Colors.white70 : Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Message Input
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: Colors.blue[700], size: 24),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}