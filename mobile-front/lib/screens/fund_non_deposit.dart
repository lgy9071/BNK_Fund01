import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 색상 팔레트 (파란 계열 통일)
class AppColors {
  static const primary = Color(0xFF0064FF);   // 포인트 파랑
  static const botBubble = Color(0xFFF3F4F6); // 봇 말풍선 배경
  static const surface = Colors.white;        // 카드/버튼 기본
  static const border = Color(0xFFE5E7EB);    // 회색 보더
  static const text = Colors.black;           // 기본 텍스트
  static const textMute = Color(0xFF6B7280);  // 보조 텍스트
}

class NonDepositGuidePage extends StatefulWidget {
  const NonDepositGuidePage({super.key});

  @override
  State<NonDepositGuidePage> createState() => _NonDepositGuidePageState();
}

class _NonDepositGuidePageState extends State<NonDepositGuidePage> {
  // 공통 여백
  static const double kAvatar = 40;
  static const double kGap = 8;
  static const double kGutter = kAvatar + kGap; // 48

  // 금액 입력
  static const int _minAmount = 1000;
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  bool _shouldFocusAmount = false;
  bool _isFormatting = false;
  int? _amountValue; // 현재 숫자 값(콤마 제거 후)

  // 금액 제출 후 투자 방식 버튼 잠금 + 금액 카드 축소 표시
  bool _investChoiceLocked = false;
  bool _amountSubmitted = false;
  String? _selectedInvestPlan; // 투자 규칙 요약(예: "매주 • 금요일", "한 번만 투자하기")

  int currentStep = 0;
  final Map<int, String> answers = {};
  final Map<int, Set<String>> disabledOptions = {};
  final List<Map<String, dynamic>> messages = [];
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> steps = [
    {
      "question": "펀드의 원금 손실 위험 가능성에 대해 어떻게 생각하세요?",
      "options": ["원금 손실 위험이 있다", "원금 손실 위험이 없다"],
      "warning": "기대수익률이 높을수록 원금 손실 위험도 높아져요. 답변을 다시 선택해주세요.",
      "triggerWrong": "원금 손실 위험이 없다"
    },
    {
      "question": "펀드의 원금 손실 규모에 대해 어떻게 생각하세요?",
      "options": ["전부 손실도 가능하다", "원금 손실 위험 없다"],
      "warning": "상품마다 차이가 있지만, 최대 100%까지 손실이 발생할 수 있어요. 답변을 다시 선택해주세요.",
      "triggerWrong": "원금 손실 위험 없다"
    },
    {
      "question": "위 내용을 충분히 확인하셨나요?",
      "options": ["확인했어요", "아니오"],
      "warning": "원금 손실 위험 가능성과 최대 원금 손실 규모를 충분히 확인한 후 펀드에 투자할 수 있어요.",
      "triggerWrong": "아니오"
    },
  ];

