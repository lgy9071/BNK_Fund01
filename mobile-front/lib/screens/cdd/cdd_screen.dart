import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_front/core/services/user_service.dart';


class CddScreen extends StatefulWidget {
  final String? accessToken;      // ✅ 추가: 액세스 토큰
  final UserService? userService; // ✅ 추가: 유저 서비스

  const CddScreen({
    super.key,
    this.accessToken,
    this.userService,
  });

  @override
  State<CddScreen> createState() => _CddScreenState();
}

class _CddScreenState extends State<CddScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CDD 화면'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Access Token: ${widget.accessToken ?? "없음"}'),
            const SizedBox(height: 16),
            Text('User Service: ${widget.userService != null ? "있음" : "없음"}'),
          ],
        ),
      ),
    );
  }
}