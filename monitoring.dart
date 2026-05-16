import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'zone.dart';
import 'danger_zone.dart';

/// 백그라운드 위치 추적 및 지오펜싱 하드웨어 이벤트를 관리하는 클래스입니다.
class Monitoring {
  
  /// 앱 시작 시 호출되어 지오펜싱 감시 시스템을 시동합니다.
  void startMonitoring(String uid) {
    
    // 1. 이벤트 리스너 등록: 사용자가 설정된 반경(200m)을 넘나들 때마다 이 코드가 실행됩니다.
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) async {
      // 'ENTER'는 위험 지역 반경 안으로 '진입'했음을 의미합니다.
      if (event.action == 'ENTER') {
        // 이벤트와 함께 저장해 둔 추가 정보(extras)를 꺼냅니다.
        final extras = event.extras ?? {};
        
        // 하드웨어 이벤트 정보만으로는 부족하므로, 임시로 DangerZone 객체를 복원합니다.
        final zone = DangerZone(
          docId: event.identifier, // 설정했던 문서 ID
          zoneName: extras['zoneName'] ?? '알 수 없는 위험 지역',
          zoneCategory: extras['zoneCategory'] ?? 'etc',
          latitude: 0.0,  // 진입 시점에는 좌표 자체보다 장소 정보가 중요하므로 임의값
          longitude: 0.0,
        );

        // 2. 파트 2의 예산 데이터와 융합하기 위해 Zone 클래스의 함수를 호출합니다.
        Zone zoneController = Zone();
        final request = await zoneController.onZoneEntered(zone);
        
        // 3. TODO: 여기서 최종 생성된 request 객체를 파트 4(AI) 서버로 쏘는 로직이 들어갑니다.
        print('[Monitoring] AI 전달용 데이터 생성: ${request.toJson()}');
      }
    });

    // 4. 플러그인 환경 설정 및 엔진 시동
    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.ACCURACY_HIGH, // GPS 정확도 최상 (배터리 소모가 있지만 정확함)
      distanceFilter: 10.0,                     // 10미터 이동할 때마다 위치 갱신
      stopOnTerminate: false,                   // ⭐️ 사용자가 앱을 강제 종료해도 백그라운드 감시 유지
      startOnBoot: true,                        // ⭐️ 스마트폰을 껐다 켜도 자동으로 감시 재시작
      logLevel: bg.Config.LOG_LEVEL_OFF,        // 콘솔에 플러그인 자체 로그가 너무 많이 찍히는 것을 방지
    )).then((bg.State state) {
      // 엔진이 정상적으로 켜졌는데 지오펜스 추적이 꺼져있다면 추적을 시작합니다.
      if (!state.enabled) {
        bg.BackgroundGeolocation.startGeofences();
      }
    });
  }

  /// 사용자가 명시적으로 감시 기능을 완전히 끄고 싶을 때 호출합니다.
  void stopMonitoring(String uid) {
    bg.BackgroundGeolocation.stop(); // 하드웨어 위치 추적 완전 중단
  }
}
