// lib/screens/branch_map.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;

/*
  ✅ 서버 의존 제거 + 주소 지오코딩 + (권장) 네이버 장소검색 프록시 연동
  - 기본: 로컬 주소 목록 + 기기 지오코딩(geocoding)으로 좌표 보완하여 마커
  - 정확모드(네이버): 프록시 서버를 통해 네이버 '부산은행' POI 검색 → 정확 좌표 마커
*/

/// ◆ 프록시 서버 주소(반드시 본인 서버 주소로 변경)
const String PROXY_BASE = 'https://YOUR_PROXY_HOST'; // 예: https://api.myapp.com

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
  final double lat; // 0이면 좌표 없음(주소만 있음)
  final double lng; // 0이면 좌표 없음(주소만 있음)

  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

/// 네이버 장소검색(프록시)에서 받는 POI 모델(프록시가 lat/lng로 변환해 준다고 가정)
class Poi {
  final String title;
  final String roadAddress;
  final double lat;
  final double lng;

  Poi({
    required this.title,
    required this.roadAddress,
    required this.lat,
    required this.lng,
  });

  factory Poi.fromJson(Map<String, dynamic> j) => Poi(
    title: (j['title'] ?? '') as String,
    roadAddress: (j['roadAddress'] ?? j['address'] ?? '') as String,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
  );
}

