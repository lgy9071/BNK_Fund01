// screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_front/core/routes/routes.dart';
import 'package:mobile_front/core/constants/colors.dart';

class LoadingScreen extends StatefulWidget {
  final Future<Map<String, dynamic>> Function() onLoad;

  const LoadingScreen({super.key, required this.onLoad});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    try {
      setState(() => progress = 0.2);

      final result = await widget.onLoad();

      if (!mounted) return;

      setState(() => progress = 1.0);

      // 🔥 최소 800ms 정도 기다려서 UI 안정화 시간 확보
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.investResult,
        arguments: result,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    const barWidth = 300.0;
    const barHeight = 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) {
                return SizedBox(
                  width: barWidth,
                  height: barHeight + 40, // 바 + 러너 공간
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // 회색 배경 바
                      Container(
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      // ✅ 그라데이션 진행 바
                      Container(
                        width: barWidth * value,
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue.withOpacity(0.5),
                              AppColors.primaryBlue,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),

                      // ✅ 러너 (바 중앙 선을 따라 달림)
                      Positioned(
                        left: (barWidth - 40) * value,
                        top: (barHeight / 2) - 20, // 중앙 맞춤 (이미지 높이 40 기준)
                        child: Image.asset(
                          "assets/images/runner.png",
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),


            const SizedBox(height: 20),
            const Text("분석 중입니다...", style: TextStyle(fontSize: 18, color: AppColors.fontColor)),
          ],
        ),
      ),
    );
  }
}
