import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Replace with your actual pages
import 'package:fridge_mate_app/pages/home_page.dart';
// import 'package:fridge_mate_app/pages/recipes_page.dart';
// import 'package:fridge_mate_app/pages/profile_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  /// The scanner controller from mobile_scanner
  final MobileScannerController _mobileScannerController =
      MobileScannerController();

  /// The scanned barcode result (if any)
  String barcodeResult = "";

  /// Keep track of which bottom nav item is selected
  int _selectedIndex = 1; // index=1 => 'Scan'

  /// Bottom navigation onTap handler
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      switch (index) {
        case 0:
          // Navigate to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage(userId: 1)),
          );
          break;
        case 1:
          // Already on Scan tab, do nothing
          break;
        case 2:
          // Navigate to Recipes or another page
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (_) => const RecipesPage()),
          // );
          break;
        case 3:
          // Navigate to Profile
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (_) => const ProfilePage()),
          // );
          break;
      }
    });
  }

  /// Scanner widget for mobile platforms
  Widget _buildMobileScanner() {
    return Column(
      children: [
        // The camera preview area
        Expanded(
          flex: 4,
          child: MobileScanner(
            controller: _mobileScannerController,
            onDetect: (BarcodeCapture barcode) {
              final barcodeList = barcode.barcodes;
              final rawValue = barcodeList.isNotEmpty
                  ? barcodeList.first.rawValue
                  : 'No result';
              setState(() => barcodeResult = rawValue ?? 'No result');
              // Pause the scanner after a result
              _mobileScannerController.stop();
            },
          ),
        ),
        // The result + "Rescan" button
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Scan Result: $barcodeResult'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Restart scanning
                  _mobileScannerController.start();
                },
                child: const Text('Rescan'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Fallback if scanning not supported on this platform
  Widget _buildUnsupportedPlatform() {
    return const Center(
      child: Text(
        'QR scanning is not supported on this platform.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  void dispose() {
    _mobileScannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only support Android/iOS out of the box
    final bool isSupportedPlatform =
        !(kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // remove default back arrow
        title: const Text(
          'FridgeMate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: isSupportedPlatform
          ? _buildMobileScanner()
          : _buildUnsupportedPlatform(),
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
