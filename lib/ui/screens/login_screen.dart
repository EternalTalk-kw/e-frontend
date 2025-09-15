// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_repository.dart';
import '../../core/api_result.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    // ✅ 리소스 정리
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await authRepository.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      if (res is ApiSuccess<void>) {
        if (!mounted) return;
        context.go('/'); // 홈으로 이동
      } else if (res is ApiFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleLogin() async {
    // ✅ 레포의 startGoogleLogin 사용 (웹이면 현재 탭으로 열림)
    final res = await authRepository.startGoogleLogin();
    if (res is ApiFailure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 시작 실패: ${res.message}')),
      );
    }
    // 성공(ApiSuccess<void>)인 경우는 브라우저 이동만 일어나므로 별도 처리 없음
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            const SizedBox(height: 48),

            // 상단 텍스트 로고
            Center(
              child: Image.asset(
                'assets/images/text_logo.png',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 56),

            // 이메일
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 비밀번호
            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),

            // 오른쪽 '회원가입' 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('회원가입', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),

            // 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _doLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBFA9FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(_loading ? '로그인 중...' : '로그인'),
              ),
            ),
            const SizedBox(height: 16),

            // 구글 로그인 버튼
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _googleLogin,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Google로 로그인',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
