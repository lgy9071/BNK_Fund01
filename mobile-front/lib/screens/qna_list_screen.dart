import 'package:flutter/material.dart';

class QnaListScreen extends StatelessWidget {
  const QnaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터로 교체
    final items = List.generate(
      5,
          (i) => (
      '문의 제목 ${i + 1}',
      '처리상태: 접수됨',
      DateTime.now().subtract(Duration(days: i)),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('내 문의')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final e = items[i];
          return ListTile(
            title: Text(e.$1),
            subtitle: Text('${e.$2} · ${e.$3.toString().split(' ').first}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 상세 페이지 이동
            },
          );
        },
      ),
    );
  }
}