// // pdf_agree_screen.dart
// import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
//
// class PdfAgreeScreen extends StatefulWidget {
//   final String title;   // 문서명 (예: 간이투자설명서)
//   final String url;     // PDF 파일 URL
//   const PdfAgreeScreen({super.key, required this.title, required this.url});
//
//   @override
//   State<PdfAgreeScreen> createState() => _PdfAgreeScreenState();
// }
//
// class _PdfAgreeScreenState extends State<PdfAgreeScreen> {
//   final _controller = PdfViewerController();
//   int _pageCount = 0;
//   int _currentPage = 1;
//
//   bool get _atLastPage => _pageCount > 0 && _currentPage >= _pageCount;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Stack(
//         children: [
//           // PDF
//           SfPdfViewer.network(
//             widget.url,
//             controller: _controller,
//             canShowPaginationDialog: false,
//             onDocumentLoaded: (d) {
//               setState(() => _pageCount = d.document.pages.count);
//             },
//             onPageChanged: (details) {
//               setState(() => _currentPage = details.newPageNumber);
//             },
//           ),
//
//           // 맨 아래에서만 뜨는 "확인했습니다" 버튼 (부드럽게 슬라이드/페이드)
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: AnimatedSlide(
//               duration: const Duration(milliseconds: 220),
//               offset: _atLastPage ? Offset.zero : const Offset(0, 1),
//               child: AnimatedOpacity(
//                 duration: const Duration(milliseconds: 220),
//                 opacity: _atLastPage ? 1 : 0,
//                 child: Container(
//                   padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black.withOpacity(0.0),
//                         Colors.black.withOpacity(0.06),
//                         Colors.black.withOpacity(0.12),
//                       ],
//                     ),
//                   ),
//                   child: SafeArea(
//                     top: false,
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 52,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF00067D),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         onPressed: () => Navigator.pop(context, true), // 동의 완료
//                         child: const Text(
//                           '확인했습니다',
//                           style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
