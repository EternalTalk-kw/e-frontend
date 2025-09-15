import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_repository.dart';
import '../../core/api_result.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _email = TextEditingController();
  final _nickname = TextEditingController();
  final _password = TextEditingController();

  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _nickname.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('디지털 유산 사용 동의서에 동의해 주세요.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // 회원가입
      final signUpRes = await authRepository.signup(
        email: _email.text.trim(),
        nickname: _nickname.text.trim(),
        password: _password.text,
      );
      if (signUpRes is ApiFailure) {
        throw (signUpRes as ApiFailure).message;
      }

      // 동의서 제출
      final consentRes = await authRepository.submitConsent(agreed: true);
      if (consentRes is ApiFailure) {
        throw (consentRes as ApiFailure).message;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입 완료! 로그인해 주세요.')),
      );
      context.go('/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showPolicy() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 8),
            Text(
              '디지털 유산 사용 동의서',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              '• 고인의 목소리/영상/텍스트를 기반으로 한 디지털 콘텐츠 생성 및 제공에 동의합니다.\n'
                  '• 관련 데이터의 처리 및 보관에 동의합니다.\n'
                  '• 서비스 약관 및 개인정보 처리방침을 확인했습니다.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // const로 두면 변수 참조 불가 → 변수로 선언
    final inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.white24),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            // 상단 텍스트 로고(선택)
            Center(
              child: Image.asset('assets/images/text_logo.png', width: 160),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: inputBorder,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nickname,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nickname',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: inputBorder,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: inputBorder,
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 동의 체크박스 + 보기
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  fillColor: MaterialStateProperty.resolveWith(
                        (states) => states.contains(MaterialState.selected)
                        ? const Color(0xFFBFA9FF)
                        : Colors.white24,
                  ),
                  checkColor: Colors.black,
                ),
                const Expanded(
                  child: Text(
                    '디지털 유산 사용 동의서에 동의합니다.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: _showPolicy,
                  child: const Text('동의서 보기', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBFA9FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_loading ? '가입 중...' : '회원가입'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
