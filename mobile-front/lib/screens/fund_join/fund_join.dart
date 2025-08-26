// lib/screens/fund_join_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api.dart';
import 'pdf_confirm_sheet.dart';
import 'fund_non_deposit.dart';

class FundJoinPage extends StatefulWidget {
  final String fundId;
  final int productId;
  const FundJoinPage({super.key, required this.fundId, required this.productId});

  @override
  State<FundJoinPage> createState() => _FundJoinPageState();
}

class RequiredDoc {
  final String type;   // "간이투자설명서" / "투자설명서" / "이용약관"
  final String title;  // "[필수] ..."
  final String url;    // /fund_document/xxx.pdf 또는 절대 URL
  bool checked;

  RequiredDoc({
    required this.type,
    required this.title,
    required this.url,
    this.checked = false,
  });

  factory RequiredDoc.fromJson(Map<String, dynamic> j) {
    return RequiredDoc(
      type: j['type'] as String,
      title: j['title'] as String,
      url: j['url'] as String,
    );
  }
}

class _FundJoinPageState extends State<FundJoinPage> {
  List<RequiredDoc> requiredDocs = [];

  // 설명 확인 3개 (텍스트 동의)
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

  bool _loading = true;
  String? _error;
  bool _openingPdf = false; // 연속 탭 방지

  bool get _requiredAllChecked =>
      requiredDocs.isNotEmpty && requiredDocs.every((d) => d.checked);

  bool get _infoAllChecked => infoDocs.every((d) => d['checked'] == true);

  bool get isAllChecked => _requiredAllChecked && _infoAllChecked;

  @override
  void initState() {
    super.initState();
    _fetchDocs();
  }

  Future<void> _fetchDocs() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/funds/${widget.fundId}/documents',
      );
      final res = await http.get(url);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final List<dynamic> arr = json.decode(res.body);
        setState(() {
          requiredDocs = arr.map((e) => RequiredDoc.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = '문서 목록 조회 실패 (${res.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '문서 목록 조회 중 오류: $e';
        _loading = false;
      });
    }
  }

  void _toggleInfoCheck(Map<String, dynamic> item) {
    setState(() {
      item['checked'] = !(item['checked'] as bool);
    });
  }

  Future<void> _openPdfAndConfirm(RequiredDoc doc) async {
    if (_openingPdf) return;
    setState(() => _openingPdf = true);

    final pdfUrl =
    doc.url.startsWith('http') ? doc.url : '${ApiConfig.baseUrl}${doc.url}';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors
          .transparent,
      builder: (_) => PdfConfirmSheet(title: doc.title, url: pdfUrl),
    );

    if (!mounted) return;
    if (result == true) {
      setState(() {
        doc.checked = true;
      });
    }
    setState(() => _openingPdf = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeBlue = const Color(0xFF00067D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('펀드 가입'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 스크롤 영역
            Expanded(
              child: ListView(
                children: [
                  // 섹션 1: 필수 문서 (행 탭 → PDF 열기)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final doc in requiredDocs)
                          InkWell(
                            onTap: _openingPdf
                                ? null
                                : () => _openPdfAndConfirm(doc),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    doc.checked
                                        ? Icons.check_circle
                                        : Icons
                                        .radio_button_unchecked,
                                    color: doc.checked
                                        ? themeBlue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      doc.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: doc.checked
                                            ? Colors.black
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  // 👉 '보기' 버튼 제거 (행 전체가 탭 타겟)
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 섹션 2: 설명 확인 3개 (텍스트 동의)
                  ...infoDocs.map((item) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () => _toggleInfoCheck(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    (item['checked'] as bool)
                                        ? Icons.check_circle
                                        : Icons
                                        .radio_button_unchecked,
                                    color:
                                    (item['checked'] as bool)
                                        ? themeBlue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
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
                                item['desc'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // 안내 문구
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

            // 하단 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllChecked
                    ? themeBlue
                    : Colors.grey.shade300,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: isAllChecked
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NonDepositGuidePage(
                          fundId: widget.fundId,
                          productId: widget.productId,
                        ),
                  ),
                );
              }
                  : null,
              child: Text(
                '네, 동의합니다',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAllChecked
                      ? Colors.white
                      : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
