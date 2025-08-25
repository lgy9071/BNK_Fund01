// fund_doc_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FundDocMeta {
  final String docType;   // 이용약관 / 투자설명서 / 간이투자설명서
  final String filePath;  // /fund_document
  final String fileName;  // "xxx.pdf"
  FundDocMeta({required this.docType, required this.filePath, required this.fileName});

  factory FundDocMeta.fromJson(Map<String, dynamic> j) => FundDocMeta(
    docType: j['docType'],
    filePath: j['filePath'],
    fileName: j['fileName'],
  );
}

class ApiConfig {
  static const baseUrl = 'http://10.0.2.2:8090';
}

/// 예) GET /api/funds/{fundId}/documents?type=간이투자설명서
Future<String> fetchDocUrl({
  required String fundId,
  required String docType,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}/api/funds/$fundId/documents')
      .replace(queryParameters: {'type': docType});
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('문서 메타 조회 실패: ${res.statusCode}');
  }
  final data = jsonDecode(res.body);
  // 서버가 단건 반환이라 가정. (배열이라면 첫 항목 사용)
  final meta = FundDocMeta.fromJson(data);
  // 공백/한글 파일명은 인코딩 필요
  final encodedName = Uri.encodeComponent(meta.fileName);
  // 최종 PDF 접근 URL (정적 서빙 혹은 파일 다운로드 라우트)
  return '${ApiConfig.baseUrl}${meta.filePath}/$encodedName';
}
