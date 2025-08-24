import 'package:flutter/material.dart';
import 'package:mobile_front/core/services/review_api.dart';
import 'package:intl/intl.dart';


class ReviewViewModal extends StatefulWidget {
  final ReviewApi api;
  final String fundId;
  const ReviewViewModal({super.key, required this.api, required this.fundId});

  @override
  State<ReviewViewModal> createState() => _ReviewViewModalState();
}

class _ReviewViewModalState extends State<ReviewViewModal> {
  Future<ReviewItemDto?>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReviewItemDto?> _load() async {
    final list = await widget.api.getReviews(widget.fundId);
    if (list.items.isEmpty) return null;
    return list.items.first; // 서버에서 본인 리뷰 포함한다고 가정(필요 시 userId 매칭)
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.4, maxChildSize: 0.7,
      builder: (_, ctrl) => FutureBuilder<ReviewItemDto?>(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data;
          final _dtFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: ListView(
              controller: ctrl,
              children: [
                Row(
                  children: [
                    const Text('내 리뷰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                if (r == null)
                  const Text('작성된 리뷰가 없습니다.', style: TextStyle(color: Colors.grey))
                else ...[
                  Text(r.text, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('작성일: ${_dtFormat.format(r.createdAt)}',
                      style: const TextStyle(color: Colors.grey)),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}
