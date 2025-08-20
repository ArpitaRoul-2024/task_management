import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_management/features/task_Sync/presentation/pages/settings.dart';
import '../../../../core/constants/colors.dart';
import '../widgets/bottom_navigation.dart';
import 'activity.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../data/models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = context.read<AuthCubit>().currentUser?.name ?? 'User';
    final initials = userName.isNotEmpty ? userName.substring(0, 2).toUpperCase() : 'AR';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavigationWidget()),
            );
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.appblue,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileCard(context, userName, initials, isDark),
            const SizedBox(height: 24),
            _sectionTitle('Entries'),
            const SizedBox(height: 12),
            Row(
              children: [
                _entryCard('Shared with me', FontAwesomeIcons.peopleGroup),
                const SizedBox(width: 16),
                _entryCard('My entries history', FontAwesomeIcons.clockRotateLeft),
              ],
            ).animate().slideY(duration: 600.ms).fadeIn(),
            const SizedBox(height: 24),
            _sectionTitle('More'),
            const SizedBox(height: 12),
            ..._buildMoreTiles(context),
            const SizedBox(height: 24),
            _logoutTile(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String userName, String initials, bool isDark) {
    return Hero(
      tag: 'profile-card',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.appblue!.withOpacity(0.8),
                  Colors.white.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
            Expanded(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Task ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appblue,
                      ),
                    ),
                    Text(
                      'Sync',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: NetworkImage(
                  'https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHB6YTFubTg0bDl5dG90aXo2cnQ5YjB1NjRlZHNjdGtwMGVlbXRybCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/xTiTnxpQ3ghPiB2Hp6/giphy.gif',
                ),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: Colors.black.withOpacity(0.5),
                child:  Image.asset("assets/Images/user.png",height: 50,)
            ),
          ),
          )]).animate().scale(duration: 600.ms).fadeIn(),
      ),
    ),
    ),
    );
  }

  Widget _entryCard(String title, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: 400.ms,
          padding: const EdgeInsets.all(16),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.appblue!.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: FaIcon(icon, size: 24, color: AppColors.appblue),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).scaleXY(end: 1.02, curve: Curves.easeOut),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.appblue,
        ),
      ),
    );
  }

  List<Widget> _buildMoreTiles(BuildContext context) {
    return [
      _moreTile('My activity', FontAwesomeIcons.chartSimple, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Activity()),
        );
      }),
      const Divider(color: Colors.grey, thickness: 1),
      _moreTile('Personal information', FontAwesomeIcons.user, () {
        _showPersonalInfoBottomSheet(context);
      }),
      const Divider(color: Colors.grey, thickness: 1),
      _moreTile('Settings', FontAwesomeIcons.gear, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      }),
      const Divider(color: Colors.grey, thickness: 1),
      _moreTile('Support center', FontAwesomeIcons.headset, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support center coming soon!')),
        );
      }),
    ];
  }

  Widget _moreTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.appblue!.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, size: 20, color: AppColors.appblue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scaleXY(end: 1.01, curve: Curves.easeOut),
    );
  }

  Widget _logoutTile(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final authCubit = context.read<AuthCubit>();
            await authCubit.signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.redAccent),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.redAccent),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).scaleXY(end: 1.01, curve: Curves.easeOut),
        );
      },
    );
  }

  void _showPersonalInfoBottomSheet(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.appblue!.withOpacity(0.1), Colors.white],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 16,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.appblue,
                    ),
                  ),
                ),
              ),
              if (user != null) ...[
                ..._buildInfoCards(user),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.appblue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.appblue!),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // TODO: Implement edit functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit feature coming soon!')),
                      );
                    },
                    child: Text(
                      'Edit',
                      style: TextStyle(fontSize: 16, color: AppColors.appblue),
                    ),
                  ),
                ),
              ] else ...[
                const Center(
                  child: Text(
                    'No user data available. Please log in.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildInfoCards(AppUser user) {
    return [
      _buildInfoCard('Name', user.name),
      _buildInfoCard('Email', user.email),
    ];
  }

  Widget _buildInfoCard(String label, String? value) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        subtitle: Text(
          value ?? 'Not available',
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        trailing: const Icon(Icons.edit, color: Colors.grey),
      ),
    );
  }
}