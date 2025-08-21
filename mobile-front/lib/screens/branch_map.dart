// lib/screens/branch_map.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterNaverMap().init(
    clientId: 'e3twx8ckch', // NCP Key ID
    onAuthFailed: (ex) => debugPrint('NAVER AUTH FAIL: $ex'),
  );

  runApp(const BranchMapApp());
}

class BranchMapApp extends StatelessWidget {
  const BranchMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BranchMapScreen(),
    );
  }
}

/* ------------------------------- 모델 ------------------------------- */
class Branch {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/* 예시 데이터 (부산 근처 임의 좌표) — 추후 REST 연동으로 교체 */
const List<Branch> kSampleBranches = [
  Branch(
    id: 1,
    name: '부산은행 본점(예시)',
    address: '부산시 중구 중앙대로',
    lat: 35.1019,
    lng: 129.0336,
  ),
  Branch(
    id: 2,
    name: 'W스퀘어점(예시)',
    address: '부산시 남구 신선로',
    lat: 35.1170,
    lng: 129.1100,
  ),
  Branch(
    id: 3,
    name: '센텀시티점(예시)',
    address: '부산시 해운대구 센텀서로',
    lat: 35.1693,
    lng: 129.1310,
  ),
];

/* ------------------------------- 화면 ------------------------------- */
class BranchMapScreen extends StatefulWidget {
  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  static const NLatLng _busan = NLatLng(35.1796, 129.0756);

  NaverMapController? _mapController;
  final _searchCtl = TextEditingController();

  bool _mapReady = false;
  NLatLng? _myLatLng;

  // 마커 보관
  final Map<int, NMarker> _markerById = {};

  // 필터 결과
  List<Branch> _within3km = [];
  static const double _radiusMeters = 3000;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 지도
            SizedBox(
              height: media.size.height * 0.33,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NaverMap(
                      options: const NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: _busan, // GPS 준비 전까지는 부산 고정
                          zoom: 12,
                        ),
                        locationButtonEnable: false, // 내장 버튼 비활성화
                      ),
                      onMapReady: (controller) async {
                        _mapController = controller;

                        // 파란 현재 위치 점 보이기
                        controller.getLocationOverlay().setIsVisible(true);

                        // 권한/서비스 확인
                        final ok = await _ensureLocationReady();

                        if (ok) {
                          // 현재 위치 가져오기
                          final pos = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.best,
                          );
                          _myLatLng = NLatLng(pos.latitude, pos.longitude);

                          // 카메라 부산 -> 내 위치로 이동
                          await controller.updateCamera(
                            NCameraUpdate.scrollAndZoomTo(
                              target: _myLatLng!,
                              zoom: 14,
                            ),
                          );

                          // 추적 모드 ON (void 반환)
                          controller.setLocationTrackingMode(
                            NLocationTrackingMode.follow,
                          );
                        }

                        // 마커/목록 초기 렌더
                        _refreshMarkersAndList();
                        setState(() => _mapReady = true);
                      },
                    ),
                  ),

                  // 커스텀 "내 위치" 버튼
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () async {
                        final target = _myLatLng ?? _busan;
                        await _mapController?.updateCamera(
                          NCameraUpdate.scrollAndZoomTo(
                            target: target,
                            zoom: _myLatLng == null ? 12 : 14,
                          ),
                        );
                        if (_myLatLng != null) {
                          _mapController?.setLocationTrackingMode(
                            NLocationTrackingMode.follow,
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),

                  if (!_mapReady)
                    const Positioned.fill(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),

            // 검색창
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchCtl,
                decoration: InputDecoration(
                  hintText: '지점명/주소 검색',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => _refreshMarkersAndList(),
              ),
            ),

            // 목록
            Expanded(child: _buildListView()),
          ],
        ),
      ),
    );
  }

  /* ----------------------------- 목록 UI ---------------------------- */
  Widget _buildListView() {
    if (_myLatLng == null) {
      return const Center(child: Text('현재 위치를 확인 중입니다...'));
    }
    if (_within3km.isEmpty) {
      return const Center(child: Text('반경 3km 내 영업점이 없습니다.'));
    }

    return ListView.separated(
      itemCount: _within3km.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = _within3km[index];
        final d = _distanceMeters(
          _myLatLng!.latitude,
          _myLatLng!.longitude,
          b.lat,
          b.lng,
        );

        return ListTile(
          title: Text(b.name),
          subtitle: Text('${b.address}\n약 ${(d / 1000).toStringAsFixed(2)} km'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            final target = NLatLng(b.lat, b.lng);
            _mapController?.updateCamera(
              NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16),
            );
            final mk = _markerById[b.id];
            mk?.setCaption(NOverlayCaption(text: b.name));
          },
        );
      },
    );
  }

  /* ------------------------ 필터 & 마커 렌더 ------------------------ */
  void _refreshMarkersAndList() {
    // 검색/필터 준비 전에는 목록만 초기화
    final my = _myLatLng;
    if (_mapController == null) {
      setState(() {});
      return;
    }

    // 1) 검색어
    final q = _searchCtl.text.trim();
    bool match(Branch b) =>
        q.isEmpty || b.name.contains(q) || b.address.contains(q);

    // 2) 반경 3km 필터 (내 위치가 있을 때만 거리 필터)
    final filtered = <Branch>[];
    for (final b in kSampleBranches) {
      if (!match(b)) continue;
      if (my == null) {
        filtered.add(b);
        continue;
      }
      final d = _distanceMeters(my.latitude, my.longitude, b.lat, b.lng);
      if (d <= _radiusMeters) filtered.add(b);
    }
    _within3km = my == null ? [] : filtered;

    // 3) 지도 마커 갱신
    if (_markerById.isNotEmpty) {
      for (final mk in _markerById.values) {
        _mapController!.deleteOverlay(mk as NOverlayInfo); // setMap(null) 대신
      }
      _markerById.clear();
    }

    if (my != null) {
      for (final b in _within3km) {
        final mk = NMarker(
          id: 'branch_${b.id}',
          position: NLatLng(b.lat, b.lng),
        );

        mk.setOnTapListener((overlay) {
          _mapController?.updateCamera(
            NCameraUpdate.scrollAndZoomTo(
              target: NLatLng(b.lat, b.lng),
              zoom: 16,
            ),
          );
          mk.setCaption(NOverlayCaption(text: b.name));
        });

        _mapController!.addOverlay(mk); // 지도에 추가
        _markerById[b.id] = mk;
      }
    }

    setState(() {});
  }

  /* ------------------------- 권한/서비스 체크 ------------------------ */
  Future<bool> _ensureLocationReady() async {
    // 서비스 ON?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 권한
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /* --------------------------- 거리 계산 --------------------------- */
  // Haversine (미터)
  double _distanceMeters(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371000.0; // 지구 반지름(m)
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
}
