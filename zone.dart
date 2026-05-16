import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../constants/app_constants.dart';
import 'danger_zone.dart';
import 'nagging_request.dart';

/// 위험 지역의 DB 저장 및 OS 지오펜싱 하드웨어 등록, 예산 데이터 융합을 담당합니다.
class Zone {
  // Firestore DB에 접근하기 위한 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 새로운 위험 지역을 추가할 때 호출되는 함수입니다. (명세서 1-3)
  Future<void> addDangerZone(DangerZone zone) async {
    // 1. 파트 2 담당자가 정해둔 공통 상수(CollectionKeys.dangerZones)를 써서 DB에 저장합니다.
    await _firestore
        .collection(CollectionKeys.dangerZones)
        .doc(zone.docId)
        .set(zone.toMap());

    // 2. DB 저장과 동시에 스마트폰 OS의 백그라운드 지오펜싱 목록에 이 장소를 등록합니다.
    await bg.BackgroundGeolocation.addGeofence(bg.Geofence(
      identifier: zone.docId,        // DB의 문서 ID와 동일하게 맞춰서 동기화
      radius: 200,                   // 명세서 요구사항에 따른 반경 200m 설정
      latitude: zone.latitude,
      longitude: zone.longitude,
      notifyOnEntry: true,           // 진입(ENTER) 시점에 이벤트를 발생시킴
      notifyOnExit: false,           // 영역 밖으로 나갈 때(EXIT)는 이벤트를 무시 (불필요한 알림 방지)
      extras: {
        'zoneName': zone.zoneName,   // 나중에 진입 이벤트가 터졌을 때 꺼내 쓰기 위해 저장해 둠
        'zoneCategory': zone.zoneCategory,
      },
    ));
  }

  /// 특정 위험 지역의 감시 상태를 켜거나(ON) 끕니다(OFF). (명세서 1-4)
  Future<void> toggleZone(String docId, bool isEnabled) async {
    // 1. DB의 isEnabled(활성화 여부) 값을 업데이트합니다.
    await _firestore
        .collection(CollectionKeys.dangerZones)
        .doc(docId)
        .update({'isEnabled': isEnabled});

    // 2. DB 업데이트 후 실제 기기의 감시 로직도 동기화합니다.
    if (!isEnabled) {
      // 껐을 경우: 하드웨어 감시 리스트에서 해당 장소를 즉각 삭제합니다.
      await bg.BackgroundGeolocation.removeGeofence(docId);
    } else {
      // 켰을 경우: DB에서 최신 정보를 다시 불러와서 하드웨어 감시 리스트에 재등록합니다.
      final doc = await _firestore.collection(CollectionKeys.dangerZones).doc(docId).get();
      if (doc.exists && doc.data() != null) {
        final zone = DangerZone.fromMap(doc.data()!);
        await bg.BackgroundGeolocation.addGeofence(bg.Geofence(
          identifier: zone.docId,
          radius: 200,
          latitude: zone.latitude,
          longitude: zone.longitude,
          notifyOnEntry: true,
          notifyOnExit: false,
          extras: {
            'zoneName': zone.zoneName,
            'zoneCategory': zone.zoneCategory,
          },
        ));
      }
    }
  }

  /// 사용자가 위험 지역에 '진입'했을 때 파트 2의 예산 정보를 긁어오는 핵심 함수입니다. (명세서 1-5)
  Future<NaggingRequest> onZoneEntered(DangerZone zone) async {
    // 1. 현재 앱에 로그인되어 있는 사용자의 UID를 가져옵니다.
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    final now = DateTime.now();
    
    // 2. 파트 2(송종민 님)가 설계한 예산 문서의 이름 규칙(예: "2026-05")을 생성합니다.
    final String currentYearMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // 3. 파트 2의 DB 경로 규칙(users/{uid}/budgets/{YYYY-MM})에 따라 실시간 예산 문서를 읽어옵니다.
    final budgetDoc = await _firestore
        .collection(CollectionKeys.users)
        .doc(uid)
        .collection(CollectionKeys.budgets)
        .doc(currentYearMonth)
        .get();

    // 값을 담을 빈 변수들 준비
    int todayBudget = 0;
    int remainingBudget = 0;
    double budgetUsageRate = 0.0;

    // 4. 파트 2 DB 문서가 실제로 존재하면, app_constants에 정의된 필드명 규칙으로 값을 추출합니다.
    if (budgetDoc.exists && budgetDoc.data() != null) {
      final data = budgetDoc.data()!;
      todayBudget = (data[BudgetKeys.todayBudget] ?? 0).toInt();
      remainingBudget = (data[BudgetKeys.remainingBudget] ?? 0).toInt();
      budgetUsageRate = (data[BudgetKeys.budgetUsageRate] ?? 0.0).toDouble();
    }

    // 5. 파트 1 정보(장소)와 파트 2 정보(돈)를 결합하여 최종적으로 파트 4(AI)로 보낼 객체를 반환합니다.
    return NaggingRequest(
      uid: uid,
      zoneName: zone.zoneName,
      zoneCategory: zone.zoneCategory,
      todayBudget: todayBudget,
      remainingBudget: remainingBudget,
      budgetUsageRate: budgetUsageRate,
      enteredAt: now,
    );
  }
}
