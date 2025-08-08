import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../models/fund.dart';

void main() {
  // 여기서는 앱 분기/스플래시 다 생략하고 Home만 바로 띄움
  final dummyFunds = <Fund>[
    Fund(id: 1, name: '한국성장주식 A', rate: 3.2, balance: 5_500_000),
    Fund(id: 2, name: '글로벌채권 인덱스', rate: -1.1, balance: 4_000_000),
  ];

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(
      myFunds: dummyFunds,
      investType: '공격 투자형',
      userName: '지용',
      onToggleTheme: () {}, // 테스트용
    ),
  ));
}