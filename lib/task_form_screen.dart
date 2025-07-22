import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'entities/task.dart';
import 'model/user_model.dart';

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
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.task == null ? 'Add Task' : 'Edit Task',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  hintText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) => setState(() => _priority = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  hintText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['To Do', 'In Progress', 'Done'].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status));
                }).toList(),
                onChanged: (value) => setState(() => _status = value),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: Text(
                  _dueDate == null ? 'Select Due Date' : 'Due: ${_dueDate!.toString().split(' ')[0]}',
                  style: const TextStyle(color: Color(0xFF007AFF)),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.users.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _assignedToId,
                  decoration: const InputDecoration(
                    hintText: 'Assign to',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.users.map((user) {
                    return DropdownMenuItem<String>(
                      value: user.id,
                      child: Text(user.name ?? 'Unassigned'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _assignedToId = value),
                ),
              ] else ...[
                const ListTile(title: Text('No users available to assign.')),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
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
                child: Text(widget.task == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}