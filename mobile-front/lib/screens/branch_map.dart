import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NaverMapSdk.instance.initialize(
    clientId: 'e3twx8ckch', // 콘솔의 Client ID 정확히
    onAuthFailed: (e) => debugPrint('NAVER AUTH FAIL: $e'),
  );

  runApp(const BranchMapApp());
}

class BranchMapApp extends StatelessWidget {
  const BranchMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: NCameraPosition(
              target: NLatLng(35.1796, 129.0756), // 부산 근처
              zoom: 12,
            ),
            locationButtonEnable: true,
          ),
        ),
      ),
    );
  }
}
