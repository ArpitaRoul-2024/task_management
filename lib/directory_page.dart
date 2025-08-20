import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'auth_cubit.dart';

class Contact {
  final String id;
  final String name;
  final String phoneNumber;

  Contact(this.id, this.name, this.phoneNumber);
}

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<Contact> _contacts = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => isLoading = true);
    try {
      final cubit = context.read<AuthCubit>();
      final userId = cubit.currentUser?.id ?? '';
      final response = await _supabase
          .from('contacts')
          .select('id, name, phone_no')
          .eq('id', userId); // Match the user ID as the foreign key
      if (mounted) {
        setState(() {
          _contacts.clear();
          _contacts.addAll(response.map((json) => Contact(
            json['id'] as String,
            json['name'] as String,
            json['phone_no']?.toString() ?? '',
          )));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching contacts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _addContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final cubit = context.read<AuthCubit>();
        final userId = cubit.currentUser?.id ?? '';
        // Debug: Log the token being used
         final response = await _supabase.from('contacts').insert({
          'id': userId, // Foreign key to users.id
          'name': _nameController.text,
          'phone_no': _phoneController.text,
        }).maybeSingle(); // Use maybeSingle for single insert
        if (response != null) {
          await _fetchContacts(); // Refresh the contact list
          Navigator.pop(context); // Close the bottom sheet
        } else {
          throw Exception('No response from insert');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding contact: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  void _showAddContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Contact',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading ? null : _addContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Add', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _startChat(String phoneNumber) {
    print('Starting chat with $phoneNumber');
  }

  void _makeCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch call')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
          ? const Center(child: Text('No contacts added yet.', style: TextStyle(color: Color(0xFF8E8E93))))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        itemBuilder: (context, index) {
          final contact = _contacts[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person, color: Colors.white)),
              title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(contact.phoneNumber),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF007AFF)),
                    onPressed: () => _startChat(contact.phoneNumber),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: Color(0xFF007AFF)),
                    onPressed: () => _makeCall(contact.phoneNumber),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : _showAddContactSheet,
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add),
      ),
    );
  }
}