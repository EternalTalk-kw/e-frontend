// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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

      // ───────────────── Body: 라운드 박스 2개 ─────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionCard([
              _buildSettingItem(Icons.language, '언어'),
              _buildSettingItem(Icons.dark_mode, '다크 모드'),
              _buildSettingItem(Icons.interests, '관심 키워드 설정'),
              _buildSettingItem(Icons.notifications, '알림 설정'),
              _buildSettingItem(Icons.delete_sweep, '캐시 삭제'),
            ]),

            const SizedBox(height: 16),

            _buildSectionCard([
              _buildSettingItem(Icons.privacy_tip, '약관 및 개인정보 처리 동의', () {
                _showDialog(context, '약관 및 개인정보 처리 동의', '''
앱을 이용함으로써 사용자님은 본 서비스의 이용약관 및 개인정보 수집·이용에 동의하게 됩니다. 수집된 정보는 더 나은 서비스 제공을 위해 활용됩니다. 
자세한 사항은 고객센터 또는 홈페이지를 참고해주세요.
''');
              }),
              _buildSettingItem(Icons.shield, '개인정보 처리방침', () {
                _showDialog(context, '개인정보 처리방침', '''
우리는 사용자 개인정보를 소중히 보호하며, 수집한 정보는 오직 서비스 제공 목적에 한해서만 사용됩니다. 
본 방침은 관련 법령에 따라 변경될 수 있으며, 최신 내용은 앱 내에서 확인 가능합니다.
''');
              }),
            ]),
          ],
        ),
      ),

      // ───────────────── Bottom Navigation (그대로) ─────────────────
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
        currentIndex: 3, // ✅ 현재 탭 = 설정
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

  // ───────────────── Helpers ─────────────────

  // 라운드 박스 컨테이너
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFA8A090),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.white24, // 밝은 그림자
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, thickness: 1, color: Colors.black26),
          ],
        ],
      ),
    );
  }

  // 개별 설정 아이템 (리플 포함)
  Widget _buildSettingItem(IconData icon, String title, [VoidCallback? onTap]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  // 다이얼로그
  static void _showDialog(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          body,
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
