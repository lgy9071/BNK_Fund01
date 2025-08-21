// models/fund_status.dart
class FundStatusListItem {
  final int id;
  final String category;
  final String title;
  final String preview;
  final int viewCount;
  final DateTime regdate;

  FundStatusListItem({
    required this.id,
    required this.category,
    required this.title,
    required this.preview,
    required this.viewCount,
    required this.regdate,
  });

  factory FundStatusListItem.fromJson(Map<String, dynamic> j) => FundStatusListItem(
    id: j['id'],
    category: j['category'],
    title: j['title'],
    preview: j['preview'] ?? '',
    viewCount: j['viewCount'] ?? 0,
    regdate: DateTime.parse(j['regdate']),
  );
}

class FundStatusDetail {
  final int id;
  final String category;
  final String title;
  final String content;
  final int viewCount;
  final DateTime regdate;
  final DateTime? moddate;

  FundStatusDetail({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.regdate,
    this.moddate,
  });

  factory FundStatusDetail.fromJson(Map<String, dynamic> j) => FundStatusDetail(
    id: j['id'],
    category: j['category'],
    title: j['title'],
    content: j['content'] ?? '',
    viewCount: j['viewCount'] ?? 0,
    regdate: DateTime.parse(j['regdate']),
    moddate: j['moddate'] != null ? DateTime.parse(j['moddate']) : null,
  );
}

class PageResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final bool last;
  PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.last,
  });
}
