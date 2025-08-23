import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(Icons.home_rounded, '홈'),
    _NavItem(Icons.account_balance_wallet_rounded, '내 금융'),
    _NavItem(Icons.addchart_rounded, '펀드 가입'),
    _NavItem(Icons.apps_rounded, '전체'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            final item = _items[i];

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onTap(i),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 🔹 밑 오오라 (활성화 시만)
                    if (active)
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 75,
                          height: 75,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryBlue.withOpacity(0.2),
                                AppColors.primaryBlue.withOpacity(0.0),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),

                    // 🔹 아이콘 + 텍스트
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: active ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            item.icon,
                            size: 28,
                            color: active
                                ? AppColors.primaryBlue
                                : AppColors.fontColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: active ? 16 : 14,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: active
                                ? AppColors.primaryBlue
                                : AppColors.fontColor,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
