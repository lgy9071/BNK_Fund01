class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;
  final PaginationInfo? pagination;

  ApiResponse({required this.success, this.data, this.message, this.errorCode, this.pagination});

  factory ApiResponse.fromJson(Map<String, dynamic> j, T Function(Object? json) parseData) {
    return ApiResponse<T>(
      success: j['success'] == true,
      data: j.containsKey('data') ? parseData(j['data']) : null,
      message: j['message'] as String?,
      errorCode: j['errorCode'] as String?,
      pagination: j['pagination'] == null
          ? null
          : PaginationInfo.fromJson(j['pagination'] as Map<String, dynamic>),
    );
  }
}

class PaginationInfo {
  final int page; // 0-based
  final int limit;
  final int totalPages;
  final int currentItems;
  final int total;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.currentItems,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> j) => PaginationInfo(
    page: j['page'],
    limit: j['limit'],
    totalPages: j['totalPages'],
    currentItems: j['currentItems'],
    total: j['total'],
    hasNext: j['hasNext'],
    hasPrev: j['hasPrev'],
  );
}