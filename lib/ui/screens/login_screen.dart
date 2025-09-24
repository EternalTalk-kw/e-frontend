// lib/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_repository.dart';
import '../../core/api_result.dart';
import '../../core/dio_client.dart';       // ✅ 로그인 후 인터셉터 갱신
import '../../core/secure_storage.dart';  // ✅ 토큰 직접 저장 시 사용(필요 시)

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
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1) 로그인 요청
      final res = await authRepository.login(
        email: _email.text.trim(),
        password: _password.text,
      );

      // 2) 실패 처리
      if (res is ApiFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
        return;
      }

      // 3) (옵션) 토큰이 ApiSuccess 페이로드로 내려온 경우, 직접 저장
      //    - authRepository.login 내부에서 이미 저장한다면 이 블록은 생략돼도 OK
      // if (res is ApiSuccess<Map<String, dynamic>>) {
      //   final token = res.data['accessToken']?.toString();
      //   if (token != null && token.isNotEmpty) {
      //     await AppSecureStorage.writeAccessToken(token);
      //   }
      // }

      // 4) 인터셉터 갱신(Authorization 자동 부착)
      await DioClient.I.refreshAuthInterceptor();

      // 5) 분기는 Gate에서: 토큰 유무/프로필 유무로 '/' 또는 '/intro2' 또는 '/login'
      if (!mounted) return;
      context.go('/gate');
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
    // 웹/모바일 각각 구현에 맞춘 시작 함수
    final res = await authRepository.startGoogleLogin();
    if (res is ApiFailure) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구글 로그인 시작 실패: ${res.message}')),
      );
      return;
    }

    // OAuth 콜백에서 토큰 수신 후:
    // 1) AppSecureStorage.writeAccessToken(token)
    // 2) await DioClient.I.refreshAuthInterceptor();
    // 3) context.go('/gate');
    //
    // ※ 위 1~3은 콜백 처리 코드에서 수행해주세요.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            const SizedBox(height: 48),
            Center(
              child: Image.asset(
                'assets/images/text.png',
                width: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 56),

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

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/signup'),
                child: const Text('회원가입', style: TextStyle(fontSize: 13)),
              ),
            ),
            const SizedBox(height: 8),

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
