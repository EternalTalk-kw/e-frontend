// lib/screens/common/loading_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});
  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 2초 뒤 게이트로 이동 → 게이트가 토큰 보고 /intro 또는 / 로 분기
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) context.go('/gate');
    });
  }

  @override
  void dispose() {
    // ✅ Timer 정리
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 160),
            const SizedBox(height: 28),
            Image.asset('assets/images/text_logo.png', width: 240),
          ],
        ),
      ),
    );
  }
}
