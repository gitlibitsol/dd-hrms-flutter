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

  static const String baseUrl = 'http://52.66.139.134/dawadostapi/';
  static const int timeoutSeconds = 20;

  /// 🔹 Universal POST Method (with timeout & error handling)
  Future<http.Response> _post(
      Uri uri, {
        Map<String, String>? headers,
        Object? body,
      }) async {
    try {
      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw Exception("No Internet connection. Please check your network.");
    } on TimeoutException {
      throw Exception("Request timed out. Please try again.");
    } catch (e) {
      throw Exception("Unexpected error occurred: $e");
    }
  }

  /// 🔹 Universal GET Method (with timeout & error handling)
  Future<http.Response> _get(
      Uri uri, {
        Map<String, String>? headers,
      }) async {
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } on SocketException {
      throw Exception("No Internet connection. Please check your network.");
    } on TimeoutException {
      throw Exception("Request timed out. Please try again.");
    } catch (e) {
      throw Exception("Unexpected error occurred: $e");
    }
  }

  /// 🔸 Centralized Response Handler
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      throw Exception(
        "Server error (${response.statusCode}): ${response.reasonPhrase}",
      );
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

    return LoginResponse.fromJson(jsonDecode(response.body));
  }

  /// 🔹 Fetch Attendance by Employee ID
  Future<Map<String, dynamic>> fetchAttendance(String empId) async {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());
    final uri = Uri.parse('${baseUrl}api/DailyMobileAttendence').replace(
      queryParameters: {"EmpID": empId, "Date": formattedDate},
    );

    final response =
    await _get(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'});

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 🔹 Upload Attendance with QR
  Future<Map<String, dynamic>> uploadAttendance(AttendanceModel model) async {
    final uri = Uri.parse('${baseUrl}api/InsertData');

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(model.toJson()),
    );

    return jsonDecode(response.body);
  }

  /// 🔹 Upload Work From Home Attendance (Without QR)
  Future<Map<String, dynamic>> uploadWFHAttendance(WFH_AttendanceModel model) async {
    final uri = Uri.parse('${baseUrl}api/InsertDataWithoutQRCode');

    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(model.toJson()),
    );

    return jsonDecode(response.body);
  }

  /// 🔹 Get Store Location by StoreID
  Future<StoreLocationResponse> getStoreLocation(String storeId) async {
    final uri = Uri.parse('${baseUrl}api/GetStoreLocation')
        .replace(queryParameters: {"StoreID": storeId});

    final response =
    await _get(uri, headers: {'Content-Type': 'application/json; charset=UTF-8'});

    return StoreLocationResponse.fromJson(jsonDecode(response.body));
  }

  /// 🔹 Sign Up API
  Future<Map<String, dynamic>> signUp(String name, String mobileNo, String emailId) async {
    final uri = Uri.parse('${baseUrl}api/EmployeeSignup').replace(queryParameters: {
      "name": name,
      "mobileNo": mobileNo,
      "emailId": emailId,
    });
    final response = await _post(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

}
