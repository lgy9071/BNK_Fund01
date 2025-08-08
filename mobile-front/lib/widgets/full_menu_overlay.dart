import 'package:flutter/material.dart';

class FullMenuOverlay extends StatefulWidget {
  // ── 전달받는 값들 ───────────────────────────────────────────────
  final String userName;
  final String userId;

  final VoidCallback onGoFundMain;
  final VoidCallback onGoFundJoin;
  final VoidCallback onGoInvestAnalysis;

  final VoidCallback onGoFAQ;
  final VoidCallback onGoGuide;
  final VoidCallback onGoMbti;
  final VoidCallback onGoForum;

  final VoidCallback onEditProfile;
  final VoidCallback onAsk;
  final VoidCallback onMyQna;

  const FullMenuOverlay({
    super.key,
    required this.userName,
    required this.userId,
    required this.onGoFundMain,
    required this.onGoFundJoin,
    required this.onGoInvestAnalysis,
    required this.onGoFAQ,
    required this.onGoGuide,
    required this.onGoMbti,
    required this.onGoForum,
    required this.onEditProfile,
    required this.onAsk,
    required this.onMyQna,
  });

  @override
  State<FullMenuOverlay> createState() => _FullMenuOverlayState();
}

class _FullMenuOverlayState extends State<FullMenuOverlay> {
  // 드래그 누적 거리
  double _dragAccum = 0;
  static const _kDismissThreshold = 80; // 80px 이상 끌면 닫기

  void _maybePop() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        _dragAccum += d.delta.dx;
        if (_dragAccum > _kDismissThreshold) _maybePop();
      },
      onHorizontalDragEnd: (_) => _dragAccum = 0, // 초기화
      child: Stack(
        children: [
          // ── 닫기 버튼 ──
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: '닫기',
              onPressed: _maybePop, // ← X 아이콘 정상 동작
            ),
          ),

          // ── 메뉴 본문 ──
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCard(
                    userName: widget.userName,
                    userId: widget.userId,
                    onEditProfile: widget.onEditProfile,
                    onAsk: widget.onAsk,
                    onMyQna: widget.onMyQna,
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(title: '펀드 메뉴'),
                  const SizedBox(height: 8),
                  _MenuList(items: [
                    _MenuItemData(
                        icon: Icons.home_outlined,
                        title: '펀드 메인',
                        onTap: widget.onGoFundMain),
                    _MenuItemData(
                        icon: Icons.playlist_add,
                        title: '펀드 가입',
                        onTap: widget.onGoFundJoin),
                    _MenuItemData(
                        icon: Icons.analytics,
                        title: '투자성향분석',
                        onTap: widget.onGoInvestAnalysis),
                  ]),
                  const SizedBox(height: 20),

                  _SectionTitle(title: '자료실'),
                  const SizedBox(height: 8),
                  _MenuList(items: [
                    _MenuItemData(
                        icon: Icons.help_outline,
                        title: 'FAQ',
                        onTap: widget.onGoFAQ),
                    _MenuItemData(
                        icon: Icons.menu_book,
                        title: '펀드 이용 가이드',
                        onTap: widget.onGoGuide),
                    _MenuItemData(
                        icon: Icons.psychology_alt,
                        title: '펀드 MBTI',
                        onTap: widget.onGoMbti),
                    _MenuItemData(
                        icon: Icons.forum_outlined,
                        title: '펀토방',
                        onTap: widget.onGoForum),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────── 보조 위젯 (기존과 동일) ───────────── */

class _ProfileCard extends StatelessWidget {
  final String userName, userId;
  final VoidCallback onEditProfile, onAsk, onMyQna;
  const _ProfileCard({
    required this.userName,
    required this.userId,
    required this.onEditProfile,
    required this.onAsk,
    required this.onMyQna,
  });
  @override
  Widget build(BuildContext context) => Card(
    elevation: .5,
    shape:
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(userId,
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: onEditProfile,
                tooltip: '내 정보 수정',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton(
                      onPressed: onAsk, child: const Text('문의하기'))),
              const SizedBox(width: 8),
              Expanded(
                  child: FilledButton.tonal(
                      onPressed: onMyQna, child: const Text('내 문의'))),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary));
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _MenuItemData({required this.icon, required this.title, required this.onTap});
}

class _MenuList extends StatelessWidget {
  final List<_MenuItemData> items;
  const _MenuList({required this.items});
  @override
  Widget build(BuildContext context) => Card(
    elevation: .3,
    shape:
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Column(
      children: items
          .map((e) => ListTile(
        leading: Icon(e.icon),
        title: Text(e.title),
        trailing: const Icon(Icons.chevron_right),
        onTap: e.onTap,
      ))
          .toList(),
    ),
  );
}