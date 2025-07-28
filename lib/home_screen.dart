import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:task_management/assets.dart';
import 'package:task_management/task_form_screen.dart';
import 'package:task_management/task_page.dart';
import 'package:task_management/task_planner_screen.dart';
import 'package:task_management/task_repo.dart';
import 'directory_page.dart';
import 'login_screen.dart';

import 'auth_cubit.dart';
import 'chat_screen.dart';
import 'entities/task.dart';
import 'model/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false; // Initially set to false, update if needed

  @override
  void initState() {
    super.initState();
    // You can load any data if needed
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              final cubit = context.read<AuthCubit>();
              await cubit.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.black),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[700],
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
                      backgroundColor: Colors.tealAccent[100],
                      radius: 25,
                      child: IconButton(
                        onPressed: () { Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TaskPage()),
                        );},
                        icon: const Icon(Icons.fact_check_outlined),
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Quick Tasks', style: TextStyle(fontSize: 15))
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.lightGreenAccent[100],
                      radius: 25,
                      child: IconButton(
                        onPressed: () { Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const  ContactsScreen()),
                        );},
                        icon: const Icon(Icons.contacts_outlined),
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Directory', style: TextStyle(fontSize: 15))
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      radius: 25,
                      child: IconButton(
                        onPressed: () { Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const  TaskPlannerScreen()),
                        );},
                        icon: const Icon(Icons.calendar_month_outlined),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Schedule', style: TextStyle(fontSize: 15))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // You can add more widgets here
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.widgets_outlined), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.location_history_outlined), label: 'Profile'),
        ],
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: const Color(0xFF8E8E93),
        showUnselectedLabels: true,

        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const assetsPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
          }
        },
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
