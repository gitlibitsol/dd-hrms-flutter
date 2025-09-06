import 'dart:convert';

class WFH_AttendanceModel {
  String? empID;
  String? empCode;
  String? address;
  String? latitude;
  String? longitude;
  String? companyId;
  String? barCodeId;
  String? attenType;
  String? dateOfThumb;
  String? timeOfThumb;
  String? fullDateTime;
  String? attenImage;
  String? punchType;
  String? location;
  String? purpose;


  WFH_AttendanceModel({
    this.empID,
    this.empCode,
    this.address,
    this.latitude,
    this.longitude,
    this.companyId,
    this.barCodeId,
    this.attenType,
    this.dateOfThumb,
    this.timeOfThumb,
    this.fullDateTime,
    this.attenImage,
    this.punchType,
    this.location,
    this.purpose,
  });

  Map<String, dynamic> toJson() {
    return {
      "EmpID": empID,
      "EmpCode": empCode,
      "Address": address,
      "Latitude": latitude,
      "Longitude": longitude,
      "CompanyId": companyId,
      "BarCodeId": barCodeId,
      "AttenType": attenType,
      "DateofThumb": dateOfThumb,
      "timeofthumb": timeOfThumb,
      "fulldatetime": fullDateTime,
      "atten_image": attenImage,
      "PunchType": punchType,
      "Location": location,
      "Purpose": purpose,
    };
  }

  static WFH_AttendanceModel fromJson(Map<String, dynamic> json) {
    return WFH_AttendanceModel(
      empID: json['EmpID'],
      empCode: json['EmpCode'],
      address: json['Address'],
      latitude: json['Latitude'],
      longitude: json['Longitude'],
      companyId: json['CompanyId'],
      barCodeId: json['BarCodeId'],
      attenType: json['AttenType'],
      dateOfThumb: json['DateofThumb'],
      timeOfThumb: json['timeofthumb'],
      fullDateTime: json['fulldatetime'],
      attenImage: json['atten_image'],
      punchType: json['PunchType'],
      location: json['Location'],
      purpose: json['Purpose'],
    );
  }
}
