import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';

class ModifyItemPage extends StatefulWidget {
  final int userId;
  final Item? item;

  /// [item] is optional; if provided, we're editing an existing item.
  /// [userId] is required to link the item to a user.
  const ModifyItemPage({
    super.key,
    required this.userId,
    this.item,
  });

  @override
  State<ModifyItemPage> createState() => _ModifyItemPageState();
}

class _ModifyItemPageState extends State<ModifyItemPage> {
  // Text controllers for user input
  final _descriptionController = TextEditingController();
  final _expirationController = TextEditingController();
  final _categoryController = TextEditingController();

  final db = Db.instance;

  @override
  void initState() {
    super.initState();

    // If an existing item was passed, fill controllers with its data
    if (widget.item != null) {
      _descriptionController.text = widget.item!.itemName;
      _expirationController.text = widget.item!.expiryDate;
      _categoryController.text = widget.item!.category;
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _descriptionController.dispose();
    _expirationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  /// Inserts a new item if none exists, otherwise updates the existing item.
  Future<void> _onDone() async {
    final description = _descriptionController.text.trim();
    final expiration = _expirationController.text.trim();
    final category = _categoryController.text.trim();

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description cannot be empty.')),
      );
      return;
    }

    if (widget.item == null) {
      // Insert a new item
      final newItem = Item(
        userId: widget.userId, // link to the user's ID
        itemName: description,
        expiryDate: expiration,
        category: category,
      );
      await db.insertItem(newItem);
    } else {
      // Update the existing item
      final updatedItem = Item(
        id: widget.item!.id, // preserve the existing item's ID
        userId: widget.userId, // link to the user's ID
        itemName: description,
        expiryDate: expiration,
        category: category,
      );
      await db.updateItem(updatedItem);
    }

    // Once done, pop with a 'true' result so the caller can refresh
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null; // Are we editing an existing item?

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image placeholder
            Container(
              width: 150,
              height: 150,
              color: Colors.grey[300],
              // In a real app, you might show an image here
            ),
            const SizedBox(height: 20),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Expiration Date field
            TextField(
              controller: _expirationController,
              decoration: InputDecoration(
                labelText: 'Expiration Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category field
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const Spacer(),

            // Done button
            ElevatedButton(
              onPressed: _onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 30,
                ),
              ),
              child: Text(
                isEditing ? 'Update' : 'Done',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