  @override
  void initState() {
    super.initState();

    messages.add({
      "type": "notice",
      "title": "상품명에 가입하기 위해 추가 정보를 확인할게요",
      "desc": "펀드와 같은 비예금 상품은 일반 예금상품과 달리 원금의 일부 또는 전부 손실이 발생할 수 있어요"
    });

    messages.add({
      "type": "choice",
      "question": steps[0]["question"],
      "options": steps[0]["options"]
    });

    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _amountFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ───────── 금액 입력 변경 핸들러 ─────────
  void _onAmountChanged() {
    if (_isFormatting) return;
    _isFormatting = true;

    final digits = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');

    // ❌ 여기서 버튼 잠그지 않음 (요구사항: 완료 누르기 전까지는 선택 가능)

    if (digits.isEmpty) {
      _amountValue = null;
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormatting = false;
      setState(() {}); // 버튼 활성화 갱신
      return;
    }

    _amountValue = int.tryParse(digits);
    final formatted = _formatCurrency(_amountValue!);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _isFormatting = false;
    setState(() {}); // 버튼/상태 갱신
  }

  // 3자리 쉼표 포맷 (1234567 -> 1,234,567)
  String _formatCurrency(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  // ───────── 질문 응답 ─────────
  void selectAnswer(String answer) {
    final step = steps[currentStep];
    final triggerWrong = step["triggerWrong"];

    setState(() {
      if (answer != triggerWrong) {
        // 정답: 기록 + 사용자 버블
        answers[currentStep] = answer;
        messages.add({"type": "user", "text": answer});

        final isLast = currentStep == steps.length - 1;
        if (isLast && answer == "확인했어요") {
          // 투자 방식 선택(봇 버블)
          messages.add({
            "type": "investChoice",
            "question": "어떻게 투자할까요?",
            "desc": "가입 후에도 변경할 수 있어요.\n펀드 투자자의 12%가 매월 투자를 하고 있어요.",
            "options": ["매일/매주/매월 투자하기", "한 번만 투자하기"],
          });
        } else {
          if (currentStep < steps.length - 1) {
            currentStep++;
            messages.add({
              "type": "choice",
              "question": steps[currentStep]["question"],
              "options": steps[currentStep]["options"]
            });
          }
        }
      } else {
        // 오답: 보기 비활성화 + 경고 말풍선 추가
        disabledOptions.putIfAbsent(currentStep, () => <String>{}).add(answer);
        messages.add({"type": "warning", "text": step["warning"] ?? ""});
      }
    });

    _scrollToBottom();
  }

  // 투자 방식 선택: 바텀시트 (매일/매주/매월 + 세부)
  Future<void> _openScheduleSheet() async {
    final periodOptions = ["매일", "매주", "매월"];

    int periodIndex = 1; // 기본: 매주
    int subIndex = 0;

    List<String> subListFor(int pIdx) {
      final p = periodOptions[pIdx];
      if (p == "매일") return ["매일"]; // 매일은 하나만
      if (p == "매주") {
        return ["월요일","화요일","수요일","목요일","금요일","토요일","일요일"];
      }
      return List<String>.generate(31, (i) => "${i + 1}일");
    }

    final leftCtrl = FixedExtentScrollController(initialItem: periodIndex);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSB) {
            // 오른쪽 목록은 periodIndex에 의해 매 빌드 재계산
            final rightOptions = subListFor(periodIndex);

            // 좌측 변경 시 우측 즉시 교체되도록 key/ctrl 재생성
            final rightPickerKey = ValueKey("right-$periodIndex");
            final rightCtrl = FixedExtentScrollController(initialItem: 0);
            subIndex = 0;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "투자 주기 선택",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          // 왼쪽: 매일/매주/매월
                          Expanded(
                            child: CupertinoPicker(
                              itemExtent: 36,
                              scrollController: leftCtrl,
                              onSelectedItemChanged: (i) {
                                setSB(() {
                                  periodIndex = i; // setSB 호출로 재빌드 → 우측 key/children 교체
                                });
                              },
                              children: periodOptions.map((e) => Center(child: Text(e))).toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 오른쪽: 요일/일자/매일(단일)
                          Expanded(
                            child: CupertinoPicker(
                              key: rightPickerKey,          // 좌측 변경 → key 변경으로 즉시 갈아끼움
                              itemExtent: 36,
                              scrollController: rightCtrl,  // 항상 0번째
                              onSelectedItemChanged: (i) => subIndex = i,
                              children: rightOptions.map((e) => Center(child: Text(e))).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final p = periodOptions[periodIndex];
                          final s = rightOptions[subIndex];
                          Navigator.pop(ctx);
                          _confirmInvestPlan("$p • $s");
                        },
                        child: const Text("확인", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 투자 방식 확정 후: 사용자 버블 + 금액 질문으로 (키패드 자동 오픈)
  void _confirmInvestPlan(String summary) {
    _selectedInvestPlan = summary;
    setState(() {
      messages.add({"type": "user", "text": summary});
      messages.add({
        "type": "amount",
        "question": "얼마를 투자할까요?",
        "placeholder": "투자금액 입력 (천원부터 투자 가능)"
      });
      _amountController.text = '';
      _amountValue = null;
      _amountSubmitted = false;     // 아직 완료 전
      _investChoiceLocked = false;  // 완료 전엔 선택 가능
      _shouldFocusAmount = true;    // 키패드 자동
    });
    _scrollToBottom();
  }

  // 한 번만 투자하기 선택
  void _chooseOneTime() {
    _selectedInvestPlan = "한 번만 투자하기";
    setState(() {
      messages.add({"type": "user", "text": "한 번만 투자하기"});
      messages.add({
        "type": "amount",
        "question": "얼마를 투자할까요?",
        "placeholder": "투자금액 입력 (천원부터 투자 가능)"
      });
      _amountController.text = '';
      _amountValue = null;
      _amountSubmitted = false;
      _investChoiceLocked = false;
      _shouldFocusAmount = true;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool get _isAmountValid => (_amountValue ?? 0) >= _minAmount;

  // “확인” 클릭: 금액 제출 → 버튼 비활성 + 입력창/버튼 숨김 + 요약 버블
  void _submitAmount() {
    if (!_isAmountValid) return;
    final formatted = _formatCurrency(_amountValue!);

    setState(() {
      _investChoiceLocked = true; // 두 버튼 잠금
      _amountSubmitted = true;    // 금액 카드에서 입력창/버튼 숨김
      messages.add({"type": "user", "text": "$formatted 원"});
      messages.add({
        "type": "summary",
        "amount": "$formatted 원",
        "plan": _selectedInvestPlan ?? "선택 안 함",
      });
    });

    // 키보드 내리기 + 입력값 초기화
    FocusScope.of(context).unfocus();
    _amountController.clear();
    _amountValue = null;

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          '펀드 가입',
          style: TextStyle(color: AppColors.text),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.text),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상단 안내 박스 (원본 UI 유지)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "본 상품은 가입 시 일반 예금상품과 달리 "),
                        TextSpan(
                          text: "원금의 일부 또는 전부 손실이 발생",
                          style: TextStyle(color: Color(0xFFBC0000), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: "할 수 있으며, 투자로 인한 손실은 투자자 본인에게 귀속됩니다."),
                      ],
                    ),
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "중요사항 이해여부 확인과정에서 충분한 이해없이 확인했다고 답변할 경우 "),
                        TextSpan(
                          text: "추후 소송이나 분쟁에서 불리하게 작용",
                          style: TextStyle(color: Color(0xFFBC0000), fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: "할 수 있습니다."),
                      ],
                    ),
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 채팅 리스트 (원본 UI 흐름 유지)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  if (msg["type"] == "notice") return _noticeBubble(msg);
                  if (msg["type"] == "warning") return _botBubble(msg["text"]);
                  if (msg["type"] == "user") return _userBubble(msg["text"]);
                  if (msg["type"] == "investChoice") return _investChoiceBubble(msg);
                  if (msg["type"] == "amount") {
                    // 완료 전엔 입력창/확인 버튼 보이고, 완료 후엔 질문 텍스트만 남김
                    return _amountSubmitted ? _amountQuestionOnly(msg) : _amountBubble(msg);
                  }
                  if (msg["type"] == "summary") return _summaryBubble(msg);

                  if (msg["type"] == "choice") {
                    final stepIdx = messages
                        .sublist(0, index + 1)
                        .where((m) => m["type"] == "choice")
                        .length - 1;

                    final step = steps[stepIdx];
                    final answered = answers[stepIdx];
                    final triggerWrong = step["triggerWrong"];
                    final isAnswered = answered != null;
                    final disabledSet = disabledOptions[stepIdx] ?? {};
                    final hideImage = stepIdx == 0; // 첫 질문만 아바타 숨김
                    final hasWrong = disabledSet.isNotEmpty;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hideImage)
                          const SizedBox(width: kGutter)
                        else ...[
                          Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
                          const SizedBox(width: kGap),
                        ],
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.botBubble,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg["question"] ?? ""),
                                const SizedBox(height: 8),
                                ...List<Widget>.from((msg["options"] as List).map((opt) {
                                  final isSelected = answered == opt;
                                  final isManuallyDisabled = disabledSet.contains(opt);
                                  final isCorrectAnswer = hasWrong && opt != triggerWrong;
                                  final isDisabled = isAnswered || isManuallyDisabled;

                                  // 스타일
                                  Color bg;
                                  Color fg;
                                  BorderSide side;

                                  if (isDisabled) {
                                    // 비활성화 상태: 둘 다 동일 그레이
                                    bg = AppColors.surface;
                                    fg = AppColors.textMute;
                                    side = const BorderSide(color: AppColors.border);
                                  } else if (isSelected || isCorrectAnswer) {
                                    bg = AppColors.primary;
                                    fg = Colors.white;
                                    side = const BorderSide(color: AppColors.primary);
                                  } else {
                                    bg = AppColors.surface;
                                    fg = AppColors.text;
                                    side = const BorderSide(color: AppColors.border);
                                  }

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: bg,
                                        foregroundColor: fg,
                                        minimumSize: const Size(double.infinity, 44),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                          side: side,
                                        ),
                                        elevation: 0,
                                      ),
                                      onPressed: isDisabled ? null : () => selectAnswer(opt),
                                      child: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  );
                                })),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 공지 버블
  Widget _noticeBubble(Map<String, dynamic> msg) {
    final isFirstNotice = msg["title"] == "상품명에 가입하기 위해 추가 정보를 확인할게요";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFirstNotice) ...[
          Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
          const SizedBox(width: kGap),
        ] else
          const SizedBox(width: kGutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '상품명', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: (msg["title"] as String?)?.replaceFirst('상품명', '') ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(msg["desc"] ?? ''),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 경고 버블(아바타 없는 줄)
  Widget _botBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: kGutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }

  // 사용자 버블 (파란색)
  Widget _userBubble(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  // ▶ 투자 방식 선택 말풍선 (경고 없음) — 아바타 포함
  Widget _investChoiceBubble(Map<String, dynamic> msg) {
    final bool disabled = _investChoiceLocked;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
        const SizedBox(width: kGap),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg["question"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(msg["desc"] ?? "", style: TextStyle(color: AppColors.textMute)),
                const SizedBox(height: 12),
                _pillButton("매일/매주/매월 투자하기",
                    onTap: disabled ? null : _openScheduleSheet, disabled: disabled),
                const SizedBox(height: 8),
                _pillButton("한 번만 투자하기",
                    onTap: disabled ? null : _chooseOneTime, disabled: disabled),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ▶ 금액 질문 말풍선 (숫자 입력 + 키패드 즉시 + 아바타 포함)
  Widget _amountBubble(Map<String, dynamic> msg) {
    if (_shouldFocusAmount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_amountFocus);
          _shouldFocusAmount = false;
        }
      });
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
        const SizedBox(width: kGap),
        Expanded(child: _amountCard(msg)),
      ],
    );
  }

