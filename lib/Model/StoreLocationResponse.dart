class StoreLocationResponse {
  final String statusCode;
  final List<StoreLocation> storeList;

  StoreLocationResponse({required this.statusCode, required this.storeList});

  factory StoreLocationResponse.fromJson(Map<String, dynamic> json) {
    return StoreLocationResponse(
      statusCode: json['Status_Code'] ?? "",
      storeList: (json['StoreLocationList'] as List)
          .map((e) => StoreLocation.fromJson(e))
          .toList(),
    );
  }
}

class StoreLocation {
  final double latitude;
  final double longitude;

  StoreLocation({required this.latitude, required this.longitude});

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    return StoreLocation(
      latitude: double.parse(json['Latitude'].toString()),
      longitude: double.parse(json['Longitude'].toString()),
    );
  }
}
