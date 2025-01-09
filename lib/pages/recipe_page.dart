import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/db.dart';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

final model = GenerativeModel(
    model: 'gemini-1.5-flash-latest',
    apiKey: "AIzaSyDtxljF3n95aH8VdY5TXOAiwgHShzjBTOo");

class RecipePage extends StatefulWidget {
  final int userId; // User ID passed to fetch items

  const RecipePage({super.key, required this.userId});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<Map<String, dynamic>> _expiringSoonRecipes = [];
  List<Map<String, dynamic>> _favoriteRecipes = [];
  bool _isLoading = true; // Loading state

  // Selected index for bottom navigation
  int _selectedIndex = 2; // Index for the Recipe Page

  @override
  void initState() {
    super.initState();
    _fetchRecipes(); // Fetch expiring soon recipes
    _fetchFavoriteRecipes(); // Fetch user's favorite recipes
  }

  /// Fetches favorite recipes from the database
  Future<void> _fetchFavoriteRecipes() async {
    final dbHelper = Db.instance;
    final favorites = await dbHelper.getFavoriteRecipes(widget.userId);

    setState(() {
      _favoriteRecipes = favorites;
    });
  }

  /// Adds a recipe to favorites
  Future<void> _addToFavorites(Map<String, dynamic> recipe) async {
    final dbHelper = Db.instance;
    await dbHelper.insertFavoriteRecipe(
      widget.userId,
      recipe['name'],
      recipe['ingredients'],
      recipe['instructions'],
    );

    // Refresh the favorite recipes list
    _fetchFavoriteRecipes();
  }

  /// Fetches the user's items from the database
  Future<List<Map<String, String>>> fetchUserItemsWithExpiry(int userId) async {
    final dbHelper = Db.instance;
    final userItems = await dbHelper.getUserItems(userId);

    // Convert fetched items into a list of maps containing name and expiry date
    return userItems
        .map((item) => {
              "name": item.itemName,
              "expiry": item.expiryDate
                  .toString()
                  .split(' ')
                  .first, // Format YYYY-MM-DD
            })
        .toList();
  }

  Future<void> _saveRecipesToFiles(
      dynamic data, List<Map<String, dynamic>> expiringSoon) async {
    // Save Expiring Soon Recipes to a JSON file
    final dataFile = File('prompt_out.json');
    await dataFile.writeAsString(jsonEncode(data));

    final expiringSoonFile = File('expiring_soon_recipes.json');
    await expiringSoonFile.writeAsString(jsonEncode(expiringSoon));
  }

  /// Fetches recipes
  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Fetch fridge items
      final fridgeItems = await fetchUserItemsWithExpiry(widget.userId);

      // Fetch recipes from AI
      String prompt =
          "Based on these ingredients and their expiration dates:\n${fridgeItems.map((item) => "${item['name']} (expires: ${item['expiry']})").join(", ")}, suggest at least 6 recipes. One recipe, does not need to use all ingredients, and also recipes should not be limited to the ingredients available. Recipe names should not include comments or notes and should not be numberedAlways provide the recipes in the following forat: **Name**: this_recipe_name, **Ingredient List**:....., **Instruction List**:....";
      // Create the content input for the model
      final content = [
        Content.multi([TextPart(prompt)])
      ];

      // Call the AI model's generateContent method
      final result = await model.generateContent(content);

