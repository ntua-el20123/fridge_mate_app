import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/register_page.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check the platform and initialize the appropriate database factory
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    // Use the default database factory for mobile platforms
    databaseFactory = databaseFactory;
  }

  // Optionally insert dummy data on app start
  final dbHelper = Db.instance;
  await dbHelper.insertUser(
    User(
      username: 'john_doe',
      password: '123456',
      email: 'mail@example.com',
      dateOfBirth: DateTime.parse('1990-01-01'),
    ),
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

  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;

    final dbHelper = Db.instance;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await dbHelper.getUserByUsername(username);

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found.')),
        );
      } else if (user.password != password) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid password.')),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomePage(userId: user.id!)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred.')),
      );
    }
  }

  void _onRegisterPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
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
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter your username'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your password'
                    : (value.length < 6
                        ? 'Password must be at least 6 characters'
                        : null),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onLoginPressed,
                child:
                    const Text('Login', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onRegisterPressed,
                child: const Text('Register',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
