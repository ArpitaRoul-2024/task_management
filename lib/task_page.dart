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

class _TaskPageState extends State<TaskPage> {
  List<Task> _assignedToMe = [];
  List<Task> _assignedByMe = [];
  List<AppUser> _users = [];
  bool isLoading = true;
  @override
  void initState() {
    // TODO: implement initState
     super.initState();
     fetchData();
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
  Widget _buildTaskList(List<Task> tasks, String emptyMessage, bool canReassign) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93), fontFamily: 'Roboto'),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.priority_high, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Priority: ${task.priority ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Status: ${task.status ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Due Date: ${task.dueDate?.toString().split(' ')[0] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Created by: ${task.createdBy?.email ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF8E8E93)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Assigned to: ${task.assignedTo?.email ?? 'N/A'}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (task.attachments.isNotEmpty)
                  ...task.attachments.map((a) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16, color: Color(0xFF007AFF)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Attachment: ${a.fileName}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF007AFF)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        backgroundColor: const Color(0xFF007AFF),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Assigned to Me',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildTaskList(_assignedToMe, 'No tasks assigned to you', false),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Assigned by Me',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildTaskList(_assignedByMe, 'No tasks assigned by you', false),
              const SizedBox(height: 80), // To leave space below for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTaskForm,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add),
      ),
    );
  }

  }

