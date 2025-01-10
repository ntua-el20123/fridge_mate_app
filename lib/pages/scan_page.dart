import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/pages/home_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  /// Controller for the mobile scanner
  final MobileScannerController _scannerController = MobileScannerController();

  /// Current index of bottom navigation bar
  int _selectedIndex = 1;

  /// Product details parsed from QR code
  String _description = '';
  String _expirationDate = '';
  String _category = '';
  String _imageUrl = '';

  /// Raw barcode value
  String _barcodeValue = '';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Bottom navigation bar item selection handler
  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage(userId: 1)),
          );
          break;
        case 1:
          // Stay on the ScanPage
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RecipePage(userId: 1)),
          );
          break;
        case 3:
          // TODO: Navigate to Profile Page if needed
          break;
      }
    });
  }

  /// Decode JSON data from the QR code and update state
  void _handleQRCodeData(String rawData) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(rawData);
      setState(() {
        _description = jsonData['description'] ?? 'Unknown';
        _expirationDate = jsonData['expiration_date'] ?? 'N/A';
        _category = jsonData['category'] ?? 'Uncategorized';
        _imageUrl = jsonData['image'] ?? '';
      });
    } catch (_) {
      // If the QR code does not contain valid JSON
      setState(() {
        _description = 'Invalid QR Code';
        _expirationDate = '';
        _category = '';
        _imageUrl = '';
      });
    }
  }

  void _clearQRCodeData() {
    setState(() {
      _description = '';
      _expirationDate = '';
      _category = '';
      _imageUrl = '';
    });
  }

  /// Checks if the current platform supports the camera scanning feature
  bool get _isSupportedPlatform {
    return !(kIsWeb ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux);
  }

  /// Builds the scanner widget and the display for scanned data
  Widget _buildScannerView() {
    return Column(
      children: [
        if (_barcodeValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildScannedDataDisplay(),
          ),
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              final String? rawValue =
                  barcodes.isNotEmpty ? barcodes.first.rawValue : null;

              if (rawValue != null) {
                setState(() => _barcodeValue = rawValue);
                _scannerController.stop();
                _handleQRCodeData(rawValue);
              }
            },
          ),
        ),
        ElevatedButton(
          onPressed: () => {_scannerController.start(), _clearQRCodeData()},
          child: const Text('Rescan'),
        ),
      ],
    );
  }

  /// Widget to display the scanned product data
  Widget _buildScannedDataDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_description.isNotEmpty) Text('Description: $_description'),
        if (_expirationDate.isNotEmpty)
          Text('Expiration Date: $_expirationDate'),
        if (_category.isNotEmpty) Text('Category: $_category'),
        if (_imageUrl.isNotEmpty)
          Image.network(
            _imageUrl,
            height: 100,
          ),
      ],
    );
  }

  /// Widget to show when the platform is unsupported
  Widget _buildUnsupportedPlatformView() {
    return const Center(
      child: Text(
        'QR scanning is not supported on this platform.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  /// Builds the bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
      ),
      body: _isSupportedPlatform
          ? _buildScannerView()
          : _buildUnsupportedPlatformView(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
