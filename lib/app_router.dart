import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'core/secure_storage.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/loading_screen.dart';
import 'ui/screens/intro_screen.dart';
import 'ui/screens/signup_screen.dart'; // ★ 추가

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const LoadingScreen()),
    GoRoute(path: '/gate',   builder: (_, __) => const _GateScreen()),
    GoRoute(path: '/intro',  builder: (_, __) => const IntroScreen()),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignUpScreen()), // ★ 추가
    GoRoute(path: '/',       builder: (_, __) => const HomeScreen()),
  ],
);

class _GateScreen extends StatefulWidget {
  const _GateScreen({super.key});
  @override State<_GateScreen> createState() => _GateScreenState();
}
class _GateScreenState extends State<_GateScreen> {
  @override
  void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    final token = await AppSecureStorage.readAccessToken();
    if (!mounted) return;
    if (token == null) {
      GoRouter.of(context).go('/intro');
    } else {
      GoRouter.of(context).go('/');
    }
  }
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
