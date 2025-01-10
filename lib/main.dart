import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/register_page.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Ensure Flutter bindings before runApp for async DB operations
void main() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Optionally insert dummy data on app start
  final dbHelper = Db.instance;
  await dbHelper.insertUser(
    User(
        username: 'stelaras',
        password: 'password',
        email: 'mail@example.com',
        dateOfBirth: DateTime.parse('1990-01-01')),
  );

  // Now run the app
  runApp(const FridgeMateApp());
}

class FridgeMateApp extends StatelessWidget {
  const FridgeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FridgeMate',
      theme: _buildThemeData(),
      home: const LoginScreen(),
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      primarySwatch: Colors.green,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Example 'forgot' callback
  void _onForgotCredentialsPressed() {
    // Implement your logic (e.g., show a dialog or navigate)
  }

  // Validate form, then check credentials against DB
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final dbHelper = Db.instance;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    // Try to get user by username
    final user = await dbHelper.getUserByUsername(username);

    if (!mounted) return;

    if (user == null) {
      // User not found in DB
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found.'),
        ),
      );
    } else if (user.password != password) {
      // Wrong password
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid password.'),
        ),
      );
    } else {
      // Login success -> navigate to Home
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HomePage(userId: user.id!)),
      );
    }
  }

  // Registration route
  void _onRegisterPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title text
              const Center(
                child: Text(
                  'Never waste a bite!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: Color.fromARGB(255, 183, 183, 183),
                    shadows: [
                      Shadow(offset: Offset(-1, -1), color: Colors.green),
                      Shadow(offset: Offset(1, -1), color: Colors.green),
                      Shadow(offset: Offset(1, 1), color: Colors.green),
                      Shadow(offset: Offset(-1, 1), color: Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your username';
                  }
                  return null; // Valid
                },
              ),
              const SizedBox(height: 20),
              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null; // Valid
                },
              ),
              const SizedBox(height: 20),
              // Forgot credentials
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Forgot username/password?',
                    style: TextStyle(fontSize: 13),
                  ),
                  TextButton(
                    onPressed: _onForgotCredentialsPressed,
                    child: const Text(
                      'Click here',
                      style: TextStyle(fontSize: 14, color: Colors.purple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Login button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
                ),
                onPressed: _onLoginPressed,
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 100),
              // Registration prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: _onRegisterPressed,
                    child: const Text(
                      'Register!',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
