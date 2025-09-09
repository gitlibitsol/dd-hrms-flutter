import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../Model/StoreLocationResponse.dart';
import '../Model/WFH_AttendanceModel.dart';
import '../Model/attendance_model.dart';
import '../Model/login_model.dart';

class ApiService {
  static const String baseUrl = 'http://35.200.253.184/dawadostapi/';
  static const int timeoutSeconds = 20;

  /// ✅ Universal HTTP POST with timeout + error handling
  Future<http.Response> _post(Uri uri, {Map<String, String>? headers, Object? body}) async {
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: timeoutSeconds));

      return response;
    } on SocketException {
      throw Exception("No Internet connection. Please check your network.");
    } on TimeoutException {
      throw Exception("Request timed out. Try again.");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  /// ✅ Universal HTTP GET with timeout + error handling
  Future<http.Response> _get(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: timeoutSeconds));

      return response;
    } on SocketException {
      throw Exception("No Internet connection. Please check your network.");
    } on TimeoutException {
      throw Exception("Request timed out. Try again.");
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  /// 🔹 Login API
  Future<LoginResponse> login(String mobileNo) async {
    final uri = Uri.parse('${baseUrl}api/EmployeeLogin')
        .replace(queryParameters: {"mobileNo": mobileNo});

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to login: ${response.reasonPhrase}');
    }
  }

  /// 🔹 Get Attendance
  Future<Map<String, dynamic>> fetchAttendance(String empId) async {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final uri = Uri.parse('${baseUrl}api/DailyMobileAttendence')
        .replace(queryParameters: {"EmpID": empId, "Date": formattedDate});

    final response = await _get(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'});

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch attendance: ${response.reasonPhrase}');
    }
  }

  /// 🔹 Upload Attendance
  Future<Map<String, dynamic>> uploadAttendance(AttendanceModel model) async {
    final uri = Uri.parse('${baseUrl}api/InsertData');

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload attendance: ${response.reasonPhrase}');
    }
  }

  /// 🔹 Upload WFH Attendance
  Future<Map<String, dynamic>> uploadWFHAttendance(WFH_AttendanceModel model) async {
    final uri = Uri.parse('${baseUrl}api/InsertDataWithoutQRCode');

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload WFH attendance: ${response.reasonPhrase}');
    }
  }

  /// 🔹 Get Store Location
  Future<StoreLocationResponse> getStoreLocation(String storeId) async {
    final uri = Uri.parse('${baseUrl}api/GetStoreLocation')
        .replace(queryParameters: {"StoreID": storeId});

    final response = await _get(uri, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      return StoreLocationResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch store location: ${response.reasonPhrase}');
    }
  }
}
