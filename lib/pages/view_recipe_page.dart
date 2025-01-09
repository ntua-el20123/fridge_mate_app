import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  _RecipePageState createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  List<dynamic> _expiringSoonRecipes = [];
  List<dynamic> _mustTryRecipes = [];
  List<dynamic> _favoriteRecipes = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    const String apiKey = 'YOUR_OPENAI_API_KEY';
    const String endpoint = 'https://api.openai.com/v1/chat/completions';

    List<String> availableItems = [
      "milk",
      "eggs",
      "cheese"
    ]; // Replace with actual fridge items
    String prompt =
        "Based on these ingredients: ${availableItems.join(", ")}, suggest recipes categorized as Expiring Soon, Must Try, and Favorite Recipes.";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4",
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "max_tokens": 300
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final textResponse = data['choices'][0]['message']['content'];

      setState(() {
        // Parse response into categories
        _expiringSoonRecipes = _extractRecipes(textResponse, "Expiring Soon");
        _mustTryRecipes = _extractRecipes(textResponse, "Must Try");
        _favoriteRecipes = _extractRecipes(textResponse, "Favorite Recipes");
      });
    }
  }

  List<dynamic> _extractRecipes(String response, String category) {
    // Implement logic to parse response into structured recipe lists
    return response.contains(category)
        ? response.split(category)[1].split("-").skip(1).toList()
        : [];
  }

  Widget _buildRecipeSection(String title, List<dynamic> recipes) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: recipes.map((recipe) {
        return ListTile(
          title: Text(recipe.toString()),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {},
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("Recipe Suggestions"),
          backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            _buildRecipeSection("Expiring Soon", _expiringSoonRecipes),
            _buildRecipeSection("Must Try", _mustTryRecipes),
            _buildRecipeSection("Favorite Recipes", _favoriteRecipes),
          ],
        ),
      ),
    );
  }
}
