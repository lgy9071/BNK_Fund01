import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/core/services/user_service.dart';
import 'package:mobile_front/utils/exit_popup.dart';

import '../core/routes/routes.dart';
import '../models/fund.dart';

/// pubspec.yaml 에 의존성 추가:
/// flutter_secure_storage: ^9.2.2

/* ===== 홈 ===== */
class HomeScreen extends StatefulWidget {
  final List<Fund> myFunds;
  final bool fundsLoading; // 🆕 추가
  final String? fundsError; // 🆕 추가
  final VoidCallback? onRefreshFunds; // 🆕 추가
  final String investType;
  final String userName;
  final String? accessToken;
  final UserService? userService;
  final Future<void> Function()? onStartInvestFlow;

  const HomeScreen({
    super.key,
    required this.myFunds,
    this.fundsLoading = false, // 🆕 추가
    this.fundsError, // 🆕 추가
    this.onRefreshFunds, // 🆕 추가
    required this.investType,
    required this.userName,
    this.accessToken,
    this.userService,
    this.onStartInvestFlow,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum FundSort { amountDesc, newest, nameAsc, rateDesc }

class _HomeScreenState extends State<HomeScreen> {
  bool _obscure = false; // 금액 숨김
  bool _expandFunds = false; // 더보기
  FundSort _sort = FundSort.amountDesc;
  String? _displayName; // 서버에서 받은 이름 저장
  String? _investTypeName; // 서버에서 받은 투자성향결과 띄우기

  // 디자인 커스텀은 ‘총 평가금액’ 카드에만 적용됨
  BgChoice _bg = BgChoice.solid(pastel(tossBlue));
  File? _bgImageFile;

  //데이터 전달 받기 위한 클래스
  @override
  void initState() {
    super.initState();
    _restoreDesign(); // ⬅︎ secure storage에서 배경/숨김 복원
    _loadMe(); // ⬅︎ 서버 프로필 로드
  }

  Future<void> _restoreDesign() async {
    final savedBg = await _DesignStorage.loadBg();
    final savedObscure = await _DesignStorage.loadObscure();
    if (!mounted) return;
    setState(() {
      if (savedBg != null) {
        _bg = savedBg;
        _bgImageFile = savedBg.image;
      }
      if (savedObscure != null) {
        _obscure = savedObscure;
      }
    });
  }

  Future<void> _loadMe() async {
    final token = widget.accessToken;
    if (token == null || token.isEmpty) return; // 토큰 없으면 패스
    try {
      final svc = widget.userService ?? UserService();
      final me = await svc.getMe(token);
      if (!mounted) return;
      setState(() {
        // name이 비어있지 않으면 화면에 반영
        _displayName = me.name.isNotEmpty ? me.name : null;
        _investTypeName = me.typename.isNotEmpty ? me.typename : null;
      });
    } catch (e) {
      debugPrint('getMe failed: $e'); // 원인 확인용
      // 실패 시 조용히 무시 (props 유지)
    }
  }

  //데이터 전달 받기 위한 클래스2

  String _won(int v) =>
      '${v.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원';

  // =================================================

  // 🆕 빈 펀드 상태 UI 빌드 메서드
  Widget _buildEmptyFundsSection() {
    final investTypeName = _investTypeName ?? widget.investType;
    final hasInvestType =
        investTypeName.isNotEmpty && investTypeName != '공격투자형'; // 기본값이 아닌 실제 성향

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '가입한 펀드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 24),

          // 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: tossBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.account_balance_outlined,
              size: 32,
              color: tossBlue,
            ),
          ),

          const SizedBox(height: 16),

          // 메인 메시지
          Text(
            '첫 투자를 시작해보세요!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.fontColor,
            ),
          ),

          const SizedBox(height: 8),

          // 서브 메시지
          Text(
            hasInvestType
                ? '투자성향에 맞는 펀드를 찾아\n안전하고 효율적인 투자를 시작해보세요'
                : '투자성향 분석을 통해 나에게 맞는\n펀드를 찾아보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.fontColor.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // 액션 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (hasInvestType) {
                  // 투자성향이 있으면 펀드 목록으로
                  // MainScaffold의 탭 전환을 통해 펀드 목록 화면으로 이동
                  // 이 부분은 MainScaffold의 onTap 로직과 연동 필요
                  Navigator.of(context).pushNamed('/fund-list');
                } else {
                  // 투자성향이 없으면 분석 플로우
                  if (widget.onStartInvestFlow != null) {
                    await widget.onStartInvestFlow!();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                hasInvestType ? '펀드 둘러보기' : '투자성향 분석하기',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🆕 로딩 상태 UI
  Widget _buildLoadingFundsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '보유 펀드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 32),

          // 로딩 인디케이터
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(tossBlue),
            strokeWidth: 3,
          ),

          const SizedBox(height: 16),

          Text(
            '펀드 정보를 불러오는 중...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.fontColor.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 🆕 에러 상태 UI
  Widget _buildErrorFundsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tossBlue.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 헤더
          Row(
            children: [
              Text(
                '보유 펀드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.fontColor,
                ),
              ),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 24),

          // 에러 아이콘
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red.shade400,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '펀드 정보를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.fontColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '네트워크 연결을 확인하고\n다시 시도해주세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.fontColor.withOpacity(0.7),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // 다시 시도 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onRefreshFunds,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.grey.shade100,
                foregroundColor: AppColors.fontColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 수정된 총 평가금액 표시 로직
  Widget _buildTotalBalanceContent() {
    if (widget.myFunds.isEmpty && !widget.fundsLoading) {
      // 빈 펀드 상태일 때 0원 + 안내 메시지
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _obscure
                ? Align(
                    key: const ValueKey('hidden'),
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _obscure = false);
                        await _DesignStorage.saveObscure(false);
                      },
                      child: Text(
                        '잔액보기',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _idealOn(_bg),
                          decoration: TextDecoration.underline,
                          decorationColor: (_bg.isImage
                              ? Colors.white70
                              : _idealOn(_bg).withOpacity(.45)),
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    key: const ValueKey('shown-empty'),
                    children: [
                      Text(
                        '0원',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _idealOn(_bg),
                          shadows: _bg.isImage
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(.55),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '펀드 가입 후 확인 가능',
                        style: TextStyle(
                          fontSize: 12,
                          color: _idealOn(_bg).withOpacity(0.7),
                          shadows: _bg.isImage
                              ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(.55),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    } else {
      // 기존 로직 (펀드가 있을 때)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _obscure
                ? Align(
                    key: const ValueKey('hidden'),
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _obscure = false);
                        await _DesignStorage.saveObscure(false);
                      },
                      child: Text(
                        '잔액보기',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _idealOn(_bg),
                          decoration: TextDecoration.underline,
                          decorationColor: (_bg.isImage
                              ? Colors.white70
                              : _idealOn(_bg).withOpacity(.45)),
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
                        color: _idealOn(_bg),
                        shadows: _bg.isImage
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(.55),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1.5),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
          ),
        ],
      );
    }
  }

  // ==================================================================

  List<Fund> _sortedFunds() {
    final list = [...widget.myFunds];
    switch (_sort) {
      case FundSort.amountDesc:
        list.sort((a, b) => b.balance.compareTo(a.balance));
        break;
      case FundSort.newest:
        list.sort((a, b) => b.id.compareTo(a.id));
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
        onToggleObscure: (v) async {
          setState(() => _obscure = v);
          await _DesignStorage.saveObscure(v); // ✅ 저장
        },
        onPickPreset: (choice) async {
          setState(() {
            _bg = choice;
            _bgImageFile = choice.image;
          });
          await _DesignStorage.saveBg(choice); // ✅ 저장
          if (context.mounted) Navigator.pop(context);
        },
        onPickImage: () async {
          final x = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (x == null) return;
          final choice = BgChoice.image(File(x.path));
          setState(() {
            _bg = choice;
            _bgImageFile = File(x.path);
          });
          await _DesignStorage.saveBg(choice); // ✅ 저장
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
    final displayName = _displayName ?? widget.userName; // 표시 이름
    final investTypeName = _investTypeName; // 투자 성향 결과 표시
    final funds = _sortedFunds();
    final baseText = AppColors.fontColor;
    final baseDim = baseText.withOpacity(.54);
    final onColor = _idealOn(_bg); // 총 평가금액 상단 텍스트 대비색

    // 더보기: 처음 2개 고정 + 나머지는 아래로 추가
    final int baseCount = math.min(2, funds.length);
    final List<Fund> firstTwo = funds.take(baseCount).toList();
    final List<Fund> rest = _expandFunds
        ? funds.skip(baseCount).toList()
        : const [];
    print(investTypeName);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // 이미 pop 처리된 경우 무시
        await showExitPopup(context);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent, // 항상 투명
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          // 그림자 제거
          automaticallyImplyLeading: false,
          // 기본 back 버튼 제거
          titleSpacing: 0,
          // 로고를 왼쪽 끝까지 붙이고 싶을 때
          title: Row(
            children: [
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  height: 33,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.account_balance, color: Colors.black),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /* 투자성향 카드 */
                InkWell(
                  onTap: () async {
                    if (investTypeName == null || investTypeName.isEmpty) {
                      if (widget.onStartInvestFlow != null) {
                        await widget.onStartInvestFlow!(); // ✅ 부모가 라우팅 + 리로드
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(14.r),
                  child: Container(
                    height:
                        (investTypeName != null && investTypeName.isNotEmpty)
                        ? 72.h
                        : 180.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: tossBlue.withOpacity(0.16),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (investTypeName != null &&
                            investTypeName.isNotEmpty) ...[
                          // ✅ 좌측 라벨: 한 줄 + 말줄임
                          Expanded(
                            child: AutoSizeText(
                              '$displayName 님의 투자성향',
                              maxLines: 1,
                              minFontSize: 10,
                              stepGranularity: 0.5,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: baseText,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // 🔹 우측 결과(텍스트 + 화살표): 폭 제한 + 한 줄 유지(자동 축소)
                          InkWell(
                            borderRadius: BorderRadius.circular(8.r),
                            onTap: () async {
                              if (widget.onStartInvestFlow != null) {
                                await widget
                                    .onStartInvestFlow!(); // ✅ 결과 화면/재검사 진입 포함
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 결과 텍스트: 너무 길면 자동 축소해서 1줄 유지
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 160.w),
                                  child: AutoSizeText(
                                    investTypeName!,
                                    maxLines: 1,
                                    minFontSize: 10,
                                    stepGranularity: 0.5,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w800,
                                      color: baseText,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Icon(
                                  Icons.chevron_right,
                                  color: baseDim,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // ❌ 투자성향 결과가 없을 때
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 5.h),

                                // 🔹 유저 이름 + 환영 문구: 한 줄 고정(자동 축소)
                                // RichText 대신 AutoSizeText.rich로 1줄 강제
                                AutoSizeText.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: displayName,
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.fontColor,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' 님 환영합니다',
                                        style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.w500,
                                          color: baseText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  minFontSize: 12,
                                  stepGranularity: 0.5,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 10.h),

                                // 🔹 안내 문구: 반드시 한 줄 + 자동 축소
                                SizedBox(
                                  width: double.infinity,
                                  child: AutoSizeText(
                                    '투자성향분석을 진행하고 펀드 가입을 시작해보세요!',
                                    maxLines: 1,
                                    minFontSize: 11,
                                    stepGranularity: 0.5,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: baseText.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 16.h),

                                // 🔹 맨 아래 버튼: 텍스트 한 줄 강제(FittedBox로 축소)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (widget.onStartInvestFlow != null) {
                                        await widget
                                            .onStartInvestFlow!(); // ✅ 부모가 끝까지 처리
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.h,
                                      ),
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '투자성향 분석하기',
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                /* 총 평가금액 카드 */
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: tossBlue.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          constraints: const BoxConstraints(minHeight: 100),
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          decoration: BoxDecoration(
                            image: _bg.isImage && _bgImageFile != null
                                ? DecorationImage(
                                    image: FileImage(_bgImageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: (!_bg.isImage && !_bg.isGradient)
                                ? _bg.c1
                                : null,
                            gradient: _bg.isGradient
                                ? LinearGradient(
                                    colors: [_bg.c1!, _bg.c2!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              if (_bg.isImage)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black.withOpacity(.28),
                                  ),
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
                                            color: _idealOn(_bg),
                                            shadows: _bg.isImage
                                                ? [
                                                    Shadow(
                                                      color: Colors.black
                                                          .withOpacity(.55),
                                                      blurRadius: 8,
                                                      offset: const Offset(
                                                        0,
                                                        1.5,
                                                      ),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.more_horiz,
                                          color: _bg.isImage
                                              ? Colors.white
                                              : _idealOn(_bg).withOpacity(.6),
                                        ),
                                        onPressed: _openSettingsSheet,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),

                                  // 🔄 수정된 부분: 펀드 없을 때 우측 정렬, 있을 때는 기존 로직 유지
                                  widget.myFunds.isEmpty
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              children: [
                                                const Spacer(),
                                                Text(
                                                  '0원',
                                                  style: TextStyle(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w700,
                                                    color: _idealOn(_bg),
                                                    shadows: _bg.isImage
                                                        ? [
                                                            Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    .55,
                                                                  ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    1.5,
                                                                  ),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Spacer(),
                                                Text(
                                                  '펀드 가입 후 확인 가능',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: _idealOn(
                                                      _bg,
                                                    ).withOpacity(.7),
                                                    shadows: _bg.isImage
                                                        ? [
                                                            Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    .35,
                                                                  ),
                                                              blurRadius: 4,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    1,
                                                                  ),
                                                            ),
                                                          ]
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        )
                                      : _buildTotalBalanceContent(),
                                  // 기존 메서드 호출 유지
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 🔄 수정된 하단 손익 정보 (빈 펀드일 때 숨김)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: (_obscure || widget.myFunds.isEmpty)
                              ? const SizedBox.shrink()
                              : Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    8,
                                    16,
                                    10,
                                  ),
                                  child: Builder(
                                    builder: (_) {
                                      final up = _pnl >= 0;
                                      final sign = up ? '+' : '−';
                                      final c = up ? Colors.red : Colors.blue;
                                      final baseText = AppColors.fontColor;
                                      return Row(
                                        children: [
                                          const Spacer(),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '평가손익',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: baseText
                                                          .withOpacity(.54),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '$sign ${_won(_pnl.abs())}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: c,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '수익률',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: baseText
                                                          .withOpacity(.54),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    '$sign ${_returnPct.abs().toStringAsFixed(2)}%',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: c,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /* 🆕 조건부 펀드 섹션 렌더링 */
                if (widget.fundsLoading)
                  _buildLoadingFundsSection()
                else if (widget.fundsError != null)
                  _buildErrorFundsSection()
                else if (widget.myFunds.isEmpty)
                  _buildEmptyFundsSection()
                else
                  /* 기존 보유 펀드 섹션 */
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tossBlue.withOpacity(0.12),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: _toMyFinance,
                              borderRadius: BorderRadius.circular(8),
                              child: Text(
                                '보유 펀드',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.fontColor,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.more_horiz,
                                color: AppColors.fontColor.withOpacity(.54),
                              ),
                              onPressed: _openFundsOptionsSheet,
                            ),
                          ],
                        ),
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
                          if (i != firstTwo.length - 1)
                            const SizedBox(height: 10),
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
                            onTap: () =>
                                setState(() => _expandFunds = !_expandFunds),
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

                _MbtiPromoCard(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.fundMbti),
                ),

                const SizedBox(height: 12),
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
        Icon(
          _sort == v ? Icons.radio_button_checked : Icons.radio_button_off,
          size: 18,
          color: AppColors.fontColor,
        ),
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

  const _FundMiniTile({
    required this.fund,
    required this.obscure,
    required this.onTap,
  });

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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.fontColor,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!obscure)
                    Text(
                      '${fund.balance.toString().replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), ',')}원',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.fontColor,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    '$arrow ${_fmtWon(delta.abs())} (${fund.rate.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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
    widget.onToggleObscure(v); // 상위(HomeScreen)에도 반영(+ 저장은 상위에서 처리)
  }

  @override
  Widget build(BuildContext context) {
    Widget tile({required Widget child, required VoidCallback onTap}) =>
        InkWell(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
          ),
        );

    final presets = <BgChoice>[
      BgChoice.solid(pastel(const Color(0xFFA8E6CF))), // 민트
      BgChoice.solid(pastel(const Color(0xFFE0BBE4))), // 라벤더
      BgChoice.solid(pastel(const Color(0xFF0064FF))), // 하늘
      // BgChoice.solid(pastel(const Color(0xFFFDCEDF))), // 베이비핑크
      BgChoice.solid(const Color(0xFFFF595E)), // 비비드 레드
      BgChoice.solid(const Color(0xFFFFCA3A)), // 옐로우
      BgChoice.solid(const Color(0xFF0064FF)), // 블루
      BgChoice.solid(const Color(0xFF2ECC71)), // 에메랄드
      // BgChoice.solid(const Color(0xFF1F3A93)), // 로얄블루
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '메인 영역 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fontColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.fontColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '디자인 설정',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.fontColor.withOpacity(.6),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in presets)
                tile(
                  onTap: () => widget.onPickPreset(p), // 저장은 상위에서 처리
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
            title: const Text(
              '금액 숨기기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.fontColor,
              ),
            ),
            trailing: Switch(
              value: _isObscure,
              onChanged: _setObscure,
              activeColor: AppColors.primaryBlue,
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
          Row(
            children: [
              const Text(
                '보유 펀드 옵션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fontColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.fontColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '정렬',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.fontColor.withOpacity(.6),
            ),
          ),
          const SizedBox(height: 6),
          _radio('금액 많은 순', FundSort.amountDesc),
          _radio('최신순', FundSort.newest),
          _radio('이름순', FundSort.nameAsc),
          _radio('수익률 높은 순', FundSort.rateDesc),

          const SizedBox(height: 10),
          const Divider(height: 1),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '전체 보기',
              style: TextStyle(
                color: AppColors.fontColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _expanded ? '펀드를 모두 펼쳐 보기' : '펀드를 모두 펼쳐 보기',
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
            child: Icon(
              Icons.add,
              size: 20,
              color: AppColors.fontColor.withOpacity(.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _MbtiPromoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MbtiPromoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF3FF), // 파스텔 블루 (연한 톤)
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(.05)), // 연한 테두리
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mbti-char3.png',
                  height: 64,
                  width: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.extension,
                    size: 36,
                    color: Colors.black45,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '나의 투자 성격은?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(.70),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '펀드 MBTI로 1분 만에 확인하기',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E1F23),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.black.withOpacity(.35)),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================

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

  // ---- 직렬화/역직렬화 (secure storage용) ----
  Map<String, dynamic> toJson() => {
    'type': isImage ? 'image' : (isGradient ? 'gradient' : 'solid'),
    'c1': c1?.value,
    'c2': c2?.value,
    'imagePath': image?.path,
  };

  static BgChoice fromJson(Map<String, dynamic> j) {
    final type = (j['type'] as String?) ?? 'solid';
    switch (type) {
      case 'image':
        final path = j['imagePath'] as String?;
        if (path != null && File(path).existsSync()) {
          return BgChoice.image(File(path));
        }
        // 이미지 파일이 사라졌으면 기본값으로 폴백
        return BgChoice.solid(pastel(tossBlue));
      case 'gradient':
        return BgChoice.gradient(
          Color((j['c1'] as num).toInt()),
          Color((j['c2'] as num).toInt()),
        );
      default:
        return BgChoice.solid(Color((j['c1'] as num).toInt()));
    }
  }
}

/* ===== Secure Storage 래퍼 ===== */
class _DesignStorage {
  static const _storage = FlutterSecureStorage();
  static const _kBg = 'home_bg_choice_v1';
  static const _kObscure = 'home_obscure_v1';

  static Future<void> saveBg(BgChoice bg) async {
    await _storage.write(key: _kBg, value: jsonEncode(bg.toJson()));
  }

  static Future<BgChoice?> loadBg() async {
    final raw = await _storage.read(key: _kBg);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return BgChoice.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveObscure(bool v) =>
      _storage.write(key: _kObscure, value: v ? '1' : '0');

  static Future<bool?> loadObscure() async {
    final raw = await _storage.read(key: _kObscure);
    if (raw == null) return null;
    return raw == '1';
  }
}

/* 배경 대비용 글자색 계산 */
Color _idealOn(
  BgChoice bg, {
  Color light = AppColors.fontColor,
  Color dark = Colors.white,
}) {
  if (bg.isImage) return dark;
  if (bg.isGradient) {
    final l1 = bg.c1!.computeLuminance();
    final l2 = bg.c2!.computeLuminance();
    return ((l1 + l2) / 2) < 0.55 ? dark : light;
  }
  final lum = (bg.c1 ?? Colors.white).computeLuminance();
  return lum < 0.55 ? dark : light;
}
