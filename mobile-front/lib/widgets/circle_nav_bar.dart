import 'package:flutter/material.dart';

const _navBlue = Color(0xFF0064FF);

class CircleNavBar extends StatelessWidget {
  const CircleNavBar({
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
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: _navBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = i == currentIndex;
            final item = _items[i];

            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 66, height: 66,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? Colors.white : Colors.transparent,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.icon, size: 33, color: active ? _navBlue : Colors.white),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: active ? _navBlue : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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