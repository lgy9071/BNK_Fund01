// lib/screens/my_finance_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/services/account_service.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/widgets/common_button.dart';

import '../models/fund.dart';

const tossBlue = Color(0xFF0064FF);

Color pastel(Color c) => c.withOpacity(.12);
import 'package:mobile_front/models/bank_account_net.dart';
import 'package:mobile_front/models/fund.dart';

const tossBlue = Color(0xFF0064FF);

// 👉 카드 테두리 공통색 (토스 블루, 살짝 투명)
final Color kCardBorder = tossBlue.withOpacity(0.16);

class MyFinanceScreen extends StatefulWidget {
  // 색상 동기화 제거: assetCardColor 없음
  final String? accessToken;
  final UserService? userService;
  final List<Fund>? myFunds;
  final bool? fundsLoading;

  final String? userId;
  final String? investTypeName;
  final VoidCallback? onGoToFundTab;

  // 홈에서 내려준 “가입 펀드” 상태 공유
  final List<Fund> myFunds;
  final bool fundsLoading;
  final String? fundsError;
  final AsyncCallback? onRefreshFunds; // Future<void> Function()

  const MyFinanceScreen({
    super.key,
    this.accessToken,
    this.userService,
    this.userId,
    this.investTypeName,
    this.onGoToFundTab,
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
      _loadAccounts();
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
      _loadAccounts();
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
        _accounts = list;
        _acctLoading = false;
      });
    } catch (e) {
      setState(() {
        _acctLoading = false;
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
        title: const Text('My'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.fontColor,
        elevation: 0.5,
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
              _CardShell(
                // ⬅︎ 모든 카드 흰 배경 + 토스블루 테두리
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _won(_totalAssets),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.fontColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_totalAssets > 0) ...[
                      SizedBox(
                        height: 170,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            values: [
                              _sumAccounts.toDouble(),
                              _sumFunds.toDouble(),
                            ],
                            holeColor: Colors.white, // 카드 배경과 일치
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
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _Legend(colorIndex: 0, label: '입출금계좌'),
                          SizedBox(width: 12),
                          _Legend(colorIndex: 1, label: '펀드'),
                        ],
                      ),
                    ] else ...[
                      // 총자산 0원일 때 동일 카드 내 안내
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline,
                                size: 40, color: Colors.black38),
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
                      )
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== 입출금 계좌 =====
              const _SectionHeader(title: '입출금 계좌'),
              const SizedBox(height: 10),

              if (_acctLoading)
                const _CardShell(child: _LoadingBlock(text: '계좌 불러오는 중...'))
              else if (_acctError != null)
                _CardShell(
                  child: _ErrorBlock(
                    text: '계좌 정보를 불러올 수 없어요',
                    onRetry: _loadAccounts,
                  ),
                )
              else if (_accounts.isEmpty)
                  const _CardShell(
                    child: _EmptyAccountsCard(),
                  )
                else
                  Column(
                    children: [
                      for (final a in _accounts) ...[
                        _AccountTile(account: a),
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
                        const Text(
                          '가입한 펀드가 없어요.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fontColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () async {
                            final hasInvestType =
                                (widget.investTypeName ?? '').isNotEmpty;

                            if (!hasInvestType) {
                              // 예쁘게 꾸민 커스텀 모달
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
  const _EmptyAccountsCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        Text(
          '등록된 입출금 계좌가 없어요.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.fontColor,
          ),
        ),
        SizedBox(height: 12),
        _OpenAccountButton(),
      ],
    );
  }
}

class _OpenAccountButton extends StatelessWidget {
  const _OpenAccountButton();

  @override
  Widget build(BuildContext context) {
    // 버튼은 부모에서 OTP 네비게이션과 새로고침을 연결해도 되고,
    // 여기서는 가벼운 placeholder 버튼만 스타일 통일
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            AppRoutes.otp,
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
  const _AccountTile({required this.account});

  String _mask(String n) {
    final parts = n.split('-');
    if (parts.isEmpty) return n;
    parts[parts.length - 1] = parts.last.length <= 2
        ? '*' * parts.last.length
        : '*' * (parts.last.length - 1);
    return parts.join('-');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder), // ✅ 토스블루 테두리
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
                Text(account.accountName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.fontColor)),
                const SizedBox(height: 4),
                Text(_mask(account.accountNumber),
                    style: TextStyle(color: AppColors.fontColor.withOpacity(.7))),
              ],
            ),
          ),
          // 우: 잔액
          Text(
            '${account.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.fontColor),
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
    final up = f.rate >= 0;
    final c = up ? Colors.red : Colors.blue;
    final icon = up ? '▲' : '▼';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kCardBorder), // ✅ 토스블루 테두리
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(f.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.fontColor)),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_won(f.balance), style: const TextStyle(color: AppColors.fontColor)),
            const SizedBox(height: 2),
            Text('$icon ${f.rate.toStringAsFixed(2)}%',
                style: TextStyle(color: c, fontWeight: FontWeight.w700)),
          ]),
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
