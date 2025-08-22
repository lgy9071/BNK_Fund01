// widgets/category_chip.dart
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class CategoryChip extends StatelessWidget {
  final String category;
  const CategoryChip({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    late Color bg, border, text;

    switch (category) {
      case '국내':
        bg = const Color(0xFFEFF4FF);
        border = const Color(0xFFCCE0FF);
        text = AppColors.primaryBlue;
        break;
      case '해외':
        bg = const Color(0xFFEFF7F1);
        border = const Color(0xFFBFE6CF);
        text = const Color(0xFF1A7F37);
        break;
      default: // 전체 등
        bg = const Color(0xFFF3F5F8);
        border = const Color(0xFFE1E6EE);
        text = AppColors.fontColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(category,
          style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
