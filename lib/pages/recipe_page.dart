import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';
import 'dart:convert';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';

class RecipePage extends StatefulWidget {
  final int userId; // User ID passed to fetch items

  const RecipePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<dynamic> _expiringSoonRecipes = [];
  List<dynamic> _mustTryRecipes = [];
  List<dynamic> _favoriteRecipes = [];
  bool _isLoading = true; // Loading state

  // Selected index for bottom navigation
  int _selectedIndex = 2; // Index for the Recipe Page

  @override
  void initState() {
    super.initState();
    _fetchRecipes(); // Fetch recipes when the page loads
  }

  /// Fetches the user's items from the database
  Future<List<Map<String, String>>> fetchUserItemsWithExpiry(int userId) async {
    final dbHelper = Db.instance;
    final userItems = await dbHelper.getUserItems(userId);

    // Convert fetched items into a list of maps containing name and expiry date
    return userItems.map((item) => {
          "name": item.itemName,
          "expiry": item.expiryDate.toString().split(' ').first // Format YYYY-MM-DD
        }).toList();
  }

  /// Fetches recipes from GPT API
  /// Fetches recipes from Gemini LLM API
Future<void> _fetchRecipes() async {
  setState(() {
    _isLoading = true; // Show loading indicator
  });

  try {
    // Fetch fridge items
    final fridgeItems = await fetchUserItemsWithExpiry(widget.userId);

    if (fridgeItems.isEmpty) {
      setState(() {
        _isLoading = false; // No items to process
      });
      return;
    }

    // Construct prompt with expiration dates
    String prompt = "Based on these ingredients and their expiration dates:\n" +
        fridgeItems
            .map((item) => "${item['name']} (expires: ${item['expiry']})")
            .join(", ") +
        ", suggest recipes categorized as Expiring Soon, Must Try, and Favorite Recipes.";

    // Call Python script
    final result = await Process.run(
      'py', // Path to Python executable
      ['.\\python_scripts\\generate_recipes.py', prompt], // Python script and arguments
    );

    if (result.exitCode == 0) {
      // Parse the Python script's JSON output
      final data = jsonDecode(result.stdout);
      final generatedText = data['text'] ?? '';

      setState(() {
        _expiringSoonRecipes = _extractRecipes(generatedText, "Expiring Soon");
        _mustTryRecipes = _extractRecipes(generatedText, "Must Try");
        _favoriteRecipes = _extractRecipes(generatedText, "Favorite Recipes");
        _isLoading = false; // Hide loading indicator
      });
    } else {
      throw Exception('Python script error: ${result.stderr}');
    }
  } catch (e) {
    setState(() {
      _isLoading = false; // Hide loading indicator
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error fetching recipes: ${e.toString()}")),
    );
  }
}

  /// Extract recipes from GPT response based on category
  List<dynamic> _extractRecipes(String response, String category) {
    // Parse response into structured recipe lists
    if (!response.contains(category)) return [];
    final categorySection = response.split(category)[1].split("-").skip(1);
    return categorySection.map((recipe) => recipe.trim()).toList();
  }

  /// Bottom navigation onTap handler
  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevents redundant navigation

    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected page
    Widget nextPage;

    switch (index) {
      case 0: // Home Page
        nextPage = HomePage(userId: widget.userId); // Pass userId to HomePage
        break;
      case 1: // Scan Page
        nextPage = const ScanPage();
        break;
      case 2: // Recipe Page
        nextPage = RecipePage(userId: widget.userId); // Stay on RecipePage
        break;
      default:
        return;
    }

    // Navigate using pushReplacement
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  //// Builds a section of recipes
Widget _buildRecipeSection(String title, List<dynamic> recipes) {
  return ExpansionTile(
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center, // Centers title horizontally
    ),
    children: recipes.map((recipe) {
      return ListTile(
        title: Text(
          recipe.toString(),
          textAlign: TextAlign.center, // Centers recipe text horizontally
        ),
      );
    }).toList(),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: false, // Removes the back button
    title: const Center(
      child: Text(
        "Recipe Suggestions",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Set text color to white
        ),
      ),
    ),
    backgroundColor: Colors.green,
  ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator()) // Show loading spinner
        : Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: [
                _buildRecipeSection("Expiring Soon", _expiringSoonRecipes),
                _buildRecipeSection("Must Try", _mustTryRecipes),
                _buildRecipeSection("Favorite Recipes", _favoriteRecipes),
              ],
            ),
          ),
    bottomNavigationBar: BottomNavigationBar(
      backgroundColor: Colors.green,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.black,
      showSelectedLabels: false,
      showUnselectedLabels: false,
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