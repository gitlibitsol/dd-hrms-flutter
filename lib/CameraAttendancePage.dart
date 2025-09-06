import 'dart:convert';
import 'dart:io';
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
      var status = await Permission.camera.request();

      if (status.isDenied) {
        _showSnackBar("Camera permission denied");
        return;
      } else if (status.isPermanentlyDenied) {
        _showSnackBar("Camera permission permanently denied. Please enable from Settings.");
        await openAppSettings();
        return;
      }

      // 🔹 Open Camera
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        _showSnackBar("No image captured");
        return;
      }

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

      final font = img.arial24; // Default font
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
      final tempFile = File('${Directory.systemTemp.path}/attend_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(modifiedBytes);
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
      setState(() => _isLoading = false);
    }
  }

  /// ✅ SnackBar Helper
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mark Attendance'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Capture Attendance Photo",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),

                // 🔹 Preview Area
                _image == null
                    ? Container(
                  height: 200,
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
                  child: Image.file(_image!, height: 250, fit: BoxFit.cover),
                ),
                SizedBox(height: 20),

                // 🔹 Button
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      "Take Photo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _takePhoto,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Loader
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
