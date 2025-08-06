import 'package:flutter/material.dart';

class NonDepositGuidePage extends StatefulWidget {
  const NonDepositGuidePage({super.key});

  @override
  State<NonDepositGuidePage> createState() => _NonDepositGuidePageState();
}

class _NonDepositGuidePageState extends State<NonDepositGuidePage> {
  int currentStep = 0;
  Map<int, String> answers = {};
  Map<int, Set<String>> disabledOptions = {}; // 비활성화된 옵션 저장
  List<Map<String, dynamic>> messages = [];

  final List<Map<String, dynamic>> steps = [
    {
      "question": "펀드의 원금 손실 위험 가능성에 대해 어떻게 생각하세요?",
      "options": ["원금 손실 위험이 있다", "원금 손실 위험이 없다"],
      "warning": "기대수익률이 높을수록 원금 손실 위험도 높아집니다. 답변을 다시 선택해주세요.",
      "triggerWrong": "원금 손실 위험이 없다"
    },
    {
      "question": "펀드의 원금 손실 규모에 대해 어떻게 생각하세요?",
      "options": ["전부 손실도 가능하다", "원금 손실 위험 없다"],
      "warning": "상품마다 차이가 있지만, 최대 100%까지 손실이 발생할 수 있습니다. 답변을 다시 선택해주세요.",
      "triggerWrong": "원금 손실 위험 없다"
    },
    {
      "question": "위 내용을 충분히 확인하셨나요?",
      "options": ["확인했어요", "아니오"],
      "warning": null,
      "triggerWrong": "아니오"
    }
  ];

  @override
  void initState() {
    super.initState();
    messages.add({"type": "question", "text": steps[0]["question"]});
  }

  void selectAnswer(String answer) {
    final step = steps[currentStep];

    setState(() {
      answers[currentStep] = answer;
      messages.add({"type": "answer", "text": answer});

      if (step["triggerWrong"] == answer) {
        // 잘못된 답변이면 해당 버튼만 비활성화
        disabledOptions.putIfAbsent(currentStep, () => {}).add(answer);
        messages.add({"type": "warning", "text": step["warning"] ?? ""});
      } else {
        // 올바른 답변이면 다음 질문으로 이동
        if (currentStep < steps.length - 1) {
          currentStep++;
          messages.add({"type": "question", "text": steps[currentStep]["question"]});
        }
      }
    });
  }

  bool get isCompleted => answers.length == steps.length &&
      disabledOptions.keys.every((key) => !steps[key]["options"]
          .every((opt) => disabledOptions[key]?.contains(opt) ?? false));

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];

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
            // 상단 경고 문구
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
                          style: TextStyle(
                              color: Color(0xFFBC0000),
                              fontWeight: FontWeight.bold),
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
                        TextSpan(
                            text: "중요사항 이해여부 확인과정에서 충분한 이해없이 확인했다고 답변할 경우 "),
                        TextSpan(
                          text: "추후 소송이나 분쟁에서 불리하게 작용",
                          style: TextStyle(
                              color: Color(0xFFBC0000),
                              fontWeight: FontWeight.bold),
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

            // 채팅 영역
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  if (msg["type"] == "question" || msg["type"] == "warning") {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/bear.png', width: 40, height: 40),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(msg["text"]),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00067D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg["text"], style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            // 선택 버튼
            Column(
              children: step["options"].map<Widget>((opt) {
                final isSelected = answers[currentStep] == opt;
                final isDisabled =
                    disabledOptions[currentStep]?.contains(opt) ?? false;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? const Color(0xFF00067D)
                          : Colors.grey.shade200,
                      foregroundColor:
                      isSelected ? Colors.white : Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: isDisabled ? null : () => selectAnswer(opt),
                    child: Text(opt),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // 다음 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isCompleted ? const Color(0xFF00067D) : Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: isCompleted
                  ? () {
                // 다음 화면 이동
              }
                  : null,
              child: const Text("다음", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
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
