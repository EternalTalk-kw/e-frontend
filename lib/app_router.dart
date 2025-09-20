import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'core/api_result.dart';
import 'core/secure_storage.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/loading_screen.dart';
import 'ui/screens/intro_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/intro2_screen.dart';
import 'features/memory/memory_repository.dart';


// ✅ 첫 진입을 게이트로 바로 보내도 됨(원하면 유지 가능)
final appRouter = GoRouter(
  initialLocation: '/gate',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const LoadingScreen()),
    GoRoute(path: '/gate',   builder: (_, __) => const _GateScreen()),
    GoRoute(path: '/intro',  builder: (_, __) => const IntroScreen()),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    GoRoute(path: '/',       builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/intro2', builder: (_, __) => const Intro2Screen()),
  ],
);

class _GateScreen extends StatefulWidget {
  const _GateScreen({super.key});
  @override State<_GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<_GateScreen> {
  @override
  void initState() {
    super.initState();
    _routeByState();
  }

  Future<void> _routeByState() async {
    // 1) 토큰 확인
    final token = await AppSecureStorage.readAccessToken();
    if (!mounted) return;

    // 토큰이 없으면 인트로(또는 로그인)로
    if (token == null) {
      GoRouter.of(context).go('/intro'); // 또는 '/login'
      return;
    }

    // 2) 토큰이 있으면 서버에 프로필 존재 여부 확인
    // NOTE: memoryRepository는 의존성 위치에 맞춰 import하세요.
    try {
      // lazy import 권장
      // ignore: avoid_dynamic_calls
      final memoryRepository = await Future.microtask(
            () => (/* 적절한 싱글턴/locator에서 */),
      );
    } catch (_) {
      // 위 패턴이 복잡하면 기존처럼 파일 상단에 import:
      // import 'features/memory/memory_repository.dart';
    }

    // 간단 버전 (이미 import 되어 있다고 가정)
    try {
      final res = await memoryRepository.hasProfile();
      if (!mounted) return;

      final hasProfile = (res is ApiSuccess<bool>) ? res.data : false;
      if (hasProfile == true) {
        GoRouter.of(context).go('/');        // 프로필 있음 → 홈
      } else {
        GoRouter.of(context).go('/intro2');  // 없음 → 온보딩(프로필 등록)
      }
    } catch (e) {
      // 실패 시 안전하게 홈/로그인 중 하나로
      GoRouter.of(context).go('/');
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
