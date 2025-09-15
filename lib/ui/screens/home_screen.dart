// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../../features/voice/voice_repository.dart';
import '../../features/video/video_repository.dart';
import '../../features/chat/chat_repository.dart';
import '../../core/api_result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final voiceRepo = VoiceRepository();
  final videoRepo = VideoRepository();
  final chatRepo = ChatRepository();

  final _ttsCtrl = TextEditingController(text: '짧은 문장으로 테스트');
  String? _mp3Url, _videoUrl, _status;
  String? _reply;

  Future<void> _generateTts() async {
    final r = await voiceRepo.generateTts(_ttsCtrl.text);
    setState(() {
      if (r is ApiSuccess<String>) {
        _mp3Url = r.data;
      } else {
        _mp3Url = (r as ApiFailure).message;
      }
    });
  }

  Future<void> _generateVideo() async {
    const photoUrl = 'https://example.com/photo.jpg';
    final audioUrl = _mp3Url;
    if (audioUrl == null) return;
    final r = await videoRepo.generate(photoUrl, audioUrl);
    if (r is ApiSuccess<String>) {
      final jobId = r.data;
      setState(() => _status = 'PENDING ($jobId)');
      final s = await videoRepo.status(jobId);
      if (s is ApiSuccess<Map<String, dynamic>>) {
        setState(() {
          _status = s.data['status'];
          _videoUrl = s.data['url'];
        });
      }
    } else {
      setState(() => _status = (r as ApiFailure).message);
    }
  }

  Future<void> _sendChat() async {
    final r = await chatRepo.send('안녕?');
    setState(() {
      if (r is ApiSuccess<Map<String, dynamic>>) {
        _reply = r.data['reply'];
      } else {
        _reply = (r as ApiFailure).message;
      }
    });
  }

  @override
  void dispose() {
    // ✅ 컨트롤러 해제
    _ttsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EternalTalk')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _ttsCtrl,
            decoration: const InputDecoration(labelText: 'TTS 텍스트(짧게)'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _generateTts, child: const Text('음성 생성')),
          if (_mp3Url != null) SelectableText('mp3: $_mp3Url'),
          const Divider(),
          FilledButton(
            onPressed: _generateVideo,
            child: const Text('영상 생성 (샘플 photoUrl 사용)'),
          ),
          if (_status != null) Text('상태: $_status'),
          if (_videoUrl != null) SelectableText('video: $_videoUrl'),
          const Divider(),
          FilledButton(onPressed: _sendChat, child: const Text('챗봇 예시 전송')),
          if (_reply != null) Text('reply: $_reply'),
        ],
      ),
    );
  }
}
