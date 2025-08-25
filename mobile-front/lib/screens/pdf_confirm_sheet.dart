// lib/pdf_confirm_sheet.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

class PdfConfirmSheet extends StatefulWidget {
  final String title;
  final String url;

  const PdfConfirmSheet({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  State<PdfConfirmSheet> createState() => _PdfConfirmSheetState();
}

class _PdfConfirmSheetState extends State<PdfConfirmSheet> {
  PdfControllerPinch? _controller;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _loading = true;
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final String url = _fixUrl(widget.url);
      final res = await http.get(Uri.parse(url));

      if (res.statusCode != 200) {
        _fail('PDF 로드 실패 (${res.statusCode})');
        return;
      }

      _bytes = res.bodyBytes;

      _controller = PdfControllerPinch(
        document: PdfDocument.openData(_bytes!), // Future<PdfDocument>
      );

      final tempDoc = await PdfDocument.openData(_bytes!);
      _totalPages = tempDoc.pagesCount;

      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      _fail('PDF 로드 중 오류: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = msg;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _fixUrl(String url) {
    // return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    return url;
  }

  bool get _atLastPage => _currentPage >= _totalPages && _totalPages > 0;

  @override
  Widget build(BuildContext context) {
    const tossBlue = Color(0xFF0061FF);
    final borderRadius = BorderRadius.vertical(top: Radius.circular(16));

    // 👇 시트 전체를 둥글게: ClipRRect + Material(white)
    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: Colors.white, // 내부 배경 (모달 배경은 투명으로 설정했음)
        child: SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.94,
            minChildSize: 0.7,
            maxChildSize: 0.98,
            expand: false,
            builder: (context, scrollController) {
              return Scaffold(
                // 배경은 Material에 이미 있으니 투명해도 OK
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(widget.title),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _error != null
                          ? Center(child: Text(_error!))
                          : _controller == null
                          ? const Center(child: Text('컨트롤러 생성 실패'))
                          : Stack(
                        children: [
                          PdfViewPinch(
                            controller: _controller!,
                            onPageChanged: (page) {
                              if (!mounted) return;
                              setState(() => _currentPage = page);
                            },
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_currentPage / $_totalPages',
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _atLastPage ? tossBlue : Colors.grey.shade300,
                            minimumSize: const Size(double.infinity, 40),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _atLastPage ? () => Navigator.pop(context, true) : null,
                          child: Text(
                            '확인했습니다',
                            style: TextStyle(
                              fontSize: 20,              // ⬅️ 글자도 같이 키우면 균형 좋아짐
                              fontWeight: FontWeight.w600,
                              color: _atLastPage ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),

                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
