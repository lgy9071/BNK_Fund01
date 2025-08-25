class QnaItem {
  final int qnaId;
  final String title;
  final String content;
  final DateTime regDate;
  final String status; // "대기" 또는 "완료"
  final String? answer;

  QnaItem({
    required this.qnaId,
    required this.title,
    required this.content,
    required this.regDate,
    required this.status,
    this.answer,
  });

  factory QnaItem.fromJson(Map<String, dynamic> json) {
    return QnaItem(
      qnaId: json['qnaId'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      regDate: DateTime.parse(json['regDate'] as String),
      status: json['status'] as String,
      answer: json['answer'] as String?, // null 허용
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qnaId': qnaId,
      'title': title,
      'content': content,
      'regDate': regDate.toIso8601String(),
      'status': status,
      'answer': answer,
    };
  }
}
