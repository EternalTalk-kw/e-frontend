import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/dio_client.dart'; // 경로는 프로젝트 구조에 맞춰 조정

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final _dio = DioClient.I.dio;

  // 프로필 데이터
  String? photoUrl;
  String? voiceId;

  // 입력/상태
  final TextEditingController _textCtl = TextEditingController();
  bool makingVoice = false;
  bool makingVideo = false;

  String? audioUrl; // 음성 제작 결과 mp3 URL
  String? jobId;    // 영상 제작 jobId
  String? videoUrl; // 최종 영상 URL

  Timer? _poller;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // photoUrl / voiceId 로드
  }

  @override
  void dispose() {
    _poller?.cancel();
    _textCtl.dispose();
    super.dispose();
  }

  // ---- API ----

  Future<void> _loadProfile() async {
    // 백엔드: /api/memory/profile GET (있다고 가정)
    try {
      final res = await _dio.get('/api/memory/profile');
      final data = (res.data is Map) ? res.data as Map : {};
      // 백엔드 DTO 명칭이 다르면 아래 키를 맞춰줘
      setState(() {
        photoUrl = data['photoUrl'] ?? data['photo_url'];
        voiceId  = data['voiceCloneId'] ?? data['voice_id'] ?? data['voiceCloneID'];
      });
    } catch (e) {
      // 없으면 설정/업로드 유도
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필을 불러오지 못했습니다. 설정에서 사진/보이스를 등록해 주세요.')),
      );
    }
  }

  Future<void> _makeVoice() async {
    final text = _textCtl.text.trim();
    if (!_isValidKoreanUnderLimit(text, 15)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('텍스트는 한글 기준 공백/이모지 제외 15자 이내여야 합니다.')),
      );
      return;
    }
    if (voiceId == null || voiceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('보이스 ID가 없습니다. 샘플 업로드로 보이스를 먼저 생성해 주세요.')),
      );
      return;
    }

    setState(() { makingVoice = true; audioUrl = null; videoUrl = null; jobId = null; });

    try {
      final res = await _dio.post('/api/voice/generate', data: {'text': text});
      // 백엔드가 String을 그대로 주든 {url: "..."}을 주든 대응
      final String url = switch (res.data) {
        String s => s,
        Map m => (m['audioUrl'] ?? m['url'] ?? m['audio_url'] ?? '').toString(),
        _ => ''
      };
      if (url.isEmpty) throw Exception('오디오 URL 없음');

      setState(() { audioUrl = url; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음성 제작 완료! 아래에서 영상 제작을 진행하세요.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('음성 제작 실패: $e')),
      );
    } finally {
      setState(() { makingVoice = false; });
    }
  }

  Future<void> _makeVideo() async {
    if (audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 음성 제작을 완료해 주세요.')),
      );
      return;
    }
    if (photoUrl == null || photoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('등록된 사진이 없습니다. 설정에서 사진을 업로드해 주세요.')),
      );
      return;
    }

    setState(() { makingVideo = true; videoUrl = null; jobId = null; });
    _poller?.cancel();

    try {
      final res = await _dio.post('/api/video/generate-from-audio', data: {
        'audioUrl': audioUrl,
      });
      final data = (res.data is Map) ? res.data as Map : {};
      final id = (data['jobId'] ?? data['video_id'] ?? data['id'] ?? '').toString();
      if (id.isEmpty) throw Exception('jobId 없음');

      setState(() { jobId = id; });

      // 상태 폴링 시작
      _poller = Timer.periodic(const Duration(seconds: 2), (_) => _pollStatus());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('영상 제작 실패: $e')),
      );
      setState(() { makingVideo = false; });
    }
  }

  Future<void> _pollStatus() async {
    if (jobId == null) return;
    try {
      final res = await _dio.get('/api/video/status/$jobId');
      final data = (res.data is Map) ? res.data as Map : {};
      final status = (data['status'] ?? '').toString().toUpperCase();
      final url    = (data['videoUrl'] ?? data['url'] ?? data['video_url'] ?? '').toString();

      if (status == 'DONE' || status == 'COMPLETED' || status == 'SUCCESS') {
        _poller?.cancel();
        setState(() { makingVideo = false; videoUrl = url.isNotEmpty ? url : null; });
        if (videoUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('완료되었지만 영상 URL이 비어 있습니다. 잠시 후 다시 시도해 주세요.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('영상 제작 완료! 재생 버튼으로 확인하세요.')),
          );
        }
      } else if (status == 'ERROR' || status == 'FAILED') {
        _poller?.cancel();
        setState(() { makingVideo = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('영상 제작 실패 (status: $status)')),
        );
      } else {
        // PROCESSING
      }
    } catch (e) {
      // 폴링 중 오류는 잠깐 넘어가고 다음 루프에서 재시도
    }
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단: 사진(좌) + 보이스ID(우)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _avatar(photoUrl),
                      const SizedBox(width: 16),
                      Expanded(child: _voiceIdBox(voiceId)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 텍스트 입력 (15자)
                  _textField15(),

                  const SizedBox(height: 12),

                  // 음성 제작 버튼
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: makingVoice ? null : _makeVoice,
                      icon: makingVoice
                          ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.graphic_eq_rounded),
                      label: Text(makingVoice ? '음성 제작중...' : '음성 제작'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  if (audioUrl != null) ...[
                    const SizedBox(height: 8),
                    _monoLine('생성된 MP3: $audioUrl'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 영상 제작 카드
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '사진 + 방금 만든 음성으로 토킹헤드 영상 제작',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text('※ 음성 제작을 먼저 완료한 뒤 눌러주세요.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (audioUrl != null && !makingVideo) ? _makeVideo : null,
                      icon: makingVideo
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.movie_creation_rounded),
                      label: Text(makingVideo ? '영상 제작중...' : '영상 제작'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (jobId != null && videoUrl == null) ...[
                    _monoLine('상태: 생성중 (jobId: $jobId)'),
                  ],

                  if (videoUrl != null) ...[
                    _monoLine('완료!'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () => _openUrl(videoUrl!),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: const Text('영상 재생'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.amberAccent,
                          side: const BorderSide(color: Colors.amberAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _monoLine(videoUrl!),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      titleSpacing: 8,
      title: Row(
        children: [
          const SizedBox(width: 4),
          Image.asset('assets/images/logo_text.png', height: 55),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
        border: Border.fromBorderSide(BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: child,
    );
  }

  Widget _avatar(String? url) {
    final placeholder = Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white54, size: 40),
    );

    if (url == null || url.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url, width: 100, height: 100, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }

  Widget _voiceIdBox(String? id) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('보이스 ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  id?.isNotEmpty == true ? id! : '미등록',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                onPressed: (id == null || id!.isEmpty)
                    ? null
                    : () {
                  Clipboard.setData(ClipboardData(text: id!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복사됨')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 18),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField15() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('메시지 (한글 15자 이내)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: _textCtl,
          maxLength: 30, // 물리적 입력 제한은 넉넉히, 아래 validator로 안내
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '예: 사랑해요, 잘 지내요',
            hintStyle: const TextStyle(color: Colors.white38),
            counterText: '',
            filled: true,
            fillColor: const Color(0xFF1E1E1E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.amberAccent),
            ),
          ),
          onChanged: (s) {
            final ok = _isValidKoreanUnderLimit(s, 15);
            setState(() {}); // 아래 카운터 다시 그림
            if (!ok && s.isNotEmpty) {
              // 과하면 살짝 알려주기
            }
          },
        ),
        const SizedBox(height: 4),
        Text(
          '현재: ${_koreanCount(_textCtl.text)}자 / 15자',
          style: TextStyle(
            color: _isValidKoreanUnderLimit(_textCtl.text, 15) ? Colors.white54 : Colors.redAccent,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  BottomNavigationBar _bottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      showUnselectedLabels: true,
      selectedItemColor: Colors.amberAccent,
      unselectedItemColor: Colors.white70,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      selectedIconTheme: const IconThemeData(size: 22),
      unselectedIconTheme: const IconThemeData(size: 22),
      currentIndex: 1,
      onTap: (index) {
        switch (index) {
          case 0: context.go('/'); break;
          case 1: context.go('/video'); break;
          case 2: context.go('/chat'); break;
          case 3: context.go('/settings'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '홈'),
        BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: '영상'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: '대화'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: '설정'),
      ],
    );
  }

  // ---- helpers: 한글 15자 검증 (공백/이모지 제외) ----

  bool _isValidKoreanUnderLimit(String? input, int limit) {
    if (input == null) return false;
    int count = 0;
    for (final rune in input.runes) {
      final cp = rune;
      if (_isWhitespace(cp)) continue;
      if (_isEmoji(cp)) continue;
      if (_isHangul(cp)) {
        count++;
        if (count > limit) return false;
      }
    }
    return count >= 1 && count <= limit;
  }

  int _koreanCount(String? input) {
    if (input == null) return 0;
    int count = 0;
    for (final cp in input.runes) {
      if (_isWhitespace(cp) || _isEmoji(cp)) continue;
      if (_isHangul(cp)) count++;
    }
    return count;
  }

  bool _isHangul(int cp) {
    return (cp >= 0xAC00 && cp <= 0xD7A3) // HANGUL_SYLLABLES
        || (cp >= 0x1100 && cp <= 0x11FF) // HANGUL_JAMO
        || (cp >= 0x3130 && cp <= 0x318F) // HANGUL_COMPATIBILITY_JAMO
        || (cp >= 0xA960 && cp <= 0xA97F) // HANGUL_JAMO_EXT_A
        || (cp >= 0xD7B0 && cp <= 0xD7FF); // HANGUL_JAMO_EXT_B
  }

  bool _isWhitespace(int cp) => String.fromCharCode(cp).trim().isEmpty;

  bool _isEmoji(int cp) =>
      (cp >= 0x1F300 && cp <= 0x1FAFF) ||
          (cp >= 0x2600 && cp <= 0x27BF) ||
          (cp >= 0xFE00 && cp <= 0xFE0F) ||
          (cp >= 0x1F1E6 && cp <= 0x1F1FF);

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL을 열 수 없습니다.')),
      );
    }
  }

  Widget _monoLine(String text) {
    return SelectableText(
      text,
      style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
    );
  }
}
