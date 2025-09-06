class LoginResponse {
  final Map<String, dynamic>? empLogin;
  final String statusCode;
  final String status;
  final String message;

  LoginResponse({
    required this.empLogin,
    required this.statusCode,
    required this.status,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      empLogin: json['EmpLogin'],
      statusCode: json['Status_Code'] ?? "",
      status: json['Status'] ?? "",
      message: json['Message'] ?? "",
    );
  }
}
