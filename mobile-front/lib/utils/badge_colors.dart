import 'package:flutter/material.dart';

class BadgeColors {
  static Color bg(String t) {
    if (t.contains('낮은위험') || t.contains('낮은 위험')) return const Color(0xFFFFEDD5); // 연한 주황
    if (t.contains('해외')) return const Color(0xFFE6F0FF);  // 연한 파랑
    if (t.contains('채권')) return const Color(0xFFEFF7EB); // 연한 그린
    if (t.contains('BNK')) return const Color(0xFFEEE7FF);  // 연한 보라
    return Colors.grey.withOpacity(.15);
  }

  static Color fg(String t, {Color defaultColor = const Color(0xFF383E56)}) {
    return defaultColor; // 필요 시 케이스별 글자색 분기 추가
  }
}