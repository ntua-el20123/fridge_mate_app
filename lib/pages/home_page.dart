import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:fridge_mate_app/pages/modify_item_page.dart';
import 'package:fridge_mate_app/pages/scan_page.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/pages/profile_page.dart';

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

class HomePage extends StatefulWidget {
  final int userId;
  final String sortType; // Added sortType parameter

  const HomePage({super.key, required this.userId, this.sortType = 'recently_added'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = Db.instance;
  List<Item> _items = [];
  String _currentSortType = 'recently_added'; // Store the current sort type
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentSortType = widget.sortType; // Initialize with the sort type from the constructor
    _fetchUserItems();
  }

  Future<void> _fetchUserItems() async {
    final userItems = await db.getUserItems(widget.userId);
    setState(() {
      _items = _sortItems(userItems, _currentSortType);
    });
  }

  List<Item> _sortItems(List<Item> items, String sortType) {
    switch (sortType) {
      case 'alphabetical':
        items.sort((a, b) => a.itemName.compareTo(b.itemName));
        break;
      case 'expiration':
        items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'recently_added':
        items.sort((a, b) => b.id!.compareTo(a.id!)); // Newest first
        break;
      case 'category':
        items.sort((a, b) => a.category.compareTo(b.category));
        break;
      default:
        break;
    }
    return items;
  }

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

  Future<void> _deleteItem(int itemId) async {
    await db.deleteItem(itemId);
    _fetchUserItems(); // Maintain current sort type
  }

  void _onSortOptionSelected(String option) {
    setState(() {
      _currentSortType = option; // Update the current sort type
      _items = _sortItems(_items, _currentSortType); // Update the sorting immediately
    });
  }

  List<Item> _getExpiringSoonItems(List<Item> allItems) {
    if (allItems.isEmpty) return [];
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return allItems
        .where((item) => item.expiryDate.isBefore(threeDaysFromNow) && item.expiryDate.isAfter(now))
        .toList();
  }

  Widget _buildExpiringSoonSection() {
    final expiringSoonItems = _getExpiringSoonItems(_items);
    if (expiringSoonItems.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            'Expires Soon',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: expiringSoonItems.map((item) {
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: item.image != null && item.image!.isNotEmpty
                            ? Image.file(
                                File(item.image!),
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
                                overflow: TextOverflow.ellipsis,
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
          const Center(
            child: Text(
              'Your Inventory',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _addItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('+ Add', style: TextStyle(color: Colors.white)),
              ),
              SortButton(onSortOptionSelected: _onSortOptionSelected),
            ],
          ),
          const SizedBox(height: 10),
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
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: item.image != null && item.image!.isNotEmpty
                                  ? Image.file(
                                      File(item.image!),
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
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.expiryDate.isBefore(DateTime.now())
                                            ? Colors.red // Highlight in red if expired
                                            : Colors.grey, // Default color for non-expired items
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

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
        onTap: (index) {
          if (_selectedIndex == index) return;

          Widget nextPage;
          switch (index) {
            case 0:
              nextPage = HomePage(userId: widget.userId, sortType: _currentSortType);
              break;
            case 1:
              nextPage = const ScanPage();
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
        },
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
