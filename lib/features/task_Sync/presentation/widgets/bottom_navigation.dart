import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:task_management/core/constants/colors.dart';

import '../pages/assets.dart';
import '../pages/chat_screen.dart';
import '../pages/home_screen.dart';
import '../pages/profile.dart';


class BottomNavigationWidget extends StatefulWidget {
  const BottomNavigationWidget({super.key});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AssetsPage(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.widgets_outlined), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.location_history_outlined), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor:  AppColors.appblue,
        unselectedItemColor: const Color(0xFF8E8E93),
        showUnselectedLabels: true,
        elevation: 8,
      ),
    );
  }
}
