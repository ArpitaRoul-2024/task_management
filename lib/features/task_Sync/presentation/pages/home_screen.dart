import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/features/task_Sync/presentation/cubit/auth_cubit.dart';
import 'package:task_management/features/task_Sync/presentation/pages/task_page.dart';
import 'package:task_management/features/task_Sync/presentation/pages/directory_page.dart';
import 'package:task_management/features/task_Sync/presentation/pages/task_planner_screen.dart';
import 'package:task_management/features/task_Sync/presentation/pages/chat_screen.dart';
import 'package:task_management/features/task_Sync/data/repositaries/task_repo.dart';
import 'package:task_management/features/task_Sync/data/models/user_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:badges/badges.dart' as badges;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';
import '../../data/models/message.dart' as model; // Import the shared Message class

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  String? selectedMood;
  late IO.Socket _socket;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  int _unreadMessageCount = 0;
  final TaskRepo _taskRepo = TaskRepo();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initializeSocket();
    _loadUnreadMessageCount();
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final cubit = context.read<AuthCubit>();
      final token = cubit.token ?? '';
      final count = await _taskRepo.getUnreadMessageCount(token);
      if (mounted) {
        setState(() {
          _unreadMessageCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread message count: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading unread messages: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(android: androidSettings);
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && mounted) {
          final senderId = response.payload;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(initialUserId: senderId)),
          ).then((_) => _loadUnreadMessageCount());
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

            if (message.receiverId == currentUserId && message.senderId != currentUserId) {
              final senderName = message.senderName ?? 'Unknown';
              _showNotification(senderName, message.message ?? 'New message', message.senderId ?? '');
              setState(() {
                _unreadMessageCount++;
              });
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

  @override
  void dispose() {
    if (_socket.connected) _socket.disconnect();
    super.dispose();
  }

  Future<void> _sendReferralInvite() async {
    final authCubit = context.read<AuthCubit>();
    final userName = authCubit.currentUser?.name ?? 'User';
    final inviteMessage = 'Hey! Join me on TaskSync with my referral. Download here: https://example.com/tasksync?ref=$userName';
    final url = 'sms:?body=$inviteMessage';
    if (await canLaunch(url)) {
      await launch(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral invite sent!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send referral invite')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final userName = authCubit.currentUser?.name ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    final now = DateTime.now();
    final hour = now.hour;

    String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: badges.Badge(
                      badgeContent: Text(
                        _unreadMessageCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      showBadge: _unreadMessageCount > 0,
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                        padding: EdgeInsets.all(6),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.yellow),
                        onPressed: () {
                          setState(() {
                            _unreadMessageCount = 0;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          ).then((_) => _loadUnreadMessageCount());
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.appblue,
                      radius: 40,
                      child: Text(
                        userInitial,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$greeting, $userName! 👋',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.taskbg,
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TaskPage()),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          color: AppColors.taskico,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Quick Tasks', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.dirbg,
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ContactsScreen()),
                            );
                          },
                          icon: const Icon(Icons.contacts_outlined),
                          color: AppColors.directorico,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Directory', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.scedulebg,
                        radius: 25,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TaskPlannerScreen()),
                            );
                          },
                          icon: const Icon(Icons.calendar_month_outlined),
                          color: AppColors.scheduleico,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Schedule', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.appblue!.withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.appblue,
                              radius: 30,
                              child: Image.asset("assets/Images/cat.png"),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Refer to Friends',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Invite friends to TaskSync!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.appblue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _sendReferralInvite,
                          child: const Text(
                            'Invite',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.appblue!.withOpacity(0.1),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What\'s the Mood of Doing Today?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select your mood to personalize your day!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMoodOption('Happy', Icons.sentiment_satisfied, 0),
                            _buildMoodOption('Focused', Icons.lightbulb_outline, 1),
                            _buildMoodOption('Relaxed', Icons.self_improvement, 2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodOption(String mood, IconData icon, int index) {
    final isSelected = selectedMood == mood;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = mood;
        });
      },
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isSelected ? AppColors.appblue : AppColors.appblue!.withOpacity(0.1),
            radius: 25,
            child: Icon(
              icon,
              size: 24,
              color: isSelected ? Colors.white : AppColors.appblue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mood,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? AppColors.appblue : Colors.black87,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}