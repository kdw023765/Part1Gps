import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

import 'danger_zone.dart';
import 'nagging_request.dart';

/// 위험 지역의 DB 저장 및 OS 지오펜싱 하드웨어 등록, 예산 데이터 융합을 담당합니다.
class Zone {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 현재 로그인된 사용자 UID 반환
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';

  /// users/{uid}/dangerZones 경로 반환
  CollectionReference<Map<String, dynamic>> get _dangerZoneCollection {
    return _firestore
        .collection('users')
        .doc(_uid)
        .collection('dangerZones');
  }

  /// 위험 지역 실시간 목록 스트림
  Stream<List<DangerZone>> getDangerZonesStream() {
    return _dangerZoneCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DangerZone.fromMap(doc.data()))
          .toList();
    });
  }

  /// 활성화된 위험 지역 개수 스트림
  Stream<int> enabledDangerZoneCountStream() {
    return _dangerZoneCollection.snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isEnabled'] == true;
      }).length;
    });
  }

  /// 새로운 위험 지역 추가
  Future<void> addDangerZone(DangerZone zone) async {
    await _dangerZoneCollection.doc(zone.docId).set(zone.toMap());

    await bg.BackgroundGeolocation.addGeofence(
      bg.Geofence(
        identifier: zone.docId,
        radius: zone.radius,
        latitude: zone.latitude,
        longitude: zone.longitude,
        notifyOnEntry: true,
        notifyOnExit: false,
        extras: {
          'zoneName': zone.zoneName,
          'zoneCategory': zone.zoneCategory,
        },
      ),
    );
  }

  /// 위험 지역 삭제
  Future<void> deleteDangerZone(String docId) async {
    await _dangerZoneCollection.doc(docId).delete();

    try {
      await bg.BackgroundGeolocation.removeGeofence(docId);
    } catch (e) {
      print('[Zone] 지오펜스 제거 실패: $e');
    }
  }

  /// 위험 지역 감시 ON / OFF
  Future<void> toggleZone(String docId, bool isEnabled) async {
    await _dangerZoneCollection.doc(docId).update({
      'isEnabled': isEnabled,
    });

    if (!isEnabled) {
      await bg.BackgroundGeolocation.removeGeofence(docId);
      return;
    }

    final doc = await _dangerZoneCollection.doc(docId).get();

    if (!doc.exists || doc.data() == null) {
      return;
    }

    final zone = DangerZone.fromMap(doc.data()!);

    await bg.BackgroundGeolocation.addGeofence(
      bg.Geofence(
        identifier: zone.docId,
        radius: zone.radius,
        latitude: zone.latitude,
        longitude: zone.longitude,
        notifyOnEntry: true,
        notifyOnExit: false,
        extras: {
          'zoneName': zone.zoneName,
          'zoneCategory': zone.zoneCategory,
        },
      ),
    );
  }

  /// 위험 지역 진입 시 예산 정보와 합쳐 AI 서버 요청 데이터 생성
  Future<NaggingRequest> onZoneEntered(DangerZone zone) async {
    final now = DateTime.now();

    final currentYearMonth =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final budgetDoc = await _firestore
        .collection('users')
        .doc(_uid)
        .collection('budgets')
        .doc(currentYearMonth)
        .get();

    int todayBudget = 0;
    int remainingBudget = 0;
    double budgetUsageRate = 0.0;

    if (budgetDoc.exists && budgetDoc.data() != null) {
      final data = budgetDoc.data()!;

      todayBudget = (data['todayBudget'] ?? 0).toInt();
      remainingBudget = (data['remainingBudget'] ?? 0).toInt();

      final usage = data['budgetUsageRate'] ?? 0.0;
      if (usage is num) {
        budgetUsageRate = usage.toDouble();
      }
    }

    return NaggingRequest(
      uid: _uid,
      zoneName: zone.zoneName,
      zoneCategory: zone.zoneCategory,
      todayBudget: todayBudget,
      remainingBudget: remainingBudget,
      budgetUsageRate: budgetUsageRate,
      enteredAt: now,
    );
  }
}
