import 'package:flutter/material.dart';

class NonDepositGuidePage extends StatefulWidget {
  const NonDepositGuidePage({super.key});

  @override
  State<NonDepositGuidePage> createState() => _NonDepositGuidePageState();
}

class _NonDepositGuidePageState extends State<NonDepositGuidePage> {
  int currentStep = 0;
  Map<int, String> answers = {};
  Map<int, Set<String>> disabledOptions = {};
  List<Map<String, dynamic>> messages = [];
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
    }
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
  }

  void selectAnswer(String answer) {
    final step = steps[currentStep];
    final triggerWrong = step["triggerWrong"];

    setState(() {
      if (answer != triggerWrong) {
        answers[currentStep] = answer;
        messages.add({"type": "user", "text": answer});

        if (currentStep < steps.length - 1) {
          currentStep++;
          messages.add({
            "type": "choice",
            "question": steps[currentStep]["question"],
            "options": steps[currentStep]["options"]
          });
        }
      } else {
        disabledOptions.putIfAbsent(currentStep, () => <String>{}).add(answer);
        messages.add({"type": "warning", "text": step["warning"] ?? ""});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == steps.length - 1;
    final selectedAnswer = answers[currentStep];
    final showNextButton = isLastStep && selectedAnswer == "확인했어요";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('펀드 가입', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
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
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  if (msg["type"] == "notice") return _noticeBubble(msg);
                  if (msg["type"] == "warning") return _botBubble(msg["text"]);
                  if (msg["type"] == "user") return _userBubble(msg["text"]);

                  if (msg["type"] == "choice") {
                    final stepIdx = messages.sublist(0, index + 1).where((m) => m["type"] == "choice").length - 1;
                    final step = steps[stepIdx];
                    final answered = answers[stepIdx];
                    final triggerWrong = step["triggerWrong"];
                    final isAnswered = answered != null;
                    final disabledSet = disabledOptions[stepIdx] ?? {};
                    final hideImage = stepIdx == 0; // 첫 번째 질문만 이미지 숨김

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        hideImage
                            ? const SizedBox(width: 48)
                            : Image.asset('assets/images/bear.png', width: 40, height: 40),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg["question"] ?? ""),
                                const SizedBox(height: 8),
                                ...msg["options"].map<Widget>((opt) {
                                  final isSelected = answered == opt;
                                  final isManuallyDisabled = disabledSet.contains(opt);
                                  final hasWrongAnswer = disabledSet.isNotEmpty;
                                  final isCorrectAnswer = hasWrongAnswer && opt != triggerWrong;
                                  final isHighlighted = isSelected || isCorrectAnswer;
                                  final isDisabled = isAnswered || isManuallyDisabled;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isHighlighted
                                            ? const Color(0xFF0059FF)
                                            : Colors.grey.shade200,
                                        foregroundColor: isHighlighted
                                            ? Colors.white
                                            : Colors.black,
                                        minimumSize: const Size(double.infinity, 44),
                                      ),
                                      onPressed: isDisabled ? null : () => selectAnswer(opt),
                                      child: Text(opt),
                                    ),
                                  );
                                }).toList(),
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
            const SizedBox(height: 16),
            if (showNextButton)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00067D),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {

                },
                child: const Text("다음", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _noticeBubble(Map<String, dynamic> msg) {
    final isFirstNotice = msg["title"] == "상품명에 가입하기 위해 추가 정보를 확인할게요";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isFirstNotice
            ? Image.asset('assets/images/bear.png', width: 40, height: 40)
            : const SizedBox(width: 48),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '상품명',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: (msg["title"] as String?)?.replaceFirst('상품명', '') ?? '',
                      ),
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

  Widget _botBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 48),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text),
          ),
        ),
      ],
    );
  }

  Widget _userBubble(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0059FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NonDepositGuidePage(),
  ));
}
