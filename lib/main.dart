import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:task_management/features/task_Sync/data/repositaries/task_repo.dart';
 import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/colors.dart';
import 'features/task_Sync/presentation/cubit/auth_cubit.dart';
import 'features/task_Sync/data/repositaries/auth_repo.dart';
import 'features/task_Sync/presentation/cubit/auth_state.dart';
import 'features/task_Sync/presentation/widgets/bottom_navigation.dart';
import 'features/task_Sync/presentation/pages/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ygwvugengpvtjvohtbjr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlnd3Z1Z2VuZ3B2dGp2b2h0YmpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE0NDgxOTksImV4cCI6MjA2NzAyNDE5OX0.4g_talCOg-mxC47QT20Z-4wfRicnpb38wBNC6QX3CYM',
  );

  // Request contacts permission on mobile platforms
  PermissionStatus contactsPermissionStatus = PermissionStatus.denied;
  if (Platform.isAndroid || Platform.isIOS) {
    contactsPermissionStatus = await Permission.contacts.request();
    if (contactsPermissionStatus.isDenied || contactsPermissionStatus.isPermanentlyDenied) {
      // Handle denied permission (e.g., show a dialog or log)
      print('Contacts permission denied : $contactsPermissionStatus');
    }
  }

  runApp(TaskApp(contactsPermissionStatus: contactsPermissionStatus));
}

class TaskApp extends StatefulWidget {
  final PermissionStatus contactsPermissionStatus;

  const TaskApp({super.key, required this.contactsPermissionStatus});

  @override
  _TaskAppState createState() => _TaskAppState();
}

class _TaskAppState extends State<TaskApp> {
  bool _isInitialLoading = true;
  AuthCubit? _authCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(AuthRepo());
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authCubit!.checkAuth();
    setState(() {
      _isInitialLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
        ),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepo()),
        RepositoryProvider(create: (context) => TaskRepo()),
      ],
      child: BlocProvider.value(
        value: _authCubit!,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Planner',
          theme: ThemeData(
            useMaterial3: false,
            primaryColor:  AppColors.appblue,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme:   AppBarTheme(
              backgroundColor: AppColors.appblue,
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
                backgroundColor: AppColors.appblue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor:AppColors.appblue,
              foregroundColor: Colors.white,
            ),
          ),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is AuthLoading) {
                return Scaffold(
                  body: Center(  child: Image.asset(
                  'assets/Images/loading.gif'        ,            width: 100,
                    height: 100,
                  ),
                  ),
                );
              } else if (state is Authenticated) {
                return const BottomNavigationWidget();
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
