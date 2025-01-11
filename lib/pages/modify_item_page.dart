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
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _descriptionController.text = widget.item!.itemName;
      _expirationController.text = widget.item!.expiryDate.toLocal().toString().split(' ')[0];
      _categoryController.text = widget.item!.category;
      if (widget.item!.image != null) {
        _imageFile = File(widget.item!.image!);
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _expirationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
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

    final itemImagePath = _imageFile?.path;

    if (widget.item == null) {
      final newItem = Item(
        userId: widget.userId,
        itemName: description,
        expiryDate: DateTime.parse(expiration),
        category: category,
        image: itemImagePath,
      );
      await db.insertItem(newItem);
    } else {
      final updatedItem = Item(
        id: widget.item!.id,
        userId: widget.userId,
        itemName: description,
        expiryDate: DateTime.parse(expiration),
        category: category,
        image: itemImagePath,
      );
      await db.updateItem(updatedItem);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
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
        nextPage = const ScanPage();
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
    final isEditing = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
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
                      : null,
                ),
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _expirationController,
              decoration: InputDecoration(
                labelText: 'Expiration Date',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              ),
              child: Text(
                isEditing ? 'Update' : 'Done',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Recipes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
