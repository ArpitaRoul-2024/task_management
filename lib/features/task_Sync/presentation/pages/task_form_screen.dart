import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

 import '../../../../core/constants/colors.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/task.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;
  final Future<String?> Function(Task task) onSave;
  final Future<void> Function(Task task) onUpdate;
  final Future<void> Function(String taskId, String fileUrl, String fileName) addAttachment;
  final List<AppUser> users;

  const TaskFormScreen({
    super.key,
    this.task,
    required this.onSave,
    required this.onUpdate,
    required this.addAttachment,
    required this.users,
  });

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  String? _priority;
  String? _status;
  String? _assignedToId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority;
    _status = widget.task?.status;
    _assignedToId = widget.task?.assignedTo?.id != null && widget.users.any((u) => u.id == widget.task!.assignedTo!.id)
        ? widget.task!.assignedTo!.id
        : null;
    print('Users: ${widget.users.map((u) => u.id).toList()}');
    print('Initial _assignedToId: $_assignedToId');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Text(
                      widget.task == null ? 'Add Task' : 'Edit Task',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // Priority Dropdown
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: const Icon(Icons.flag),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['Low', 'Medium', 'High'].map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _priority = value),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.check_circle_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: ['To Do', 'In Progress', 'Done'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _status = value),
                  ),
                  const SizedBox(height: 16),

                  // Due Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _dueDate == null ? 'Select Due Date' : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: _dueDate == null ? theme.hintColor : null),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(primary: theme.colorScheme.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) setState(() => _dueDate = date);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Assign To Dropdown
                  if (widget.users.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: _assignedToId,
                      decoration: InputDecoration(
                        labelText: 'Assign to',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: widget.users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user.id,
                          child: Text(user.name ?? 'Unassigned', style: theme.textTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _assignedToId = value),
                    ),
                  ] else ...[
                    ListTile(
                      title: Text('No users available to assign.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Save/Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final task = Task(
                            id: widget.task?.id ?? '',
                            title: _titleController.text,
                            description: _descriptionController.text,
                            dueDate: _dueDate,
                            priority: _priority,
                            status: _status,
                            createdBy: widget.task?.createdBy,
                            assignedTo: _assignedToId != null && _assignedToId!.isNotEmpty
                                ? AppUser(id: _assignedToId!, email: '', role: 'User', name: (widget.users.firstWhere((u) => u.id == _assignedToId, orElse: () => AppUser(id: '', email: '', role: '', name: 'Unassigned')).name ?? 'Unassigned'))
                                : null,
                            attachments: widget.task?.attachments ?? [],
                          );

                          try {
                            if (widget.task == null) {
                              final taskId = await widget.onSave(task);
                              if (taskId != null && context.mounted) {
                                Navigator.pop(context);
                              }
                            } else {
                              await widget.onUpdate(task);
                              if (context.mounted) Navigator.pop(context);
                            }
                          } catch (e) {
                            print('Error saving task: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to save task: $e')),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appblue,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(widget.task == null ? 'Save' : 'Update', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}