/*
  🔧 여기에 네가 가진 지점 데이터로 채워넣어.
  - lat/lng 없는 건 0으로 두면 주소 기반 지오코딩을 시도한다.
  - 실제 운영 시엔 assets/json로 빼는 걸 권장.
*/
const List<Branch> LOCAL_BRANCHES = [
  Branch(id: 1,  name: '중앙대로지점',       address: '부산광역시 부산진구 (범천동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 2,  name: '범일로지점',         address: '부산광역시 동구 (범일동) 범일로', lat: 0, lng: 0),
  Branch(id: 3,  name: '중앙대로지점',       address: '부산광역시 동구 (범일동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 4,  name: '법원로지점',         address: '부산광역시 연제구 (거제동) 법원로', lat: 0, lng: 0),
  Branch(id: 5,  name: '법원로지점',         address: '부산광역시 연제구 (거제동) 법원로', lat: 0, lng: 0),
  Branch(id: 6,  name: '센텀3로지점',        address: '부산광역시 해운대구 (우동) 센텀3로', lat: 0, lng: 0),
  Branch(id: 7,  name: '태종로지점',         address: '부산광역시 영도구 (봉래동3가) 태종로', lat: 0, lng: 0),
  Branch(id: 8,  name: '부곡로지점',         address: '부산광역시 금정구 (부곡동) 부곡로', lat: 0, lng: 0),
  Branch(id: 9,  name: '문현금융로지점',     address: '부산광역시 남구 (문현동) 문현금융로', lat: 0, lng: 0),
  Branch(id: 10, name: '명지국제7로지점',    address: '부산광역시 강서구 (명지동) 명지국제7로', lat: 0, lng: 0),
  Branch(id: 11, name: '명지국제7로지점',    address: '부산광역시 강서구 (명지동) 명지국제7로', lat: 0, lng: 0),
  Branch(id: 12, name: '화지로지점',         address: '부산광역시 부산진구 (양정동) 화지로', lat: 0, lng: 0),
  Branch(id: 13, name: '중앙대로지점',       address: '부산광역시 연제구 (연산동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 14, name: '금샘로485지점',      address: '부산광역시 금정구 (남산동) 금샘로485', lat: 0, lng: 0),
  Branch(id: 15, name: '시민공원로지점',     address: '부산광역시 부산진구 (부암동) 시민공원로', lat: 0, lng: 0),
  Branch(id: 16, name: '새싹로지점',         address: '부산광역시 부산진구 (부전동) 새싹로', lat: 0, lng: 0),
  Branch(id: 17, name: '부전로지점',         address: '부산광역시 부산진구 (부전동) 부전로', lat: 0, lng: 0),
  Branch(id: 18, name: '중앙대로지점',       address: '부산광역시 부산진구 (부전동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 19, name: '상동로지점',         address: '경기도 부천시 (상동) 상동로', lat: 0, lng: 0),
  Branch(id: 20, name: '대청로지점',         address: '부산광역시 중구 (부평동2가) 대청로', lat: 0, lng: 0),
  Branch(id: 21, name: '낙동대로1570번길지점', address: '부산광역시 북구 (구포동) 낙동대로1570번길', lat: 0, lng: 0),
  Branch(id: 22, name: '낙동대로901번길지점',  address: '부산광역시 사상구 (감전동) 낙동대로901번길', lat: 0, lng: 0),
  Branch(id: 23, name: '대동로지점',         address: '부산광역시 사상구 (감전동) 대동로', lat: 0, lng: 0),
  Branch(id: 24, name: '사상로지점',         address: '부산광역시 사상구 (주례동) 사상로', lat: 0, lng: 0),
  Branch(id: 25, name: '아시아드대로지점',   address: '부산광역시 동래구 (사직동) 아시아드대로', lat: 0, lng: 0),
  Branch(id: 26, name: '사직북로지점',       address: '부산광역시 동래구 (사직동) 사직북로', lat: 0, lng: 0),
  Branch(id: 27, name: '미남로지점',         address: '부산광역시 동래구 (사직동) 미남로', lat: 0, lng: 0),
  Branch(id: 28, name: '낙동대로398번길지점', address: '부산광역시 사하구 (당리동) 낙동대로398번길', lat: 0, lng: 0),
  Branch(id: 29, name: '삼계중앙로지점',     address: '경상남도 김해시 (삼계동) 삼계중앙로', lat: 0, lng: 0),
  Branch(id: 30, name: '삼산로지점',         address: '울산광역시 남구 (삼산동) 삼산로', lat: 0, lng: 0),
  Branch(id: 31, name: '구덕로지점',         address: '부산광역시 서구 (토성동4가) 구덕로', lat: 0, lng: 0),
  Branch(id: 32, name: '서동로지점',         address: '부산광역시 금정구 (부곡동) 서동로', lat: 0, lng: 0),
  Branch(id: 33, name: '중앙대로691번길지점', address: '부산광역시 부산진구 (부전동) 중앙대로691번길', lat: 0, lng: 0),
  Branch(id: 34, name: '유통단지1로지점',    address: '부산광역시 강서구 (대저2동) 유통단지1로', lat: 0, lng: 0),
  Branch(id: 35, name: '세종대로지점',       address: '서울특별시 중구 (태평로2가) 세종대로', lat: 0, lng: 0),
  Branch(id: 36, name: '선수촌로지점',       address: '부산광역시 해운대구 (반여동) 선수촌로', lat: 0, lng: 0),
  Branch(id: 37, name: '아차산로지점',       address: '서울특별시 성동구 (성수동) 아차산로', lat: 0, lng: 0),
  Branch(id: 38, name: '센텀중앙로지점',     address: '부산광역시 해운대구 (우동) 센텀중앙로', lat: 0, lng: 0),
  Branch(id: 39, name: '센텀중앙로지점',     address: '부산광역시 해운대구 (재송동) 센텀중앙로', lat: 0, lng: 0),
  Branch(id: 40, name: '충무대로지점',       address: '부산광역시 서구 (암남동) 충무대로', lat: 0, lng: 0),
  Branch(id: 41, name: '송정중앙로지점',     address: '부산광역시 해운대구 (송정동) 송정중앙로', lat: 0, lng: 0),
  Branch(id: 42, name: '충렬대로지점',       address: '부산광역시 동래구 (수안동) 충렬대로', lat: 0, lng: 0),
  Branch(id: 43, name: '남천동로지점',       address: '부산광역시 수영구 (남천동) 남천동로', lat: 0, lng: 0),
  Branch(id: 44, name: '수영로지점',         address: '부산광역시 수영구 (수영동) 수영로', lat: 0, lng: 0),
  Branch(id: 45, name: '수영로741번길지점',  address: '부산광역시 수영구 (수영동) 수영로741번길', lat: 0, lng: 0),
  Branch(id: 46, name: '효원로지점',         address: '경기도 수원시 팔달구 효원로', lat: 0, lng: 0),
  Branch(id: 47, name: '고관로지점',         address: '부산광역시 동구 (수정동) 고관로', lat: 0, lng: 0),
  Branch(id: 48, name: '체육공원로399번길지점', address: '부산광역시 금정구 (두구동) 체육공원로399번길', lat: 0, lng: 0),
  Branch(id: 49, name: '경기과기대로지점',   address: '경기도 시흥시 (정왕동) 경기과기대로', lat: 0, lng: 0),
  Branch(id: 50, name: '백양대로지점',       address: '부산광역시 부산진구 (개금동) 백양대로', lat: 0, lng: 0),
  Branch(id: 51, name: '덕상로지점',         address: '부산광역시 사상구 (덕포동) 덕상로', lat: 0, lng: 0),
  Branch(id: 52, name: '신라대학길지점',     address: '부산광역시 사상구 (괘법동) 신라대학길', lat: 0, lng: 0),
  Branch(id: 53, name: '덕천로234번길지점',  address: '부산광역시 북구 (만덕동) 덕천로234번길', lat: 0, lng: 0),
  Branch(id: 54, name: '백양대로지점',       address: '부산광역시 사상구 (모라동) 백양대로', lat: 0, lng: 0),
  Branch(id: 55, name: '광복중앙로지점',     address: '부산광역시 중구 (신창동1가) 광복중앙로', lat: 0, lng: 0),
  Branch(id: 56, name: '장평로지점',         address: '부산광역시 사하구 (신평동) 장평로', lat: 0, lng: 0),
  Branch(id: 57, name: '하신번영로지점',     address: '부산광역시 사하구 (신평동) 하신번영로', lat: 0, lng: 0),
  Branch(id: 58, name: '까치고개로지점',     address: '부산광역시 서구 (아미동2가) 까치고개로', lat: 0, lng: 0),
  Branch(id: 59, name: '안락로지점',         address: '부산광역시 동래구 (안락동) 안락로', lat: 0, lng: 0),
  Branch(id: 60, name: '충렬대로지점',       address: '부산광역시 동래구 (안락동) 충렬대로', lat: 0, lng: 0),
  Branch(id: 61, name: '수암로149번길지점',  address: '울산광역시 남구 (야음동) 수암로149번길', lat: 0, lng: 0),
  Branch(id: 62, name: '중앙로지점',         address: '경상남도 양산시 (북부동) 중앙로', lat: 0, lng: 0),
  Branch(id: 63, name: '금오13길지점',       address: '경상남도 양산시 동면 금오13길', lat: 0, lng: 0),
  Branch(id: 64, name: '중앙대로지점',       address: '부산광역시 부산진구 (양정동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 65, name: '중평로지점',         address: '울산광역시 울주군 삼남면 중평로', lat: 0, lng: 0),
  Branch(id: 66, name: '국제금융로2길지점',  address: '서울특별시 영등포구 (여의도동) 국제금융로2길', lat: 0, lng: 0),
  Branch(id: 67, name: '연수로지점',         address: '부산광역시 연제구 (연산동) 연수로', lat: 0, lng: 0),
  Branch(id: 68, name: '중앙대로지점',       address: '부산광역시 연제구 (연산동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 69, name: '세병로지점',         address: '부산광역시 연제구 (연산동) 세병로', lat: 0, lng: 0),
  Branch(id: 70, name: '안연로지점',         address: '부산광역시 동래구 (안락동) 안연로', lat: 0, lng: 0),
  Branch(id: 71, name: '연제로지점',         address: '부산광역시 연제구 (연산동) 연제로', lat: 0, lng: 0),
  Branch(id: 72, name: '새싹로지점',         address: '부산광역시 부산진구 (연지동) 새싹로', lat: 0, lng: 0),
  Branch(id: 73, name: '과정로지점',         address: '부산광역시 연제구 (연산동) 과정로', lat: 0, lng: 0),
  Branch(id: 74, name: '태종로지점',         address: '부산광역시 영도구 (청학동) 태종로', lat: 0, lng: 0),
  Branch(id: 75, name: '절영로지점',         address: '부산광역시 영도구 (대교동2가) 절영로', lat: 0, lng: 0),
  Branch(id: 76, name: '웃서발로지점',       address: '부산광역시 영도구 (동삼동) 웃서발로', lat: 0, lng: 0),
  Branch(id: 77, name: '영선대로지점',       address: '부산광역시 영도구 (영선동2가) 영선대로', lat: 0, lng: 0),
  Branch(id: 78, name: '문현금융로지점',     address: '부산광역시 남구 (문현동) 문현금융로', lat: 0, lng: 0),
  Branch(id: 79, name: '대영로지점',         address: '부산광역시 중구 (영주동) 대영로', lat: 0, lng: 0),
  Branch(id: 80, name: '금강공원로지점',     address: '부산광역시 동래구 (온천동) 금강공원로', lat: 0, lng: 0),
  Branch(id: 81, name: '유엔평화로지점',     address: '부산광역시 남구 (용당동) 유엔평화로', lat: 0, lng: 0),
  Branch(id: 82, name: '안골로지점',         address: '경상남도 창원시 진해구 안골로', lat: 0, lng: 0),
  Branch(id: 83, name: '선수촌로21번길지점', address: '부산광역시 해운대구 (반여동) 선수촌로21번길', lat: 0, lng: 0),
  Branch(id: 84, name: '용호로지점',         address: '부산광역시 남구 (용호동) 용호로', lat: 0, lng: 0),
  Branch(id: 85, name: '두왕로154번길지점',  address: '울산광역시 남구 (달동) 두왕로154번길', lat: 0, lng: 0),
  Branch(id: 86, name: '학성로지점',         address: '울산광역시 중구 (학산동) 학성로', lat: 0, lng: 0),
  Branch(id: 87, name: '호계로지점',         address: '울산광역시 북구 (신천동) 호계로', lat: 0, lng: 0),
  Branch(id: 88, name: '용호로지점',         address: '부산광역시 남구 (용호동) 용호로', lat: 0, lng: 0),
  Branch(id: 89, name: '은청로지점',         address: '인천광역시 남동구 은청로', lat: 0, lng: 0),
  Branch(id: 90, name: '해빛로지점',         address: '부산광역시 기장군 (일광면) 해빛로', lat: 0, lng: 0),
  Branch(id: 91, name: '장림번영로지점',     address: '부산광역시 사하구 (장림동) 장림번영로', lat: 0, lng: 0),
  Branch(id: 92, name: '세실로지점',         address: '부산광역시 해운대구 (좌동) 세실로', lat: 0, lng: 0),
  Branch(id: 93, name: '계동로지점',         address: '경상남도 김해시 장유면 계동로', lat: 0, lng: 0),
  Branch(id: 94, name: '금정로지점',         address: '부산광역시 금정구 (장전동) 금정로', lat: 0, lng: 0),
  Branch(id: 95, name: '재반로지점',         address: '부산광역시 해운대구 (재송동) 재반로', lat: 0, lng: 0),
  Branch(id: 96, name: '전포대로지점',       address: '부산광역시 부산진구 (전포동) 전포대로', lat: 0, lng: 0),
  Branch(id: 97, name: '동천로지점',         address: '부산광역시 부산진구 (부전동) 동천로', lat: 0, lng: 0),
  Branch(id: 98, name: '정관7로지점',        address: '부산광역시 기장군 정관면 정관7로', lat: 0, lng: 0),
  Branch(id: 99, name: '정관면지점',         address: '부산광역시 기장군 (모전리) 정관면', lat: 0, lng: 0),
  Branch(id: 100, name: '대천로103번길지점', address: '부산광역시 해운대구 (좌동) 대천로103번길', lat: 0, lng: 0),
  Branch(id: 101, name: '중구로지점',        address: '부산광역시 중구 (대청동1가) 중구로', lat: 0, lng: 0),
  Branch(id: 102, name: '중앙대로지점',       address: '부산광역시 중구 (동광동1가) 중앙대로', lat: 0, lng: 0),
  Branch(id: 103, name: '중앙대로지점',       address: '부산광역시 중구 (중앙동4가) 중앙대로', lat: 0, lng: 0),
  Branch(id: 104, name: '서부로지점',        address: '경상남도 김해시 진영읍 서부로', lat: 0, lng: 0),
  Branch(id: 105, name: '중앙대로지점',       address: '경상남도 창원시 성산구 중앙대로', lat: 0, lng: 0),
  Branch(id: 106, name: '태종로지점',         address: '부산광역시 영도구 (청학동) 태종로', lat: 0, lng: 0),
  Branch(id: 107, name: '중앙대로251번길지점', address: '부산광역시 동구 (초량동) 중앙대로251번길', lat: 0, lng: 0),
  Branch(id: 108, name: '성지로지점',         address: '부산광역시 부산진구 (연지동) 성지로', lat: 0, lng: 0),
  Branch(id: 109, name: '충무대로지점',       address: '부산광역시 서구 (충무동1가) 충무대로', lat: 0, lng: 0),
  Branch(id: 110, name: '과정로지점',         address: '부산광역시 연제구 (연산동) 과정로', lat: 0, lng: 0),
  Branch(id: 111, name: '중앙대로지점',       address: '부산광역시 금정구 (남산동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 112, name: '고덕중앙로지점',     address: '경기도 평택시 (고덕동) 고덕중앙로', lat: 0, lng: 0),
  Branch(id: 113, name: '하신중앙로지점',     address: '부산광역시 사하구 (하단동) 하신중앙로', lat: 0, lng: 0),
  Branch(id: 114, name: '대동로지점',         address: '부산광역시 사상구 (학장동) 대동로', lat: 0, lng: 0),
  Branch(id: 115, name: '중동2로지점',        address: '부산광역시 해운대구 (중동) 중동2로', lat: 0, lng: 0),
  Branch(id: 116, name: '중동1로지점',        address: '부산광역시 해운대구 (중동) 중동1로', lat: 0, lng: 0),
  Branch(id: 117, name: '해운대로지점',       address: '부산광역시 해운대구 (우동) 해운대로', lat: 0, lng: 0),
  Branch(id: 118, name: '화명신도시로지점',   address: '부산광역시 북구 (화명동) 화명신도시로', lat: 0, lng: 0),
  Branch(id: 119, name: '학사로지점',         address: '부산광역시 북구 (화명동) 학사로', lat: 0, lng: 0),
  Branch(id: 120, name: '화전산단6로지점',    address: '부산광역시 강서구 (화전동) 화전산단6로', lat: 0, lng: 0),
  Branch(id: 121, name: '신선로지점',         address: '부산광역시 남구 (용호동) 신선로', lat: 0, lng: 0),
  Branch(id: 122, name: '가야대로지점',       address: '부산광역시 부산진구 (가야동) 가야대로', lat: 0, lng: 0),
  Branch(id: 123, name: '우암로지점',         address: '부산광역시 남구 (감만동) 우암로', lat: 0, lng: 0),
  Branch(id: 124, name: '새벽로지점',         address: '부산광역시 사상구 (감전동) 새벽로', lat: 0, lng: 0),
  Branch(id: 125, name: '옥천로지점',         address: '부산광역시 사하구 (감천동) 옥천로', lat: 0, lng: 0),
  Branch(id: 126, name: '감천로지점',         address: '부산광역시 사하구 (감천동) 감천로', lat: 0, lng: 0),
  Branch(id: 127, name: '강남대로지점',       address: '서울특별시 서초구 (서초동) 강남대로', lat: 0, lng: 0),
  Branch(id: 128, name: '미음산단로127번길지점', address: '부산광역시 강서구 (구랑동) 미음산단로127번길', lat: 0, lng: 0),
  Branch(id: 129, name: '가야대로지점',       address: '부산광역시 부산진구 (개금동) 가야대로', lat: 0, lng: 0),
  Branch(id: 130, name: '복지로지점',         address: '부산광역시 부산진구 (개금동) 복지로', lat: 0, lng: 0),
  Branch(id: 131, name: '거제중앙로29번길지점', address: '경상남도 거제시 (고현동) 거제중앙로29번길', lat: 0, lng: 0),
  Branch(id: 132, name: '거제대로지점',       address: '부산광역시 연제구 (거제동) 거제대로', lat: 0, lng: 0),
  Branch(id: 133, name: '법원로지점',         address: '부산광역시 연제구 (거제동) 법원로', lat: 0, lng: 0),
  Branch(id: 134, name: '수영로지점',         address: '부산광역시 남구 (대연동) 수영로', lat: 0, lng: 0),
  Branch(id: 135, name: '광남로지점',         address: '부산광역시 수영구 (남천동) 광남로', lat: 0, lng: 0),
  Branch(id: 136, name: '수영로지점',         address: '부산광역시 수영구 (광안동) 수영로', lat: 0, lng: 0),
  Branch(id: 137, name: '운산로지점',         address: '부산광역시 사상구 (괘법동) 운산로', lat: 0, lng: 0),
  Branch(id: 138, name: '낙동대로지점',       address: '부산광역시 사하구 (괴정동) 낙동대로', lat: 0, lng: 0),
  Branch(id: 139, name: '중앙대로지점',       address: '부산광역시 연제구 (거제동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 140, name: '백양대로지점',       address: '부산광역시 북구 (구포동) 백양대로', lat: 0, lng: 0),
  Branch(id: 141, name: '디지털로지점',       address: '서울특별시 구로구 (구로동) 디지털로', lat: 0, lng: 0),
  Branch(id: 142, name: '구서로지점',         address: '부산광역시 금정구 (구서동) 구서로', lat: 0, lng: 0),
  Branch(id: 143, name: '백양대로지점',       address: '부산광역시 북구 (덕천동) 백양대로', lat: 0, lng: 0),
  Branch(id: 144, name: '시랑로79번길지점',   address: '부산광역시 북구 (구포동) 시랑로79번길', lat: 0, lng: 0),
  Branch(id: 145, name: '충장대로지점',       address: '부산광역시 동구 (초량동) 충장대로', lat: 0, lng: 0),
  Branch(id: 146, name: '금곡대로616번길지점', address: '부산광역시 북구 (금곡동) 금곡대로616번길', lat: 0, lng: 0),
  Branch(id: 147, name: '서동로지점',         address: '부산광역시 금정구 (서동) 서동로', lat: 0, lng: 0),
  Branch(id: 148, name: '중앙대로지점',       address: '부산광역시 금정구 (부곡동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 149, name: '읍내로지점',         address: '부산광역시 기장군 기장읍 읍내로', lat: 0, lng: 0),
  Branch(id: 150, name: '수림로지점',         address: '부산광역시 금정구 (부곡동) 수림로', lat: 0, lng: 0),
  Branch(id: 151, name: '공항진입로지점',     address: '부산광역시 강서구 (대저2동) 공항진입로', lat: 0, lng: 0),
  Branch(id: 152, name: '가락로지점',         address: '경상남도 김해시 (부원동) 가락로', lat: 0, lng: 0),
  Branch(id: 153, name: '골든루트로66번길 5지점', address: '경상남도 김해시 주촌면 골든루트로66번길 5', lat: 0, lng: 0),
  Branch(id: 154, name: '못골로지점',         address: '부산광역시 남구 (대연동) 못골로', lat: 0, lng: 0),
  Branch(id: 155, name: '금강로지점',         address: '부산광역시 금정구 (남산동) 금강로', lat: 0, lng: 0),
  Branch(id: 156, name: '양산역로지점',       address: '경상남도 양산시 (중부동) 양산역로', lat: 0, lng: 0),
  Branch(id: 157, name: '수영로지점',         address: '부산광역시 수영구 (남천동) 수영로', lat: 0, lng: 0),
  Branch(id: 158, name: '충렬대로지점',       address: '부산광역시 동래구 (온천동) 충렬대로', lat: 0, lng: 0),
  Branch(id: 159, name: '함박로지점',         address: '경상남도 김해시 (외동) 함박로', lat: 0, lng: 0),
  Branch(id: 160, name: '가야대로지점',       address: '부산광역시 사상구 (주례동) 가야대로', lat: 0, lng: 0),
  Branch(id: 161, name: '녹산산단232로지점',  address: '부산광역시 강서구 (송정동) 녹산산단232로', lat: 0, lng: 0),
  Branch(id: 162, name: '녹산산단335로지점',  address: '부산광역시 강서구 (송정동) 녹산산단335로', lat: 0, lng: 0),
  Branch(id: 163, name: '다대로429번길지점',  address: '부산광역시 사하구 (다대동) 다대로429번길', lat: 0, lng: 0),
  Branch(id: 164, name: '다대로지점',         address: '부산광역시 사하구 (다대동) 다대로', lat: 0, lng: 0),
  Branch(id: 165, name: '당감로지점',         address: '부산광역시 부산진구 (당감동) 당감로', lat: 0, lng: 0),
  Branch(id: 166, name: '낙동대로지점',       address: '부산광역시 사하구 (당리동) 낙동대로', lat: 0, lng: 0),
  Branch(id: 167, name: '백양관문로지점',     address: '부산광역시 부산진구 (개금동) 백양관문로', lat: 0, lng: 0),
  Branch(id: 168, name: '달구벌대로지점',     address: '대구광역시 달서구 (두류동) 달구벌대로', lat: 0, lng: 0),
  Branch(id: 169, name: '구덕로지점',         address: '부산광역시 서구 (서대신동3가) 구덕로', lat: 0, lng: 0),
  Branch(id: 170, name: '황령대로319번가길지점', address: '부산광역시 남구 (대연동) 황령대로319번가길', lat: 0, lng: 0),
  Branch(id: 171, name: '수영로지점',         address: '부산광역시 남구 (대연동) 수영로', lat: 0, lng: 0),
  Branch(id: 172, name: '낙동북로지점',       address: '부산광역시 강서구 (대저1동) 낙동북로', lat: 0, lng: 0),
  Branch(id: 173, name: '둔산로지점',         address: '대전광역시 서구 (둔산동) 둔산로', lat: 0, lng: 0),
  Branch(id: 174, name: '덕계로지점',         address: '경상남도 양산시 (덕계동) 덕계로', lat: 0, lng: 0),
  Branch(id: 175, name: '사상로지점',         address: '부산광역시 사상구 (덕포동) 사상로', lat: 0, lng: 0),
  Branch(id: 176, name: '구청로지점',         address: '부산광역시 동구 (수정동) 구청로', lat: 0, lng: 0),
  Branch(id: 177, name: '인제로지점',         address: '경상남도 김해시 (어방동) 인제로', lat: 0, lng: 0),
  Branch(id: 178, name: '대영로지점',         address: '부산광역시 서구 (동대신동2가) 대영로', lat: 0, lng: 0),
  Branch(id: 179, name: '명륜로94번길지점',   address: '부산광역시 동래구 (수안동) 명륜로94번길', lat: 0, lng: 0),
  Branch(id: 180, name: '신선로지점',         address: '부산광역시 남구 (용당동) 신선로', lat: 0, lng: 0),
  Branch(id: 181, name: '낙동대로550번길지점', address: '부산광역시 사하구 (하단동) 낙동대로550번길', lat: 0, lng: 0),
  Branch(id: 182, name: '양지로지점',         address: '부산광역시 부산진구 (양정동) 양지로', lat: 0, lng: 0),
  Branch(id: 183, name: '중앙대로지점',       address: '부산광역시 금정구 (구서동) 중앙대로', lat: 0, lng: 0),
  Branch(id: 184, name: '마린시티3로지점',    address: '부산광역시 해운대구 (우동) 마린시티3로', lat: 0, lng: 0),
  Branch(id: 185, name: '마린시티2로지점',    address: '부산광역시 해운대구 (우동) 마린시티2로', lat: 0, lng: 0),
  Branch(id: 186, name: '봉양로지점',         address: '경상남도 창원시 마산회원구 봉양로', lat: 0, lng: 0),
  Branch(id: 187, name: '덕천로지점',         address: '부산광역시 북구 (만덕동) 덕천로', lat: 0, lng: 0),
  Branch(id: 188, name: '과정로지점',         address: '부산광역시 수영구 (망미동) 과정로', lat: 0, lng: 0),
  Branch(id: 189, name: '분포로지점',         address: '부산광역시 남구 (용호동) 분포로', lat: 0, lng: 0),
  Branch(id: 190, name: '신선로지점',         address: '부산광역시 남구 (용호동) 신선로', lat: 0, lng: 0),
  Branch(id: 191, name: '명륜로지점',         address: '부산광역시 동래구 (명륜동) 명륜로', lat: 0, lng: 0),
  Branch(id: 192, name: '반송로지점',         address: '부산광역시 동래구 (명장동) 반송로', lat: 0, lng: 0),
  Branch(id: 193, name: '명지오션시티11로지점', address: '부산광역시 강서구 (명지동) 명지오션시티11로', lat: 0, lng: 0),
  Branch(id: 194, name: '명지국제8로지점',     address: '부산광역시 강서구 명지동 명지국제8로', lat: 0, lng: 0),
  Branch(id: 195, name: '사상로지점',         address: '부산광역시 사상구 (모라동) 사상로', lat: 0, lng: 0),
  Branch(id: 196, name: '다대로지점',         address: '부산광역시 사하구 (다대동) 다대로', lat: 0, lng: 0),
  Branch(id: 197, name: '대학로지점',         address: '울산광역시 남구 (무거동) 대학로', lat: 0, lng: 0),
  Branch(id: 198, name: '수영로지점',         address: '부산광역시 남구 (문현동) 수영로', lat: 0, lng: 0),
  Branch(id: 199, name: '야리로지점',         address: '경상남도 양산시 물금읍 야리로', lat: 0, lng: 0),
  Branch(id: 200, name: '충렬대로107번길지점', address: '부산광역시 동래구 (온천동) 충렬대로107번길', lat: 0, lng: 0),
  Branch(id: 201, name: '광안해변로지점',     address: '부산광역시 수영구 (민락동) 광안해변로', lat: 0, lng: 0),
  Branch(id: 202, name: '아랫반송로21번길지점', address: '부산광역시 해운대구 (반송동) 아랫반송로21번길', lat: 0, lng: 0),
  Branch(id: 203, name: '신반송로지점',       address: '부산광역시 해운대구 (반송동) 신반송로', lat: 0, lng: 0),
  Branch(id: 204, name: '재반로지점',         address: '부산광역시 해운대구 (반여동) 재반로', lat: 0, lng: 0),

];

/* ------------------------------- 화면 ------------------------------- */
class BranchMapScreen extends StatefulWidget {
  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  static const NLatLng _busan = NLatLng(35.1796, 129.0756);
  static const double _kDefaultRadiusMeters = 3000.0; // 3km

  NaverMapController? _mapController;
  final _searchCtl = TextEditingController();

  bool _mapReady = false;
  bool _loading = false;

  // 권한 상태
  bool _permissionChecked = false;
  bool _permissionGranted = false;

  NLatLng? _myLatLng;

  // 로컬 전체 목록
  List<Branch> _allBranches = LOCAL_BRANCHES;

  // 반경/검색 필터 결과(로컬 모드용)
  List<Branch> _filtered = [];

  // 지도 마커(로컬 모드)
  final Map<int, NMarker> _markerById = {};

  // 반경 조절
  double _radiusMeters = _kDefaultRadiusMeters;

  // 주소 지오코딩 결과 캐시(앱 세션 동안) - 로컬 모드
  final Map<int, NLatLng> _coordById = {};

  // ====== 정확(네이버) 모드 ======
  bool _useNaver = false; // 토글 스위치
  List<Poi> _pois = [];
  final Map<String, NMarker> _poiMarkers = {}; // key = "$lat,$lng"

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1) 권한 체크 중
    if (!_permissionChecked) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    // 2) 권한 미허용
    if (!_permissionGranted) {
      return Scaffold(
        body: SafeArea(child: _buildPermissionGate()),
      );
    }

    // 3) 지도/검색/목록
    final media = MediaQuery.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: media.size.height * 0.36,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NaverMap(
                      options: const NaverMapViewOptions(
                        initialCameraPosition: NCameraPosition(
                          target: _busan,
                          zoom: 12,
                        ),
                        locationButtonEnable: false,
                      ),
                      onMapReady: (controller) async {
                        _mapController = controller;
                        controller.getLocationOverlay().setIsVisible(true);
                        await _setupMapAfterReady();
                        if (!mounted) return;
                        setState(() => _mapReady = true);
                      },
                      // 👇 이 부분 추가
                      onCameraIdle: () async {
                        if (_useNaver) {
                          await _loadBnkPoisFromProxy();
                        }
                      },
                    ),

                  ),

                  // 내 위치 이동 버튼
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
                        // 이동 후 정확모드면 새로운 중심으로 검색
                        if (_useNaver) {
                          await _loadBnkPoisFromProxy();
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),

                  if (!_mapReady || _loading)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black12,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 상단 컨트롤바: 검색 + 반경 슬라이더 + 정확(네이버) 토글
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtl,
                      decoration: InputDecoration(
                        hintText: _useNaver ? '지점명/주소(POI 필터)' : '지점명/주소(로컬)',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        if (_useNaver) {
                          _applyPoiFilterOnly();
                        } else {
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      const Text('정확(네이버)', style: TextStyle(fontSize: 12)),
                      Switch(
                        value: _useNaver,
                        onChanged: (v) async {
                          setState(() => _useNaver = v);
                          if (_useNaver) {
                            await _loadBnkPoisFromProxy();
                          } else {
                            _applyFilters();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Text('반경'),
                  Expanded(
                    child: Slider(
                      value: _radiusMeters,
                      min: 500,
                      max: 5000,
                      divisions: 9,
                      label: _fmtDistance(_radiusMeters),
                      onChanged: (v) async {
                        setState(() => _radiusMeters = v);
                        if (_useNaver) {
                          await _loadBnkPoisFromProxy();
                        } else {
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                  Text(_fmtDistance(_radiusMeters)),
                ],
              ),
            ),

            // 목록(모드별)
            Expanded(child: _useNaver ? _buildPoiListView() : _buildLocalListView()),
          ],
        ),
      ),
    );
  }

  /* ----------------------- 권한 관련 뷰/로직 ----------------------- */

  Widget _buildPermissionGate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '반경 내 영업점을 보여주려면 위치 권한이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(
                  onPressed: _requestPermission,
                  child: const Text('권한 허용하기'),
                ),
                OutlinedButton(
                  onPressed: Geolocator.openAppSettings,
                  child: const Text('앱 설정 열기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initPermissions() async {
    final ok = await _ensureLocationReady(requestIfDenied: true);
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = ok;
    });
  }

  Future<void> _requestPermission() async {
    final ok = await _ensureLocationReady(requestIfDenied: true);
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = ok;
    });
  }

  Future<bool> _ensureLocationReady({bool requestIfDenied = true}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied && requestIfDenied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  /* ----------------------- 지도 준비 이후 세팅 ---------------------- */
  Future<void> _setupMapAfterReady() async {
    if (!_permissionGranted) return;

    try {
      setState(() => _loading = true);

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _myLatLng = NLatLng(pos.latitude, pos.longitude);

      await _mapController?.updateCamera(
        NCameraUpdate.scrollAndZoomTo(target: _myLatLng!, zoom: 14),
      );

      _mapController?.setLocationTrackingMode(
        NLocationTrackingMode.follow,
      );

      if (_useNaver) {
        await _loadBnkPoisFromProxy();
      } else {
        _applyFilters();
      }
    } catch (e) {
      if (!mounted) return;
      _myLatLng = null;
      if (_useNaver) {
        await _loadBnkPoisFromProxy(); // 위치 없어도 지도 중심으로 검색
      } else {
        _applyFilters();
      }
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /* ----------------------------- 목록 UI (로컬) ---------------------------- */
  Widget _buildLocalListView() {
    if (_myLatLng == null) {
      return const Center(child: Text('현재 위치를 확인 중입니다...'));
    }
    if (_filtered.isEmpty) {
      return const Center(child: Text('조건에 맞는 영업점이 없습니다.'));
    }

    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = _filtered[index];

        // 좌표 소스: (1) 고정 lat/lng → (2) 캐시된 지오코딩 좌표
        final coord = (b.lat != 0 && b.lng != 0)
            ? NLatLng(b.lat, b.lng)
            : _coordById[b.id];

        final distText = (_myLatLng != null && coord != null)
            ? _fmtDistance(_distanceMeters(
            _myLatLng!.latitude, _myLatLng!.longitude, coord.latitude, coord.longitude))
            : '거리 계산 중…';

        return ListTile(
          title: Text(b.name),
          subtitle: Text('${b.address}\n약 $distText'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final target = coord ?? await _coordFor(b);
            if (target == null) return;
            _mapController?.updateCamera(
              NCameraUpdate.scrollAndZoomTo(target: target, zoom: 16),
            );
            final mk = _markerById[b.id];
            mk?.setCaption(NOverlayCaption(text: b.name));

            // ✅ 선택 즉시 이전 화면으로 지점명 반환
            if (mounted) Navigator.pop(context, b.name);
          },
        );
      },
    );
  }

  /* ----------------------------- 목록 UI (네이버 POI) ---------------------------- */
  Widget _buildPoiListView() {
    if (_pois.isEmpty) {
      return const Center(child: Text('부산은행 지점을 검색 중이거나, 결과가 없습니다.'));
    }

    // 검색어(지점명/주소)로 POI 목록 필터(클라측)
    final q = _searchCtl.text.trim().toLowerCase();
    final list = _pois.where((p) {
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.roadAddress.toLowerCase().contains(q);
    }).toList();

    if (list.isEmpty) {
      return const Center(child: Text('검색 조건에 맞는 지점이 없습니다.'));
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final p = list[index];
        final coord = NLatLng(p.lat, p.lng);
        final distText = (_myLatLng != null)
            ? _fmtDistance(_distanceMeters(
            _myLatLng!.latitude, _myLatLng!.longitude, coord.latitude, coord.longitude))
            : '';

        return ListTile(
          title: Text(p.title.replaceAll(RegExp(r'<\/?b>'), '')),
          subtitle: Text('${p.roadAddress}\n${distText.isEmpty ? '' : '약 $distText'}'),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            _mapController?.updateCamera(
              NCameraUpdate.scrollAndZoomTo(target: coord, zoom: 16),
            );
            // 네이버 검색 결과의 타이틀에는 <b> 태그가 섞여서 올 수 있으니 제거
            final cleanTitle = p.title.replaceAll(RegExp(r'</?b>'), '');

            // ✅ 선택 즉시 이전 화면으로 지점명 반환
            if (mounted) Navigator.pop(context, cleanTitle);
          },
        );
      },
    );
  }

  /* ------------------------ 필터(반경+검색) : 로컬 ------------------------ */
  void _applyFilters() {
    // 1) 검색 필터 먼저
    final q = _searchCtl.text.trim().toLowerCase();
    bool match(Branch b) =>
        q.isEmpty ||
            b.name.toLowerCase().contains(q) ||
            b.address.toLowerCase().contains(q);
    final base = _allBranches.where(match).toList();

    // 2) 내 위치 없으면 목록만 갱신(거리 표시/반경 필터는 보류)
    if (_myLatLng == null) {
      setState(() => _filtered = base);
      _renderMarkersLocal(); // 좌표 보유분만 마커
      return;
    }

    // 3) 좌표 보유/미보유 분리
    final List<Branch> immediate = [];
    final List<Branch> needGeocode = [];
    for (final b in base) {
      if (b.lat != 0 && b.lng != 0 || _coordById.containsKey(b.id)) {
        immediate.add(b);
      } else {
        needGeocode.add(b);
      }
    }

    // 4) 즉시 반경 필터
    final List<Branch> within = [];
    for (final b in immediate) {
      final ll = (b.lat != 0 && b.lng != 0)
          ? NLatLng(b.lat, b.lng)
          : _coordById[b.id]!;
      final d = _distanceMeters(
          _myLatLng!.latitude, _myLatLng!.longitude, ll.latitude, ll.longitude);
      if (d <= _radiusMeters) within.add(b);
    }

    setState(() {
      _filtered = within;
    });
    _renderMarkersLocal();

    // 5) 주소만 있는 애들은 순차 지오코딩 → 결과 나오면 갱신
    () async {
      for (final b in needGeocode) {
        final ll = await _coordFor(b);
        if (!mounted || ll == null) continue;
        final d = _distanceMeters(
            _myLatLng!.latitude, _myLatLng!.longitude, ll.latitude, ll.longitude);
        if (d <= _radiusMeters) {
          if (!_filtered.any((x) => x.id == b.id)) {
            setState(() => _filtered = [..._filtered, b]);
            _renderMarkersLocal();
          }
        }
        await Future.delayed(const Duration(milliseconds: 80)); // 호출 간 텀
      }
    }();
  }

  /* ------------------------ 네이버 POI 필터만 (클라) ------------------------ */
  void _applyPoiFilterOnly() {
    // 마커는 _pois 전체를 기준으로 다시 그림 (검색은 리스트에서만 필터)
    _renderMarkersPoi();
  }

  /* -------------------------- 마커 렌더/정리 -------------------------- */

  // 로컬 모드 마커
  void _renderMarkersLocal() async {
    if (_mapController == null) return;

    // 기존 마커 제거 (로컬)
    for (final mk in _markerById.values) {
      // ignore: invalid_use_of_protected_member
      _mapController!.deleteOverlay(mk as NOverlayInfo);
    }
    _markerById.clear();

    // 네이버 POI 마커는 유지/비표시
    for (final mk in _poiMarkers.values) {
      // 감추는 대신 그냥 두되, 겹치면 헷갈릴 수 있어서 정확모드 아닐 땐 제거
      _mapController!.deleteOverlay(mk as NOverlayInfo);
    }
    _poiMarkers.clear();

    // 새 마커 추가
    for (final b in _filtered) {
      NLatLng? ll;
      if (b.lat != 0 && b.lng != 0) {
        ll = NLatLng(b.lat, b.lng);
      } else {
        ll = _coordById[b.id] ?? await _coordFor(b);
      }
      if (ll == null) continue;

      final mk = NMarker(
        id: 'branch_${b.id}',
        position: ll,
      );

      mk.setOnTapListener((overlay) async {
        await _mapController?.updateCamera(
          NCameraUpdate.scrollAndZoomTo(target: ll!, zoom: 16),
        );
        mk.setCaption(NOverlayCaption(text: b.name));
      });

      _mapController!.addOverlay(mk);
      _markerById[b.id] = mk;
    }
  }

  // 네이버 POI 모드 마커
  void _renderMarkersPoi() {
    if (_mapController == null) return;

    // 로컬 마커 제거
    for (final mk in _markerById.values) {
      // ignore: invalid_use_of_protected_member
      _mapController!.deleteOverlay(mk as NOverlayInfo);
    }
    _markerById.clear();

    // 기존 POI 마커 제거
    for (final mk in _poiMarkers.values) {
      // ignore: invalid_use_of_protected_member
      _mapController!.deleteOverlay(mk as NOverlayInfo);
    }
    _poiMarkers.clear();

    // 검색어 필터(표시는 리스트 기준과 동일하게)
    final q = _searchCtl.text.trim().toLowerCase();

    for (final p in _pois) {
      if (q.isNotEmpty) {
        final t = p.title.toLowerCase();
        final a = p.roadAddress.toLowerCase();
        if (!t.contains(q) && !a.contains(q)) continue;
      }

      final ll = NLatLng(p.lat, p.lng);
      final id = 'poi_${p.lat}_${p.lng}';
      final mk = NMarker(id: id, position: ll);

      mk.setOnTapListener((overlay) async {
        await _mapController?.updateCamera(
          NCameraUpdate.scrollAndZoomTo(target: ll, zoom: 16),
        );
        mk.setCaption(NOverlayCaption(text: p.title.replaceAll(RegExp(r'<\/?b>'), '')));
      });

      _mapController!.addOverlay(mk);
      _poiMarkers[id] = mk;
    }
  }

  /* ----------------------------- 카메라 아이들 ----------------------------- */
  Future<void> _onCameraIdle() async {
    if (!_useNaver) return;
    await _loadBnkPoisFromProxy();
  }

  /* --------------------------- 프록시 호출(권장) --------------------------- */
  /// 현재 지도 중심/반경 기준으로 '부산은행' 장소검색
  Future<void> _loadBnkPoisFromProxy() async {
    if (_mapController == null) return;

    setState(() => _loading = true);

    try {
      final cam = await _mapController!.getCameraPosition();
      final center = cam.target; // 지도의 현재 중심

      final url = Uri.parse('$PROXY_BASE/poi/search-bnk').replace(
        queryParameters: {
          'lat': center.latitude.toString(),
          'lng': center.longitude.toString(),
          'radius': _radiusMeters.toString(), // 미터 단위
          'q': '부산은행', // 서버에서 기본값 처리해도 됨
          'limit': '30',  // 필요 시 조정
        },
      );

      final res = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (res.statusCode != 200) {
        throw Exception('Proxy ${res.statusCode}: ${res.body}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        throw const FormatException('Unexpected proxy response shape');
      }
      final pois = decoded.map<Poi>((j) => Poi.fromJson(j as Map<String, dynamic>)).toList();

      setState(() {
        _pois = pois;
      });

      _renderMarkersPoi();
    } catch (e) {
      // 실패 시 조용히 유지(로그만)
      debugPrint('POI fetch failed: $e');
      setState(() {
        _pois = [];
      });
      _renderMarkersPoi();
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  /* --------------------------- 지오코딩 (로컬) --------------------------- */
  // 주소 → 좌표 (성공 시 캐시에 저장)
  Future<NLatLng?> _coordFor(Branch b) async {
    // (1) 고정 좌표가 있으면 그걸로
    if (b.lat != 0 && b.lng != 0) return NLatLng(b.lat, b.lng);

    // (2) 캐시에 있으면 재사용
    final cached = _coordById[b.id];
    if (cached != null) return cached;

    // (3) 플랫폼 내장 지오코딩 사용 (키 불필요, 단 정확도/가용성은 기기/지역에 따라 상이)
    try {
      final list = await geo.locationFromAddress(b.address);
      if (list.isNotEmpty) {
        final ll = NLatLng(list.first.latitude, list.first.longitude);
        _coordById[b.id] = ll;
        return ll;
      }
    } catch (_) {
      // 실패는 조용히 무시 (목록/마커에서 제외)
    }
    return null;
  }

  /* --------------------------- 거리 계산 --------------------------- */
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // m
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

  String _fmtDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
}
