import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:task_management/task_repo.dart';

import 'auth_cubit.dart';
import 'auth_repo.dart';
import 'auth_state.dart';
import 'home_screen.dart';
import 'login_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ygwvugengpvtjvohtbjr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NDgxOTksImV4cCI6MjA2NzAyNDE5OX0.4g_talCOg-mxC47QT20Z-4wfRicnpb38wBNC6QX3CYM',
  );
  runApp(const TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepo()),
        RepositoryProvider(create: (context) => TaskRepo()),
      ],
      child: BlocProvider(
        create: (context) => AuthCubit(context.read<AuthRepo>())..checkAuth(),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Planner',
          theme: ThemeData(
            useMaterial3: false,
            primaryColor: const Color(0xFF007AFF),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF007AFF),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontFamily: 'Roboto', color: Colors.black87),
              titleLarge: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold, fontSize: 20),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF007AFF),
              foregroundColor: Colors.white,
            ),
          ),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
                );
              } else if (state is Authenticated) {
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
        ),
      ),
    );
  }
}