import 'package:flutter/material.dart';

class SortButton extends StatelessWidget {
  const SortButton({super.key});

  // Handle the selected sort option here
  void _onSortOptionSelected(String option) {
    switch (option) {
      case 'alphabetical':
        // Handle alphabetical sort
        break;
      case 'expiration':
        // Handle expiration date sort
        break;
      case 'recently_added':
        // Handle recently added sort
        break;
      case 'category':
        // Handle category sort
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _onSortOptionSelected,
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
              style: TextStyle(
                  color: Colors.white, fontSize: 16), // Text color and size
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Example method for deleting an item. In a real app, this might be more complex.
  void _onDeleteItem() {
    // Handle delete logic
  }

  // Example method for adding a new item.
  void _onAddItem() {
    // Handle adding a new item
  }

  // Builds the "Expires Soon" section.
  Widget _buildExpiringSoonSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
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
          Row(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description'),
                    SizedBox(height: 5),
                    Text(
                      'Ex. 21/11/24',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _onDeleteItem,
                icon: const Icon(Icons.delete, color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Builds the "Your Inventory" section with a list of items.
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
              const SortButton(),
            ],
          ),
          const SizedBox(height: 10),
          // Inventory List
          Expanded(
            child: ListView.builder(
              itemCount: 5, // example count
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Container(
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Description'),
                              SizedBox(height: 5),
                              Text(
                                'Ex. 19/11/24',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _onDeleteItem,
                          icon: const Icon(Icons.delete, color: Colors.black),
                        ),
                      ],
                    ),
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
        // Set this to remove the default back arrow
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
            label: 'Home', // Selected label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
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
