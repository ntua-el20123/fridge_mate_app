import 'dart:convert';
import 'package:fridge_mate_app/pages/profile_page.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/db.dart';
import 'dart:typed_data'; // Add this import
import 'package:flutter/services.dart'; // Add this import for NetworkAssetBundle

class ScanPage extends StatefulWidget {
  final int userId;

  const ScanPage({super.key, required this.userId});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _scannerController = MobileScannerController();
  int _selectedIndex = 1;
  String _barcodeValue = '';
  String _description = '';
  String _expirationDate = '';
  String _category = '';
  String _imageUrl = '';

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    if (_selectedIndex == index) return;

    Widget nextPage;

    switch (index) {
      case 0:
        nextPage = HomePage(userId: widget.userId);
        break;
      case 1:
        nextPage = ScanPage(userId: widget.userId);
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
  }

  void _handleQRCodeData(String rawData) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(rawData);
      setState(() {
        _description = jsonData['description'] ?? 'Unknown';
        _expirationDate =
            jsonData['expiration_date'] ?? DateTime.now().toIso8601String();
        _category = jsonData['category'] ?? 'Uncategorized';
        _imageUrl = jsonData['image'] ?? '';
      });
    } catch (_) {
      setState(() {
        _barcodeValue = rawData;
      });
    }
  }

  Future<void> _insertItemToDatabase() async {
    try {
      final dbHelper = Db.instance;
      Uint8List? imageBytes;

      if (_imageUrl.isNotEmpty) {
        final imageData =
            await NetworkAssetBundle(Uri.parse(_imageUrl)).load('');
        imageBytes = imageData.buffer.asUint8List();
      }
      final newItem = Item(
        userId: widget.userId,
        itemName: _description,
        expiryDate: DateTime.parse(_expirationDate),
        category: _category,
        image: imageBytes != null
            ? base64Encode(imageBytes)
            : null, // Convert image to base64 string
      );
      await dbHelper.insertItem(newItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added to inventory!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: $e')),
      );
    }
  }

  void _clearQRCodeData() {
    setState(() {
      _barcodeValue = '';
      _description = '';
      _expirationDate = '';
      _category = '';
      _imageUrl = '';
    });
  }

  bool get _isSupportedPlatform {
    return !(kIsWeb ||
        Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isLinux);
  }

  Widget _buildScannerView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (_barcodeValue.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(9.0),
            child: Text('Scanned Data: $_barcodeValue'),
          ),
        if (_description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(9.0),
            child: Text('Description: $_description'),
          ),
        Flexible(
          fit: FlexFit.loose,
          child: MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              _scannerController.stop();
              final barcodes = capture.barcodes;
              final String? rawValue =
                  barcodes.isNotEmpty ? barcodes.first.rawValue : null;

              if (rawValue != null) {
                setState(() => _barcodeValue = rawValue);
                _handleQRCodeData(rawValue);
              }
            },
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: () => {_scannerController.start(), _clearQRCodeData()},
          child: const Text('Rescan',
              style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
        if (_barcodeValue.isNotEmpty)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: _insertItemToDatabase,
            child: const Text('Add to Inventory',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildUnsupportedPlatformView() {
    return const Center(
      child: Text(
        'QR scanning is not supported on this platform.',
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
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
