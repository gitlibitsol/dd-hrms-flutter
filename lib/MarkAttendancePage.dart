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
    final status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _showSnackbar("Unable to fetch location. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      setState(() {
        _currentAddress = place != null
            ? "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}"
            : "Address unavailable";
      });

      await _saveLocationData(_currentAddress, position);
    } catch (e) {
      _showSnackbar("Unable to fetch location. Error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveLocationData(String address, Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', address);
    await prefs.setDouble('latitude', position.latitude);
    await prefs.setDouble('longitude', position.longitude);
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

    final prefs = await SharedPreferences.getInstance();
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
        title: const Text("Punch Type"),
        content:
        const Text("Choose Punch In or Punch Out before scanning QR code."),
        actions: [
          TextButton(
            onPressed: () => _scanQRCodeWithPunch("In"),
            child: const Text("Punch In"),
          ),
          TextButton(
            onPressed: () => _scanQRCodeWithPunch("Out"),
            child: const Text("Punch Out"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Step 5: Save Punch Type
  Future<void> _scanQRCodeWithPunch(String punchType) async {
    Navigator.pop(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('punchType', punchType);

    _showSnackbar("Selected Punch: $punchType");

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CameraAttendancePage2()),
      );
    }
  }

  /// 🔹 Dialogs
  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enable Location"),
        content: const Text("Your GPS is OFF. Please enable location services."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text(
            "Location permission is permanently denied. Please enable it from settings."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Snackbar
  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mark Attendance",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildTextField(_locationController, "Location"),
              const SizedBox(height: 16),

              _buildTextField(_purposeController, "Purpose"),
              const SizedBox(height: 16),

              _buildWorkTypeDropdown(),
              const SizedBox(height: 20),

              Center(child: _buildGetLocationButton()),
              const SizedBox(height: 20),

              Center(child: _buildSubmitButton()),
              const SizedBox(height: 30),

              const Text("📍 Current Address:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_currentAddress,
                  style:
                  TextStyle(fontSize: 15, color: Colors.grey.shade800)),
            ],
          ),
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
      items: ['WFH', 'OD']
          .map((type) =>
          DropdownMenuItem<String>(value: type, child: Text(type)))
          .toList(),
      onChanged: (value) => setState(() => _workType = value),
    );
  }

  Widget _buildGetLocationButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _getCurrentLocation,
      icon: const Icon(Icons.location_on),
      label: _isLoading
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Colors.white),
      )
          : const Text("Get Current Location"),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitAttendance,
      child: const Text("Submit"),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
