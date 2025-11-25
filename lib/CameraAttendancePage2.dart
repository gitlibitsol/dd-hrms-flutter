import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import 'HomePage.dart';
import 'Model/WFH_AttendanceModel.dart';
import 'network/api_service.dart';

class CameraAttendancePage2 extends StatefulWidget {
  @override
  _CameraAttendancePage2State createState() => _CameraAttendancePage2State();
}

class _CameraAttendancePage2State extends State<CameraAttendancePage2> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  /// Snackbar
  void _showSnackBar(String msg, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    ));
  }

  /// Camera Permission
  Future<bool> _cameraPermission() async {
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar("Camera permission permanently denied. Open settings.");
      openAppSettings();
      return false;
    } else {
      _showSnackBar("Camera permission denied");
      return false;
    }
  }

  /// Location Permission
  Future<bool> _locationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      _showSnackBar("Location permission permanently denied. Open settings.");
      openAppSettings();
      return false;
    } else {
      _showSnackBar("Location permission denied");
      return false;
    }
  }

  /// Take Photo
  Future<void> _takePhoto() async {
    bool loc = await _locationPermission();
    if (!loc) return;

    bool cam = await _cameraPermission();
    if (!cam) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (picked == null) {
      _showSnackBar("No image captured");
      return;
    }

    setState(() {
      _image = File(picked.path);
    });

    await _processAndUploadImage();
  }

  /// Add Watermark + Upload
  Future<void> _processAndUploadImage() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      String? userId = prefs.getString('userid');
      String? empCode = prefs.getString('empCode');
      String? companyId = prefs.getString('companyID');
      String? address = prefs.getString('address');
      String? punchType = prefs.getString('punchType');
      String? location = prefs.getString('location');
      String? purpose = prefs.getString('purpose');
      String? workType = prefs.getString('workType');
      String? lat = prefs.getString('latitude');
      String? lng = prefs.getString('longitude');

      if (lat == null || lng == null || lat == "0.0" || lng == "0.0") {
        _showSnackBar("Location not found. Try again.");
        return;
      }

      final bytes = await _image!.readAsBytes();
      img.Image? original = img.decodeImage(bytes);

      if (original == null) {
        _showSnackBar("Image processing error");
        return;
      }

      /// WATERMARK TEXT
      List<String> lines = [
        address ?? "",
        "Lat: $lat, Lng: $lng",
        "Time: ${DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now())}",
      ];

      final textColor = img.ColorRgb8(255, 0, 0);
      final font = img.arial24;

      int startY = original.height - (lines.length * 40) - 20;

      for (int i = 0; i < lines.length; i++) {
        img.drawString(
          original,
          lines[i],
          x: 20,
          y: startY + (i * 40),
          color: textColor,
          font: font,
        );
      }

      final resized = img.copyResize(original, width: 900);
      List<int> finalBytes = img.encodeJpg(resized, quality: 80);

      String base64Photo = base64Encode(finalBytes);

      /// SAVE WATERMARKED IMAGE TO TEMP FILE
      final tmp = File(
          "${Directory.systemTemp.path}/wfh_${DateTime.now().millisecondsSinceEpoch}.jpg");
      await tmp.writeAsBytes(finalBytes);

      setState(() => _image = tmp);

      /// Build Model
      final model = WFH_AttendanceModel(
        empID: userId,
        empCode: empCode,
        address: address,
        latitude: lat,
        longitude: lng,
        companyId: companyId,
        attenType: workType,
        dateOfThumb: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
        timeOfThumb: TimeOfDay.now().format(context),
        fullDateTime: DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now()),
        attenImage: base64Photo,
        punchType: punchType,
        location: location,
        purpose: purpose,
      );

      final response = await _apiService.uploadWFHAttendance(model);

      String status = response["Status_Code"];
      String message = response["Message"];

      _showSnackBar(message,
          color: status == "200" ? Colors.green : Colors.red);

      if (status == "200") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => HomePage()));
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WFH Attendance"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: _image == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt, size: 90, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No image selected",
                      style: TextStyle(color: Colors.grey)),
                ],
              )
                  : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _takePhoto,
            icon: const Icon(Icons.camera),
            label: _isLoading
                ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text("Take Photo"),
            style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 30)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
