import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';

class QuestionCard extends StatelessWidget {
  final String questionText;
  final List<String> options;
  final bool multi;                  // true: 체크박스, false: 라디오
  final Set<int> selectedIndexes;    // 현재 선택된 보기 인덱스들
  final ValueChanged<Set<int>> onChanged;

  final double questionFontSize;
  final double optionFontSize;

  const QuestionCard({

    super.key,
    required this.questionText,
    required this.options,
    required this.multi,
    required this.selectedIndexes,
    required this.onChanged,
    this.questionFontSize = 22, // 기본값
    this.optionFontSize = 15,   // 기본값
  });

  void _toggleSingle(int i) {
    onChanged({i});
  }

  void _toggleMulti(int i) {
    final next = {...selectedIndexes};
    if (next.contains(i)) {
      next.remove(i);
    } else {
      next.add(i);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ 단일선택용 현재 선택 값 (Radio groupValue에 사용)
    final int? singleSelected =
    selectedIndexes.isEmpty ? null : selectedIndexes.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 질문 타이틀
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Text(
            questionText,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: questionFontSize,
            ),
          ),
        ),

        // ✅ 질문과 보기 사이 간격
        const SizedBox(height: 36),

        // 보기 카드 리스트
        ...List.generate(options.length, (i) {
          final bool selected = selectedIndexes.contains(i);

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
                width: selected ? 1.3 : 1,
              ),
            ),
            child: ListTile(
              // 탭 전체 영역 반응
              onTap: () => multi ? _toggleMulti(i) : _toggleSingle(i),

              // ✅ 안쪽 패딩 확대(터치감/가독성)
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),

              title: Text(
                options[i],
                  style: TextStyle(fontSize: optionFontSize)
              ),

              // ✅ trailing 컨트롤 (체크박스/라디오)
              trailing: multi
                  ? Checkbox(
                value: selected,
                onChanged: (_) => _toggleMulti(i),
                // 필요 시 터치영역 축소
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
                  : Radio<int>(
                value: i,
                // ❗ 기존 코드의 groupValue 버그 수정:
                // 각 타일마다 selected? i : null 주면 그룹이 깨져요.
                groupValue: singleSelected,
                onChanged: (_) => _toggleSingle(i),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primaryBlue,
              ),
            ),
          );
        }),

        // 아래 공간
        const SizedBox(height: 12),
      ],
    );
  }
}