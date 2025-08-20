import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add for animations
import 'package:task_management/features/task_Sync/presentation/pages/task_page.dart';
import 'package:task_management/features/task_Sync/presentation/pages/task_planner_screen.dart';
import '../../../../core/constants/colors.dart';
import '../widgets/bottom_navigation.dart';
import 'chat_screen.dart';
import 'directory_page.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _communicationItems = [
    {
      'name': 'Chat',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.teal,
      'backgroundColor': const Color(0xFFE0F2F1),
    },
    {
      'name': 'Directory',
      'icon': Icons.contacts_outlined,
      'color': AppColors.directorico,
      'backgroundColor': AppColors.dirbg,
    },
  ];

  final List<Map<String, dynamic>> _operationsItems = [
    {
      'name': 'Schedule',
      'icon': Icons.calendar_month_outlined,
      'color': AppColors.scheduleico,
      'backgroundColor': AppColors.scedulebg,
    },
    {
      'name': 'Quick Tasks',
      'icon': Icons.check_circle_outline,
      'color': AppColors.taskico,
      'backgroundColor': AppColors.taskbg,
      'badge': '✔',
    },
  ];

  List<Map<String, dynamic>> _filteredCommunication = [];
  List<Map<String, dynamic>> _filteredOperations = [];

  @override
  void initState() {
    super.initState();
    _filteredCommunication = List.from(_communicationItems);
    _filteredOperations = List.from(_operationsItems);
    _searchController.addListener(_filterItems);
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCommunication = _communicationItems
          .where((item) => item['name'].toString().toLowerCase().contains(query))
          .toList();
      _filteredOperations = _operationsItems
          .where((item) => item['name'].toString().toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = LinearGradient(
                    colors: [AppColors.appblue!, Colors.white],
                  ).createShader(const Rect.fromLTWH(0, 0, 200, 20)),
              ),
            ),
          ),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.appblue!, Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(Map<String, dynamic> item) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          switch (item['name']) {
            case 'Chat':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
              break;
            case 'Directory':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactsScreen()),
              );
              break;
            case 'Schedule':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskPlannerScreen()),
              );
              break;
            case 'Quick Tasks':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskPage()),
              );
              break;
            default:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No screen found')),
              );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item['backgroundColor'],
                item['color'].withOpacity(0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item['backgroundColor'],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item['color'].withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: item['color'].withOpacity(0.5), width: 1),
                ),
                child: Icon(item['icon'], color: item['color'], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              if (item['badge'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.appblue!, Colors.lightBlueAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['badge'],
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(end: 1.02, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.appblue!, Colors.blueAccent],
            ),
          ),
        ),
        elevation: 6,
        title: const Text(
          'Assets',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  BottomNavigationWidget()),
              );
            }
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search, color: AppColors.appblue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _filterItems();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.appblue!.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.appblue!, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_filteredCommunication.isNotEmpty) buildSectionTitle('Communication'),
          ..._filteredCommunication.map(buildItem),
          if (_filteredOperations.isNotEmpty) buildSectionTitle('Operations'),
          ..._filteredOperations.map(buildItem),
        ],
      ),
    );
  }
}