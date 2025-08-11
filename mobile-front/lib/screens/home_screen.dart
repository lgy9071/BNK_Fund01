import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/fund.dart';

/* 색 */
const tossBlue = Color(0xFF0064FF);
const tossGray = Color(0xFF202632);
Color pastel(Color c) => Color.lerp(Colors.white, c, 0.12)!;

/* ====== 커스텀 배경 모델 ====== */
class BgChoice {
  final Color? c1, c2;
  final File? image;
  const BgChoice._({this.c1, this.c2, this.image});
  factory BgChoice.solid(Color c) => BgChoice._(c1: c);
  factory BgChoice.gradient(Color a, Color b) => BgChoice._(c1: a, c2: b);
  factory BgChoice.image(File f) => BgChoice._(image: f);

  bool get isImage => image != null;
  bool get isGradient => c2 != null && image == null;
}

/* ====== 홈 ====== */
class HomeScreen extends StatefulWidget {
  final List<Fund> myFunds;
  final String investType;
  final String userName;
  const HomeScreen({
    super.key,
    required this.myFunds,
    required this.investType,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum FundSort { amountDesc, newest, nameAsc, rateDesc }

class _HomeScreenState extends State<HomeScreen> {
  bool _obscure = false;
  bool _expandFunds = false;
  FundSort _sort = FundSort.amountDesc;

  BgChoice _bg = BgChoice.solid(pastel(tossBlue));
  File? _bgImageFile;

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  List<Fund> _sortedFunds() {
    final list = [...widget.myFunds];
    switch (_sort) {
      case FundSort.amountDesc:
        list.sort((a, b) => b.balance.compareTo(a.balance));
        break;
      case FundSort.newest:
        list.sort((a, b) => b.id.compareTo(a.id)); // id 큰게 최신 가정
        break;
      case FundSort.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case FundSort.rateDesc:
        list.sort((a, b) => b.rate.compareTo(a.rate));
        break;
    }
    return list;
  }

  int get _totalBal => widget.myFunds.fold(0, (s, f) => s + f.balance);
  int get _pnl => widget.myFunds
      .map((f) => (f.balance * (f.rate / 100.0)))
      .fold<int>(0, (s, v) => s + v.round());
  double get _returnPct {
    final base = _totalBal - _pnl;
    if (base <= 0) return 0;
    return (_pnl / base) * 100.0;
  }

  Future<void> _openDesignSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DesignSheet(
        onPickPreset: (choice) {
          setState(() {
            _bg = choice;
            _bgImageFile = choice.image;
          });
          Navigator.pop(context);
        },
        onPickImage: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x == null) return;
          setState(() {
            _bg = BgChoice.image(File(x.path));
            _bgImageFile = File(x.path);
          });
          if (context.mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _toMyFinance() => Navigator.of(context).pushNamed('/my-finance');

  @override
  Widget build(BuildContext context) {
    final funds = _sortedFunds();
    final visible = _expandFunds ? funds.length : math.min(2, funds.length);
    final titleShadow = _bg.isImage
        ? [Shadow(color: Colors.black.withOpacity(.55), blurRadius: 8, offset: const Offset(0, 1.5))]
        : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* 헤더 */
              Row(children: [
                InkWell(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/splash_logo.png',
                        height: 33,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.notifications_none, color: Colors.black54),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.palette_outlined, color: Colors.black87),
                  onPressed: _openDesignSheet,
                ),
              ]),
              const SizedBox(height: 12),

              /* 투자성향 — 흰 배경 + 얇은 파란 테두리 */
              InkWell(
                onTap: () => Navigator.of(context).pushNamed('/invest-type'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tossBlue.withOpacity(0.16), width: 1),
                  ),
                  child: Row(
                    children: [
                      Text('${widget.userName}님의 투자성향',
                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      const Spacer(),
                      Text(widget.investType,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              /* 총 평가금액 — 테두리 추가 + 상/하 분리 */
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tossBlue.withOpacity(0.12), width: 1), // 🔵 테두리
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 윗부분(커스텀 영역)
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          image: _bg.isImage && _bgImageFile != null
                              ? DecorationImage(image: FileImage(_bgImageFile!), fit: BoxFit.cover)
                              : null,
                          color: (!_bg.isImage && !_bg.isGradient) ? _bg.c1 : null,
                          gradient: _bg.isGradient
                              ? LinearGradient(
                              colors: [_bg.c1!, _bg.c2!],
                              begin: Alignment.topLeft, end: Alignment.bottomRight)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            if (_bg.isImage)
                              Positioned.fill(child: Container(color: Colors.black.withOpacity(.35))),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  InkWell(
                                    onTap: _toMyFinance,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Text('총 평가금액',
                                        style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700,
                                          color: _bg.isImage ? Colors.white : Colors.black,
                                          shadows: titleShadow,
                                        )),
                                  ),
                                  const Spacer(),
                                  PopupMenuButton(
                                    icon: Icon(Icons.more_horiz,
                                        color: _bg.isImage ? Colors.white : Colors.black54),
                                    onSelected: (_) => setState(() => _obscure = !_obscure),
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Text(_obscure ? '잔액보기' : '잔액 숨기기'),
                                      )
                                    ],
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _obscure
                                      ? Align(
                                    key: const ValueKey('hidden'),
                                    alignment: Alignment.centerRight, // 👉 오른쪽 정렬
                                    child: Text(
                                      '잔액보기',
                                      style: TextStyle(
                                        fontSize: 26, fontWeight: FontWeight.bold,
                                        color: _bg.isImage ? Colors.white : Colors.black,
                                        shadows: titleShadow,
                                      ),
                                    ),
                                  )
                                      : Align(
                                    key: const ValueKey('shown'),
                                    alignment: Alignment.centerRight, // 👉 오른쪽 정렬
                                    child: Text(
                                      _won(_totalBal),
                                      style: TextStyle(
                                        fontSize: 26, fontWeight: FontWeight.bold,
                                        color: _bg.isImage ? Colors.white : Colors.black,
                                        shadows: titleShadow,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 아랫부분(흰 바 고정: 평가손익/수익률) — 둘 다 오른쪽 가로배치
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Builder(builder: (_) {
                          final pnlUp = _pnl >= 0;
                          final arrow = pnlUp ? '▲' : '▼';
                          final c = pnlUp ? Colors.red : Colors.blue;

                          Widget metric(String label, String value) => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 2),
                              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 2),
                              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
                            ],
                          );

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end, // 👉 오른쪽 정렬
                            children: [
                              metric('평가손익', '$arrow ${_won(_pnl.abs())}'),
                              const SizedBox(width: 18),
                              metric('수익률', '$arrow ${_returnPct.abs().toStringAsFixed(2)}%'),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              /* 보유 펀드 — 테두리 */
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      InkWell(
                        onTap: _toMyFinance,
                        borderRadius: BorderRadius.circular(8),
                        child: const Text('보유 펀드',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      PopupMenuButton<FundSort>(
                        icon: const Icon(Icons.more_horiz, color: Colors.black54),
                        onSelected: (s) => setState(() => _sort = s),
                        itemBuilder: (_) => [
                          _sortItem('금액 많은 순', FundSort.amountDesc),
                          _sortItem('최신순', FundSort.newest),
                          _sortItem('이름순', FundSort.nameAsc),
                          _sortItem('수익률 높은 순', FundSort.rateDesc),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 10),
                    for (int i = 0; i < visible; i++) ...[
                      _FundMiniTile(
                        fund: funds[i],
                        obscure: _obscure,
                        onTap: () => Navigator.of(context).pushNamed(
                          '/fund/transactions',
                          arguments: funds[i].id,
                        ),
                      ),
                      if (i != visible - 1) const SizedBox(height: 8),
                    ],
                    if (funds.length > 2) const SizedBox(height: 10),
                    if (funds.length > 2)
                      GestureDetector(
                        onTap: () => setState(() => _expandFunds = !_expandFunds),
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tossBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _expandFunds ? '접기' : '더보기',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text('추천/공지 섹션 자리', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<FundSort> _sortItem(String label, FundSort v) => PopupMenuItem(
    value: v,
    child: Row(
      children: [
        Icon(_sort == v ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}

/* ===== 보유 펀드 타일 ===== */
class _FundMiniTile extends StatelessWidget {
  final Fund fund;
  final bool obscure;
  final VoidCallback onTap;
  const _FundMiniTile({required this.fund, required this.obscure, required this.onTap});

  String _fmtWon(int v) =>
      '${v.toString().replaceAll(RegExp(r"\B(?=(\d{3})+(?!\d))"), ",")}원';

  @override
  Widget build(BuildContext context) {
    final up = fund.rate >= 0;
    final arrow = up ? '▲' : '▼';
    final color = up ? Colors.red : Colors.blue;
    final delta = (fund.balance * (fund.rate / 100)).round(); // 증감 금액

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: .5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  fund.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!obscure)
                    Text(
                      '${fund.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  const SizedBox(height: 2),
                  // 증감 금액 + 퍼센트
                  Text(
                    '$arrow ${_fmtWon(delta.abs())} (${fund.rate.toStringAsFixed(2)}%)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===== 디자인 시트 ===== */
class _DesignSheet extends StatelessWidget {
  final void Function(BgChoice) onPickPreset;
  final VoidCallback onPickImage;
  const _DesignSheet({required this.onPickPreset, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    Widget tile({required Widget child, required VoidCallback onTap}) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.black12),
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(10), child: child),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('메인 영역 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
          ]),
          const SizedBox(height: 6),
          const Text('디자인 설정', style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              tile(onTap: () => onPickPreset(BgChoice.solid(pastel(tossBlue))), child: Container(color: pastel(tossBlue))),
              tile(
                onTap: () => onPickPreset(BgChoice.gradient(const Color(0xFFFF9AB7), const Color(0xFFF7E88B))),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF9AB7), Color(0xFFF7E88B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              tile(onTap: () => onPickPreset(BgChoice.solid(const Color(0xFF3D6BFF))), child: Container(color: const Color(0xFF3D6BFF))),
              tile(onTap: () => onPickPreset(BgChoice.solid(const Color(0xFFFBE5DB))), child: Container(color: const Color(0xFFFBE5DB))),
              tile(onTap: () => onPickPreset(BgChoice.solid(const Color(0xFFE9E6FF))), child: Container(color: const Color(0xFFE9E6FF))),
              tile(onTap: onPickImage, child: const _PlusTile()),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlusTile extends StatelessWidget {
  const _PlusTile();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFFF4F4F4)),
        Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26, width: 1.2),
            ),
            child: const Icon(Icons.add, size: 20, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}