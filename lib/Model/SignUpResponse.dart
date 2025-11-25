class SignupResponse {
  final EmpLogin? empLogin;
  final String statusCode;
  final String status;
  final String message;


  SignupResponse({
    this.empLogin,
    required this.statusCode,
    required this.status,
    required this.message,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      empLogin:
      json['EmpLogin'] != null ? EmpLogin.fromJson(json['EmpLogin']) : null,
      statusCode: json['Status_Code']?.toString() ?? "",
      status: json['Status'] ?? "",
      message: json['Message'] ?? "",
    );
  }
}

class EmpLogin {
  final int id;
  final String empName;
  final String empCode;
  final String status;
  final String companyID;

  EmpLogin({
    required this.id,
    required this.empName,
    required this.empCode,
    required this.status,
    required this.companyID,
  });

  factory EmpLogin.fromJson(Map<String, dynamic> json) {
    return EmpLogin(
      id: json['Id'] ?? 0,
      empName: json['EmpName'] ?? "",
      empCode: json['EmpCode'] ?? "",
      status: json['Status'] ?? "",
      companyID: json['CompanyID']?.toString() ?? "",
    );
  }
}
