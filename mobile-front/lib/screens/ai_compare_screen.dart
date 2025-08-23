// lib/screens/ai_compare_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_front/models/compare_fund_view.dart';

const tossBlue = Color(0xFF0064FF);
const deepPurple = Color(0xFF6D28D9);


Future<void> showAiCompareSheetFromViews(
    BuildContext context, {
      required List<CompareFundView> views, // 최소 2개
      required String accessToken,
      required String baseUrl,
    }) async {
  if (views.length < 2) {
    throw ArgumentError('AI 비교에는 최소 2개가 필요합니다.');
  }
  final a = views[0];
  final b = views[1];

  await showAiCompareSheet(
    context,
    fundIds: [a.fundId, b.fundId],
    accessToken: accessToken,
    baseUrl: baseUrl,
    fundLabels: [a.name, b.name], // 상단에 표시할 이름
  );
}

/// 모달로 열기 (내용만큼 높이, 라운드)
Future<void> showAiCompareSheet(
    BuildContext context, {
      required List<String> fundIds,
      required String accessToken,
      required String baseUrl,
      List<String>? fundLabels, // [A라벨, B라벨] (선택: 펀드명 표시)
    }) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _RoundedSheet(
              child: AiCompareScreen(
                fundIds: fundIds,
                accessToken: accessToken,
                baseUrl: baseUrl,
                fundLabels: fundLabels,
              ),
            ),
          ),
        ),
      );
    },
  );
}


