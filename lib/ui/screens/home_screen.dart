// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ✅ 네비게이션 고루터 사용

class HomeScreen extends StatelessWidget {
  final String photoUrl;           // 고인 사진 URL
  final String personalityPrompt;  // 고인의 성격 문구
  final String displayName;        // 라운드 박스 좌측 상단 배지

  const HomeScreen({
    super.key,
    required this.photoUrl,
    required this.personalityPrompt,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        titleSpacing: 8,
        title: Row(
          children: [
            const SizedBox(width: 4),
            Image.asset('assets/images/logo_text.png', height: 55),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ───────── 1) displayName + 사진 + personalityPrompt ─────────
            _RoundBox(
              child: LayoutBuilder(
                builder: (context, c) {
                  final boxW = c.maxWidth;
                  final photoSize = boxW / 2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측 상단 displayName (사진과 겹치지 않게 위에 분리 배치)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PhotoPreview(url: photoUrl, size: photoSize),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: photoSize,
                              child: Center(
                                child: _TwoLineText(
                                  text: personalityPrompt,
                                  style: const TextStyle(
                                    // ▼ 색상을 배경(#A8A090)에 어울리는 웜 아이보리로 톤업 + 은은한 그림자
                                    color: Color(0xFFEDE3C8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 0.5),
                                        blurRadius: 0.5,
                                        color: Colors.black26,
                                      ),
                                    ],
                                  ),
                                  gap: 6,
                                  withDoubleQuotes: true, // "…" 사이로 표시
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // ✅ 박스 하단에 약간의 여백
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ───────── 2) 고인에게 듣고싶은 말 + 영상 바로가기 ─────────
            _RoundBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuotedGradientText(
                    "고인에게 '듣고싶은 말로 영상'을 제작해 보세요.",
                    baseStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _GhostButton(
                      label: '영상 화면 바로가기',
                      onPressed: () => context.go('/video'), // ✅ GoRouter로 연결
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ───────── 3) 고인과 자유롭게 대화 + 대화 화면 바로가기 ─────────
            _RoundBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuotedGradientText(
                    "고인과 '자유롭게 대화'해보세요.",
                    baseStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _GhostButton(
                      label: '대화 화면 바로가기',
                      onPressed: () => context.go('/chat'), // ✅ GoRouter로 연결
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 하단 네비게이션
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        showUnselectedLabels: true,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white70,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedIconTheme: const IconThemeData(size: 22),
        unselectedIconTheme: const IconThemeData(size: 22),
        currentIndex: 0,
        onTap: (index) {
          // ✅ GoRouter로 탭 전환
          switch (index) {
            case 0:
              context.go('/');        // 홈
              break;
            case 1:
              context.go('/video');   // 영상
              break;
            case 2:
              context.go('/chat');    // 대화
              break;
            case 3:
              context.go('/settings'); // 설정
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: '영상'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: '대화'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
        ],
      ),
    );
  }
}

/// 라운드 박스(배경: #A8A090)
class _RoundBox extends StatelessWidget {
  final Widget child;
  const _RoundBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA8A090),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// 사진 미리보기
class _PhotoPreview extends StatelessWidget {
  final String url;
  final double size;
  const _PhotoPreview({required this.url, this.size = 100});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: hasUrl
          ? Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
    width: size,
    height: size,
    color: Colors.black.withOpacity(0.25),
    alignment: Alignment.center,
    child: const Icon(Icons.person, color: Colors.white70, size: 28),
  );
}

/// 인용문 텍스트를 2줄로 분리하여
/// 첫 줄은 좌측 정렬, 두 번째 줄은 우측 정렬로 그려줌.
/// withDoubleQuotes=true면 첫 줄 앞에 “, 두 번째 줄 뒤에 ” 를 붙여 렌더링.
class _TwoLineText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double gap;
  final bool withDoubleQuotes;

  const _TwoLineText({
    required this.text,
    required this.style,
    this.gap = 6,
    this.withDoubleQuotes = false,
  });

  @override
  Widget build(BuildContext context) {
    final (l1raw, l2raw) = _splitTwoLines(text);
    final l1 = withDoubleQuotes ? '“$l1raw' : l1raw;
    final l2 = withDoubleQuotes ? '$l2raw”' : l2raw;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l1,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: gap),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l2,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (String, String) _splitTwoLines(String s) {
    final plain = s.trim().replaceAll(RegExp(r'^[“"]|[”"]$'), '');
    if (plain.length <= 12) return (plain, '');
    final mid = (plain.length / 2).round();
    final idx = [
      plain.indexOf(' ', mid),
      plain.indexOf(',', mid),
      plain.indexOf('.', mid),
    ]
        .where((i) => i != -1)
        .fold<int>(-1, (p, n) => (p == -1 || (n < p && n != -1)) ? n : p);
    if (idx != -1) {
      return (plain.substring(0, idx).trim(), plain.substring(idx + 1).trim());
    }
    return (plain.substring(0, mid).trim(), plain.substring(mid).trim());
  }
}

/// 문장 안에서 '따옴표로 감싼 부분만' 그라데이션 처리
class _QuotedGradientText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Gradient gradient;

  const _QuotedGradientText(
      this.text, {
        required this.baseStyle,
        this.gradient = const LinearGradient(
          colors: [Color(0xFFFFE08A), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r"'([^']+)'");
    int cursor = 0;

    for (final m in regex.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, m.start), style: baseStyle));
      }
      final quoted = m.group(1)!;
      spans.add(TextSpan(
        text: quoted,
        style: baseStyle.copyWith(
          foreground: Paint()..shader = gradient.createShader(const Rect.fromLTWH(0, 0, 600, 40)),
          fontWeight: FontWeight.w700,
        ),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

/// 버튼: 검정 배경 + 글씨는 박스 배경색(#A8A090)
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GhostButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        backgroundColor: Colors.black,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
