// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/api_result.dart';
import 'core/secure_storage.dart';

import 'ui/screens/loading_screen.dart';
import 'ui/screens/intro_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/home_screen.dart'; // HomeScreen(photoUrl, personalityPrompt, displayName)

// ✅ 임시 화면들
import 'ui/screens/video_screen.dart';
import 'ui/screens/chat_screen.dart';
import 'ui/screens/settings_screen.dart';

import 'features/memory/memory_repository.dart'; // memoryRepository.hasProfile(), getProfile()

/// 전역 라우터
final appRouter = GoRouter(
  initialLocation: '/gate',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const LoadingScreen()),
    GoRoute(path: '/gate',   builder: (_, __) => const _GateScreen()),
    GoRoute(path: '/intro',  builder: (_, __) => const IntroScreen()),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()),
    // 홈: 프로필 로드 → HomeScreen 주입
    GoRoute(path: '/',       builder: (_, __) => const _HomeScreenRoute()),
    // 온보딩(프로필 등록) — 그대로 유지(TODO 화면)
    GoRoute(path: '/intro2', builder: (_, __) => const _TodoScreen(title: 'Intro2 (TODO)')),
    // ✅ 임시 화면 연결
    GoRoute(path: '/video',    builder: (_, __) => const VideoScreen()),
    GoRoute(path: '/chat',     builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
);

/// 최초 진입 분기 스크린
class _GateScreen extends StatefulWidget {
  const _GateScreen({super.key});
  @override
  State<_GateScreen> createState() => _GateScreenState();
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

    if (token == null || token.isEmpty) {
      GoRouter.of(context).go('/intro'); // 필요 시 '/login'으로 변경 가능
      return;
    }

    // 2) 프로필 존재 여부 확인
    try {
      final res = await memoryRepository.hasProfile();
      if (!mounted) return;

      final has = (res is ApiSuccess<bool>) ? res.data : false;
      GoRouter.of(context).go(has ? '/' : '/intro2');
    } catch (_) {
      if (!mounted) return;
      GoRouter.of(context).go('/'); // 안전한 기본 경로
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// 홈 진입 시 서버에서 프로필을 로드해 HomeScreen에 주입
class _HomeScreenRoute extends StatefulWidget {
  const _HomeScreenRoute({super.key});
  @override
  State<_HomeScreenRoute> createState() => _HomeScreenRouteState();
}

class _HomeScreenRouteState extends State<_HomeScreenRoute> {
  Future<({String photoUrl, String personalityPrompt, String displayName})> _load() async {
    final res = await memoryRepository.getProfile();

    if (res is ApiSuccess<Map<String, dynamic>>) {
      final data = res.data;
      final photoUrl = _asString(_pick(data, ['photoUrl', 'imageUrl', 'avatarUrl']));
      final prompt   = _asString(_pick(data, ['personalityPrompt', 'prompt', 'persona']));
      final name     = _asString(_pick(data, ['displayName', 'name', 'nickname']));
      return (photoUrl: photoUrl, personalityPrompt: prompt, displayName: name);
    } else {
      // 프로필이 없거나 실패한 경우 빈 값으로 홈 표시
      return (photoUrl: '', personalityPrompt: '', displayName: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String photoUrl, String personalityPrompt, String displayName})>(
      future: _load(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final d = snap.data!;
        return HomeScreen(
          photoUrl: d.photoUrl,
          personalityPrompt: d.personalityPrompt,
          displayName: d.displayName,
        );
      },
    );
  }
}

/// 간단한 TODO 화면(기존 intro2용 유지)
class _TodoScreen extends StatelessWidget {
  final String title;
  const _TodoScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text(title)),
      body: const Center(
        child: Text('준비 중…', style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}

/// ---- helpers ----
dynamic _pick(Map<String, dynamic> src, List<String> keys) {
  for (final k in keys) {
    if (src.containsKey(k)) return src[k];
  }
  return null;
}

String _asString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}
