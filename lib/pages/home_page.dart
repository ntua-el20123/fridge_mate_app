import 'package:flutter/material.dart';
import 'package:fridge_mate_app/db.dart';
import 'package:fridge_mate_app/pages/modify_item_page.dart';

/// A button that shows a popup menu to select a sorting option.
class SortButton extends StatelessWidget {
  final Function(String) onSortOptionSelected;

  /// Pass in a callback to handle the user’s choice.
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
          color: Colors.green, // Background color
          borderRadius: BorderRadius.circular(30), // Rounded corners
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

/// The home page displays the user’s items and an “Expiring Soon” section.
class HomePage extends StatefulWidget {
  final int userId;

  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final db = Db.instance;

  /// Stores all the items owned by the user.
  List<Item> _items = [];

  /// Items that are about to expire soon (you define the criteria).
  Item? _expiringSoon;

  @override
  void initState() {
    super.initState();
    _loadUserItems();
  }

  /// Fetch the user’s items from the database and update the UI.
  Future<void> _loadUserItems() async {
    final userItems = await db.getUserItems(widget.userId);

    setState(() {
      _items = userItems;
      _expiringSoon = _filterExpiringSoon(userItems);
    });
  }

  Item? _filterExpiringSoon(List<Item> allItems) {
    if (allItems.isEmpty) return null;
    allItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return allItems.first;
  }

  /// Callback from SortButton to sort the list of items in various ways.
  void _onSortOptionSelected(String option) {
    setState(() {
      switch (option) {
        case 'alphabetical':
          _items.sort((a, b) => a.itemName.compareTo(b.itemName));
          break;
        case 'expiration':
          // For real comparison, parse expiryDate as DateTime.
          // Here we do a simple string comparison:
          _items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          break;
        case 'recently_added':
          // If you assume higher ID means more recent,
          // sort descending by ID:
          _items.sort((a, b) => b.id!.compareTo(a.id!));
          break;
        case 'category':
          _items.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
      // Re-filter expiring soon as well
      _expiringSoon = _filterExpiringSoon(_items);
    });
  }

  /// Navigate to modify item page to add a new item.
  void _onAddItem() async {
    // Example: Navigate to a page that returns true/false if a new item was added
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyItemPage(userId: widget.userId),
      ),
    );

    if (result == true) {
      // Reload items after successful addition
      _loadUserItems();
    }
  }

  /// Navigate to modify item page to edit the existing item.
  void _onItemClicked(Item item) async {
    // Navigate with the item info
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyItemPage(userId: widget.userId, item: item),
      ),
    );

    if (result == true) {
      // Reload items after successful modification
      _loadUserItems();
    }
  }

  /// Delete a specific item and reload the list.
  Future<void> _onDeleteItem(int itemId) async {
    await db.deleteItem(itemId);
    _loadUserItems();
  }

  /// Builds a list of items that are “about to expire soon.”
  Widget _buildExpiringSoonSection() {
    if (_expiringSoon == null) {
      return const SizedBox(); // No items expiring soon
    }

    final item = _expiringSoon!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expires Soon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Placeholder for an image thumbnail
              Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
              ),
              const SizedBox(width: 10),
              // Details
              Expanded(
                child: InkWell(
                  onTap: () => _onItemClicked(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.itemName),
                      const SizedBox(height: 5),
                      Text(
                        'Ex. ${item.expiryDate}',
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
                onPressed: () => _onDeleteItem(item.id!),
                icon: const Icon(Icons.delete, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the “Your Inventory” section with the user’s items.
  Widget _buildInventorySection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Inventory',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          // Buttons: Add and Sort
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _onAddItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  '+ Add',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              // Our SortButton with the callback
              SortButton(onSortOptionSelected: _onSortOptionSelected),
            ],
          ),
          const SizedBox(height: 10),
          // Inventory List
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text('No items yet.'),
                  )
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
                            // Placeholder for an image thumbnail
                            Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(width: 10),
                            // Details (tap to edit)
                            Expanded(
                              child: InkWell(
                                onTap: () => _onItemClicked(item),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Ex. ${item.expiryDate}',
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
                              onPressed: () => _onDeleteItem(item.id!),
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.black,
                              ),
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
        // Remove the default back arrow
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
