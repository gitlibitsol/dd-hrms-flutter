import 'dart:convert';

class Attendance {
  final String empName;
  final String empInTime;
  final String empOutTime;

  Attendance({required this.empName, required this.empInTime, required this.empOutTime});

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      empName: json['EmpName'],
      empInTime: json['EmpInTime'],
      empOutTime: json['EmpOutTime'],
    );
  }
}
