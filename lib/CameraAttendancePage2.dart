import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'Model/WFH_AttendanceModel.dart';
import 'network/api_service.dart';
import 'package:image/image.dart' as img;

class CameraAttendancePage2 extends StatefulWidget {
  @override
  _CameraAttendancePage2State createState() => _CameraAttendancePage2State();
}

class _CameraAttendancePage2State extends State<CameraAttendancePage2> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  /// 🔹 Show Snackbar (safe)
  void _showSnackBar(String message, {Color bgColor = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: bgColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🔹 Request Camera Permission
  Future<bool> _checkCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSnackBar("Camera permission permanently denied. Enable it from Settings.");
      await openAppSettings();
    } else if (status.isRestricted) {
      _showSnackBar("Camera access is restricted on this device.");
    } else {
      _showSnackBar("Camera permission denied");
    }
    return false;
  }

  /// 🔹 Request Location Permission
  Future<bool> _checkLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      _showSnackBar("Location permission permanently denied. Enable it from Settings.");
      await openAppSettings();
    } else if (status.isRestricted) {
      _showSnackBar("Location services are restricted.");
    } else {
      _showSnackBar("Location permission denied");
    }
    return false;
  }

  /// 🔹 Validate Location before photo
  bool _isLocationValid(String? lat, String? lng) {
    if (lat == null || lng == null || lat == "0.0" || lng == "0.0") {
      _showSnackBar("Fetching location... Please try again.");
      return false;
    }
    return true;
  }

  /// 🔹 Capture Photo
  Future<void> _takePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUserId = prefs.getString('userid');
    String? savedEmpCode = prefs.getString('empCode');
    String? savedCompanyID = prefs.getString('companyID');
    String? savedAddress = prefs.getString('address');
    String? savedLatitude = prefs.getDouble('latitude')?.toString();
    String? savedLongitude = prefs.getDouble('longitude')?.toString();
    String? savedPunchType = prefs.getString('punchType');
    String? savedLocation = prefs.getString('location');
    String? savedPurpose = prefs.getString('purpose');
    String? savedWorkType = prefs.getString('workType');

    if (!await _checkLocationPermission()) return;
    if (!_isLocationValid(savedLatitude, savedLongitude)) return;
    if (!await _checkCameraPermission()) return;

    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) {
      _showSnackBar("No image captured.");
      return;
    }

    if (!mounted) return;
    setState(() {
      _image = File(pickedFile.path);
    });

    await _uploadImage(
      savedUserId,
      savedEmpCode,
      savedCompanyID,
      savedAddress,
      savedLatitude,
      savedLongitude,
      savedPunchType,
      savedLocation,
      savedPurpose,
      savedWorkType,
    );
  }

  /// 🔹 Upload Image with Watermark
  Future<void> _uploadImage(
      String? userId,
      String? empCode,
      String? savedCompanyID,
      String? savedAddress,
      String? savedLatitude,
      String? savedLongitude,
      String? savedPunchType,
      String? savedLocation,
      String? savedPurpose,
      String? savedWorkType,
      ) async {
    if (_image == null) {
      _showSnackBar('No image selected');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final bytes = await _image!.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        _showSnackBar("Failed to process image");
        return;
      }

      List<String> lines = [
        savedAddress ?? '',
        "Lat: ${savedLatitude ?? ''}, Lng: ${savedLongitude ?? ''}",
        "Time: ${DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now())}",
      ];

      final font = img.arial24;
      final textColor = img.ColorRgb8(255, 0, 0);

      int lineHeight = 40;
      int startY = originalImage.height - (lines.length * lineHeight) - 20;

      for (int i = 0; i < lines.length; i++) {
        img.drawString(
          originalImage,
          lines[i],
          x: 20,
          y: startY + (i * lineHeight),
          font: font,
          color: textColor,
        );
      }

      final resized = img.copyResize(originalImage, width: 800);
      List<int> modifiedBytes = img.encodeJpg(resized, quality: 70);
      String uploadImagePhoto = base64Encode(modifiedBytes);

      final tempFile = File(
        '${Directory.systemTemp.path}/wfh_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(modifiedBytes);

      if (!mounted) return;
      setState(() {
        _image = tempFile;
      });

      final attendanceModel = WFH_AttendanceModel(
        empID: userId,
        empCode: empCode,
        address: savedAddress,
        latitude: savedLatitude,
        longitude: savedLongitude,
        companyId: savedCompanyID,
        attenType: savedWorkType,
        dateOfThumb: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
        timeOfThumb: TimeOfDay.now().format(context),
        fullDateTime: DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now()),
        attenImage: uploadImagePhoto,
        punchType: savedPunchType,
        location: savedLocation,
        purpose: savedPurpose,
      );

      final response = await _apiService.uploadWFHAttendance(attendanceModel);
      String status = response['Status_Code'];
      String message = response['Message'];

      _showSnackBar(message, bgColor: status == "200" ? Colors.green : Colors.red);

      if (status == "200" && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('WFH Attendance'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture Attendance Photo',
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _image == null
                      ? Container(
                    height: screenHeight * 0.25,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.image_not_supported,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: screenHeight * 0.3,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _takePhoto,
                      label: _isLoading
                          ? (Platform.isIOS
                          ? const CupertinoActivityIndicator(radius: 12)
                          : const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ))
                          : const Text(
                        'Take Photo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Platform.isIOS
                      ? const CupertinoActivityIndicator(radius: 18)
                      : const CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
