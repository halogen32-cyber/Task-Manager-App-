import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'auth_screen.dart';
import 'task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Back4App ---
  // Replace with your own keys
  const String appId = 'vy44kU0Lz1GCqAVy4wcABmaqM7BMDIdwTDXpwWIf';
  const String serverUrl = 'https://parseapi.back4app.com';
  const String clientKey = 'qXCaueL3szdCtq7xxGcYRYC4P3LvnPI2SG6h9cRw';

  await Parse().initialize(
    appId,
    serverUrl,
    clientKey: clientKey,
    autoSendSessionId: true,
    liveQueryUrl: serverUrl, // Use your serverUrl for LiveQuery
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final ParseUser? currentUser = await ParseUser.currentUser();
    if (!mounted) return;

    setState(() {
      _isLoggedIn = currentUser != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // A simple way to navigate based on auth state.
    // We pass a function to AuthScreen to update this wrapper's state on success.
    if (_isLoggedIn) {
      return TaskListScreen(onLogout: () {
        setState(() {
          _isLoggedIn = false;
        });
      });
    } else {
      return AuthScreen(onLoginSuccess: () {
        setState(() {
          _isLoggedIn = true;
        });
      });
    }
  }
}