  // 금액 입력 완료 후: 질문 텍스트만 남기는 버전
  Widget _amountQuestionOnly(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
        const SizedBox(width: kGap),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(msg["question"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // 금액 입력 카드 + 확인 버튼
  Widget _amountCard(Map<String, dynamic> msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.botBubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg["question"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocus,
              keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: msg["placeholder"] ?? "투자금액 입력",
                suffixText: (_amountValue == null) ? null : "원", // 숫자 입력되면 '원' 표시
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitAmount(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAmountValid ? AppColors.primary : AppColors.surface,
                foregroundColor: _isAmountValid ? Colors.white : AppColors.textMute,
                minimumSize: const Size(double.infinity, 46),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: _isAmountValid ? AppColors.primary : AppColors.border),
                ),
              ),
              onPressed: _isAmountValid ? _submitAmount : null,
              child: const Text("확인", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // 요약 버블 (투자금액 / 투자 규칙)
  Widget _summaryBubble(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: kGutter),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.botBubble,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("투자금액", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(msg["amount"] ?? ""),
                const SizedBox(height: 8),
                const Text("투자 규칙", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(msg["plan"] ?? ""),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillButton(String text, {required VoidCallback? onTap, bool disabled = false}) {
    final bg = disabled ? AppColors.botBubble : AppColors.surface; // 비활성은 회색 배경
    final fg = disabled ? AppColors.textMute : AppColors.text;     // 비활성은 회색 글자
    final sideColor = AppColors.border;                             // 회색 테두리

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          minimumSize: const Size(double.infinity, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: sideColor),
          ),
        ),
        onPressed: disabled ? null : onTap, // 완전 비활성
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NonDepositGuidePage(),
  ));
}
