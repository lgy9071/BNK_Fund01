import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/utils/exit_popup.dart';
import '../core/routes/routes.dart';
import '../models/fund.dart';
import 'package:mobile_front/core/services/invest_result_service.dart';
import 'package:mobile_front/screens/invest_type_result_loader.dart';
import 'package:mobile_front/core/constants/api.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c) => Color.lerp(Colors.white, c, 0.12)!;

/* ===== 배경 선택 모델 ===== */
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

/* 배경 대비용 글자색 계산 */
Color _idealOn(BgChoice bg,
    {Color light = AppColors.fontColor, Color dark = Colors.white}) {
  if (bg.isImage) return dark;
  if (bg.isGradient) {
    final l1 = bg.c1!.computeLuminance();
    final l2 = bg.c2!.computeLuminance();
    return ((l1 + l2) / 2) < 0.55 ? dark : light;
  }
  final lum = (bg.c1 ?? Colors.white).computeLuminance();
  return lum < 0.55 ? dark : light;
}

/* ===== 홈 ===== */
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
  bool _obscure = false;          // 금액 숨김
  bool _expandFunds = false;      // 더보기
  FundSort _sort = FundSort.amountDesc;

  // 디자인 커스텀은 ‘총 평가금액’ 카드에만 적용됨
  BgChoice _bg = BgChoice.solid(pastel(tossBlue));
  File? _bgImageFile;

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  List<Fund> _sortedFunds() {
    final list = [...widget.myFunds];
    switch (_sort) {
      case FundSort.amountDesc: list.sort((a, b) => b.balance.compareTo(a.balance)); break;
      case FundSort.newest:     list.sort((a, b) => b.id.compareTo(a.id)); break;
      case FundSort.nameAsc:    list.sort((a, b) => a.name.compareTo(b.name)); break;
      case FundSort.rateDesc:   list.sort((a, b) => b.rate.compareTo(a.rate)); break;
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

  void _toMyFinance() => Navigator.of(context).pushNamed('/my-finance');

  /* ===== 설정 모달(디자인 + 금액 숨기기) ===== */
  Future<void> _openSettingsSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _DesignSheet(
        isObscure: _obscure,
        onToggleObscure: (v) => setState(() => _obscure = v),
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

  /* ===== 보유 펀드 옵션 모달(정렬 + 전체보기 스위치) ===== */
  Future<void> _openFundsOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FundsOptionsSheet(
        currentSort: _sort,
        isExpanded: _expandFunds,
        onSelectSort: (s) => setState(() => _sort = s),
        onToggleExpand: (v) => setState(() => _expandFunds = v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final funds = _sortedFunds();
    final baseText = AppColors.fontColor;
    final baseDim = baseText.withOpacity(.54);
    final onColor = _idealOn(_bg); // 총 평가금액 상단 텍스트 대비색

    // 더보기: 처음 2개 고정 + 나머지는 아래로 추가
    final int baseCount = math.min(2, funds.length);
    final List<Fund> firstTwo = funds.take(baseCount).toList();
    final List<Fund> rest = _expandFunds ? funds.skip(baseCount).toList() : const [];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 이미 pop 처리된 경우 무시
        await showExitPopup(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white, // 메인 뒷배경 흰색
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
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      height: 33,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.account_balance, color: baseText),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: baseDim),
                    onPressed: () {},
                  ),
                ]),
                const SizedBox(height: 12),

                /* 투자성향 카드 (이름/성향 + 화살표) */
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.investType),
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
                            style: TextStyle(fontSize: 15, color: baseText)),
                        const Spacer(),
                        Text(widget.investType,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w800, color: baseText)),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: baseDim),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                /* 총 평가금액 카드 */
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 100),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          decoration: BoxDecoration(
                            image: _bg.isImage && _bgImageFile != null
                                ? DecorationImage(image: FileImage(_bgImageFile!), fit: BoxFit.cover)
                                : null,
                            color: (!_bg.isImage && !_bg.isGradient) ? _bg.c1 : null,
                            gradient: _bg.isGradient
                                ? LinearGradient(
                                colors: [_bg.c1!, _bg.c2!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight)
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (_bg.isImage)
                                Positioned.fill(
                                  child: Container(color: Colors.black.withOpacity(.28)),
                                ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: _toMyFinance,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Text(
                                          '총 평가금액',
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: onColor,
                                            shadows: _bg.isImage
                                                ? [
                                              Shadow(
                                                  color: Colors.black.withOpacity(.55),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 1.5))
                                            ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(Icons.more_horiz,
                                            color: _bg.isImage ? Colors.white : onColor.withOpacity(.6)),
                                        onPressed: _openSettingsSheet,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: _obscure
                                        ? Align(
                                      key: const ValueKey('hidden'),
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _obscure = false),
                                        child: Text(
                                          '잔액 보기',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: onColor,
                                            decoration: TextDecoration.underline,
                                            decorationColor: (_bg.isImage
                                                ? Colors.white70
                                                : onColor.withOpacity(.45)),
                                          ),
                                        ),
                                      ),
                                    )
                                        : Align(
                                      key: const ValueKey('shown'),
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        _won(_totalBal),
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: onColor,
                                          shadows: _bg.isImage
                                              ? [
                                            Shadow(
                                                color: Colors.black.withOpacity(.55),
                                                blurRadius: 8,
                                                offset: const Offset(0, 1.5))
                                          ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: _obscure
                              ? const SizedBox.shrink()
                              : Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                            child: Builder(builder: (_) {
                              final up = _pnl >= 0;
                              final sign = up ? '+' : '−';
                              final c = up ? Colors.red : Colors.blue;
                              return Row(
                                children: [
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('평가손익',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: baseText.withOpacity(.54))),
                                          const SizedBox(width: 10),
                                          Text('$sign ${_won(_pnl.abs())}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: c)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('수익률',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: baseText.withOpacity(.54))),
                                          const SizedBox(width: 10),
                                          Text('$sign ${_returnPct.abs().toStringAsFixed(2)}%',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: c)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                /* 보유 펀드 */
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        InkWell(
                          onTap: _toMyFinance,
                          borderRadius: BorderRadius.circular(8),
                          child: Text('보유 펀드',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600, color: baseText)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.more_horiz, color: baseDim),
                          onPressed: _openFundsOptionsSheet,
                        ),
                      ]),
                      const SizedBox(height: 10),

                      for (int i = 0; i < firstTwo.length; i++) ...[
                        _FundMiniTile(
                          fund: firstTwo[i],
                          obscure: _obscure,
                          onTap: () => Navigator.of(context).pushNamed(
                            '/fund/transactions',
                            arguments: firstTwo[i].id,
                          ),
                        ),
                        if (i != firstTwo.length - 1) const SizedBox(height: 10),
                      ],

                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            for (int i = 0; i < rest.length; i++) ...[
                              const SizedBox(height: 10),
                              _FundMiniTile(
                                fund: rest[i],
                                obscure: _obscure,
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/fund/transactions',
                                  arguments: rest[i].id,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (funds.length > 2) const SizedBox(height: 14),
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
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                _expandFunds ? '접기' : '더보기',
                                key: ValueKey(_expandFunds),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Text('추천/공지 섹션 자리',
                    style: TextStyle(color: baseText.withOpacity(.6))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuEntry<FundSort> _sortItem(String label, FundSort v) => PopupMenuItem(
    value: v,
    child: Row(
      children: [
        Icon(_sort == v ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18, color: AppColors.fontColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.fontColor)),
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
    final delta = (fund.balance * (fund.rate / 100)).round();

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
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.fontColor),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!obscure)
                    Text(
                      '${fund.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
                      style: const TextStyle(fontSize: 14, color: AppColors.fontColor),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '$arrow ${_fmtWon(delta.abs())} (${fund.rate.toStringAsFixed(2)}%)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
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

/* ===== 바텀시트: 디자인 + 금액 숨기기 ===== */
class _DesignSheet extends StatefulWidget {
  final bool isObscure;
  final ValueChanged<bool> onToggleObscure;
  final void Function(BgChoice) onPickPreset;
  final VoidCallback onPickImage;

  const _DesignSheet({
    required this.isObscure,
    required this.onToggleObscure,
    required this.onPickPreset,
    required this.onPickImage,
  });

  @override
  State<_DesignSheet> createState() => _DesignSheetState();
}

class _DesignSheetState extends State<_DesignSheet> {
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isObscure; // 모달 열릴 때 상태 반영
  }

  void _setObscure(bool v) {
    setState(() => _isObscure = v); // 모달 내 즉시 갱신
    widget.onToggleObscure(v);      // 상위(HomeScreen)에도 반영
  }

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

    final presets = <BgChoice>[
      BgChoice.solid(const Color(0xFF7FA7FF)), // 파란 계열
      BgChoice.solid(const Color(0xFFFFA8D0)), // 핑크 계열
      BgChoice.solid(const Color(0xFF8FFF9F)), // 초록 계열
      BgChoice.solid(const Color(0xFFFFC371)), // 주황 계열
      BgChoice.solid(const Color(0xFFF5F7FF)), // 연회색
      BgChoice.solid(const Color(0xFFE0BBFF)), // 라일락
      BgChoice.solid(const Color(0xFFB2EBF2)), // 민트
      BgChoice.solid(const Color(0xFFFFE082)), // 연노랑
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('메인 영역 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.fontColor)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.fontColor),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 6),
          Text('디자인 설정',
              style: TextStyle(fontSize: 15, color: AppColors.fontColor.withOpacity(.6))),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in presets)
                tile(
                  onTap: () => widget.onPickPreset(p),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (!p.isImage && !p.isGradient) ? p.c1 : null,
                      gradient: p.isGradient
                          ? LinearGradient(
                        colors: [p.c1!, p.c2!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                    ),
                  ),
                ),
              tile(onTap: widget.onPickImage, child: const _PlusTile()),
            ],
          ),

          const SizedBox(height: 18),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _isObscure ? '금액 보기' : '금액 숨기기',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.fontColor,
              ),
            ),
            trailing: Switch(
              value: _isObscure,
              onChanged: _setObscure,
            ),
            onTap: () => _setObscure(!_isObscure),
          ),
        ],
      ),
    );
  }
}

