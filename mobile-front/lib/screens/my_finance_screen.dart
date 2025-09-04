import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/services/account_service.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/widgets/common_button.dart';

import '../models/bank_account_net.dart';
import '../models/fund.dart';

const tossBlue = Color(0xFF0064FF);

// 👉 카드 테두리 공통색 (토스 블루, 살짝 투명)
final Color kCardBorder = tossBlue.withOpacity(0.16);

class MyFinanceScreen extends StatefulWidget {
  final String? accessToken;
  final UserService? userService;

  final String? userId;
  final String? investTypeName;
  final VoidCallback? onGoToFundTab;

  // 홈에서 내려준 “가입 펀드” 상태 공유 (한 번만 선언)
  final List<Fund> myFunds;
  final bool fundsLoading;
  final String? fundsError;
  final AsyncCallback? onRefreshFunds;

  const MyFinanceScreen({
    super.key,
    this.accessToken,
    this.userService,
    this.userId,
    this.investTypeName,
    this.onGoToFundTab,

    // 기본값 제공
    this.myFunds = const [],
    this.fundsLoading = false,
    this.fundsError,
    this.onRefreshFunds,
  });

  @override
  State<MyFinanceScreen> createState() => _MyFinanceScreenState();
}

class _MyFinanceScreenState extends State<MyFinanceScreen> {
  final _accountSvc = AccountService();

