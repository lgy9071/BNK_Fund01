import 'package:flutter/material.dart';

class FundJoinPage extends StatefulWidget {
  const FundJoinPage({super.key});

  @override
  State<FundJoinPage> createState() => _FundJoinPageState();
}

class _FundJoinPageState extends State<FundJoinPage> {
  final List<Map<String, dynamic>> requiredDocs = [
    {"title": "[필수] 간이투자설명서 동의", "checked": false},
    {"title": "[필수] 투자설명서 동의", "checked": false},
    {"title": "[필수] 상품약관 동의", "checked": false},
    {"title": "[필수] 금융상품 가입 전 안내", "checked": false},
  ];

  final List<Map<String, dynamic>> infoDocs = [
    {
      "title": "불법·탈법 차명거래 금지 설명 확인",
      "desc":
      "「금융실명거래 및 비밀보장에 관한 법률」 제3조 제3항에 따라 누구든지 불법재산의 은닉, 자금세탁행위, 공중협박자금 조달행위 및 강제집행의 면탈, 그 밖의 탈법행위를 목적으로 타인의 실명으로 금융거래를 하여서는 안되며, 이를 위반 시 5년 이하의 징역 또는 5천만원 이하의 벌금에 처해질 수 있습니다. 본인은 위 내용을 안내 받고, 충분히 이해하였음을 확인합니다.",
      "checked": false
    },
    {
      "title": "예금자보호법 설명 확인",
      "desc":
      "본인이 가입하는 금융상품(펀드)은 예금자보호법에 따라 보호되지 않음(단, 투자자예탁금에 한하여 원금과 소정의 이자를 합하여 1인당 5천만원까지 보호)에 대하여 설명을 보고, 충분히 이해하였음을 확인합니다.",
      "checked": false
    },
    {
      "title": "은행상품 구속행위 규제제도 안내",
      "desc":
      "금융소비자보호법(제20조)상 구속행위 여부 판정에 따라 신규일 이후 1개월 이내 본인명의 대출거래가 제한될 수 있습니다.",
      "checked": false
    },
  ];

  bool get isAllChecked {
    return requiredDocs.every((doc) => doc['checked'] == true) &&
        infoDocs.every((doc) => doc['checked'] == true);
  }

  void toggleCheck(Map<String, dynamic> item) {
    setState(() {
      item['checked'] = !item['checked'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('펀드 가입'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ 스크롤 영역
            Expanded(
              child: ListView(
                children: [
                  // 섹션 1
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: requiredDocs.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            onTap: () => toggleCheck(item),
                            child: Row(
                              children: [
                                Icon(
                                  item['checked']
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: item['checked']
                                      ? const Color(0xFF00067D)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: item['checked']
                                          ? Colors.black
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 섹션 2
                  ...infoDocs.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => toggleCheck(item),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    item['checked']
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: item['checked']
                                        ? const Color(0xFF00067D)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['desc'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // ✅ 안내 문구만 스크롤에 포함
                  const Text(
                    "본인은 본 상품 가입에 필요한 필수 서류를 교부받고\n"
                        "그 내용을 충분히 이해하였으며,\n"
                        "이에 따라 본 상품 가입에 동의합니다",
                    style: TextStyle(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ✅ 버튼 (활성/비활성)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isAllChecked ? const Color(0xFF00067D) : Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: isAllChecked ? () {
                // 동의 버튼 눌렀을 때 처리
              } : null,
              child: Text(
                '네, 동의합니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAllChecked ? Colors.white : Colors.grey,
                ),
              ),
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
    home: FundJoinPage(),
  ));
}

