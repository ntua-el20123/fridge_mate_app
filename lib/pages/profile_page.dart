import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/main.dart'; // Import the main script to access LoginScreen

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  late User _user;
  late List<Item> _expiredItems = [];
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchExpiredItems();
  }

  /// Fetch user data
  Future<void> _fetchUserData() async {
    final dbHelper = Db.instance;
    final users = await dbHelper.getUsers();
    if (users.isNotEmpty) {
      setState(() {
        _user = users.firstWhere((u) => u.id == widget.userId);
        _isLoading = false;
      });
    }
  }

  /// Fetch expired items
  Future<void> _fetchExpiredItems() async {
    final dbHelper = Db.instance;
    final allItems = await dbHelper.getUserItems(widget.userId);

    final now = DateTime.now();
    setState(() {
      _expiredItems =
          allItems.where((item) => item.expiryDate.isBefore(now)).toList();
    });
  }

  /// Bottom navigation handler
  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    Widget nextPage;

    switch (index) {
      case 0:
        nextPage = HomePage(userId: widget.userId);
        break;
      case 1:
        nextPage = ScanPage(userId: widget.userId);
        break;
      case 2:
        nextPage = RecipePage(userId: widget.userId);
        break;
      case 3:
        nextPage = ProfilePage(userId: widget.userId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  /// Logout handler
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => const LoginScreen()), // Redirect to LoginScreen
      (route) => false, // Remove all routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.kitchen),
            SizedBox(width: 10),
            Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Picture Placeholder
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.black45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome Text
                  Center(
                    child: Text(
                      'Welcome ${_user.username}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Settings Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Settings Page Coming Soon!')),
                        );
                      },
                      icon: const Icon(
                        Icons.settings,
                        size: 28,
                      ),
                      label: const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                        size: 28,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications Section
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Notifications List (Scrollable)
                  Expanded(
                    child: ListView(
                      children: [
                        if (_expiredItems.isNotEmpty)
                          ..._expiredItems.map((item) {
                            return _buildNotificationCard(
                              'Item "${item.itemName}" has expired!',
                              () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(
                                      userId: widget.userId,
                                      sortType: 'expiration',
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList()
                        else
                          _buildNotificationCard(
                            'No expired items at the moment.',
                            null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String message, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
