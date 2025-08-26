// lib/pdf_confirm_sheet.dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

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
  final PdfViewerController _viewerController = PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 1;
  bool _loading = true;
  String? _error;

  String _fixUrl(String url) {
    // return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    return url;
  }

  bool get _atLastPage => _currentPage >= _totalPages && _totalPages > 0;

  @override
  void dispose() {
    // PdfViewerController에는 dispose 없음
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const tossBlue = Color(0xFF0061FF);
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(16));
    final uri = Uri.parse(_fixUrl(widget.url));

    // 하단 버튼에 가리지 않도록 여유 패딩
    final safeBottom = MediaQuery.of(context).padding.bottom;
    const barInnerHeight = 56.0;
    const barVPadding = 16.0;
    final bottomBarHeight = barInnerHeight + barVPadding + safeBottom;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.94,
            minChildSize: 0.7,
            maxChildSize: 0.98,
            expand: false,
            builder: (context, _) {
              return Scaffold(
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
                body: Stack(
                  children: [
                    // PDF 뷰어 (마지막 페이지가 버튼에 가리지 않게 하단 패딩)
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomBarHeight),
                        child: PdfViewer.uri(
                          uri,
                          controller: _viewerController,
                          params: PdfViewerParams(
                            // 문서 준비 완료: 총 페이지 계산 + 1페이지로 강제 시작
                            onViewerReady: (document, controller) {
                              if (!mounted) return;
                              setState(() {
                                _totalPages = document.pages.length;
                                _loading = false;
                                _error = null;
                                _currentPage = 1;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _viewerController.goToPage(pageNumber: 1);
                              });
                            },
                            // 페이지 변경 추적
                            onPageChanged: (pageNumber) {
                              if (!mounted) return;
                              final p = pageNumber ?? _currentPage;
                              if (p != _currentPage) {
                                setState(() => _currentPage = p);
                              }
                            },
                            // 스크롤 썸(기본 제공) — 2.1.x에서는 커스텀 파라미터 제한적
                            viewerOverlayBuilder: (context, size, handleLinkTap) {
                              return [
                                PdfViewerScrollThumb(
                                  controller: _viewerController,
                                  // 2.1.x에선 alignment/label/height 등의 파라미터가 없을 수 있어요.
                                  // 기본 썸을 그대로 사용(기능만).
                                ),
                              ];
                            },
                          ),
                        ),
                      ),
                    ),

                    // 페이지 카운터 배지
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_currentPage / $_totalPages',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    // 하단 확인 버튼
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16 + MediaQuery.of(context).padding.bottom,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _atLastPage ? tossBlue : Colors.grey.shade300,
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
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _atLastPage ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),

                    // 로딩/에러 오버레이
                    if (_loading)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    if (_error != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
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