      // Check if the result has valid data
      if ((result.text?.isNotEmpty ?? false)) {
        final generatedText = result
            .text!; // Extract the generated text (force unwrap since we checked for null)
        // Extract recipes from AI output
        final expiringSoon = _extractRecipes(generatedText);
        // Load favorite recipes from the database
        final dbHelper = Db.instance;
        final favoriteRecipes =
            await dbHelper.getFavoriteRecipes(widget.userId);

        setState(() {
          _expiringSoonRecipes = expiringSoon;
          _favoriteRecipes = favoriteRecipes; // Ensure proper data loading
          _isLoading = false; // Hide loading indicator
        });
      } else {
        throw Exception('AI model returned an empty response.');
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

  /// Extract recipes from the response
  List<Map<String, dynamic>> _extractRecipes(String response) {
    final List<Map<String, dynamic>> parsedRecipes = [];
    if (!response.contains("**Name**:")) return parsedRecipes;

    // Split the response into recipe blocks based on the "**Name**:" keyword
    final recipeBlocks = response.split("**Name**:").skip(1).toList();

    for (var block in recipeBlocks) {
      // Extract the recipe name
      final nameMatch = RegExp(r'^(.*?)\n').firstMatch(block);
      final recipeName = nameMatch?.group(1)?.trim() ?? 'Unknown Recipe';

      // Extract the ingredient list
      final ingredientMatch =
          RegExp(r'\*\*Ingredient List\*\*: (.*?)\n\n', dotAll: true)
              .firstMatch(block);
      final ingredientList = ingredientMatch?.group(1)?.split(', ') ?? [];

      // Extract the instruction list
      final instructionMatch =
          RegExp(r'\*\*Instruction List\*\*: (.*)', dotAll: true)
              .firstMatch(block);
      final instructions =
          instructionMatch?.group(1)?.trim() ?? 'No instructions provided.';

      // Add the recipe to the parsed list
      parsedRecipes.add({
        'name': recipeName,
        'ingredients': ingredientList,
        'instructions': instructions,
      });
    }

    return parsedRecipes;
  }

  /// Check ingredient availability
  Future<Map<String, dynamic>> _checkIngredientsAvailability(
      Map<String, dynamic> recipe) async {
    // Fetch fridge items (available ingredients) from the database
    final fridgeItems = await fetchUserItemsWithExpiry(widget.userId);

    // Extract the ingredients from the recipe
    final ingredients = recipe['ingredients'] as List<String>? ?? [];

    // Helper function to check if a recipe ingredient is available in the fridge items
    bool isIngredientAvailable(String recipeIngredient) {
      return fridgeItems.any((fridgeItem) {
        final fridgeName = fridgeItem['name']?.toLowerCase() ?? '';
        return recipeIngredient.toLowerCase().contains(fridgeName);
      });
    }

    // Find missing ingredients
    final missingIngredients = ingredients
        .where((ingredient) => !isIngredientAvailable(ingredient))
        .toList();

    return {
      'available':
          missingIngredients.isEmpty, // True if no ingredients are missing
      'missingCount': missingIngredients.length, // Count of missing ingredients
      'missingIngredients': missingIngredients, // List of missing ingredients
    };
  }

  void _addRecipeToFavorites(Map<String, dynamic> recipe) async {
    final dbHelper = Db.instance;

    await dbHelper.insertFavoriteRecipe(
      widget.userId,
      recipe['name'] ?? 'Unknown Recipe',
      List<String>.from(recipe['ingredients'] ?? []),
      recipe['instructions'] ?? 'No instructions provided.',
    );

    // Refresh the favorite recipes list
    final updatedFavorites = await dbHelper.getFavoriteRecipes(widget.userId);
    setState(() {
      _favoriteRecipes = updatedFavorites;
    });
  }

  void _removeRecipeFromFavorites(Map<String, dynamic> recipe) async {
    final dbHelper = Db.instance;

    await dbHelper.deleteFavoriteRecipeByName(
        widget.userId, recipe['name'] ?? '');

    // Refresh the favorite recipes list
    final updatedFavorites = await dbHelper.getFavoriteRecipes(widget.userId);
    setState(() {
      _favoriteRecipes = updatedFavorites;
    });
  }

  /// Show recipe details
  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recipe['name'] ?? 'Recipe Details'),
          content: Text(
            'Ingredients:\n${recipe['ingredients']?.join(", ") ?? "No ingredients available."}\n\n'
            'Instructions:\n${recipe['instructions'] ?? "No instructions available."}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Bottom navigation onTap handler
  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return; // Prevents redundant navigation

    setState(() {
      _selectedIndex = index;
    });

    Widget nextPage;

    switch (index) {
      case 0:
        nextPage = HomePage(userId: widget.userId);
        break;
      case 1:
        nextPage = const ScanPage();
        break;
      case 2:
        nextPage = RecipePage(userId: widget.userId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Recipe Suggestions",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage, // Pull-to-refresh action
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            _buildRecipeSection(
              "New Recipes",
              _expiringSoonRecipes,
              isLoading: _isLoading, // Pass loading state
            ),
            _buildRecipeSection(
              "Your Favorite Recipes",
              _favoriteRecipes,
              isFavoriteSection: true,
            ),
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

  /// Pull-to-refresh action
  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });
    await _fetchRecipes(); // Reload recipes
  }

  /// Updated Recipe Section Builder
  Widget _buildRecipeSection(
    String title,
    List<Map<String, dynamic>> recipes, {
    bool isFavoriteSection =
        false, // Optional parameter to distinguish sections
    bool isLoading = false, // Optional parameter for loading state
  }) {
    final expandedStates = <String, bool>{title: true};

    return StatefulBuilder(
      builder: (context, setState) {
        return ExpansionTile(
          initiallyExpanded: expandedStates[title] ?? false,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          onExpansionChanged: (isExpanded) {
            setState(() {
              expandedStates[title] = isExpanded;
            });
          },
          children: isLoading
              ? [
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 20.0), // Larger margin
                    child: const Center(child: CircularProgressIndicator()),
                  )
                ]
              : recipes.map((recipe) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _checkIngredientsAvailability(recipe),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final ingredientsAvailable = snapshot.data!;
                        final isFavorite = _favoriteRecipes.contains(
                            recipe); // Check if the recipe is a favorite
                        final description = ingredientsAvailable['available']
                            ? 'All ingredients available : )'
                            : 'Some ingredients are missing : (';
                        return GestureDetector(
                          onTap: () {
                            _showRecipeDetails(recipe);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.only(right: 10),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['name'] ?? 'Unknown Recipe',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isFavorite) {
                                            _removeRecipeFromFavorites(recipe);
                                          } else {
                                            _addRecipeToFavorites(recipe);
                                          }
                                        });
                                      },
                                    ),
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: ingredientsAvailable['available']
                                            ? Colors.green
                                            : Colors.yellow,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: ingredientsAvailable['available']
                                            ? const Icon(Icons.check,
                                                color: Colors.white)
                                            : Text(
                                                '${ingredientsAvailable['missingCount']}',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const Text('No data available');
                      }
                    },
                  );
                }).toList(),
        );
      },
    );
  }
}
