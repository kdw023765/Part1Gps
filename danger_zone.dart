/// 사용자가 설정한 위험 지역(쇼핑몰, 백화점 등) 정보를 담는 데이터 모델 클래스입니다.
class DangerZone {
  final String docId;        // Firestore 문서의 고유 ID (지오펜싱 식별자로도 사용됨)
  final String zoneName;     // 위험 지역의 이름 (예: "스타필드 코엑스")
  final String zoneCategory; // 카테고리 (mall / dept / entertainment / etc 등)
  final double latitude;     // 해당 장소의 위도
  final double longitude;    // 해당 장소의 경도
  final double radius;       // 지오펜스 반경(m)
  final bool isEnabled;      // 위험 지역 감시 활성화 여부

  DangerZone({
    required this.docId,
    required this.zoneName,
    required this.zoneCategory,
    required this.latitude,
    required this.longitude,
    this.radius = 200.0,
    this.isEnabled = true,
  });

  /// 앱 메모리에 있는 이 객체를 Firestore DB에 저장하기 위해 JSON(Map) 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    return {
      'docId': docId,
      'zoneName': zoneName,
      'zoneCategory': zoneCategory,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isEnabled': isEnabled,
    };
  }

  /// Firestore DB나 지오펜스 이벤트에서 읽어온 JSON(Map) 데이터를 DangerZone 객체로 변환합니다.
  factory DangerZone.fromMap(Map<String, dynamic> map) {
    return DangerZone(
      docId: (map['docId'] ?? '').toString(),
      zoneName: (map['zoneName'] ?? '').toString(),
      zoneCategory: (map['zoneCategory'] ?? 'etc').toString(),
      latitude: _toDouble(map['latitude']),
      longitude: _toDouble(map['longitude']),
      radius: _toDouble(map['radius'], defaultValue: 200.0),
      isEnabled: map['isEnabled'] is bool ? map['isEnabled'] as bool : true,
    );
  }

  static double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
