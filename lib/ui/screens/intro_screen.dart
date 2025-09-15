import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  final List<String> _messages = const [
    "안녕하세요. '추억하고 싶은, 다시보고 싶은 사람'이 있으신가요?",
    "저희 '이터널톡'이 도와드리겠습니다.", // (임시)
    "그럼 시작해볼까요?",
  ];

  int _index = 0;

  // 메시지 안에서 '따옴표' 부분만 그라데이션 처리한 RichText 생성
  Widget _buildQuotedGradientText(String text) {
    // 따옴표로 감싼 부분 찾기 (가장 첫 쌍만 처리)
    final match = RegExp(r"'([^']+)'").firstMatch(text);

    if (match == null) {
      // 따옴표가 없으면 전체 흰색
      return Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          height: 1.5,
        ),
      );
    }

    final before = text.substring(0, match.start);
    final quoted = match.group(1)!; // 따옴표 안
    final after = text.substring(match.end);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontSize: 22,
          height: 1.5,
          color: Colors.white,
        ),
        children: [
          TextSpan(text: before),
          // 따옴표 안쪽만 위젯으로 분리해서 ShaderMask 적용
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: _GradientText(
              quoted,
              style: const TextStyle(
                fontSize: 22,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF8CB5D1), // 로고의 블루 톤과 비슷하게
                  Color(0xFFE09A76), // 로고의 오렌지 톤과 비슷하게
                ],
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  void _onNext() {
    if (_index < _messages.length - 1) {
      setState(() => _index += 1);
    } else {
      context.go('/login'); // 마지막: 로그인 화면으로
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _messages.length - 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // 가운데 문구 (부드럽게 페이드 전환)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey(_index),
                  alignment: Alignment.center,
                  child: _buildQuotedGradientText(_messages[_index]),
                ),
              ),
              const Spacer(),
              // 하단 버튼 영역
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFA9FF), // 은은한 연보라 (다크 테마 위)
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isLast ? '로그인 하기' : '확인', style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 텍스트 전체에 선형 그라데이션을 적용하는 위젯
class _GradientText extends StatelessWidget {
  const _GradientText(
      this.text, {
        required this.gradient,
        this.style,
      });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
