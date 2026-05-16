import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

class Monitoring {
  void startMonitoring(String uid) {
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      // 진입(ENTER) 시 이벤트 처리 (Zone 클래스와 연동 필요)
      print('[Geofence] 진입 감지: ${event.identifier}');
    });

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      logLevel: bg.Config.LOG_LEVEL_OFF, // 불필요한 로그 끔
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.startGeofences();
      }
    });
  }

  void stopMonitoring(String uid) {
    bg.BackgroundGeolocation.stop();
  }
}
