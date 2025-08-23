// lib/models/compare_ai_models.dart
import 'dart:convert';

class CompareAiRow {
  final String item;     // "펀드유형|위험등급|운용사|1M|3M|12M"
  final String a;
  final String b;
  final String winner;   // "A" | "B" | "tie" | "unknown"
  final String comment;

  CompareAiRow({
    required this.item,
    required this.a,
    required this.b,
    required this.winner,
    required this.comment,
  });

  factory CompareAiRow.fromJson(Map<String, dynamic> json) => CompareAiRow(
    item: (json['item'] ?? '-') as String,
    a: (json['a'] ?? '-') as String,
    b: (json['b'] ?? '-') as String,
    winner: (json['winner'] ?? 'unknown') as String,
    comment: (json['comment'] ?? '-') as String,
  );
}

class CompareAiRecommendation {
  final String profile; // "안정형|안정추구형|위험중립형|적극투자형|공격투자형|미설정"
  final String pick;    // "A" | "B" | "tie"
  final String reason;

  CompareAiRecommendation({
    required this.profile,
    required this.pick,
    required this.reason,
  });

  factory CompareAiRecommendation.fromJson(Map<String, dynamic> json) =>
      CompareAiRecommendation(
        profile: (json['profile'] ?? '미설정') as String,
        pick: (json['pick'] ?? 'tie') as String,
        reason: (json['reason'] ?? '-') as String,
      );
}

class CompareAiResponse {
  final String summary;
  final List<CompareAiRow> rows;
  final CompareAiRecommendation recommendation;
  final String riskNote;

  CompareAiResponse({
    required this.summary,
    required this.rows,
    required this.recommendation,
    required this.riskNote,
  });

  factory CompareAiResponse.fromJson(Map<String, dynamic> json) => CompareAiResponse(
    summary: (json['summary'] ?? '-') as String,
    rows: ((json['rows'] as List?) ?? [])
        .map((e) => CompareAiRow.fromJson(e as Map<String, dynamic>))
        .toList(),
    recommendation: CompareAiRecommendation.fromJson(
        (json['recommendation'] as Map<String, dynamic>? ?? const {})),
    riskNote: (json['riskNote'] ?? '-') as String,
  );

  static CompareAiResponse parse(String body) =>
      CompareAiResponse.fromJson(jsonDecode(body) as Map<String, dynamic>);
}
