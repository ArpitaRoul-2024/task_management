import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_management/task_form_screen.dart';
import 'package:task_management/task_repo.dart';

import 'auth_cubit.dart';
import 'entities/task.dart';
import 'model/user_model.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _assignedToMe = [];
  List<Task> _assignedByMe = [];
  List<AppUser> _users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      final cubit = context.read<AuthCubit>();
      final userId = cubit.currentUser?.id ?? '';
      final token = cubit.token ?? '';
      if (token.isEmpty) throw Exception('No authentication token');

      final tasks = await context.read<TaskRepo>().fetchTasks(userId, token);
      final users = await context.read<TaskRepo>().fetchUsers(token);

      if (mounted) {
        setState(() {
          _assignedToMe = tasks.where((task) => task.assignedTo?.id == userId).toList();
          _assignedByMe = tasks.where((task) => task.createdBy?.id == userId).toList();
          _users = users;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showTaskForm({Task? task}) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskFormScreen(
        task: task,
        onSave: (task) async {
          final token = context.read<AuthCubit>().token ?? '';
          final taskId = await context.read<TaskRepo>().addTask(task, token);
          if (taskId != null) await fetchData();
          return taskId;
        },
        onUpdate: (task) async {
          final token = context.read<AuthCubit>().token ?? '';
          await context.read<TaskRepo>().updateTask(task, token);
          await fetchData();
        },
        addAttachment: (taskId, fileUrl, fileName) async {
          final token = context.read<AuthCubit>().token ?? '';
          await context.read<TaskRepo>().addAttachment(taskId, fileUrl, fileName, token);
          await fetchData();
        },
        users: _users,
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, String emptyMessage) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF8E8E93),
            fontFamily: 'Roboto',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                task.title,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        task.description!,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildInfoRow(Icons.priority_high, 'Priority: ${task.priority ?? 'N/A'}'),
                  _buildInfoRow(Icons.check_circle, 'Status: ${task.status ?? 'N/A'}'),
                  _buildInfoRow(Icons.calendar_today, 'Due Date: ${task.dueDate?.toString().split(' ')[0] ?? 'N/A'}'),
                  _buildInfoRow(Icons.person, 'Created by: ${task.createdBy?.email ?? 'N/A'}'),
                  _buildInfoRow(Icons.person_outline, 'Assigned to: ${task.assignedTo?.email ?? 'N/A'}'),
                  if (task.attachments.isNotEmpty)
                    ...task.attachments.map((a) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildInfoRow(Icons.attach_file, 'Attachment: ${a.fileName}',
                          color: const Color(0xFF007AFF)),
                    )),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF007AFF)),
                    onPressed: () => _showTaskForm(task: task),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final token = context.read<AuthCubit>().token ?? '';
                      try {
                        await context.read<TaskRepo>().deleteTask(task.id, token);
                        await fetchData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task deleted successfully'),
                              backgroundColor: Color(0xFF007AFF),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting task: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color color = const Color(0xFF8E8E93)}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Task Management',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF34C759)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Assigned to Me'),
            Tab(text: 'Assigned by Me'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
                : TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildTaskList(_assignedToMe, 'No tasks assigned to you'),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: fetchData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: _buildTaskList(_assignedByMe, 'No tasks assigned by you'),
                  ),
                ),
              ],
            ),
          ),
          // Add Task Button at the bottom
          Padding(
            padding: const EdgeInsets. only(bottom: 50.0),
            child: SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _showTaskForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Add Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}