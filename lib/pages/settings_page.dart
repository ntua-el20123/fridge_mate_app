import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';

class SettingsPage extends StatefulWidget {
  final int userId;

  const SettingsPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  int _recipeCount = 6; // Default value for recipes
  bool _isLoading = true;
  late User _user;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch the user data from the database
  Future<void> _fetchUserData() async {
    final dbHelper = Db.instance;
    final user = await dbHelper.getUserById(widget.userId);

    if (user != null) {
      setState(() {
        _user = user;
        _usernameController.text = user.username;
        _emailController.text = user.email;
        _dobController.text = user.dateOfBirth.toLocal().toString().split(' ')[0];
        _recipeCount = user.recipeCount; // Fetch the recipe count from the database
        _isLoading = false;
      });
    }
  }

  /// Save changes to the database
  Future<void> _saveSettings() async {
    final dbHelper = Db.instance;

    final updatedUser = User(
      id: _user.id,
      username: _usernameController.text.trim(),
      password: _user.password, // Keep the password unchanged
      email: _emailController.text.trim(),
      dateOfBirth: DateTime.parse(_dobController.text.trim()),
      recipeCount: _recipeCount, // Pass the updated recipe count
    );

    await dbHelper.updateUser(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings updated successfully!')),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Edit Personal Information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dobController,
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'AI Settings',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Number of recipes to generate:',
                        style: TextStyle(fontSize: 16),
                      ),
                      DropdownButton<int>(
                        value: _recipeCount,
                        items: List.generate(10, (index) => index + 1)
                            .map((count) => DropdownMenuItem(
                                  value: count,
                                  child: Text('$count'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _recipeCount = value; // Update the recipe count locally
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
