import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

/// 큰 단계(1~3) + (선택) 작은 단계(질문 진행) 헤더
class StepHeader extends StatelessWidget {
  /// 1: 작성동의, 2: 문제, 3: 완료
  final int bigStep; // 1..3
  /// 작은 단계(문제 진행 단계). null이면 표시 안 함
  final int? smallStepCurrent; // 1..N
  final int? smallStepTotal;   // N
  final bool showBigProgress;        // ✅ 추가: 큰 단계 프로그레스바 표시 여부

  const StepHeader({
    super.key,
    required this.bigStep,
    this.smallStepCurrent,
    this.smallStepTotal,
    this.showBigProgress = true,     // 기본 true (기존 화면들 영향 X)
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSmall = smallStepCurrent != null && smallStepTotal != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 큰 단계 표시 (칩 스타일)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BigStepChip(index: 1, label: '작성동의', active: bigStep == 1),
              _DividerArrow(),
              _BigStepChip(index: 2, label: '확인서작성', active: bigStep == 2),
              _DividerArrow(),
              _BigStepChip(index: 3, label: '분석결과', active: bigStep == 3),
            ],
          ),
        ),
        // 큰 단계 프로그레스 (1/3, 2/3, 3/3)
        if (showBigProgress)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('$bigStep / 3', style: theme.textTheme.bodySmall),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: bigStep / 3,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 작은 단계(문제 진행) — 큰 단계가 2일 때만 표시
        if (showSmall) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${smallStepCurrent!} / ${smallStepTotal!}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: smallStepCurrent! / smallStepTotal!,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                      const AlwaysStoppedAnimation(AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BigStepChip extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  const _BigStepChip({
    required this.index,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final base = active ? AppColors.primaryBlue : Colors.grey.shade300;
    final on = active ? Colors.white : Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? base : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: active ? Colors.white : base,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? AppColors.primaryBlue : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on,
              )),
        ],
      ),
    );
  }
}

class _DividerArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade500),
    );
  }
}
