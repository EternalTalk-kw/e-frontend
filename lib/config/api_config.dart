// lib/constants/api_config.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // flutter run ... --dart-define=API_BASE_URL=http://<host>:<port>
  static const String _env =
  String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_env.isNotEmpty) return _env;

    // ✅ dart-define이 없을 때의 안전한 기본값
    // - Web(Chrome): 백엔드가 같은 머신에서 도는 경우 localhost 사용
    // - Android 에뮬레이터: 10.0.2.2 로 호스트 PC의 localhost 접근
    return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
  }
}
