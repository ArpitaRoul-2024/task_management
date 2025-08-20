import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/features/task_Sync/data/repositaries/task_repo.dart';
import 'package:task_management/features/task_Sync/presentation/cubit/auth_cubit.dart';
import 'package:task_management/features/task_Sync/data/models/user_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/colors.dart';
import '../widgets/bottom_navigation.dart';
import '../../data/models/message.dart' as model; // Import the shared Message class

class ChatScreen extends StatefulWidget {
  final String? initialUserId;
  const ChatScreen({super.key, this.initialUserId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TaskRepo _taskRepo = TaskRepo();
  final TextEditingController _messageController = TextEditingController();
  String? _selectedUserId;
  List<AppUser> _users = [];
  List<model.Message> _messages = []; // Use model.Message
  final ScrollController _scrollController = ScrollController();
  final String _initialUserId = 'b307a592-7db7-491d-a887-96573698d3e6';
  late IO.Socket _socket;
  bool _isLoading = false;
  bool _isFullScreenChat = false;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeSocket();
    _selectedUserId = widget.initialUserId ?? _initialUserId;
    _loadUsers();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && mounted) {
          setState(() {
            _selectedUserId = response.payload;
            _isFullScreenChat = true;
            _loadMessages();
            _markMessagesAsRead();
          });
        }
      },
    );

    _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _showNotification(String senderName, String message, String senderId) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'New Message from $senderName',
      message,
      notificationDetails,
      payload: senderId,
    );
  }

  void _initializeSocket() {
    try {
      _socket = IO.io(
        'https://task-management-9gaz.onrender.com',
        <String, dynamic>{
          'transports': ['websocket'],
          'autoConnect': false,
        },
      );
      _socket.connect();

      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      _socket.emit('authenticate', token);

      _socket.on('newMessage', (data) {
        if (mounted) {
          try {
            final message = model.Message.fromJson(data as Map<String, dynamic>);
            final cubit = context.read<AuthCubit>();
            final currentUserId = cubit.currentUser?.id;

            if ((message.senderId == currentUserId || message.receiverId == currentUserId) &&
                (message.receiverId == _selectedUserId || message.senderId == _selectedUserId)) {
              setState(() => _messages.add(message));
              _scrollToBottom();
            } else if (message.receiverId == currentUserId && message.senderId != _selectedUserId) {
              _showNotification(
                message.senderName ?? 'Unknown',
                message.message ?? 'New message',
                message.senderId ?? '',
              );
            }
          } catch (e) {
            print('Error processing newMessage event: $e');
          }
        }
      });

      _socket.on('connect_error', (error) => print('Socket connection error: $error'));
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  Future<void> _loadUsers() async {
    if (_isLoading || _users.isNotEmpty) return;
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      final users = await _taskRepo.fetchUsers(token);
      if (mounted) {
        setState(() {
          _users = users;
          if (_selectedUserId == null) {
            _selectedUserId = _users.isNotEmpty && _users.any((user) => user.id == _initialUserId)
                ? _initialUserId
                : _users.isNotEmpty
                ? _users.first.id
                : null;
          }
          if (_selectedUserId != null) {
            _loadMessages();
            _markMessagesAsRead();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error in _loadUsers: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_selectedUserId == null) return;
    try {
      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      final currentUserId = cubit.currentUser?.id ?? '';
      await _taskRepo.markMessagesAsRead(currentUserId, _selectedUserId!, token);
    } catch (e) {
      print('Error marking messages as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking messages as read: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_isLoading || _selectedUserId == null) return;
    setState(() => _isLoading = true);
    try {
      final cubit = context.read<AuthCubit>();
      final senderId = cubit.currentUser?.id ?? '';
      final token = cubit.token ?? '';
      if (_selectedUserId == null || senderId.isEmpty || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid state to load messages.'), backgroundColor: Colors.red),
          );
        }
        return;
      }
      final messages = await _taskRepo.fetchMessages(senderId, _selectedUserId!, token);
      if (mounted) {
        setState(() {
          _messages = messages ?? [];
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      if (_isLoading) return;
      setState(() => _isLoading = true);
      try {
        final cubit = context.read<AuthCubit>();
        final senderId = cubit.currentUser?.id ?? '';
        final token = cubit.token ?? '';
        await _taskRepo.sendMessage(senderId, _selectedUserId!, _messageController.text, token);
        _messageController.clear();
        setState(() {});
        _loadMessages();
      } catch (e) {
        if (mounted) {
          print('Error in _sendMessage: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFullScreenChat() {
    setState(() => _isFullScreenChat = _selectedUserId != null);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final senderId = cubit.currentUser?.id ?? '';
    final currentTime = DateTime.now().toLocal();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Images/chatbg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black12, Colors.black26],
            stops: [0.0, 0.8],
          ),
        ),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator().animate().rotate(duration: 1000.ms),
        )
            : AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: _isFullScreenChat
              ? _buildFullScreenChat(context, cubit, senderId, currentTime)
              : _buildSplitScreen(context, cubit, senderId, currentTime),
        ),
      ),
    );
  }

  Widget _buildSplitScreen(BuildContext context, AuthCubit cubit, String senderId, DateTime currentTime) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.05)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Contacts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.appblue,
                          shadows: [
                            Shadow(color: Colors.black38, offset: const Offset(1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const BottomNavigationWidget()),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final initials = user.name?.isNotEmpty == true
                          ? user.name!.substring(0, 1).toUpperCase()
                          : 'U';
                      return Card(
                        color: Colors.white.withOpacity(0.2),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.appblue,
                            child: Text(
                              initials,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            radius: 22,
                          ),
                          title: Text(
                            user.name ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black38, offset: const Offset(1, 1), blurRadius: 2),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: _selectedUserId == user.id,
                          selectedTileColor: AppColors.appblue!.withOpacity(0.4),
                          onTap: () {
                            setState(() {
                              _selectedUserId = user.id;
                              _loadMessages();
                              _markMessagesAsRead();
                              _toggleFullScreenChat();
                            });
                          },
                        ).animate().fadeIn(duration: 400.ms).scaleXY(end: 1.02),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenChat(BuildContext context, AuthCubit cubit, String senderId, DateTime currentTime) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.appblue!, AppColors.appblue!.withOpacity(0.6)],
            ),
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _isFullScreenChat = false),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    _selectedUserId != null
                        ? _users.firstWhere(
                          (user) => user.id == _selectedUserId,
                      orElse: () => AppUser(id: '', name: 'Unknown', email: '', role: ''),
                    ).name ?? 'Unknown'
                        : 'Select a Contact',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white.withOpacity(0.1), Colors.black12],
              ),
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe = (message.senderId ?? '') == senderId;
                final senderName = message.senderName ??
                    _users.firstWhere(
                          (user) => (user.id ?? '') == (message.senderId ?? ''),
                      orElse: () => AppUser(id: '', name: 'Unknown', email: '', role: ''),
                    ).name ??
                    'Unknown';
                return Align(
                  alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isSentByMe
                        ? AppColors.appblue!.withOpacity(0.8)
                        : Colors.grey[200]!.withOpacity(0.9),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                      child: Column(
                        crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message ?? 'No message',
                            style: TextStyle(
                              color: isSentByMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                            maxLines: 10,
                            overflow: TextOverflow.ellipsis,
                          ).animate().fadeIn(duration: 600.ms).slideY(),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                senderName,
                                style: TextStyle(
                                  color: isSentByMe ? Colors.white70 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(message.createdAt ?? currentTime).hour.toString().padLeft(2, '0')}:${(message.createdAt ?? currentTime).minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  color: isSentByMe ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: AppColors.appblue!.withOpacity(0.6), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.appblue!, AppColors.appblue!.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 24),
                    onPressed: _sendMessage,
                  ),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.grey[600]!, Colors.grey[800]!],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white, size: 24),
                  onPressed: () {
                    // TODO: Implement voice input
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}