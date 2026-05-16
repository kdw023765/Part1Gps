class DangerZone {
  final String docId;
  final String zoneName;
  final String zoneCategory; // app_constants.dart 의 DangerZoneCategories 사용
  final double latitude;
  final double longitude;

  DangerZone({
    required this.docId,
    required this.zoneName,
    required this.zoneCategory,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'zoneName': zoneName,
      'zoneCategory': zoneCategory,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
