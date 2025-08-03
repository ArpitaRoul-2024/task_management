import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:task_management/task_repo.dart';

import 'auth_cubit.dart';
import 'chat_screen.dart';
import 'entities/task.dart';
import 'home_screen.dart';

class TaskPlannerScreen extends StatefulWidget {
  const TaskPlannerScreen({super.key});

  @override
  _TaskPlannerScreenState createState() => _TaskPlannerScreenState();
}

class _TaskPlannerScreenState extends State<TaskPlannerScreen> {
  DateTime _selectedDay = DateTime.now();
  List<Task> _tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final cubit = context.read<AuthCubit>();
      final userId = cubit.currentUser?.id ?? '';
      final token = cubit.token ?? '';
      final tasks = await context.read<TaskRepo>().fetchTasks(userId, token);
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tasks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Appointment> _buildAppointments() {
    return _tasks.where((task) => task.dueDate != null).map((task) {
      return Appointment(
        startTime: task.dueDate!,
        endTime: task.dueDate!.add(const Duration(hours: 1)),
        subject: task.title,
        notes: task.description,
        color: _getColorForStatus(task.status),
      );
    }).toList();
  }

  Color _getColorForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.greenAccent.shade700;
      case 'in progress':
        return Colors.orange.shade700;
      case 'pending':
        return Colors.redAccent;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == day.year &&
          task.dueDate!.month == day.month &&
          task.dueDate!.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007AFF),
        title: const Text('Task Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // CALENDAR
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SfCalendar(
              view: CalendarView.month,
              dataSource: TaskCalendarDataSource(_buildAppointments()),
              todayHighlightColor: const Color(0xFF007AFF),
              backgroundColor: Colors.white,
              selectionDecoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF007AFF), width: 2),
              ),
              monthViewSettings: const MonthViewSettings(
                showAgenda: false,
                appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
              ),
              onTap: (CalendarTapDetails details) {
                if (details.date != null) {
                  setState(() {
                    _selectedDay = details.date!;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 10),

          // TASK LIST
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
              ),
              child: _getTasksForDay(_selectedDay).isEmpty
                  ? Center(
                child: Text(
                  'No tasks on this day',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
                  : ListView.builder(
                itemCount: _getTasksForDay(_selectedDay).length,
                itemBuilder: (context, index) {
                  final task = _getTasksForDay(_selectedDay)[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(task.description ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            task.status ?? 'N/A',
                            style: TextStyle(
                              color: _getColorForStatus(task.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getColorForStatus(task.status).withOpacity(0.8),
                        child: const Icon(Icons.task_alt, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
     );
  }
}

class TaskCalendarDataSource extends CalendarDataSource {
  TaskCalendarDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}
