// lib/features/auth/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dio_client.dart';
import '../../core/secure_storage.dart';
import '../../core/api_result.dart';

class AuthRepository {
  final _dio = DioClient.I.dio;

  Future<ApiResult<void>> signup({
    required String email,
    required String nickname,
    required String password,
  }) async {
    try {
      await _dio.post('/api/auth/signup', data: {
        'email': email,
        'nickname': nickname,
        'password': password,
      });
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '회원가입 실패',
      );
    }
  }

  /// 디지털 유산 사용 동의서 제출
  Future<ApiResult<void>> submitConsent({required bool agreed}) async {
    try {
      await _dio.post('/api/users/consent', data: {
        'agreed': agreed,
      });
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '동의서 제출 실패',
      );
    }
  }

  Future<ApiResult<void>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token =
          res.data['token'] as String? ?? res.data['accessToken'] as String?;
      if (token == null) return const ApiFailure('토큰이 없습니다');
      await AppSecureStorage.saveAccessToken(token);
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '로그인 실패',
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> me() async {
    try {
      final res = await _dio.get('/api/users/me');
      return ApiSuccess(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '내 정보 조회 실패',
      );
    }
  }

  Future<void> logout() async => AppSecureStorage.clear();

  /// 구글 로그인 시작: 백엔드 OAuth2 엔드포인트 열기
  /// - Web: 현재 탭에서 진행(webOnlyWindowName: '_self')
  /// - 기타 플랫폼: 기본 동작(외부 앱/브라우저)
  Future<ApiResult<void>> startGoogleLogin() async {
    try {
      final base = _dio.options.baseUrl;
      if (base.isEmpty) {
        return const ApiFailure('baseUrl이 비어있습니다 (DioClient 설정 확인)');
      }

      final uri = Uri.parse('$base/oauth2/authorize/google');

      final ok = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        // Web에서만 적용: 현재 탭에서 열기. (비웹 플랫폼에서는 무시됨)
        webOnlyWindowName: '_self',
      );

      if (!ok) return const ApiFailure('구글 로그인 시작 실패');
      return const ApiSuccess(null);
    } catch (e) {
      return ApiFailure('구글 로그인 에러: $e');
    }
  }

  /// 구글 로그인 URL 반환
  Future<Uri> googleAuthorizeUri() async {
    final base = _dio.options.baseUrl;
    if (base.isEmpty) {
      throw Exception('baseUrl이 비어 있습니다. DioClient 설정 확인 필요');
    }
    return Uri.parse('$base/oauth2/authorize/google');
  }

  /// 프로필 수정
  Future<ApiResult<void>> updateProfile({
    required String nickname,
    String? avatarUrl,
  }) async {
    try {
      await _dio.put('/api/users/profile', data: {
        'nickname': nickname,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '프로필 수정 실패',
      );
    }
  }

  /// 계정 삭제
  Future<ApiResult<void>> deleteAccount() async {
    try {
      await _dio.delete('/api/users/delete');
      await AppSecureStorage.clear();
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(
        e.response?.data?['message']?.toString() ?? '계정 삭제 실패',
      );
    }
  }
}

final authRepository = AuthRepository();
