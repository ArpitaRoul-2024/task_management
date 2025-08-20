import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/auth_cubit.dart';
import 'package:task_management/login_screen.dart';
import 'package:task_management/task_page.dart';
import 'package:task_management/directory_page.dart';
import 'package:task_management/task_planner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;

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

    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
        : SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {

                  },
                ),
              ],
            ),
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TaskPage()),
                          );
                        },
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ContactsScreen()),
                          );
                        },
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TaskPlannerScreen()),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Sch edule', style: TextStyle(fontSize: 15))
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
