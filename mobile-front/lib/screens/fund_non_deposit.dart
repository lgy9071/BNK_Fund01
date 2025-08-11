import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 색상 팔레트 (파란 계열 통일)
class AppColors {
  static const primary = Color(0xFF0064FF);   // 포인트 파랑
  static const btn = Color(0xFF2D1ADA);       // 버튼 색상
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
  int? _amountValue;

  // 상태
  bool _investChoiceLocked = false; // 금액 제출 후 두 버튼 비활성화
  bool _amountSubmitted = false;    // 금액 카드에서 입력창/버튼 숨김
  String? _selectedInvestPlan;      // 예: "매주 • 금요일", "한 번만 투자하기"
  String _selectedAccount = "성윤지의 통장1"; // 출금계좌

  // 신규: 사후관리지점
  String? _selectedBranch;          // 예: "부산중앙지점" / "없음"
  String? _lastAmountText;          // 예: "100,000 원"

  // “버블 1개” 유지용 인덱스
  int? _planUserMsgIndex;   // 사용자 버블(투자 규칙) 위치
  int? _amountMsgIndex;     // 금액 입력 버블 위치

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

    if (digits.isEmpty) {
      _amountValue = null;
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormatting = false;
      setState(() {});
      return;
    }

    _amountValue = int.tryParse(digits);
    final formatted = _formatCurrency(_amountValue!);
    _amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _isFormatting = false;
    setState(() {});
  }

  // 3자리 쉼표 포맷
  String _formatCurrency(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final r = s.length - i;
      buf.write(s[i]);
      if (r > 1 && r % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  // ───────── 질문 응답 ─────────
  void selectAnswer(String answer) {
    final step = steps[currentStep];
    final triggerWrong = step["triggerWrong"];

    setState(() {
      if (answer != triggerWrong) {
        answers[currentStep] = answer;
        messages.add({"type": "user", "text": answer});

        final isLast = currentStep == steps.length - 1;
        if (isLast && answer == "확인했어요") {
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
        disabledOptions.putIfAbsent(currentStep, () => <String>{}).add(answer);
        messages.add({"type": "warning", "text": step["warning"] ?? ""});
      }
    });

    _scrollToBottom();
  }

  // ───────── 투자 방식 선택 공통 처리 (버블 1개 유지) ─────────
  void _setPlanAndEnsureAmountBubble(String summary) {
    _selectedInvestPlan = summary;

    setState(() {
      // 사용자 버블(투자 규칙) — 있으면 업데이트, 없으면 추가
      if (_planUserMsgIndex == null) {
        messages.add({"type": "user", "text": summary});
        _planUserMsgIndex = messages.length - 1;
      } else {
        messages[_planUserMsgIndex!]["text"] = summary;
      }

      // 금액 입력 버블 — 1개만 유지
      final amountMsg = {
        "type": "amount",
        "question": "얼마를 투자할까요?",
        "placeholder": "투자금액 입력 (천원부터 투자 가능)"
      };
      if (_amountMsgIndex == null) {
        messages.add(amountMsg);
        _amountMsgIndex = messages.length - 1;
      } else {
        messages[_amountMsgIndex!] = amountMsg; // 같은 자리 재사용
      }

      // 입력 상태 초기화 (키패드 띄우기)
      _amountController.text = '';
      _amountValue = null;
      _amountSubmitted = false;
      _investChoiceLocked = false; // 제출 전까진 선택 가능
      _shouldFocusAmount = true;
    });

    _scrollToBottom();
  }

  // 투자 방식 선택: 바텀시트
  Future<void> _openScheduleSheet() async {
    final periodOptions = ["매일", "매주", "매월"];
    int periodIndex = 1; // 기본: 매주
    int subIndex = 0;

    List<String> subListFor(int pIdx) {
      final p = periodOptions[pIdx];
      if (p == "매일") return ["매일"];
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
            final rightOptions = subListFor(periodIndex);
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
                          child: Text("투자 주기 선택",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoPicker(
                              itemExtent: 36,
                              scrollController: leftCtrl,
                              onSelectedItemChanged: (i) {
                                setSB(() { periodIndex = i; });
                              },
                              children: periodOptions.map((e) => Center(child: Text(e))).toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoPicker(
                              key: rightPickerKey,
                              itemExtent: 36,
                              scrollController: rightCtrl,
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
                          _setPlanAndEnsureAmountBubble("$p • $s");
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

  // 한 번만 투자하기
  void _chooseOneTime() => _setPlanAndEnsureAmountBubble("한 번만 투자하기");

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

  // 금액 확인
  void _submitAmount() {
    if (!_isAmountValid) return;
    final formatted = _formatCurrency(_amountValue!);

    setState(() {
      _investChoiceLocked = true; // 버튼 잠금
      _amountSubmitted = true;    // 입력창/확인 버튼 숨김
      _lastAmountText = "$formatted 원";

      messages.add({"type": "user", "text": _lastAmountText}); // 사용자 버블

      // ✅ 금액 다음 질문: 사후관리지점 선택
      messages.add({
        "type": "branchChoice",
        "question": "사후관리지점은 어떻게 할까요?",
        "handled": false,
      });
    });

    FocusScope.of(context).unfocus();
    _amountController.clear();
    _amountValue = null;
    _scrollToBottom();
  }

  // ──────── 사후관리지점: '없음' 선택 ────────
  void _chooseBranchNone() {
    setState(() {
      _selectedBranch = "없음";
      _markLastBranchChoiceHandled();
      messages.add({"type": "user", "text": "사후관리지점: 없음"});
      _enqueueDebitConfirm();
    });
    _scrollToBottom();
  }

  // ──────── 사후관리지점: 지점 선택 (바텀시트) ────────
  Future<void> _selectBranch() async {
    final branches = <String>[
      "부산중앙지점",
      "부산서면지점",
      "서울강남지점",
      "서울광화문지점",
      "대구동성로지점",
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text("지점 선택", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.border),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, i) {
                    return ListTile(
                      title: Text(branches[i]),
                      onTap: () => Navigator.pop(ctx, branches[i]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    setState(() {
      _selectedBranch = selected;
      _markLastBranchChoiceHandled();
      messages.add({"type": "user", "text": "사후관리지점: $selected"});
      _enqueueDebitConfirm();
    });
    _scrollToBottom();
  }

  // 마지막 branchChoice 버블 handled=true 로 표시
  void _markLastBranchChoiceHandled() {
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i]["type"] == "branchChoice" && messages[i]["handled"] == false) {
        messages[i]["handled"] = true;
        break;
      }
    }
  }

  // 사후관리지점 선택 후 → 출금계좌 확인 말풍선 큐잉
  void _enqueueDebitConfirm() {
    messages.add({
      "type": "debitConfirm",
      "amount": _lastAmountText ?? "",
      "account": _selectedAccount,
      "handled": false,
    });
  }

  // 출금계좌 변경 반영
  void _updateLastDebitConfirmAccount(String newAccount) {
    _selectedAccount = newAccount;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i]["type"] == "debitConfirm" && messages[i]["handled"] == false) {
        setState(() { messages[i]["account"] = newAccount; });
        break;
      }
    }
  }

  // 출금계좌 확인 완료 → 요약
  void _confirmDebitAndShowSummary(Map<String, dynamic> msg) {
    if (msg["handled"] == true) return;
    setState(() {
      msg["handled"] = true;
      messages.add({"type": "user", "text": "확인했어요"});
      messages.add({
        "type": "summary",
        "amount": msg["amount"] ?? "",
        "plan": _selectedInvestPlan ?? "선택 안 함",
        "account": _selectedAccount,
        "branch": _selectedBranch ?? "없음",
      });
    });
    _scrollToBottom();
  }

  // 계좌 선택 바텀시트
  Future<void> _openAccountSheet() async {
    final items = [
      "성윤지의 통장1",
      "성윤지의 통장2",
      "성윤지의 통장3",
    ];
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              return ListTile(
                title: Text(items[i]),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateLastDebitConfirmAccount(items[i]);
                },
              );
            },
          ),
        );
      },
    );
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
            // 상단 안내 박스
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

            // 채팅 리스트
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
                  if (msg["type"] == "branchChoice") return _branchChoiceBubble(msg);
                  if (msg["type"] == "amount") {
                    return _amountSubmitted ? _amountQuestionOnly(msg) : _amountBubble(msg);
                  }
                  if (msg["type"] == "debitConfirm") return _debitConfirmBubble(msg);
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

                                  Color bg;
                                  Color fg;
                                  BorderSide side;

                                  if (isDisabled) {
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

  // ▶ 투자 방식 선택 말풍선
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
                Text(msg["desc"] ?? "", style: const TextStyle(color: AppColors.textMute)),
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

  // ▶ 사후관리지점 선택 말풍선
  Widget _branchChoiceBubble(Map<String, dynamic> msg) {
    final bool handled = (msg["handled"] as bool?) ?? false;

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
                const Text("사후관리지점은 어떻게 할까요?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _pillButton("지점 선택", onTap: handled ? null : _selectBranch, disabled: handled),
                const SizedBox(height: 8),
                _pillButton("없음", onTap: handled ? null : _chooseBranchNone, disabled: handled),
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

  // 제출 후: 질문 텍스트만
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
            child: Text(msg["question"] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                suffixText: (_amountValue == null) ? null : "원",
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

  // 출금계좌 확인 버블
  Widget _debitConfirmBubble(Map<String, dynamic> msg) {
    final handled = (msg["handled"] as bool?) ?? false;
    final amount = msg["amount"] as String? ?? "";
    final account = msg["account"] as String? ?? _selectedAccount;

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
                Text("$amount을\n아래 계좌에서 출금할게요.",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text("· 출금계좌  ", style: TextStyle(color: AppColors.textMute)),
                    Expanded(child: Text(account, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: handled ? AppColors.botBubble : AppColors.primary,
                      foregroundColor: handled ? AppColors.textMute : Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: handled ? AppColors.border : AppColors.primary),
                      ),
                    ),
                    onPressed: handled ? null : () => _confirmDebitAndShowSummary(msg),
                    child: const Text("확인했어요", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.text,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onPressed: handled ? null : _openAccountSheet,
                    child: const Text("출금계좌 변경하기", style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ 요약 버블 (아바타 + '펀드 가입하기' 버튼 추가)
  Widget _summaryBubble(Map<String, dynamic> msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/images/bear.png', width: kAvatar, height: kAvatar),
        const SizedBox(width: kGap),
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
                const Text("지금까지 입력한 내용을\n요약해서 보여드릴게요.",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                const Text("· 투자금액", style: TextStyle(color: AppColors.textMute)),
                Text(msg["amount"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text("· 투자규칙", style: TextStyle(color: AppColors.textMute)),
                Text(msg["plan"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text("· 출금계좌", style: TextStyle(color: AppColors.textMute)),
                Text(msg["account"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text("· 사후관리지점", style: TextStyle(color: AppColors.textMute)),
                Text(msg["branch"] ?? "없음", style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.btn,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // TODO: 실제 가입 처리
                    },
                    child: const Text("펀드 가입하기", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pillButton(String text, {required VoidCallback? onTap, bool disabled = false}) {
    final bg = disabled ? AppColors.botBubble : AppColors.surface;
    final fg = disabled ? AppColors.textMute : AppColors.text;
    final sideColor = AppColors.border;

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
        onPressed: disabled ? null : onTap,
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
