import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

import 'danger_zone.dart';
import 'zone.dart';

/// 백그라운드 위치 추적 및 지오펜싱 이벤트를 관리하는 클래스입니다.
class Monitoring {
  bool _isListening = false;

  /// 앱 시작 시 호출되어 지오펜싱 감시 시스템을 시동합니다.
  Future<void> startMonitoring(String uid) async {
    if (_isListening) {
      print('[Monitoring] 이미 감시 중입니다.');
      return;
    }

    _isListening = true;

    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) async {
      try {
        if (event.action != 'ENTER') {
          return;
        }

        final extras = event.extras ?? {};

        final zone = DangerZone(
          docId: event.identifier,
          zoneName: extras['zoneName']?.toString() ?? '알 수 없는 위험 지역',
          zoneCategory: extras['zoneCategory']?.toString() ?? 'etc',
          latitude: 0.0,
          longitude: 0.0,
        );

        final zoneController = Zone();
        final request = await zoneController.onZoneEntered(zone);

        /// TODO:
        /// 1. FastAPI /ai/nag 엔드포인트로 request.toJson() 전송
        /// 2. 응답 메시지를 로컬 알림 또는 Firebase Messaging으로 표시
        print('[Monitoring] AI 전달용 데이터 생성 완료');
        print(request.toJson());
      } catch (e) {
        print('[Monitoring] 지오펜스 이벤트 처리 실패: $e');
      }
    });

    final state = await bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: false,
        startOnBoot: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE,
        geofenceModeHighAccuracy: true,
        enableHeadless: true,
      ),
    );

    if (!state.enabled) {
      await bg.BackgroundGeolocation.startGeofences();
    }

    print('[Monitoring] 백그라운드 지오펜싱 시작 완료');
  }

  /// 사용자가 명시적으로 감시 기능을 끄고 싶을 때 호출
  Future<void> stopMonitoring(String uid) async {
    await bg.BackgroundGeolocation.stop();
    _isListening = false;

    print('[Monitoring] 백그라운드 지오펜싱 중지 완료');
  }
}