class _RoundedSheet extends StatelessWidget {
  final Widget child;
  const _RoundedSheet({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

/// ───────── 새 스키마 모델 ─────────
class AiCompareNew {
  final String profileSummary;
  final List<String> prosA;
  final List<String> consA;
  final List<String> prosB;
  final List<String> consB;
  final String pick;   // "A" | "B" | "tie"
  final String reason;
  final String riskNote;

  AiCompareNew({
    required this.profileSummary,
    required this.prosA,
    required this.consA,
    required this.prosB,
    required this.consB,
    required this.pick,
    required this.reason,
    required this.riskNote,
  });

  factory AiCompareNew.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> pc = (json['prosCons'] as Map?)?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
    List<String> _arr(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? const [];
    final A = (pc['A'] as Map?) ?? const {};
    final B = (pc['B'] as Map?) ?? const {};
    final finalPick = (json['finalPick'] as Map?) ?? const {};
    return AiCompareNew(
      profileSummary: (json['profileSummary'] ?? '') as String,
      prosA: _arr(A['pros']),
      consA: _arr(A['cons']),
      prosB: _arr(B['pros']),
      consB: _arr(B['cons']),
      pick: (finalPick['pick'] ?? 'tie') as String,
      reason: (finalPick['reason'] ?? '-') as String,
      riskNote: (json['riskNote'] ?? '') as String,
    );
  }

  bool get isValid => profileSummary.isNotEmpty || prosA.isNotEmpty || prosB.isNotEmpty || reason.isNotEmpty;
}

/// ───────── 구 스키마 폴백용 (summary/rows/recommendation) ─────────
class LegacyRow {
  final String item, a, b, winner, comment;
  LegacyRow(this.item, this.a, this.b, this.winner, this.comment);
  factory LegacyRow.fromMap(Map m) => LegacyRow(
    (m['item'] ?? '-').toString(),
    (m['a'] ?? '-').toString(),
    (m['b'] ?? '-').toString(),
    (m['winner'] ?? 'unknown').toString(),
    (m['comment'] ?? '-').toString(),
  );
}
class LegacyResp {
  final String summary, riskNote;
  final List<LegacyRow> rows;
  final String recProfile, recPick, recReason;
  LegacyResp({
    required this.summary,
    required this.rows,
    required this.recProfile,
    required this.recPick,
    required this.recReason,
    required this.riskNote,
  });
  factory LegacyResp.fromJson(Map<String, dynamic> json) => LegacyResp(
    summary: (json['summary'] ?? '').toString(),
    rows: ((json['rows'] as List?) ?? const []).map((e) => LegacyRow.fromMap(e as Map)).toList(),
    recProfile: (json['recommendation']?['profile'] ?? '').toString(),
    recPick: (json['recommendation']?['pick'] ?? 'tie').toString(),
    recReason: (json['recommendation']?['reason'] ?? '').toString(),
    riskNote: (json['riskNote'] ?? '').toString(),
  );
  bool get isValid => summary.isNotEmpty || rows.isNotEmpty || recReason.isNotEmpty;
}

/// 실제 화면(내용만큼 높이)
class AiCompareScreen extends StatefulWidget {
  final List<String> fundIds;
  final String accessToken;
  final String baseUrl;
  final List<String>? fundLabels; // [A라벨, B라벨]
  const AiCompareScreen({
    super.key,
    required this.fundIds,
    required this.accessToken,
    required this.baseUrl,
    this.fundLabels,
  });
  @override
  State<AiCompareScreen> createState() => _AiCompareScreenState();
}

class _AiCompareScreenState extends State<AiCompareScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final uri = Uri.parse('${widget.baseUrl}/api/compare-ai/compare');
    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'funds': widget.fundIds}),
    );
    debugPrint('[AI Compare] status=${res.statusCode}');
    debugPrint('[AI Compare] body=${res.body}');
    if (res.statusCode != 200) {
      throw Exception('AI 비교 실패: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // 로딩도 시트 느낌의 최소 높이로
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 260),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Grabber(),
                SizedBox(height: 8),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: tossBlue,),
                  ),
                ),
              ],
            ),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return _ErrorBlock(error: snap.error?.toString() ?? '알 수 없는 오류', onRetry: _retry);
        }

        final map = snap.data!;
        final AiCompareNew newer = AiCompareNew.fromJson(map);
        final bool hasNew = newer.isValid;
        final LegacyResp legacy = LegacyResp.fromJson(map);
        final bool hasLegacy = legacy.isValid;

        if (!hasNew && !hasLegacy) {
          return _ErrorBlock(error: '표시할 데이터가 없습니다. (스키마 불일치)', onRetry: _retry);
        }

        // 상단에 표시할 펀드명 라벨
        final aLabel = (widget.fundLabels != null && widget.fundLabels!.isNotEmpty)
            ? widget.fundLabels![0]
            : 'A';
        final bLabel = (widget.fundLabels != null && widget.fundLabels!.length >= 2)
            ? widget.fundLabels![1]
            : 'B';

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Grabber(),
              Row(
                children: [
                  const Text('AI 비교', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 8),

              // ── A/B 펀드명이 뭔지 알려주는 박스 ─────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12.withOpacity(.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow('A', aLabel, tossBlue),
                    const SizedBox(height: 6),
                    _legendRow('B', bLabel, deepPurple),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (hasNew) ...[
                const _SectionTitle('펀드별 장단점'),
                _CardBlock(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ProsConsColumn(
                          tag: 'A',
                          color: tossBlue,            // ← A 컬러
                          pros: newer.prosA,
                          cons: newer.consA,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProsConsColumn(
                          tag: 'B',
                          color: deepPurple,          // ← B 컬러
                          pros: newer.prosB,
                          cons: newer.consB,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const _SectionTitle('비교표'),
                _LegacyRowsTable(
                  legacy.rows,
                  aHeader: aLabel,
                  bHeader: bLabel,
                ),
                const SizedBox(height: 12),

                const _SectionTitle('최종 추천'),
                _CardBlock(child: _FinalPickChip(pick: legacy.recPick, reason: legacy.recReason)),
                if (legacy.riskNote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _RiskNote(text: legacy.riskNote),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// ───────── 공용 위젯/헬퍼 ─────────

class _ErrorBlock extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Grabber(),
          Row(
            children: [
              const Text('AI 비교', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(height: 8),
          Text(error),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44, height: 4,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900));
}

class _CardBlock extends StatelessWidget {
  final Widget child;
  const _CardBlock({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12.withOpacity(.12)),
      ),
      child: child,
    );
  }
}

class _ProsConsColumn extends StatelessWidget {
  final String tag;           // 'A' | 'B'
  final Color color;          // A/B 컬러
  final List<String> pros;
  final List<String> cons;

  const _ProsConsColumn({
    required this.tag,
    required this.color,
    required this.pros,
    required this.cons,
  });

  @override
  Widget build(BuildContext context) {
    final hasPros = pros.isNotEmpty;
    final hasCons = cons.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 제목: 동그란 A/B 뱃지 ───────────────────────
        _ABadge(tag: tag, color: color),
        const SizedBox(height: 10),

        if (hasPros) ...[
          const Text('장점', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...pros.map(_bullet).toList(),
          if (hasCons) const SizedBox(height: 8),
        ],
        if (hasCons) ...[
          const Text('단점', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ...cons.map(_bullet).toList(),
        ],
        if (!hasPros && !hasCons)
          const Text('-', style: TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _FinalPickChip extends StatelessWidget {
  final String pick; // "A" | "B" | "tie"
  final String reason;
  const _FinalPickChip({required this.pick, required this.reason});
  @override
  Widget build(BuildContext context) {
    String title; Color color;
    if (pick == 'A') { title = 'A 추천'; color = tossBlue; }
    else if (pick == 'B') { title = 'B 추천'; color = deepPurple; }
    else { title = '동률/상황별'; color = Colors.grey; }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        Text(reason.isEmpty ? '-' : reason),
      ],
    );
  }
}

class _RiskNote extends StatelessWidget {
  final String text;
  const _RiskNote({required this.text});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.info_outline, size: 20, color: Colors.grey),
      const SizedBox(width: 6),
      const Expanded(
        child: Text(
          '본 분석 결과는 AI가 생성한 참고용 정보이므로,\n투자 결정 시 참고용으로만 활용해주세요.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    ],
  );
}

/// 상단 A/B 펀드명 라인
Widget _legendRow(String tag, String name, Color color) {
  return Row(
    children: [
      Container(
        width: 18, height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

/// 폴백: 구 스키마 테이블 (컬러 헤더/지브라/라운드/세로줄)
class _LegacyRowsTable extends StatelessWidget {
  final List<LegacyRow> rows;
  final String aHeader;
  final String bHeader;
  const _LegacyRowsTable(this.rows, {this.aHeader = '펀드 A', this.bHeader = '펀드 B'});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const Text('항목이 없습니다.');

    final header = TableRow(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tossBlue.withOpacity(.95), tossBlue.withOpacity(.80)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
      ),
      children: const [
        _TCell('항목', bold: true, center: true),
        _BadgeHeader(label: 'A', color: tossBlue),
        _BadgeHeader(label: 'B', color: deepPurple),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단 A/B 이름 상자 (표 위에도 한 번 더 명시)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black12.withOpacity(.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow('A', aHeader, tossBlue),
              const SizedBox(height: 6),
              _legendRow('B', bHeader, deepPurple),
            ],
          ),
        ),
        const SizedBox(height: 8),

        DecoratedBox(
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.black12.withOpacity(.22)),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.black12.withOpacity(.25), width: .7),
                horizontalInside: BorderSide(color: Colors.black12.withOpacity(.12), width: .7),
                top: BorderSide(color: Colors.black12.withOpacity(.35), width: 1),
                bottom: BorderSide(color: Colors.black12.withOpacity(.35), width: 1),
                left: BorderSide(color: Colors.black12.withOpacity(.35), width: 1),
                right: BorderSide(color: Colors.black12.withOpacity(.35), width: 1),
              ),
              columnWidths: const {
                0: FixedColumnWidth(96),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                header,
                ...List<TableRow>.generate(rows.length, (i) {
                  final r = rows[i];
                  final bg = i.isEven ? const Color(0xFFF9FBFF) : const Color(0xFFF1F5FF);
                  return TableRow(
                    decoration: BoxDecoration(color: bg),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Text(
                          r.item,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Text(r.a),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        child: Text(r.b),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String text;
  const _HeadCell(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _TCell extends StatelessWidget {
  final String text;
  final bool bold;
  final bool center;

  const _TCell(this.text, {this.bold = false, this.center = false}); // ← const 추가

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400),
    ),
  );
}

class _ABadge extends StatelessWidget {
  final String tag;   // 'A' | 'B'
  final Color color;
  const _ABadge({required this.tag, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
