import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/colors.dart';
import 'activity_manager.dart';
import '../cubit/auth_cubit.dart';

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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchContacts();
  }

  Future<void> _requestPermissionAndFetchContacts() async {
    var status = await Permission.contacts.status;
    print('Contact permission status: $status');
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      print('Requested permission status: $status');
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact permission denied')),
          );
        }
        return;
      }
    }
    _fetchContactsFromPhone();
  }

  Future<void> _fetchContactsFromPhone() async {
    setState(() => isLoading = true);
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withThumbnail: false,
        );
        if (mounted) {
          setState(() {
            _contacts.clear();
            _contacts.addAll(contacts.map((contact) => Contact(
              const Uuid().v4(),
              contact.displayName ?? 'Unknown',
              contact.phones.isNotEmpty ? contact.phones.first.number ?? '' : '',
            )).where((contact) => contact.phoneNumber.isNotEmpty));
          });
        }
        await _syncContactsWithSupabase();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied by system')),
          );
        }
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

  Future<void> _syncContactsWithSupabase() async {
    final cubit = context.read<AuthCubit>();
    final userId = cubit.currentUser?.id ?? '';
    if (userId.isEmpty) return;

    try {
      final existingContacts = await _supabase
          .from('contacts')
          .select('id, name, phone_no')
          .eq('id', userId);

      for (var contact in _contacts) {
        final exists = existingContacts.any((c) => c['phone_no'] == contact.phoneNumber);
        if (!exists) {
          await _supabase.from('contacts').insert({
            'id': userId,
            'name': contact.name,
            'phone_no': contact.phoneNumber,
          });
        }
      }
      // Log the sync activity
      await ActivityManager.logActivity('Synced ${_contacts.length} contacts with Supabase');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing contacts: $e')),
        );
      }
    }
  }

  Future<void> _inviteContact(String phoneNumber) async {
    const inviteMessage = 'Join me on TaskSync! Download here: https://example.com/tasksync'; // Replace with actual app link
    final url = 'sms:$phoneNumber?body=$inviteMessage';
    try {
      if (await canLaunch(url)) {
        await launch(url);
        // Log the invite activity
        final cubit = context.read<AuthCubit>();
        final userEmail = cubit.currentUser?.email ?? 'Unknown User';
        await ActivityManager.logActivity('Invite sent to $phoneNumber by $userEmail');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite sent!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not send invite')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending invite: $e')),
        );
      }
    }
  }

  void _startChat(String phoneNumber) {
    print('Starting chat with $phoneNumber');
    // Implement chat logic (e.g., open a chat screen)
  }

  Future<void> _makeCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch call')),
        );
      }
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
          ? const Center(child: Text('No contacts found.', style: TextStyle(color: Color(0xFF8E8E93))))
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
                    icon:   Icon(Icons.chat, color:AppColors.appblue),
                    onPressed: () => _startChat(contact.phoneNumber),
                  ),
                  IconButton(
                    icon:   Icon(Icons.call, color: AppColors.appblue),
                    onPressed: () => _makeCall(contact.phoneNumber),
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: AppColors.appblue),
                    onPressed: () => _inviteContact(contact.phoneNumber),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}