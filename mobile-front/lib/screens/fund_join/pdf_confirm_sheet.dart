// lib/pdf_confirm_sheet.dart
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:async';
import 'dart:math' as math;

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

  // 부드러움 보정(스로틀/애니메이션)
  static const int _throttleMs = 60;
  int _lastJumpUs = 0;
  int? _pendingPage;
  Timer? _throttleTimer;
  Timer? _animateTimer;

  String _fixUrl(String url) {
    // return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
    return url;
  }

  bool get _atLastPage => _currentPage >= _totalPages && _totalPages > 0;

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _animateTimer?.cancel();
    super.dispose();
  }

  void _goToPageThrottled(int target) {
    if (_totalPages <= 0) return;
    final nowUs = DateTime.now().microsecondsSinceEpoch;

    void jump(int p) => _viewerController.goToPage(pageNumber: p);

    if (nowUs - _lastJumpUs >= _throttleMs * 1000) {
      _lastJumpUs = nowUs;
      _pendingPage = null;
      _throttleTimer?.cancel();
      jump(target);
    } else {
      _pendingPage = target;
      _throttleTimer ??= Timer(Duration(milliseconds: _throttleMs + 10), () {
        final p = _pendingPage;
        _pendingPage = null;
        _throttleTimer = null;
        if (p != null) {
          _lastJumpUs = DateTime.now().microsecondsSinceEpoch;
          jump(p);
        }
      });
    }
  }

  void _animateToPage(int target) {
    _animateTimer?.cancel();
    if (target == _currentPage) return;

    final dir = target > _currentPage ? 1 : -1;
    final stepMs = (_totalPages > 30) ? 8 : 12;

    _animateTimer = Timer.periodic(Duration(milliseconds: stepMs), (t) {
      final next = _currentPage + dir;
      _viewerController.goToPage(pageNumber: next);
      if (next == target) {
        t.cancel();
        _animateTimer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tossBlue = Color(0xFF0061FF);
    final borderRadius = const BorderRadius.vertical(top: Radius.circular(16));
    final uri = Uri.parse(_fixUrl(widget.url));

    // 하단 버튼에 가리지 않도록 패딩
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
                    // 1) PDF 뷰어 (마지막 페이지 가림 방지 패딩)
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: bottomBarHeight),
                        child: PdfViewer.uri(
                          uri,
                          controller: _viewerController,
                          params: PdfViewerParams(
                            onViewerReady: (document, controller) {
                              if (!mounted) return;
                              setState(() {
                                _totalPages = document.pages.length;
                                _loading = false;
                                _error = null;
                                _currentPage = 1; // 항상 1페이지 시작
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _viewerController.goToPage(pageNumber: 1);
                              });
                            },
                            onPageChanged: (pageNumber) {
                              if (!mounted) return;
                              final p = pageNumber ?? _currentPage;
                              if (p != _currentPage) {
                                setState(() => _currentPage = p);
                              }
                            },
                            // 기본 썸은 사용 안 함(숫자 제거 목적)
                            viewerOverlayBuilder: (context, size, handleLinkTap) => const <Widget>[],
                          ),
                        ),
                      ),
                    ),

                    // 2) 커스텀 스크롤바 (숫자 없음, 짧은 썸)
                    if (_totalPages > 1)
                      Positioned(
                        right: 8,
                        top: 8,
                        bottom: bottomBarHeight + 8,
                        child: _PdfPageScrollbar(
                          currentPage: _currentPage,
                          totalPages: _totalPages,
                          trackWidth: 6,
                          thumbHeight: 64, // ← 짧게 (원하면 56~72 사이로 조절)
                          trackRadius: 8,
                          onDragToPage: (page) => _goToPageThrottled(page),
                          onDragEndToPage: (page) => _animateToPage(page),
                          onTapToPage: (page) => _viewerController.goToPage(pageNumber: page),
                        ),
                      ),

                    // 3) 우측 상단 페이지 카운터
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

                    // 4) 하단 확인 버튼
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

                    // 5) 로딩/에러 오버레이
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

/// 커스텀 페이지 스크롤바 (숫자 라벨 없음, 덜컥거림 최소화)
class _PdfPageScrollbar extends StatefulWidget {
  const _PdfPageScrollbar({
    required this.currentPage,
    required this.totalPages,
    required this.onDragToPage,
    required this.onDragEndToPage,
    required this.onTapToPage,
    this.trackWidth = 6,
    this.thumbHeight = 64,
    this.trackRadius = 8,
  });

  final int currentPage;
  final int totalPages;

  final ValueChanged<int> onDragToPage;
  final ValueChanged<int> onDragEndToPage;
  final ValueChanged<int> onTapToPage;

  final double trackWidth;
  final double thumbHeight;
  final double trackRadius;

  @override
  State<_PdfPageScrollbar> createState() => _PdfPageScrollbarState();
}

class _PdfPageScrollbarState extends State<_PdfPageScrollbar> {
  double _trackHeight = 0;
  bool _dragging = false;
  double _dragThumbTop = 0; // 드래그 중 썸 위치(시각만)
  double? _lastDragDy;
  int _lastSentPage = 1;

  // 페이지→비율(0~1)
  double get _ratio {
    if (widget.totalPages <= 1) return 0;
    return (widget.currentPage - 1) / (widget.totalPages - 1);
  }

  // 위치→페이지(모노토닉 보정)
  int _positionToPageMonotonic(Offset localPos) {
    if (_trackHeight <= 0) return widget.currentPage;
    final movable = math.max(1.0, _trackHeight - widget.thumbHeight);
    final y = (localPos.dy - widget.thumbHeight / 2).clamp(0.0, movable);
    final t = movable == 0 ? 0.0 : (y / movable); // 0~1
    var page = (t * (widget.totalPages - 1)).round() + 1;

    // 드래그 방향에 따라 되돌림 방지
    if (_lastDragDy != null) {
      final dirDown = localPos.dy > _lastDragDy!;
      if (dirDown) {
        page = math.max(page, _lastSentPage);
      } else {
        page = math.min(page, _lastSentPage);
      }
    }
    return page.clamp(1, widget.totalPages);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        _trackHeight = constraints.maxHeight;

        final movable = math.max(1.0, _trackHeight - widget.thumbHeight);
        final thumbTopFromPage = movable * _ratio;
        final thumbTop = _dragging ? _dragThumbTop : thumbTopFromPage;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (d) {
            // 탭 즉시 이동
            final page = _positionToPageMonotonic(d.localPosition);
            _lastSentPage = page;
            widget.onTapToPage(page);
          },
          onVerticalDragStart: (d) {
            setState(() {
              _dragging = true;
              _lastDragDy = d.localPosition.dy;
              _lastSentPage = widget.currentPage;
              // 시작 시 썸 위치도 현재 페이지 기준으로 고정
              _dragThumbTop = thumbTopFromPage;
            });
          },
          onVerticalDragUpdate: (d) {
            final y = (d.localPosition.dy - widget.thumbHeight / 2).clamp(0.0, movable);
            setState(() {
              _dragThumbTop = y; // 시각적 위치는 손가락을 따라감
            });
            final page = _positionToPageMonotonic(d.localPosition);
            if (page != _lastSentPage) {
              _lastSentPage = page;
              widget.onDragToPage(page); // 스로틀된 점프
            }
            _lastDragDy = d.localPosition.dy;
          },
          onVerticalDragEnd: (d) {
            setState(() {
              _dragging = false;
              _lastDragDy = null;
            });
            widget.onDragEndToPage(_lastSentPage); // 짧은 애니메이션으로 마무리
          },
          child: Stack(
            children: [
              // 트랙
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: widget.trackWidth,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(widget.trackRadius),
                  ),
                ),
              ),
              // 썸
              Positioned(
                right: 0,
                top: thumbTop,
                child: Container(
                  width: widget.trackWidth,
                  height: widget.thumbHeight,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(widget.trackRadius),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
