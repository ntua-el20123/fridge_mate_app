import 'dart:convert';
import 'package:fridge_mate_app/pages/profile_page.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fridge_mate_app/pages/recipe_page.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/modify_item_page.dart';
import 'package:fridge_mate_app/db.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
  bool _scanCompleted = false;

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
    if (_scanCompleted) return; // Prevent multiple scans

    _scanCompleted = true;
    try {
      final Map<String, dynamic> jsonData = jsonDecode(rawData);
      setState(() {
        _description = jsonData['description'] ?? 'Unknown';
        _expirationDate =
            jsonData['expiration_date'] ?? DateTime.now().toIso8601String();
        _category = jsonData['category'] ?? 'Uncategorized';
        _imageUrl = jsonData['image'] ?? '';
      });
      _navigateToModifyItemPage(); // Automatically navigate after scanning
    } catch (_) {
      setState(() {
        _barcodeValue = rawData;
      });
    }
  }

  Future<void> _navigateToModifyItemPage() async {
    Uint8List? imageBytes;
    if (_imageUrl.isNotEmpty) {
      try {
        final imageData =
            await NetworkAssetBundle(Uri.parse(_imageUrl)).load('');
        imageBytes = imageData.buffer.asUint8List();
      } catch (_) {
        imageBytes = null;
      }
    }

    final item = Item(
      userId: widget.userId,
      itemName: _description,
      expiryDate: DateTime.tryParse(_expirationDate) ??
          DateTime.now().add(const Duration(days: 7)),
      category: _category,
      image: imageBytes != null ? base64Encode(imageBytes) : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModifyItemPage(userId: widget.userId, item: item),
      ),
    );
  }

  void _clearQRCodeData() {
    setState(() {
      _barcodeValue = '';
      _description = '';
      _expirationDate = '';
      _category = '';
      _imageUrl = '';
      _scanCompleted = false;
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
              if (!_scanCompleted) {
                final barcodes = capture.barcodes;
                final String? rawValue =
                    barcodes.isNotEmpty ? barcodes.first.rawValue : null;

                if (rawValue != null) {
                  setState(() => _barcodeValue = rawValue);
                  _scannerController.stop();
                  _handleQRCodeData(rawValue);
                }
              }
            },
          ),
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.food_bank), label: 'Recipes'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
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
              'Scan Code',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
      body: _isSupportedPlatform
          ? _buildScannerView()
          : _buildUnsupportedPlatformView(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
