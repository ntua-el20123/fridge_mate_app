import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:fridge_mate_app/pages/modify_item_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';

/// SortButton: Shows a popup menu for different sorting options.
class SortButton extends StatelessWidget {
  final Function(String) onSortOptionSelected;

  const SortButton({
    super.key,
    required this.onSortOptionSelected,
  });

  void _handleSelection(String option) {
    onSortOptionSelected(option);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _handleSelection,
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'alphabetical',
          child: Text('Alphabetically'),
        ),
        const PopupMenuItem(
          value: 'expiration',
          child: Text('Expiration date'),
        ),
        const PopupMenuItem(
          value: 'recently_added',
          child: Text('Recently added'),
        ),
        const PopupMenuItem(
          value: 'category',
          child: Text('Category'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// HomePage: Displays the user’s items and an “Expiring Soon” section.
class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Reference to the singleton database helper.
  final db = Db.instance;

  /// All items owned by the user.
  List<Item> _items = [];

  /// A single item that’s about to expire soon.
  List<Item> _expiringSoon = [];

  /// Currently selected bottom navigation index.
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserItems();
  }

  /// Fetches the user’s items from the database and updates UI.
  Future<void> _fetchUserItems() async {
    final userItems = await db.getUserItems(widget.userId);
    setState(() {
      _items = userItems;
      _expiringSoon = _getExpiringSoonItems(userItems);
    });
  }

/// Returns a list of items expiring within the next 3 days.
List<Item> _getExpiringSoonItems(List<Item> allItems) {
  if (allItems.isEmpty) return [];
  
  final now = DateTime.now();
  final threeDaysFromNow = now.add(const Duration(days: 3));
  
  // Filter items expiring within the next 3 days
  return allItems
      .where((item) => item.expiryDate.isBefore(threeDaysFromNow) && item.expiryDate.isAfter(now))
      .toList();
}

  /// Called when a sort option is selected from SortButton.
  void _onSortOptionSelected(String option) {
    print('Sort option selected: $option'); // Debugging
    setState(() {
      switch (option) {
        case 'alphabetical':
          _items.sort((a, b) => a.itemName.compareTo(b.itemName));
          break;
        case 'expiration':
          _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          break;
        case 'recently_added':
          _items.sort((a, b) => b.id!.compareTo(a.id!)); // Newest first
          break;
        case 'category':
          _items.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
      print(_items); // Debugging: Check the sorted order
      _expiringSoon = _getExpiringSoonItems(_items); // Recompute if necessary
    });
  }


  /// Navigate to ModifyItemPage to add a new item, refresh on success.
  Future<void> _addItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyItemPage(userId: widget.userId),
      ),
    );
    if (result == true) {
      _fetchUserItems();
    }
  }

  /// Navigate to ModifyItemPage to edit an existing item, refresh on success.
  Future<void> _editItem(Item item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyItemPage(userId: widget.userId, item: item),
      ),
    );
    if (result == true) {
      _fetchUserItems();
    }
  }

  /// Delete an item and refresh the list.
  Future<void> _deleteItem(int itemId) async {
    await db.deleteItem(itemId);
    _fetchUserItems();
  }


Widget _buildExpiringSoonSection() {
  final expiringSoonItems = _getExpiringSoonItems(_items); // Fetch items expiring soon
  if (expiringSoonItems.isEmpty) {
    return const SizedBox(); // No items expiring soon
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Center the "Expires Soon" text
      const Center(
        child: Text(
          'Expires Soon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Horizontally scrollable section
      SizedBox(
        height: 100, // Set a fixed height for the scrollable area
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: expiringSoonItems.map((item) {
              return Container(
                width: 200, // Ensure consistent width for each item
                margin: const EdgeInsets.only(right: 8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Display item image
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: item.image != null && item.image!.isNotEmpty
                          ? Image.file(
                              File(item.image!), // Load from file
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error);
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                    const SizedBox(width: 10),

                    // Item details
                    Expanded(
                      child: InkWell(
                        onTap: () => _editItem(item),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis, // Prevent overflow
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Ex. ${item.expiryDate.toString().split(' ').first}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Delete button
                    IconButton(
                      onPressed: () => _deleteItem(item.id!),
                      icon: const Icon(Icons.delete, color: Colors.black),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}




 Widget _buildInventorySection() {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Center the "Your Inventory" text
        const Center(
          child: Text(
            'Your Inventory',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Add & Sort buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _addItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                '+ Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SortButton(onSortOptionSelected: _onSortOptionSelected),
          ],
        ),
        const SizedBox(height: 10),

        // Items list
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('No items yet.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Display item image
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: item.image != null && item.image!.isNotEmpty
                                ? Image.file(
                                    File(item.image!), // Load from file
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                  )
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          const SizedBox(width: 10),

                          // Item details
                          Expanded(
                            child: InkWell(
                              onTap: () => _editItem(item),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.itemName),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Ex. ${item.expiryDate.toString().split(' ').first}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Delete button
                          IconButton(
                            onPressed: () => _deleteItem(item.id!),
                            icon: const Icon(Icons.delete, color: Colors.black),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}




// Bottom navigation onTap handler
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
      nextPage = RecipePage(userId: widget.userId); // Pass userId to RecipePage
      break;
    //case 3: // Profile Page
      // = const ProfilePage(); // ProfilePage should be implemented
      //break;
    default:
      return;
  }

  // Navigate using pushReplacement
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => nextPage),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Remove default back arrow
        automaticallyImplyLeading: false,
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
          children: [
            _buildExpiringSoonSection(),
            const SizedBox(height: 20),
            _buildInventorySection(),
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
}