  List<BankAccountNet> _accounts = [];
  bool _acctLoading = true;
  String? _acctError;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _loadAccounts(); // ← 최초 로드
    } else {
      _acctLoading = false;
      _acctError = null;
    }
  }

  @override
  void didUpdateWidget(covariant MyFinanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId &&
        widget.userId != null &&
        widget.userId!.isNotEmpty) {
      _loadAccounts(); // ← userId 바뀌면 재로딩
    }
  }

  Future<void> _loadAccounts() async {
    if (widget.userId == null || widget.userId!.isEmpty) {
      setState(() {
        _acctLoading = false;
        _acctError = null;
        _accounts = const [];
      });
      return;
    }
    setState(() {
      _acctLoading = true;
      _acctError = null;
    });
    try {
      final list = await _accountSvc.getDepositAccountsByUser(widget.userId!);
      setState(() {
        _accounts = list; // ← 성공: 계좌 목록 저장
        _acctLoading = false;
      });
    } catch (e) {
      setState(() {
        _acctLoading = false; // ← 실패: 에러 메시지 저장
        _acctError = e.toString();
        _accounts = const [];
      });
    }
  }

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  int get _sumAccounts => _accounts.fold(0, (s, a) => s + a.balance);
  int get _sumFunds => widget.myFunds.fold(0, (s, f) => s + f.balance);
  int get _totalAssets => _sumAccounts + _sumFunds;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경은 화이트
      appBar: AppBar(
        title: const Text('내 금융', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.fontColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadAccounts();
          await (widget.onRefreshFunds?.call() ?? Future.value());
        },
        color: tossBlue,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== 총 자산 + 자산 분포(같은 카드) =====
              const Text(
                '총 자산',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fontColor,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ 변경: 로딩 중이면 스켈레톤, 아니면 기존 카드
              (_acctLoading || widget.fundsLoading)
                  ? const _CardShell(child: _TotalAssetsSkeleton())
                  : _CardShell(
                child: _TotalAssetsCard(
                  total: _totalAssets,
                  accountsSum: _sumAccounts,
                  fundsSum: _sumFunds,
                ),
              ),

              const SizedBox(height: 24),

              // ===== 입출금 계좌 =====
              const _SectionHeader(title: '입출금 계좌'),
              const SizedBox(height: 10),

              if (_acctLoading)
                const _AccountSkeletonList() // 카드 테두리는 각 row 안에 이미 적용
              else if (_acctError != null)
                _CardShell(
                  child: _ErrorBlock(
                    text: '계좌 정보를 불러올 수 없어요',
                    onRetry: _loadAccounts,
                  ),
                )
              else if (_accounts.isEmpty)
                  _CardShell(
                  child: _EmptyAccountsCard(
                      accessToken: widget.accessToken,
                      userService: widget.userService,
                      ),
                  )
              else
                Column(
                  children: [
                    for (int i = 0; i < _accounts.length; i++) ...[
                      _AccountTile(account: _accounts[i], index: i + 1), // ✅ index 전달
                      const SizedBox(height: 10),
                    ],
                  ],
                ),

              const SizedBox(height: 24),

              // ===== 가입 펀드 =====
              const _SectionHeader(title: '가입 펀드'),
              const SizedBox(height: 10),

              if (widget.fundsLoading)
                const _CardShell(child: _LoadingBlock(text: '펀드 불러오는 중...'))
              else if (widget.fundsError != null)
                _CardShell(
                  child: _ErrorBlock(
                    text: '펀드 정보를 불러올 수 없어요',
                    onRetry: widget.onRefreshFunds,
                  ),
                )
              else if (widget.myFunds.isEmpty)
                // ✅ 빈 펀드 상태: 안내 + '펀드 가입하러 가기' 버튼 (투자성향 검사 분기)
                  _CardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: const Text(
                            '가입한 펀드가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.fontColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final hasInvestType =
                                (widget.investTypeName ?? '').isNotEmpty;

                            if (!hasInvestType) {
                              final go = await _showInvestTypeDialog();
                              if (!go) return;

                              final bool? done = await Navigator.pushNamed<bool?>(
                                context,
                                AppRoutes.investType,
                              );

                              // 검사 완료 후 펀드 가입 탭으로 유도
                              if (done == true) {
                                widget.onGoToFundTab?.call();
                              }
                            } else {
                              // 이미 투자성향 있음 → 펀드 가입 탭으로
                              widget.onGoToFundTab?.call();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: tossBlue.withOpacity(.6)),
                            foregroundColor: tossBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('펀드 가입하러 가기'),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      for (final f in widget.myFunds) ...[
                        _FundRow(f: f),
                        const SizedBox(height: 10),
                      ]
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // 모달 꾸미기
  Future<bool> _showInvestTypeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

          // 🔹 헤더
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tossBlue.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.analytics_outlined, color: tossBlue),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '투자성향분석이 필요해요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.fontColor,
                  ),
                ),
              ),
            ],
          ),

          // 🔹 본문
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '펀드를 가입하기 전에 간단한 분석으로\n나에게 맞는 상품을 추천해드릴게요.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.fontColor.withOpacity(.8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const _BulletRow(text: '소요 시간 약 1분'),
              const _BulletRow(text: '분석 결과로 맞춤 펀드 추천'),
              const _BulletRow(text: '언제든 재검사 가능'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tossBlue.withOpacity(.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kCardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: tossBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '분석은 투자 권유가 아닌\n정보 제공 절차예요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.fontColor.withOpacity(.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 🔹 버튼
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('나중에', style: TextStyle(color: AppColors.fontColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: tossBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('분석하러 가기'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

// 모달에 쓰일 불릿 위젯 추가
class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppColors.fontColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.fontColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.fontColor,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.fontColor.withOpacity(.66),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // ✅ 모든 카드 흰 배경
        border: Border.all(color: kCardBorder), // ✅ 모든 카드 토스블루 테두리
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 1),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  final String text;
  const _LoadingBlock({required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 4),
      const CircularProgressIndicator(strokeWidth: 3, color: tossBlue),
      const SizedBox(height: 12),
      Text(text, style: TextStyle(color: AppColors.fontColor.withOpacity(.7))),
    ]);
  }
}

class _ErrorBlock extends StatelessWidget {
  final String text;
  final AsyncCallback? onRetry;
  const _ErrorBlock({required this.text, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: const [
        Icon(Icons.error_outline, color: Colors.red),
        SizedBox(width: 8),
        Text('오류',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.fontColor)),
      ]),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: TextStyle(color: AppColors.fontColor.withOpacity(.8))),
      ),
      if (onRetry != null) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async => await onRetry!(),
            child: const Text('다시 시도'),
          ),
        )
      ],
    ]);
  }
}

