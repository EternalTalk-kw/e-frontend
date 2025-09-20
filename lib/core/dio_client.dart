// lib/core/dio_client.dart
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'secure_storage.dart';

class DioClient {
  DioClient._();
  static final DioClient I = DioClient._();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  )..interceptors.add(_buildAuthInterceptor());

  /// ✅ 로그인/로그아웃 등 토큰 변화가 생겼을 때 인터셉터를 재설정
  Future<void> refreshAuthInterceptor() async {
    // 다른 인터셉터를 쓰고 있다면 개별적으로 관리해도 됨.
    dio.interceptors.clear();
    dio.interceptors.add(_buildAuthInterceptor());
  }

  static InterceptorsWrapper _buildAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AppSecureStorage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          await AppSecureStorage.clear();
          // TODO: 필요 시 전역 라우팅으로 로그인 화면 이동 트리거
        }
        handler.next(e);
      },
    );
  }
}
