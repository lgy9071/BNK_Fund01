// screens/questionnaire_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/models/question.dart';
import 'package:mobile_front/widgets/question_card.dart';
import 'package:mobile_front/widgets/show_custom_confirm_dialog.dart';
import 'package:mobile_front/widgets/step_header.dart'; // 경로 확인

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // 11문항 정의 (9번만 복수선택)
  late final List<Question> _questions = [
    const Question(
      text: '다음 중 고객님의 수입원을\n가장 잘 나타내는 것은 어느 것입니까?',
      options: ['현재 일정한 수입이 발생하고 있으며, \n향후 현재 수준을 유지하거나 증가할 것으로 예상', '현재 일정한 수입이 발생하고 있으나, \n향후 감소하거나 불안정할 것으로 예상', '현재 일정한 수입이 없으며, 연금이 주 수입원임'],
    ),
    const Question(
      text: '연간소득 현황에 가장 가까운 것은 \n어느 것입니까?',
      options: ['1억 이상', '5천만원이상 ~ 1억 미만', '3천만원 이상 ~ 5천만 미만', '3천만원미만'],
    ),
    const Question(
      text: '총 자산대비 투자상품의 비중은 \n어느 정도입니까?',
      options: ['30% 이상', '20% 이상', '10% 이상', '10% 미만'],
    ),
    const Question(
      text: '본인의 지식수준과 가장 가까운 것은 \n어느 것입니까?',
      options: ['파생상품을 포함한 대부분의 금융투자상품의 \n구조 및 위험을 이해하고 있음', '널리 알려진 금융투자상품(주식,채권 및 펀드 등)의 구조 및 위험을 깊이 있게 이해하고 있음', '널리 알려진 금융투자상품(주식,채권 및 펀드 등)의 구조 및 위험을 일정 부분 이해하고 있음', '금융투자상품에 대해 거의 알지 못함'],
    ),
    const Question(
      text: '투자원금에 손실이 발생할 경우 \n감수할 수 있는 손실수준은 어느 것입니까?',
      options: ['기대이익이 높다면, 20%이상 전액 손실도 \n감수할 수 있다', '원금 기준 20% 미만의 손실은 감수할 수 \n있을 것 같다', '원금 기준 10% 미만의 손실은 감수할 수 \n있을 것 같다', '투자 원금은 반드시 보전되어야 한다'],
    ),
    const Question(
      text: '투자하는 자금의 투자예정기간은 \n얼마나 되십니까?',
      options: ['3년 이상', '2년 이상 ~ 3년 미만', '1년 이상 ~ 2년 미만', '6개월이상 ~ 1년 미만', '6개월 미만'],
    ),
    const Question(
      text: '투자자금의 성격에 가장 잘 부합하는 것은 어느 것입니까?',
      options: ['여유 자금', '사업 자금', '자녀교육 자금', '주택 마련 자금', '노후 자금'],
    ),
    const Question(
      text: '목표로 하는 투자의 기대이익 수준은 \n어느 것입니까?',
      options: ['원금 기준 20% 내외의 이익을 목표로 한다', '원금 기준 10% 내외의 이익을 목표로 한다', '원금 기준 6% 내외의 이익을 목표로 한다', '원금 기준 3% 내외의 이익을 목표로 한다'],
    ),
    const Question(
      text: '투자 경험이 있는 투자상품이 있나요?\n(복수선택가능)',
      options: ['ELW, 선물옵션, 시장수익률 이상의 수익을 \n추구하는 주식형 펀드, 파생상품에 투자하는 펀드, 주식 신용거래 등',
        '신용도가 낮은 회사채, 주식, 원금이 보장되지 않는 ELF(ELS) 시장수익률 수준의 수익을 추구하는 주식형 펀드 등',
        '신용도 중간 등급의 회사채, 원금의 일부만 \n보장되는 ELF(ELS) 혼합형 펀드 등',
        '금융채, 신용도가 높은 회사채, 채권형펀드, \n원금보장형 ELF(ELS), ELD 등',
        '은행, 예∙적금, 국채, 지방채, 보증채, MMF, CMA 등'],
      multi: true, // ✅ 복수선택
    ),
    const Question(
      text: '투자경험기간에 가장 가까운 것은 \n어느 것입니까?',
      options: ['3년 이상', '1년 이상 ~ 3년 미만', '1년 미만', '없음'],
    ),
    const Question(
      text: '파생상품/원금비보장형 • \n파생결합증권/파생상품투자펀드에 \n투자한 경험이 있으신가요?',
      options: ['3년 이상', '1년 이상 ~ 3년 미만', '1년 미만', '없음'],
    ),
  ];

  // 선택 저장: 문항인덱스 -> 선택 인덱스들
  final Map<int, Set<int>> _answers = {};
  int _index = 0;

  bool get _isLast => _index == _questions.length - 1;
  bool get _hasSelection => (_answers[_index] ?? {}).isNotEmpty;


  bool _isBlockedCurrent() {
    // 0-based로 5번 문항은 _index == 4
    if (_index != 4) return false;

    // 4번 보기(0-based index 3)가 선택되어 있으면 막음
    final sel = _answers[_index] ?? <int>{};
    return sel.contains(3);
  }

  Future<void> _showBlockedAlert() async {
    if (!mounted) return;
    await showAppConfirmDialog(
      context: context,
      title: '진행 안내',
      message: '펀드 상품은 원금 보장형이 없습니다.\n다음으로 진행하려면 다른 선택지를 \n선택해 주세요.',
      confirmText: '확인',
      showCancel: false, // 확인 버튼만 표시
      confirmColor: const Color(0xFF383E56), // 기존 스타일 색상 맞춤
    );
  }



  void _goNext() async {
    // ▼ 막힘 조건이면 경고만 띄우고 return
    if (_isBlockedCurrent()) {
      await _showBlockedAlert();
      return;
    }

    if (_isLast) {
      _submit();
    } else {
      setState(() => _index++);
    }
  }


  void _onChangeSelection(Set<int> newSel) {
    setState(() {
      _answers[_index] = newSel;
    });
  }

  Future<bool> _handleBack() async {
    if (_index == 0) return true; // 첫 문항이면 화면 자체를 뒤로
    setState(() => _index--);     // 아니면 문항만 이전으로
    return false;
  }

  void _submit() {
    // TODO: 서버 전송 or 결과 화면 이동
    debugPrint('answers: $_answers');
    Navigator.of(context).pop(_answers);
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_index];
    final selected = _answers[_index] ?? <int>{};
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('확인서 작성'),
          centerTitle: true,
          // 뒤로가기 버튼이 문항 이전 로직을 먼저 타도록 커스텀
          scrolledUnderElevation: 0,             // ✅ 스크롤 시 음영 제거
          surfaceTintColor: Colors.transparent,
          backgroundColor: theme.colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () async {
              final allowPop = await _handleBack();
              if (allowPop && context.mounted) {
                Navigator.of(context).maybePop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // ✅ 큰 단계 프로그레스바 숨김
              StepHeader(
                bigStep: 2,                       // (동의 → 설문 → …)
                smallStepCurrent: _index + 1,     // 현재 문항
                smallStepTotal: _questions.length, // 총 문항
                showBigProgress: false,           // ← 큰 단계 바 숨기기
              ),
              SizedBox(height: 10,),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    SizedBox(height: 20), // ← 상단 여백
                    QuestionCard(
                      questionText: q.text,
                      options: q.options,
                      multi: q.multi,
                      selectedIndexes: selected,
                      onChanged: _onChangeSelection,
                      questionFontSize: (){
                        if(_index != 6) return 21.0;
                        if(_index != 8) return 21.0;
                        return 22.0;
                      }(),
                      optionFontSize: (){
                        if(_index == 0 || _index == 3) return 13.2;
                        if(_index == 7) return 15.0;
                        if(_index != 6) return 14.0;
                        return 15.0;
                      }(),
                    ),
                    SizedBox(height: 20), // ← 하단 여백
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasSelection ? _goNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isLast ? '완료' : '다음', style: TextStyle(fontSize: 17),),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}