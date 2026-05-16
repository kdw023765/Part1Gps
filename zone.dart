import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'danger_zone.dart';
import 'nagging_request.dart';

class Zone {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 위험 지역 추가 (Firestore + 기기 지오펜스 등록)
  Future<void> addDangerZone(DangerZone zone) async {
    await _firestore.collection('danger_zones').doc(zone.docId).set(zone.toMap());

    await bg.BackgroundGeolocation.addGeofence(bg.Geofence(
      identifier: zone.docId,
      radius: 200, 
      latitude: zone.latitude,
      longitude: zone.longitude,
      notifyOnEntry: true,
      notifyOnExit: false,
      extras: {
        'zoneCategory': zone.zoneCategory,
        'zoneName': zone.zoneName,
      }
    ));
  }

  // 위험 지역 상태 토글
  Future<void> toggleZone(String docId, bool isEnabled) async {
    await _firestore.collection('danger_zones').doc(docId).update({
      'isEnabled': isEnabled,
    });

    if (!isEnabled) {
      await bg.BackgroundGeolocation.removeGeofence(docId);
    } else {
      // 켜는 경우 DB에서 다시 불러와서 addGeofence를 해주는 로직이 추가로 필요할 수 있음
    }
  }

  // 진입 시 파트 2(DB)에서 예산 정보 조회 후 Request 객체 반환
  Future<NaggingRequest> onZoneEntered(String uid, bg.GeofenceEvent event) async {
    final extras = event.extras ?? {};
    final zoneName = extras['zoneName'] ?? '알 수 없는 지역';
    final zoneCategory = extras['zoneCategory'] ?? 'etc';

    // 파트 2(송종민) DB 연동
    final budgetDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .doc('current')
        .get();

    int todayBudget = 0;
    int remainingBudget = 0;
    double budgetUsageRate = 0.0;

    if (budgetDoc.exists && budgetDoc.data() != null) {
      final data = budgetDoc.data()!;
      todayBudget = data['todayBudget'] ?? 0;
      remainingBudget = data['remainingBudget'] ?? 0;
      budgetUsageRate = (data['budgetUsageRate'] ?? 0.0).toDouble();
    }

    return NaggingRequest(
      uid: uid,
      zoneName: zoneName,
      zoneCategory: zoneCategory,
      todayBudget: todayBudget,
      remainingBudget: remainingBudget,
      budgetUsageRate: budgetUsageRate,
      enteredAt: DateTime.now(),
    );
  }
}
