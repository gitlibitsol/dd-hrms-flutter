import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math';
import 'CameraAttendancePage.dart';
import 'network/api_service.dart';

class QrCodeScanner extends StatefulWidget {
  @override
  _QrCodeScannerState createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  String qrCode = '';
  String address = 'Fetching location...';
  double userLatitude = 0.0;
  double userLongitude = 0.0;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  /// 🔹 Show message (Snackbar)
  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /// 🔹 Get current location with safe fallback
  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);

    try {
      // Service check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("Please enable Location Services");
        await Geolocator.openLocationSettings();
        setState(() => _loadingLocation = false);
        return;
      }

      // Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage("Location permission denied");
          setState(() => _loadingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage("Permission permanently denied. Enable from settings");
        await Geolocator.openAppSettings();
        setState(() => _loadingLocation = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showMessage("Could not fetch location");
        setState(() => _loadingLocation = false);
        return;
      }

      setState(() {
        userLatitude = position!.latitude;
        userLongitude = position.longitude;
      });

      // Get address
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            address =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.postalCode}";
          });
        }
      } catch (_) {
        _showMessage("Unable to fetch address");
      }
    } catch (e) {
      _showMessage("Error fetching location: $e");
    }

    if (mounted) setState(() => _loadingLocation = false);
  }

  /// 🔹 Punch Dialog
  void _showPunchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Select Punch Option",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text(
              "Please select Punch In or Punch Out before scanning QR code."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scanQRCodeWithPunch("In");
              },
              child: Text("Punch In"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scanQRCodeWithPunch("Out");
              },
              child: Text("Punch Out"),
            ),
          ],
        );
      },
    );
  }

  /// 🔹 Scan QR + Check Geofence
  Future<void> _scanQRCodeWithPunch(String punchType) async {
    if (_loadingLocation || userLatitude == 0.0) {
      _showMessage("Fetching location, please wait...");
      return;
    }

    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        setState(() => qrCode = result.rawContent);

        // ✅ Check geofence with API
        await _getStoreLocationAndCheck(qrCode, punchType);
      } else {
        _showMessage("No QR code detected");
      }
    } on FormatException {
      _showMessage("Scan cancelled");
    } catch (e) {
      _showMessage("QR Scan failed: $e");
    }
  }

  /// 🔹 Get Store Location from API + Check Geofence
  Future<void> _getStoreLocationAndCheck(
      String storeId, String punchType) async {
    try {
      final apiService = ApiService();
      final response = await apiService.getStoreLocation(storeId);

      if (response.statusCode == "200") {
        for (var store in response.storeList) {
          bool inside = _checkGeofence(store.latitude, store.longitude, 300);

          if (inside) {
            await _storeData(storeId, punchType);
          } else {
            _showMessage("Outside geofence area");
          }
        }
      } else {
        _showMessage("Invalid response from server");
      }
    } catch (e) {
      _showMessage("Error fetching store location: $e");
    }
  }

  /// 🔹 Geofence Check
  bool _checkGeofence(double storeLat, double storeLng, double radiusMeters) {
    const earthRadius = 6371000; // meters
    double dLat = _degToRad(storeLat - userLatitude);
    double dLng = _degToRad(storeLng - userLongitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(userLatitude)) *
            cos(_degToRad(storeLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance <= radiusMeters;
  }

  double _degToRad(double deg) => deg * pi / 180.0;

  /// 🔹 Save Data
  Future<void> _storeData(String qrCode, String punchType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String scanTime = DateTime.now().toIso8601String();

    await prefs.setString('qrCodeId', qrCode);
    await prefs.setString('scantime', scanTime);
    await prefs.setString('address', address);
    await prefs.setDouble('latitude', userLatitude);
    await prefs.setDouble('longitude', userLongitude);
    await prefs.setString('punchType', punchType);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CameraAttendancePage()),
      );
    }
  }

  /// 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('QR Code Scanner', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.qr_code_scanner, size: 80, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                'Tap the button below to scan a QR code.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // 🔹 Scan Button
              ElevatedButton.icon(
                icon: Icon(Icons.qr_code),
                label: Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadingLocation ? null : _showPunchDialog,
              ),

              SizedBox(height: 30),

              // 🔹 Info Cards
              _buildInfoCard(
                title: 'Scanned QR Code',
                value: qrCode.isEmpty ? 'No code scanned yet' : qrCode,
                icon: Icons.code,
              ),
              _buildInfoCard(
                title: 'Current Address',
                value: _loadingLocation ? 'Fetching location...' : address,
                icon: Icons.location_on,
              ),
              _buildInfoCard(
                title: 'Coordinates',
                value: _loadingLocation
                    ? 'Fetching...'
                    : 'Lat: $userLatitude\nLng: $userLongitude',
                icon: Icons.my_location,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable Info Card
  Widget _buildInfoCard(
      {required String title, required String value, required IconData icon}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 28),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
