import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

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
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFA8A090),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              '공사중..',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),

      // 하단 네비게이션 바
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
        currentIndex: 1, // ✅ 현재 탭 = 영상
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
