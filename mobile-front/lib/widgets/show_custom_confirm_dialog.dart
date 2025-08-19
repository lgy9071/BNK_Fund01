import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
// import 'package:mobile_front/core/constants/colors.dart'; // AppColors 쓰면 주석 해제

/// 공통 확인/취소 다이얼로그
/// 반환값: 확인 = true, 취소 = false, 바깥 탭/뒤로가기 = null
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = '확인',
  String cancelText = '취소',
  bool showCancel = true,
  bool barrierDismissible = true,
  Color? confirmColor, // 기본: theme.primary
  Color cancelBgColor = const Color(0xFFF0F1F5),
  Color cancelFgColor = const Color(0xFF383E56),
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final primary = confirmColor ?? theme.colorScheme.primary; // AppColors.primaryBlue 사용 가능

      return AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF383E56),
              ),
            ),
            const SizedBox(height: 15),

            // 본문
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 25),

            // 버튼 영역
            Row(
              children: [
                if (showCancel) ...[
                  Flexible(
                    flex: 3,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx, rootNavigator: true).pop(false);
                        onCancel?.call();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: cancelBgColor,
                        foregroundColor: cancelFgColor,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                // 확인 버튼
                Flexible(
                  flex: 7,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx, rootNavigator: true).pop(true);
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue, // AppColors.primaryBlue 사용하려면 여기에 지정
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
