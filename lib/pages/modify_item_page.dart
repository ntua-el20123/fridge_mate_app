import 'dart:convert';
import 'dart:typed_data'; 
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/pages/profile_page.dart';

class ModifyItemPage extends StatefulWidget {
  final int userId;
  final Item? item;

  const ModifyItemPage({
    super.key,
    required this.userId,
    this.item,
  });

  @override
  State<ModifyItemPage> createState() => _ModifyItemPageState();
}

class _ModifyItemPageState extends State<ModifyItemPage> {
  final _descriptionController = TextEditingController();
  final _expirationController = TextEditingController();
  final _categoryController = TextEditingController();
  final db = Db.instance;

  File? _imageFile;
  Uint8List? _imageBytes; // Add this field to store the decoded image bytes
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;
  bool isEditing =
      false; // Add this flag to determine if the item is being edited

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _populateFields(widget.item!);
    }
    _checkIfItemExists();
  }

  Future<void> _checkIfItemExists() async {
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      final userItems = await db.getUserItems(widget.userId);
      final existingItem = userItems.firstWhere(
        (item) => item.itemName == description,
        orElse: () => Item(
          userId: widget.userId,
          itemName: '',
          expiryDate: DateTime.now(),
          category: '',
        ),
      );
      if (existingItem.itemName.isNotEmpty) {
        setState(() {
          _populateFields(existingItem);
          isEditing = true;
        });
      } else {
        setState(() {
          isEditing = false;
        });
      }
    }
  }

  void _populateFields(Item item) {
    _descriptionController.text = item.itemName;
    _expirationController.text =
        item.expiryDate.toLocal().toString().split(' ')[0];
    _categoryController.text = item.category;
    if (item.image != null && item.image!.isNotEmpty) {
      _imageBytes = base64Decode(item.image!); // Decode the base64 string
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _expirationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

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

    String? itemImagePath;
    if (_imageFile != null) {
      itemImagePath = base64Encode(await _imageFile!.readAsBytes());
    } else if (_imageBytes != null) {
      itemImagePath = base64Encode(_imageBytes!);
    }

    if (isEditing) {
      final updatedItem = Item(
        id: widget.item?.id,
        userId: widget.userId,
        itemName: description,
        expiryDate: DateTime.parse(expiration),
        category: category,
        image: itemImagePath,
      );
      await db.updateItem(updatedItem);
    } else {
      final newItem = Item(
        userId: widget.userId,
        itemName: description,
        expiryDate: DateTime.parse(expiration),
        category: category,
        image: itemImagePath,
      );
      await db.insertItem(newItem);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(userId: widget.userId)),
    );
  }

  void _onCancel() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(userId: widget.userId)),
    );
  }

  /// Handles bottom navigation
  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    Widget nextPage;

    switch (index) {
      case 0: // Home
        nextPage = HomePage(userId: widget.userId);
        break;
      case 1: // Scan
        nextPage = ScanPage(userId: widget.userId);
        break;
      case 2: // Recipes
        nextPage = RecipePage(userId: widget.userId);
        break;
      case 3: // Profile
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
              'FridgeMate',
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
                image: _imageFile != null
                    ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      )
                    : _imageBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_imageBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: _imageFile == null && _imageBytes == null
                  ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _expirationController,
              decoration: InputDecoration(
                labelText: 'Expiration Date',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _onDone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                  ),
                  child: Text(
                    isEditing ? 'Update' : 'Done',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 30),
                  ),
                  child: Text(
                    'Cancel',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.food_bank), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
