import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'danger_zone.dart';
import 'zone.dart';

/// 파트 1 위험지역 추가/목록/ON-OFF 화면 예시입니다.
/// 실제 프로젝트에서는 lib/screens/danger_zone_screen.dart 로 옮겨서 사용하세요.
class DangerZoneScreen extends StatefulWidget {
  const DangerZoneScreen({super.key});

  @override
  State<DangerZoneScreen> createState() => _DangerZoneScreenState();
}

class _DangerZoneScreenState extends State<DangerZoneScreen> {
  final Zone _zoneService = Zone();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController(text: 'mall');
  final TextEditingController _radiusController = TextEditingController(text: '200');

  LatLng _selectedPosition = const LatLng(37.5665, 126.9780); // 기본값: 서울 시청 근처
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _addDangerZone() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim().isEmpty
        ? 'etc'
        : _categoryController.text.trim();
    final radius = double.tryParse(_radiusController.text.trim()) ?? 200.0;

    if (name.isEmpty) {
      _showMessage('위험지역 이름을 입력하세요.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final zone = DangerZone(
        docId: DateTime.now().millisecondsSinceEpoch.toString(),
        zoneName: name,
        zoneCategory: category,
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        radius: radius,
        isEnabled: true,
      );

      await _zoneService.addDangerZone(zone);

      _nameController.clear();
      _showMessage('위험지역이 추가되었습니다.');
    } catch (e) {
      _showMessage('위험지역 추가 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위험지역 관리'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15,
              ),
              onTap: (LatLng position) {
                setState(() => _selectedPosition = position);
              },
              markers: {
                Marker(
                  markerId: const MarkerId('selectedDangerZone'),
                  position: _selectedPosition,
                  infoWindow: const InfoWindow(title: '선택한 위험지역'),
                ),
              },
              circles: {
                Circle(
                  circleId: const CircleId('dangerZoneRadius'),
                  center: _selectedPosition,
                  radius: double.tryParse(_radiusController.text.trim()) ?? 200.0,
                  strokeWidth: 2,
                  fillColor: Colors.red.withOpacity(0.15),
                  strokeColor: Colors.red,
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '위험지역 이름',
                    hintText: '예: 스타필드 코엑스',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: '카테고리',
                    hintText: 'mall / dept / entertainment / etc',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _radiusController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '반경(m)',
                    hintText: '예: 200',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _addDangerZone,
                    child: Text(_isSaving ? '저장 중...' : '위험지역 추가'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