/* ===== 보유 펀드 옵션 모달 ===== */
class _FundsOptionsSheet extends StatefulWidget {
  final FundSort currentSort;
  final bool isExpanded;
  final ValueChanged<FundSort> onSelectSort;
  final ValueChanged<bool> onToggleExpand;

  const _FundsOptionsSheet({
    required this.currentSort,
    required this.isExpanded,
    required this.onSelectSort,
    required this.onToggleExpand,
  });

  @override
  State<_FundsOptionsSheet> createState() => _FundsOptionsSheetState();
}

class _FundsOptionsSheetState extends State<_FundsOptionsSheet> {
  late FundSort _selected;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSort;
    _expanded = widget.isExpanded;
  }

  Widget _radio(String label, FundSort v) {
    return RadioListTile<FundSort>(
      value: v,
      groupValue: _selected,
      onChanged: (nv) {
        if (nv == null) return;
        setState(() => _selected = nv);
        widget.onSelectSort(nv);
      },
      title: Text(label, style: const TextStyle(color: AppColors.fontColor)),
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: tossBlue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text(
              '보유 펀드 옵션',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.fontColor),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.fontColor),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 6),
          Text('정렬', style: TextStyle(fontSize: 15, color: AppColors.fontColor.withOpacity(.6))),
          const SizedBox(height: 6),
          _radio('금액 많은 순', FundSort.amountDesc),
          _radio('최신순', FundSort.newest),
          _radio('이름순', FundSort.nameAsc),
          _radio('수익률 높은 순', FundSort.rateDesc),

          const SizedBox(height: 10),
          const Divider(height: 1),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('전체 보기', style: TextStyle(color: AppColors.fontColor, fontWeight: FontWeight.w600)),
            subtitle: Text(
              _expanded ? '접어서 2개만 보기' : '펀드를 모두 펼쳐 보기',
              style: TextStyle(color: AppColors.fontColor.withOpacity(.6)),
            ),
            value: _expanded,
            onChanged: (v) {
              setState(() => _expanded = v);
              widget.onToggleExpand(v);
            },
            activeColor: tossBlue,
          ),

          const SizedBox(height: 6),
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
            child: Icon(Icons.add, size: 20, color: AppColors.fontColor.withOpacity(.7)),
          ),
        ),
      ],
    );
  }
}