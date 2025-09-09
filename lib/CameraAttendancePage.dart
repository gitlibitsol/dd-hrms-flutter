import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import 'HomePage.dart';
import 'Model/attendance_model.dart';
import 'network/api_service.dart';

class CameraAttendancePage extends StatefulWidget {
  @override
  _CameraAttendancePageState createState() => _CameraAttendancePageState();
}

class _CameraAttendancePageState extends State<CameraAttendancePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  /// ✅ Capture Photo
  Future<void> _takePhoto() async {
    try {
      // 🔹 Request Camera Permission
      final status = await Permission.camera.request();

      if (status.isDenied) {
        _showSnackBar("Camera permission denied");
        return;
      } else if (status.isPermanentlyDenied) {
        _showSnackBar("Camera permission permanently denied. Please enable it from Settings.");
        await openAppSettings();
        return;
      } else if (status.isRestricted) {
        _showSnackBar("Camera access is restricted on this device.");
        return;
      }

      // 🔹 Open Camera
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        _showSnackBar("No image captured");
        return;
      }

      if (!mounted) return;
      setState(() {
        _image = File(pickedFile.path);
      });

      // 🔹 Load Saved Data
      final prefs = await SharedPreferences.getInstance();
      await _uploadImage(
        userId: prefs.getString('userid'),
        empCode: prefs.getString('empCode'),
        savedQrCodeId: prefs.getString('qrCodeId'),
        savedCompanyID: prefs.getString('companyID'),
        savedAddress: prefs.getString('address'),
        savedLatitude: prefs.getDouble('latitude')?.toString(),
        savedLongitude: prefs.getDouble('longitude')?.toString(),
        savedPunchType: prefs.getString('punchType'),
      );
    } catch (e) {
      _showSnackBar("Error capturing photo: $e");
    }
  }

  /// ✅ Upload Image with Watermark
  Future<void> _uploadImage({
    String? userId,
    String? empCode,
    String? savedQrCodeId,
    String? savedCompanyID,
    String? savedAddress,
    String? savedLatitude,
    String? savedLongitude,
    String? savedPunchType,
  }) async {
    if (_image == null) {
      _showSnackBar('No image selected');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🔹 Read & Process Image
      final bytes = await _image!.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception("Failed to process image");

      // 🔹 Add Watermark
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

      // 🔹 Resize + Compress
      final resized = img.copyResize(originalImage, width: 800);
      List<int> modifiedBytes = img.encodeJpg(resized, quality: 70);
      String uploadImagePhoto = base64Encode(modifiedBytes);

      // 🔹 Save for Preview
      final tempFile = File(
          '${Directory.systemTemp.path}/attend_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(modifiedBytes);

      if (!mounted) return;
      setState(() => _image = tempFile);

      // 🔹 Prepare Data
      final attendanceModel = AttendanceModel(
        empID: userId,
        empCode: empCode,
        address: savedAddress,
        latitude: savedLatitude,
        longitude: savedLongitude,
        companyId: savedCompanyID,
        barCodeId: savedQrCodeId,
        attenType: "QRCode",
        dateOfThumb: DateFormat('dd-MMM-yyyy').format(DateTime.now()),
        timeOfThumb: TimeOfDay.now().format(context),
        fullDateTime: DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime.now()),
        attenImage: uploadImagePhoto,
        punchType: savedPunchType,
      );

      // 🔹 Call API
      final response = await _apiService.uploadAttendance(attendanceModel);
      _showSnackBar(response['Message'] ?? "Upload finished");

      if (response['Status_Code'] == "200" && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      _showSnackBar("Upload failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// ✅ SnackBar Helper
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
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
                    "Capture Attendance Photo",
                    style: TextStyle(
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),

                  // 🔹 Preview Area
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
                    child: Text("No image selected"),
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

                  // 🔹 Button
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.camera_alt),
                      label: Text(
                        "Take Photo",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.02,
                        ),
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _takePhoto,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),

            // 🔹 Loader
            if (_isLoading)
              Container(
                color: Colors.black45,
                child: Center(
                  child: Platform.isIOS
                      ? CupertinoActivityIndicator(radius: 18)
                      : CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
