// screens/fund_status_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_front/core/constants/colors.dart';
import 'package:mobile_front/screens/fund_status/fund_status.dart';
import 'package:mobile_front/screens/fund_status/fund_status_service.dart';
import 'package:mobile_front/widgets/category_chip.dart';

class FundStatusDetailScreen extends StatefulWidget {
  final int id;
  const FundStatusDetailScreen({super.key, required this.id});

  @override
  State<FundStatusDetailScreen> createState() => _FundStatusDetailScreenState();
}

class _FundStatusDetailScreenState extends State<FundStatusDetailScreen> {
  final _api = FundStatusApi();
  final _format = DateFormat('yyyy.MM.dd HH:mm');
  Future<FundStatusDetail>? _future;

  @override
  void initState() {
    super.initState();
    _future = _api.detail(widget.id); // 서버에서 조회수 + 상세 반환
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.fontColor),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<FundStatusDetail>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(child: Text('오류: ${snap.error}'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // 제목
              Text(d.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.fontColor)),
              const SizedBox(height: 8),
              // 메타 정보
              Row(children: [
                CategoryChip(category: d.category),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text(_format.format(d.regdate),
                    style: const TextStyle(fontSize: 12, color: AppColors.fontColor)),
                const SizedBox(width: 10),
                const Icon(Icons.remove_red_eye_outlined, size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 4),
                Text('${d.viewCount}', style: const TextStyle(fontSize: 12, color: AppColors.fontColor)),
              ]),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEAEFF8)),
              const SizedBox(height: 14),
              // 본문
              Text(d.content, style: const TextStyle(height: 1.6, color: AppColors.fontColor)),
            ],
          );
        },
      ),
    );
  }
}
