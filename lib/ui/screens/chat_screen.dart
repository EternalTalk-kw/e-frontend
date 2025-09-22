import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../features/chat/chat_repository.dart';
import '../../core/api_result.dart';
import '../../core/dio_client.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  // 남은 글자 (서버 기준)
  int _remaining = 0;

  // 프로필(고인) 정보
  String _displayName = '기억 친구';
  String? _photoUrl; // null이면 로컬 로고로 폴백

  // 간단한 메시지 메모리 (필요 시 서버 저장 구조로 확장 가능)
  final List<_Message> _messages = <_Message>[
    _Message(
      role: _Role.bot,
      text: "안녕하세요. 편하게 이야기해요. 기억하고 싶은 이야기, 전하고 싶은 말이 있다면 들려주세요.",
      ts: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadQuota();
    _loadProfile(); // ✅ 고인 프로필 로드
  }

  Future<void> _loadProfile() async {
    try {
      final dio = DioClient.I.dio;
      // 기대 응답: { displayName, photoUrl? }
      final res = await dio.get('/api/memory/profile');
      if (!mounted) return;

      final data = Map<String, dynamic>.from(res.data ?? {});
      final name = (data['displayName'] as String?)?.trim();
      final photo = (data['photoUrl'] as String?)?.trim();

      setState(() {
        if (name != null && name.isNotEmpty) {
          _displayName = name;
        }
        // photoUrl이 http/https로 오면 네트워크 이미지, 비어있으면 폴백
        if (photo != null && photo.isNotEmpty) {
          _photoUrl = photo;
        } else {
          _photoUrl = null; // 폴백 사용
        }
      });
    } on DioException {
      // 프로필이 아직 없거나 오류인 경우, 기본값으로 조용히 진행
      if (!mounted) return;
      setState(() {
        _displayName = _displayName; // 그대로
        _photoUrl = null; // 폴백 사용
      });
    }
  }

  Future<void> _loadQuota() async {
    final result = await chatRepository.quota();
    if (!mounted) return;
    switch (result) {
      case ApiSuccess<int> s:
        setState(() {
          _remaining = s.data;
        });
      case ApiFailure<int> _:
        break;
    }
  }

  // 서버의 "입력 글자 수"는 공백 제외 코드포인트 기준이므로 클라이언트도 근사치 표시
  int _countForQuota(String text) {
    final noWs = text.replaceAll(RegExp(r'\s+'), '');
    return noWs.runes.length;
  }

  Future<void> _send() async {
    final text = _controller.text.trimRight();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_Message(role: _Role.user, text: text, ts: DateTime.now()));
    });
    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 50));
    _scrollToBottom();

    final result = await chatRepository.send(text);

    if (!mounted) return;
    switch (result) {
      case ApiSuccess<Map<String, dynamic>> s:
        final data = s.data;
        final reply = (data['reply'] as String?) ?? '';
        final remain = (data['remainingCharsToday'] as int?) ?? _remaining;

        setState(() {
          _messages.add(_Message(role: _Role.bot, text: reply, ts: DateTime.now()));
          _remaining = max(0, remain);
          _sending = false;
        });
        _scrollToBottom();

      case ApiFailure<Map<String, dynamic>> f:
        setState(() {
          _sending = false;
        });
        _showSnack(f.message);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 상단/하단 고정은 그대로 유지
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
        child: Column(
          children: [
            // 대화 목록
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final isUser = m.role == _Role.user;

                  if (isUser) {
                    // ✅ 사용자 버블: 기존 그대로
                    return Align(
                      alignment: Alignment.centerRight,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F1F),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                              bottomLeft: Radius.circular(14),
                              bottomRight: Radius.circular(4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                                color: Colors.black.withOpacity(0.6),
                              ),
                            ],
                          ),
                          child: Text(
                            m.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.42,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // ✅ 봇(고인) 메시지: 아바타 + 이름 라벨 + 말풍선
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Avatar(
                            size: 34,
                            photoUrl: _photoUrl,
                            fallbackAsset: 'assets/images/logo.png',
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // displayName 라벨
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                    child: Text(
                                      _displayName,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // 말풍선
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(14),
                                        topRight: Radius.circular(14),
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(14),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      m.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.42,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 입력 바
            _InputBar(
              controller: _controller,
              sending: _sending,
              remaining: _remaining,
              onSendPressed: _send,
              quotaCounter: _countForQuota,
            ),
          ],
        ),
      ),

      // 하단 네비게이션 바 (그대로)
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
        currentIndex: 2, // ✅ 현재 탭 = 대화
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/video');
              break;
            case 2:
              context.go('/chat');
              break;
            case 3:
              context.go('/settings');
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

enum _Role { user, bot }

class _Message {
  final _Role role;
  final String text;
  final DateTime ts;

  _Message({required this.role, required this.text, required this.ts});
}

class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.remaining,
    required this.onSendPressed,
    required this.quotaCounter,
  });

  final TextEditingController controller;
  final bool sending;
  final int remaining;
  final VoidCallback onSendPressed;
  final int Function(String) quotaCounter;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  late int _localCount;

  @override
  void initState() {
    super.initState();
    _localCount = widget.quotaCounter(widget.controller.text);
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _localCount = widget.quotaCounter(widget.controller.text);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.controller.text.trim().isNotEmpty && !widget.sending;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 입력창
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: widget.controller,
                      maxLines: 4,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요…',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '오늘 남은 입력: ${widget.remaining}자',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          '현재 입력: $_localCount자',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 전송 버튼
            SizedBox(
              height: 44,
              width: 44,
              child: ElevatedButton(
                onPressed: canSend ? widget.onSendPressed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSend ? Colors.amberAccent : const Color(0xFF2E2E2E),
                  foregroundColor: canSend ? Colors.black : Colors.white24,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: canSend ? 2 : 0,
                ),
                child: widget.sending
                    ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                    : const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 고인 프로필 아바타.
/// - photoUrl이 http/https면 네트워크 이미지
/// - null/빈값/오류 시 assets 폴백 사용
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.photoUrl,
    required this.fallbackAsset,
  });

  final double size;
  final String? photoUrl;
  final String fallbackAsset;

  bool get _isNetwork =>
      photoUrl != null &&
          photoUrl!.isNotEmpty &&
          (photoUrl!.startsWith('http://') || photoUrl!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final radius = size / 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: _isNetwork
            ? Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Image.asset(fallbackAsset, fit: BoxFit.cover),
        )
            : Image.asset(fallbackAsset, fit: BoxFit.cover),
      ),
    );
  }
}