class _EmptyAccountsCard extends StatelessWidget {
  final String? accessToken;
  final UserService? userService;

  const _EmptyAccountsCard({this.accessToken, this.userService});  // ← 추가

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: const Text(
            '등록된 입출금 계좌가 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.fontColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _OpenAccountButton(                         // ← 전달
          accessToken: accessToken,
          userService: userService,
        ),
      ],
    );
  }
}

class _OpenAccountButton extends StatelessWidget {
  final String? accessToken;
  final UserService? userService;

  const _OpenAccountButton({this.accessToken, this.userService});  // ← 추가

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.otp,
            arguments: {                               // ← 토큰/서비스 전달
              'accessToken': accessToken,
              'userService': userService,
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: tossBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: const Text(
          '입출금 계좌 개설',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final BankAccountNet account;
  final int index; // ✅ 추가

  const _AccountTile({required this.account, required this.index});

  @override
  Widget build(BuildContext context) {
    // 별칭 없으면 기본값으로 "입출금계좌{index}" 표시
    final displayName = (account.accountName.isEmpty)
        ? '입출금계좌$index'
        : account.accountName;

    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 좌: 계좌명/번호
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.fontColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.accountNumber,
                  style: TextStyle(color: AppColors.fontColor.withOpacity(.7)),
                ),
              ],
            ),
          ),
          // 우: 잔액
          Text(
            '${account.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.fontColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundRow extends StatelessWidget {
  final Fund f;

  const _FundRow({required this.f});
  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  @override
  Widget build(BuildContext context) {
    final String pct = f.rate.toStringAsFixed(2);
    final bool isZero = pct == '0.00';
    final bool up = f.rate > 0;

    final Color pctColor = isZero
        ? const Color(0xFF5A5F6B)
        : (up ? Colors.red : Colors.blue);
    final String prefix = isZero ? '' : (up ? '▲ ' : '▼ ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 펀드명 (왼쪽) + 간격
          Expanded(
            child: Text(
              f.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.fontColor,
              ),
            ),
          ),
          const SizedBox(width: 12), // ✅ 숫자랑 충분한 간격 확보

          // 금액 + 수익률 (오른쪽)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _won(f.balance),
                style: const TextStyle(color: AppColors.fontColor),
              ),
              const SizedBox(height: 2),
              Text(
                '$prefix$pct%',
                style: TextStyle(
                  color: pctColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ====== 도넛 차트 페인터 & 범례 ====== */
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final Color holeColor;

  _DonutPainter({
    required this.values,
    this.holeColor = Colors.white,
  });

  static const _palette = [
    Color(0xFF6AA3FF), // 입출금계좌
    Color(0xFF3DDC97), // 펀드
    Color(0xFFFFC85C),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sum = values.fold<double>(0, (s, v) => s + v);
    if (sum <= 0) return;

    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..color = Colors.black12;
    canvas.drawCircle(center, radius, bg);

    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / sum) * 2 * math.pi;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 24
        ..color = _palette[i % _palette.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        p,
      );
      start += sweep;
    }
    final hole = Paint()..color = holeColor; // 카드 배경과 동일(화이트)
    canvas.drawCircle(center, radius - 16, hole);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.holeColor != holeColor || old.values.join(',') != values.join(',');
}

class _Legend extends StatelessWidget {
  final int colorIndex;
  final String label;

  const _Legend({required this.colorIndex, required this.label});

  static const _palette = [
    Color(0xFF6AA3FF),
    Color(0xFF3DDC97),
    Color(0xFFFFC85C),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _palette[colorIndex],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.fontColor)),
      ],
    );
  }
}

