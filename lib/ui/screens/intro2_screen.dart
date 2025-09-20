// lib/screens/intro/intro2_screen.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/api_result.dart';
import '../../features/chat/chat_repository.dart';   // upsertProfile 사용
import '../../features/memory/memory_repository.dart';
import '../../features/video/video_repository.dart';
import '../../features/voice/voice_repository.dart';

class Intro2Screen extends StatefulWidget {
  const Intro2Screen({super.key});

  @override
  State<Intro2Screen> createState() => _Intro2ScreenState();
}

class _Intro2ScreenState extends State<Intro2Screen> with TickerProviderStateMixin {
  int _step = 0; // 0~6
  bool _consented = false;

  final _displayName = TextEditingController();
  final _personality = TextEditingController();
  String? _photoUrl;
  String? _voiceId; // 업로드/발급된 voice_id

  bool _loading = false;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  Future<void> _checkExistingProfile() async {
    final res = await memoryRepository.hasProfile();
    if (res is ApiSuccess<bool> && res.data == true && mounted) {
      context.go('/'); // 이미 프로필 있음 → 홈
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _personality.dispose();
    _fade.dispose();
    super.dispose();
  }

  // 텍스트: 따옴표 안쪽만 그라데이션
  Widget _quotedGradientText(String text) {
    final m = RegExp(r"'([^']+)'").firstMatch(text);
    if (m == null) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
      );
    }
    final before = text.substring(0, m.start);
    final quoted = m.group(1)!;
    final after = text.substring(m.end);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.5),
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF8CB5D1), Color(0xFFE09A76)],
              ).createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
              blendMode: BlendMode.srcIn,
              child: Text(
                quoted,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  String _messageForStep(int i) {
    switch (i) {
      case 0: return "유족 데이터를 앱 내에서만 사용하는데에 동의하시나요?";
      case 1: return "그럼 프로필 등록을 시작하겠습니다!";
      case 2: return "“고인을 뭐라고 부르셨었나요?”";
      case 3: return "“고인의 사진을 등록해주세요”";
      case 4: return "“고인의 음성 샘플을 업로드해주세요”";
      case 5: return "“고인의 성격은 어떠셨었나요?”";
      case 6: return "수고하셨습니다! 이제 메인화면에서 이용하고 싶은 기능을 이용해주세요!";
      default: return "";
    }
  }

  Future<void> _next() async {
    if (_loading) return;

    switch (_step) {
      case 0:
        if (!_consented) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('동의하셔야 진행할 수 있어요.')));
          return;
        }
        setState(() => _step++);
        break;

      case 1:
        setState(() => _step++);
        break;

      case 2:
        if (_displayName.text.trim().isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('고인의 호칭을 입력해주세요.')));
          return;
        }
        setState(() => _step++);
        break;

      case 3: // 사진 업로드
        await _pickPhotoAndUpload();
        if (_photoUrl != null) setState(() => _step++);
        break;

      case 4: // 음성 샘플 업로드 -> voice_id 발급
        await _pickVoiceAndUpload();
        if (_voiceId != null) setState(() => _step++);
        break;

      case 5: // 성격 입력 + 저장
        if (_personality.text.trim().isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('성격을 한 줄이라도 적어주세요.')));
          return;
        }
        setState(() => _loading = true);
        final saveRes = await chatRepository.upsertProfile(
          displayName: _displayName.text.trim(),
          personalityPrompt: _personality.text.trim(),
          // 필요 시 서버 스펙에 맞춰 아래도 전달하도록 확장
          // photoUrl: _photoUrl,
          // voiceId: _voiceId,
        );
        setState(() => _loading = false);
        if (saveRes is ApiFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('저장 실패: ${saveRes.message}')));
          return;
        }
        setState(() => _step++);
        break;

      case 6:
        if (mounted) context.go('/'); // 끝 → 홈
        break;
    }
  }

  // ✅ 사진 업로드: 웹/모바일 분기
  Future<void> _pickPhotoAndUpload() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (x == null) return;

      setState(() => _loading = true);
      final ApiResult<String> res = kIsWeb
          ? await videoRepository.uploadPhotoWeb(x)   // 웹: 바이트 업로드
          : await videoRepository.uploadPhoto(x.path); // 모바일/데스크톱: 경로 업로드
      setState(() => _loading = false);

      if (res is ApiFailure<String>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 업로드 실패: ${res.message}')),
        );
      } else if (res is ApiSuccess<String>) {
        _photoUrl = res.data;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진 업로드 완료')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  // ✅ 음성 샘플 업로드: 웹/모바일 분기
  Future<void> _pickVoiceAndUpload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['wav', 'mp3', 'm4a'],
        withData: kIsWeb, // 웹에서 bytes 필요
      );
      final pf = picked?.files.single;
      if (pf == null) return;

      setState(() => _loading = true);
      final ApiResult<String> res = kIsWeb
          ? await voiceRepository.uploadSampleWeb(pf)     // 웹: 바이트 업로드
          : await voiceRepository.uploadSample(pf.path!); // 모바일/데스크톱: 경로 업로드
      setState(() => _loading = false);

      if (res is ApiFailure<String>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('음성 업로드 실패: ${res.message}')),
        );
      } else if (res is ApiSuccess<String>) {
        _voiceId = res.data;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('음성 샘플 업로드 완료')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }

  // ==================== 미리보기 위젯 (추가) ====================
  Widget _photoPreview() {
    if (_photoUrl == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1, // 정사각 썸네일
        child: Image.network(
          _photoUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (c, w, p) =>
          p == null ? w : const Center(child: CircularProgressIndicator()),
          errorBuilder: (c, e, s) => Container(
            color: Colors.white10,
            alignment: Alignment.center,
            child: const Text('이미지 불러오기 실패', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ),
    );
  }
  // ===========================================================

  Widget _content() {
    final isLast = _step == 6;

    return Column(
      children: [
        const Spacer(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
          child: Container(
            key: ValueKey(_step),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _quotedGradientText(_messageForStep(_step)),
          ),
        ),
        const SizedBox(height: 24),

        if (_step == 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Checkbox(
                value: _consented,
                onChanged: (v) => setState(() => _consented = v ?? false),
                fillColor: MaterialStateProperty.resolveWith(
                      (s) => s.contains(MaterialState.selected)
                      ? const Color(0xFFBFA9FF)
                      : Colors.white24,
                ),
                checkColor: Colors.black,
              ),
              const Text('동의합니다', style: TextStyle(color: Colors.white)),
            ],
          ),

        if (_step == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _displayName,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: '예: 할머니, 아버지, 선생님…',
                hintStyle: TextStyle(color: Colors.white38),
                border: UnderlineInputBorder(),
              ),
            ),
          ),

        // ====== 변경된 step 3 UI (미리보기 표시) ======
        if (_step == 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_photoUrl != null) ...[
                  _photoPreview(),
                  const SizedBox(height: 12),
                  const Text('사진 업로드 완료', style: TextStyle(color: Colors.white70)),
                ] else ...[
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white10,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '사진을 업로드하면 여기 미리보기가 표시돼요',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: _loading ? null : _pickPhotoAndUpload,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: Text(_photoUrl == null ? '사진 선택 및 업로드' : '사진 교체하기'),
                ),
              ],
            ),
          ),
        // ============================================

        if (_step == 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                if (_voiceId != null)
                  Text(
                    'voice_id: $_voiceId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _loading ? null : _pickVoiceAndUpload,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                  ),
                  child: const Text('음성 샘플 선택 및 업로드'),
                ),
              ],
            ),
          ),

        if (_step == 5)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _personality,
              minLines: 3,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '예: 조용하지만 따뜻하고, 아침 산책을 좋아하셨어요…',
                hintStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
            ),
          ),

        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBFA9FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isLast ? '메인으로' : '다음'),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: _content()),
    );
  }
}
