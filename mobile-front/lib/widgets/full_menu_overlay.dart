import 'package:flutter/material.dart';

const tossBlue = Color(0xFF0064FF);
Color pastel(Color c) => c.withOpacity(.12); // 파스텔 톤

class FullMenuOverlay extends StatefulWidget {
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
  double _dragAccum = 0;
  static const _kDismissThreshold = 80;

  void _maybePop() => Navigator.of(context, rootNavigator: true).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경 흰색
      body: Stack(
        children: [
          // 본문(제스처 포함)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) {
                _dragAccum += d.delta.dx;
                if (_dragAccum > _kDismissThreshold) _maybePop();
              },
              onHorizontalDragEnd: (_) => _dragAccum = 0,
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
                      _MenuItemData(icon: Icons.home_outlined, title: '펀드 메인', onTap: widget.onGoFundMain),
                      _MenuItemData(icon: Icons.playlist_add,  title: '펀드 가입', onTap: widget.onGoFundJoin),
                      _MenuItemData(icon: Icons.analytics,     title: '투자성향분석', onTap: widget.onGoInvestAnalysis),
                    ]),
                    const SizedBox(height: 20),

                    _SectionTitle(title: '자료실'),
                    const SizedBox(height: 8),
                    _MenuList(items: [
                      _MenuItemData(icon: Icons.help_outline,   title: 'FAQ',           onTap: widget.onGoFAQ),
                      _MenuItemData(icon: Icons.menu_book,      title: '펀드 이용 가이드', onTap: widget.onGoGuide),
                      _MenuItemData(icon: Icons.psychology_alt, title: '펀드 MBTI',      onTap: widget.onGoMbti),
                      _MenuItemData(icon: Icons.forum_outlined, title: '펀토방',          onTap: widget.onGoForum),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          // 닫기 버튼 (맨 위 레이어)
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: _maybePop,
              tooltip: '닫기',
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────── 보조 위젯 ───────────── */

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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pastel(tossBlue), // 카드 바깥 배경 = 파스텔 토스블루
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        color: Colors.white, // 카드 내용 = 흰색
        elevation: 0,
        margin: const EdgeInsets.all(6), // 파스텔 배경이 테두리처럼 보이도록
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFEFF4FF),
                    child: Icon(Icons.person, color: tossBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                        Text(userId,   style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.black87),
                    onPressed: onEditProfile,
                    tooltip: '내 정보 수정',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 정보/버튼 사이 구분선
              Divider(height: 1, color: Colors.grey.shade300),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAsk,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('문의하기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: onMyQna,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF6F8FF),
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('내 문의'),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pastel(tossBlue), // 카드 바깥 배경 = 파스텔 토스블루
        borderRadius: BorderRadius.circular(14),
      ),
      child: Card(
        color: Colors.white, // 카드 내용 = 흰색
        elevation: 0,
        margin: const EdgeInsets.all(6), // 파스텔 테두리처럼 보이게
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              ListTile(
                leading: Icon(items[i].icon, color: Colors.black87),
                title: Text(items[i].title, style: const TextStyle(color: Colors.black)),
                trailing: const Icon(Icons.chevron_right, color: Colors.black54),
                onTap: items[i].onTap,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(.25), // 정보 사이 구분선
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}