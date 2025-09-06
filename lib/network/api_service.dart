import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../Model/StoreLocationResponse.dart';
import '../Model/WFH_AttendanceModel.dart';
import '../Model/attendance_model.dart';
import '../Model/login_model.dart';


class ApiService {

  static const String baseUrl = 'http://35.200.253.184/dawadostapi/';

  Future<LoginResponse> login(String mobileNo) async {
    try {
      final uri = Uri.parse('${baseUrl}api/EmployeeLogin')
          .replace(queryParameters: {"mobileNo": mobileNo});

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to login: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Login API error: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAttendance(String empId) async {
    final formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    final uri = Uri.parse('${baseUrl}api/DailyMobileAttendence')
        .replace(queryParameters: {
      "EmpID": empId,
      "Date": formattedDate,
    });

    try {
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Attendance API error: $e');
    }
  }

  Future<Map<String, dynamic>> uploadAttendance(AttendanceModel model) async {
    try {
      final uri = Uri.parse('${baseUrl}api/InsertData');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(model.toJson()), // 👈 sending body like @Body in Retrofit
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to upload attendance: $e');
    }
  }

  Future<Map<String, dynamic>> uploadWFHAttendance(WFH_AttendanceModel model) async {
    try {
      final uri = Uri.parse('${baseUrl}api/InsertDataWithoutQRCode');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(model.toJson()), // 👈 same as @Body in Retrofit
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload WFH attendance: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to upload WFH attendance: $e');
    }
  }

  /// ✅ Get Store Location API (with query param like Retrofit)
  Future<StoreLocationResponse> getStoreLocation(String storeId) async {
    try {
      final uri = Uri.parse('${baseUrl}api/GetStoreLocation')
          .replace(queryParameters: {"StoreID": storeId});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return StoreLocationResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to fetch store location: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching store location: $e');
    }
  }

}
