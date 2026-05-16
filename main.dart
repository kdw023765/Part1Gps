import 'package:flutter/material.dart';
import 'monitoring.dart';
import 'zone.dart';

void main() {
  runApp(const MaterialApp(
    home: Part1GpsMainScreen(),
  ));
}

class Part1GpsMainScreen extends StatefulWidget {
  const Part1GpsMainScreen({super.key});

  @override
  State<Part1GpsMainScreen> createState() => _Part1GpsMainScreenState();
}

class _Part1GpsMainScreenState extends State<Part1GpsMainScreen> {
  final Monitoring _monitoring = Monitoring();
  final String _uid = "user_999"; 

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 감시 켜기
    _monitoring.startMonitoring(_uid);
  }

  @override
  void dispose() {
    _monitoring.stopMonitoring(_uid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('파트 1: GPS 위치 가드')),
      body: const Center(
        child: Text('GPS 감시 백그라운드 실행 중... (Mock Location 앱으로 테스트)'),
      ),
    );
  }
}
