import 'package:flutter/material.dart';

class CreateDepositAccountScreen extends StatelessWidget {
  const CreateDepositAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예금계좌 개설'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          '예금계좌 개설 화면입니다',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}