class _AccountSkeletonList extends StatelessWidget {
  const _AccountSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    Widget _bar({required double w, required double h}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    Widget _row() => Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(w: 120, h: 16),
                const SizedBox(height: 8),
                _bar(w: 160, h: 14),
              ],
            ),
          ),
          _bar(w: 80, h: 18),
        ],
      ),
    );

    return Column(
      children: [
        _row(),
        const SizedBox(height: 10),
        _row(),
      ],
    );
  }
}

class _TotalAssetsSkeleton extends StatelessWidget {
  const _TotalAssetsSkeleton({super.key});

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: const Color(0xFFEDEFF3),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 금액 자리
        Align(
          alignment: Alignment.centerRight,
          child: _bar(160, 26),
        ),
        const SizedBox(height: 12),
        // 도넛 차트 자리
        SizedBox(
          height: 170,
          child: Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE3E6EC), width: 24),
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 범례 자리
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 점 + 텍스트 바
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDDE1E8),
                  ),
                ),
                const SizedBox(width: 6),
                _bar(72, 12),
              ],
            ),
            const SizedBox(width: 16),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFDDE1E8),
                  ),
                ),
                const SizedBox(width: 6),
                _bar(48, 12),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _TotalAssetsCard extends StatelessWidget {
  final int total;
  final int accountsSum;
  final int fundsSum;

  const _TotalAssetsCard({
    super.key,
    required this.total,
    required this.accountsSum,
    required this.fundsSum,
  });

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r"\B(?=(\d{3})+(?!\d))"), ",")}원';

  @override
  Widget build(BuildContext context) {
    // 총 자산이 0원일 때는 기존 “빈 상태” 메시지 유지
    if (total <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.savings_outlined, size: 40, color: Colors.black38),
            const SizedBox(height: 8),
            Text(
              '자산 데이터가 없습니다',
              style: TextStyle(
                color: AppColors.fontColor.withOpacity(.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '계좌 개설이나 펀드 가입 후 확인하세요',
              style: TextStyle(
                color: AppColors.fontColor.withOpacity(.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final double accPct =
    total == 0 ? 0 : (accountsSum / total * 100.0);
    final double fundPct =
    total == 0 ? 0 : (fundsSum / total * 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 섹션 1: 금액 영역 ──────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '보유 총액',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0x99000000),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _won(total),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.fontColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Divider(height: 24, thickness: 1, color: kCardBorder),

        // ── 섹션 2: 그래프/분포 영역 ─────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 왼쪽: 도넛 차트
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 170,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [
                      accountsSum.toDouble(),
                      fundsSum.toDouble(),
                    ],
                    holeColor: Colors.white,
                  ),
                  child: const Center(
                    child: Text(
                      '비중',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.fontColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 중간 세로 구분선
            Container(
              width: 1,
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: kCardBorder,
            ),

            // 오른쪽: 범례 + 카테고리별 금액/비중
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // _Legend(colorIndex: 0, label: '입출금계좌'),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: '입출금계좌',
                    amount: _won(accountsSum),
                    percent: '${accPct.toStringAsFixed(1)}%',
                    dotColor: const Color(0xFF6AA3FF),
                  ),
                  const SizedBox(height: 12),

                  // _Legend(colorIndex: 1, label: '펀드'),
                  const SizedBox(height: 6),
                  _BreakdownRow(
                    label: '펀드',
                    amount: _won(fundsSum),
                    percent: '${fundPct.toStringAsFixed(1)}%',
                    dotColor: const Color(0xFF3DDC97),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String amount;
  final String percent;
  final Color dotColor;

  const _BreakdownRow({
    super.key,
    required this.label,
    required this.amount,
    required this.percent,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ● 색 점
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 4, right: 8),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),

        // 라벨 + 금액/퍼센트 (세로 정렬)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 라벨
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.fontColor,
                ),
              ),
              const SizedBox(height: 2),
              // 금액 + 퍼센트
              Row(
                children: [
                  Expanded(
                    child: Text(
                      amount,
                      style: const TextStyle(
                        color: AppColors.fontColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    percent,
                    style: TextStyle(
                      color: AppColors.fontColor.withOpacity(.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
