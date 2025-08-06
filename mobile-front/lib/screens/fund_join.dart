import 'package:flutter/material.dart';

class FundJoinPage extends StatelessWidget {
  const FundJoinPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String?>> items = [
      {
        "title": "[필수] 간이투자설명서 동의",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": "assets/pdf/simple_investment.pdf"
      },
      {
        "title": "[필수] 투자설명서 동의",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": "assets/pdf/investment_doc.pdf"
      },
      {
        "title": "[필수] 상품약관 동의",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": "assets/pdf/product_terms.pdf"
      },
      {
        "title": "[필수] 금융상품 가입 전 안내",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": "assets/pdf/product_info.pdf"
      },
      {
        "title": "불법·탈법 차명거래 금지 설명 확인",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": null
      },
      {
        "title": "예금자보호법 설명 확인",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": null
      },
      {
        "title": "은행상품 구속행위 규제제도 안내",
        "desc": "설명 내용",
        "enabled": "true",
        "pdf": null
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('펀드가입'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  bool enabled = items[index]['enabled'] == "true";
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: enabled ? Colors.white : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: enabled ? Colors.grey : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                items[index]['title']!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: enabled ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: (enabled && items[index]['pdf'] != null)
                              ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerPage(
                                  pdfPath: items[index]['pdf']!,
                                ),
                              ),
                            );
                          }
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(items[index]['desc']!),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "본인은 본 상품 가입에 필요한 필수 서류를 교부받고\n"
                  "그 내용을 충분히 이해하였으며,\n"
                  "이에 따라 본 상품 가입에 동의합니다",
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // 전체 동의 처리
              },
              child: const Text(
                '네, 동의합니다',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 단독 실행용 main 함수
void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FundJoinPage(),
  ));
}
