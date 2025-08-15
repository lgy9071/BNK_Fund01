import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/main.dart' show navigatorKey; // 루트 네비게이터용

// 마지막 뒤로가기 시각 전역 보관
DateTime? _lastBackPressedAt;
// 현재 떠있는 플로팅바(있으면 교체)
OverlayEntry? _infoBarEntry;

/// 🔁 뒤로가기 2번에 종료: 첫 번째엔 커스텀 플로팅바 안내,
/// 2초 안에 한 번 더 누르면 true 리턴(호출부에서 SystemNavigator.pop() 실행)
Future<bool> showExitPopup(BuildContext context) async {
  final now = DateTime.now();

  // 2초 초과 → 첫 번째 백프레스: 안내만 띄우고 종료 안함
  if (_lastBackPressedAt == null ||
      now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
    _lastBackPressedAt = now;
    _showFloatingInfoBar('한번 더 누르면 앱이 종료됩니다.');
    return false; // 종료하지 않음
  }

  // 2초 안에 두 번째 백프레스 → 종료 신호
  return true;
}

void _showFloatingInfoBar(String message) {
  // 항상 루트 오버레이 사용 (중첩 네비/다이얼로그 대비)
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) return;

  _infoBarEntry?.remove();
  _infoBarEntry = OverlayEntry(
    builder: (_) => _FloatingInfoBar(
      message: message,
      onDismissed: () {
        _infoBarEntry?.remove();
        _infoBarEntry = null;
      },
    ),
  );
  overlay.insert(_infoBarEntry!);
}

class _FloatingInfoBar extends StatefulWidget {
  final String message;
  final VoidCallback onDismissed;
  const _FloatingInfoBar({
    Key? key,
    required this.message,
    required this.onDismissed,
  }) : super(key: key);

  @override
  State<_FloatingInfoBar> createState() => _FloatingInfoBarState();
}

class _FloatingInfoBarState extends State<_FloatingInfoBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _scale =
  CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
  CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // 2초 보여주고 사라지기
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 360),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.info_outline, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '한번 더 누르면 앱이 종료됩니다.',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}