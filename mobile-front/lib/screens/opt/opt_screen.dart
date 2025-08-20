import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class OptScreen extends StatelessWidget {
  const OptScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('투자성향분석'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.fontColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 80, color: Color(0xFF0064FF)),
                SizedBox(height: 20),
                Text(
                  '입출금 계좌 개설',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.fontColor,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '새로운 입출금 계좌를 개설하는 페이지입니다.',
                  style: TextStyle(fontSize: 16, color: AppColors.fontColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
