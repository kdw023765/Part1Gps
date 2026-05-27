import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

import 'danger_zone.dart';

/// 위험 지역 진입 시 호출할 콜백 타입입니다.
/// UI 파트에서는 이 콜백 안에서 SnackBar, Dialog, Local Notification 등을 띄우면 됩니다.
typedef DangerZoneWarningCallback = Future<void> Function(DangerZone zone);

/// 사용자 현재 위치(GPS)를 백그라운드에서 감시하고,
/// 등록된 위험 지역 반경 안으로 들어오면 경고를 발생시키는 클래스입니다.
class Monitoring {
  bool _isListening = false;

  DangerZoneWarningCallback? _onWarning;

  /// 앱 시작 시 호출되어 지오펜싱 감시 시스템을 시작합니다.
  ///
  /// [uid]는 팀 명세서 함수 시그니처 유지를 위해 남겨두었습니다.
  /// [onWarning]에는 위험지역 진입 시 실행할 경고 로직을 넣으면 됩니다.
  Future<void> startMonitoring(
    String uid, {
    DangerZoneWarningCallback? onWarning,
  }) async {
    _onWarning = onWarning;

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
          latitude: _toDouble(extras['latitude']),
          longitude: _toDouble(extras['longitude']),
          radius: _toDouble(extras['radius'], defaultValue: 200.0),
          isEnabled: true,
        );

        final message = makeWarningMessage(zone);
        print('[Monitoring] 위험지역 반경 진입 감지: $message');

        if (_onWarning != null) {
          await _onWarning!(zone);
        }
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

    print('[Monitoring] GPS 기반 위험지역 감시 시작 완료');
  }

  /// 현재 GPS 위치를 한 번만 가져옵니다.
  /// 화면에서 "현재 위치 기반" 버튼을 눌렀을 때 사용하면 됩니다.
  Future<bg.Location> getCurrentLocation() async {
    return bg.BackgroundGeolocation.getCurrentPosition(
      samples: 1,
      persist: false,
      timeout: 30,
      desiredAccuracy: 30,
    );
  }

  /// 사용자가 명시적으로 감시 기능을 끄고 싶을 때 호출합니다.
  Future<void> stopMonitoring(String uid) async {
    await bg.BackgroundGeolocation.stop();
    _isListening = false;
    _onWarning = null;

    print('[Monitoring] GPS 기반 위험지역 감시 중지 완료');
  }

  /// 기본 경고 문구 생성
  String makeWarningMessage(DangerZone zone) {
    return '${zone.zoneName} 위험 반경 근처입니다. 지출 주의하세요!';
  }

  double _toDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
