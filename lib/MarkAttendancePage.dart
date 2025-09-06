import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'CameraAttendancePage2.dart';

class MarkAttendancePage extends StatefulWidget {
  @override
  _MarkAttendancePageState createState() => _MarkAttendancePageState();
}

class _MarkAttendancePageState extends State<MarkAttendancePage> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();

  String _currentAddress = "Not yet fetched";
  bool _isLoading = false;
  String? _workType; // Dropdown value

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLocation();
  }

  /// 🔹 Step 1: Check Location Permission
  Future<void> _checkPermissionsAndLocation() async {
    var status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showEnableLocationDialog();
      } else {
        _getCurrentLocation();
      }
    } else if (status.isDenied) {
      _showSnackbar("Location permission is required to mark attendance.");
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    }
  }

  /// 🔹 Step 2: Get Current Location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;

      setState(() {
        _currentAddress =
        "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
      });

      await _saveLocationData(_currentAddress, position);
    } catch (e) {
      _showSnackbar("Unable to fetch location. Please try again.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveLocationData(String address, Position position) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', address);
    await prefs.setString('latitude', position.latitude.toString());
    await prefs.setString('longitude', position.longitude.toString());
  }

  /// 🔹 Step 3: Submit Attendance
  Future<void> _submitAttendance() async {
    if (_locationController.text.isEmpty || _purposeController.text.isEmpty) {
      _showSnackbar('Please enter location and purpose.');
      return;
    } else if (_workType == null) {
      _showSnackbar('Please select Work Type.');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('location', _locationController.text);
    await prefs.setString('purpose', _purposeController.text);
    await prefs.setString('workType', _workType!);

    _showPunchDialog();
  }

  /// 🔹 Step 4: Punch Dialog
  void _showPunchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Punch Type"),
        content: Text("Choose Punch In or Punch Out before scanning QR code."),
        actions: [
          TextButton(
            onPressed: () => _scanQRCodeWithPunch("In"),
            child: Text("Punch In"),
          ),
          TextButton(
            onPressed: () => _scanQRCodeWithPunch("Out"),
            child: Text("Punch Out"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Step 5: Save Punch Type
  void _scanQRCodeWithPunch(String punchType) async {
    Navigator.pop(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('punchType', punchType);

    _showSnackbar("Selected Punch: $punchType");

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CameraAttendancePage2()),
    );
  }

  /// 🔹 Dialogs
  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Enable Location"),
        content: Text("Your GPS is OFF. Please enable location services."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Permission Required"),
        content: Text("Location permission is permanently denied. Please enable it from settings."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Snackbar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mark Attendance",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            _buildTextField(_locationController, "Location"),
            SizedBox(height: 16),

            _buildTextField(_purposeController, "Purpose"),
            SizedBox(height: 16),

            _buildWorkTypeDropdown(),
            SizedBox(height: 20),

            Center(child: _buildGetLocationButton()),
            SizedBox(height: 20),

            Center(child: _buildSubmitButton()),
            SizedBox(height: 30),

            Text("📍 Current Address:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text(_currentAddress, style: TextStyle(fontSize: 15, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  /// Widgets
  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildWorkTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Work Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      value: _workType,
      items: ['WFH', 'OD'].map((type) {
        return DropdownMenuItem<String>(value: type, child: Text(type));
      }).toList(),
      onChanged: (value) => setState(() => _workType = value),
    );
  }

  Widget _buildGetLocationButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _getCurrentLocation,
      icon: Icon(Icons.location_on),
      label: _isLoading
          ? SizedBox(
          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text("Get Current Location"),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitAttendance,
      child: Text("Submit"),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
