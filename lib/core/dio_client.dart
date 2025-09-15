import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'secure_storage.dart';

class DioClient {
  DioClient._();
  static final DioClient I = DioClient._();

  late final Dio dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    contentType: 'application/json',
  ))
    ..interceptors.add(InterceptorsWrapper(
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
          // TODO: 라우팅으로 로그인 화면 이동 트리거 (필요시)
        }
        handler.next(e);
      },
    ));
}
