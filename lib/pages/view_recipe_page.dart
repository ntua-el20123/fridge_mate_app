import 'package:flutter/material.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/profile_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';

class ViewRecipePage extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final List<String> availableIngredients;

  const ViewRecipePage({
    Key? key,
    required this.recipe,
    required this.availableIngredients,
  }) : super(key: key);

  @override
  State<ViewRecipePage> createState() => _ViewRecipePageState();
}

class _ViewRecipePageState extends State<ViewRecipePage> {
  int _selectedIndex = 2; // Index for the bottom navigation bar
  late List<String> _ingredientNames;
  late List<bool> _checkedState;

  /// Handles navigation based on the selected bottom navigation item
  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    Widget nextPage;

    switch (index) {
      case 0: // Home
        nextPage = const HomePage(userId: 1); // Replace with the actual userId
        break;
      case 1: // Scan
        nextPage = const ScanPage();
        break;
      case 2: // Recipes
        nextPage = const RecipePage(userId: 1); // Replace with the actual userId
        break;
      case 3: // Recipes
        nextPage = const ProfilePage(userId: 1); // Replace with the actual userId
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

  @override
  void initState() {
    super.initState();

    // Ensure ingredient names are initialized
    _ingredientNames = (widget.recipe['ingredients'] as List<dynamic>?)
            ?.map((ingredient) => ingredient.toString().replaceAll(RegExp(r'\(expires:.*?\)'), '').trim())
            .toList() ??
        []; // Default to an empty list if null

    // Initialize the checked state based on available ingredients
    _checkedState = _ingredientNames
        .map<bool>((ingredient) => widget.availableIngredients.any(
              (available) => ingredient.toLowerCase().contains(available.toLowerCase()),
            ))
        .toList();
  }


  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.kitchen),
            const SizedBox(width: 10),
            const Text(
              'View Recipe',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Recipe Image Placeholder
            Center(
              child: Container(
                width: 150,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.image,
                  size: 100,
                  color: Colors.black45,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recipe Name
            Text(
              recipe['name'] ?? 'Unknown Recipe',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Ingredients
            const Text(
              "Ingredients:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _ingredientNames.length,
              (index) {
                return ListTile(
                  contentPadding: EdgeInsets.zero, // Remove default padding
                  leading: Checkbox(
                    value: _checkedState[index],
                    onChanged: (newValue) {
                      setState(() {
                        _checkedState[index] = newValue ?? false;
                      });
                    },
                    checkColor: Colors.white,
                    activeColor: Colors.green,
                  ),
                  title: Text(
                    _ingredientNames[index],
                    style: TextStyle(
                      color: _checkedState[index] ? Colors.black : Colors.red,
                      fontSize: 18,
                    ),
                    softWrap: true,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Instructions
            const Text(
              "Instructions:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...List.generate(
              recipe['instructions'] is List ? recipe['instructions'].length : 1,
              (index) {
                final instruction = recipe['instructions'] is List
                    ? recipe['instructions'][index]
                    : recipe['instructions'];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    instruction,
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
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
}
