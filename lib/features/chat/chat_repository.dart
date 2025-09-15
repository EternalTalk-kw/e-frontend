import 'package:dio/dio.dart';
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class ChatRepository {
  final _dio = DioClient.I.dio;

  Future<ApiResult<void>> upsertProfile({
    required String displayName,
    required String personalityPrompt,
  }) async {
    try {
      await _dio.put('/api/memory/profile', data: {
        'displayName': displayName,
        'personalityPrompt': personalityPrompt,
      });
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '프로필 저장 실패');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> send(String text) async {
    try {
      final res = await _dio.post('/api/chat/send', data: {'text': text});
      return ApiSuccess(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '전송 실패');
    }
  }

  Future<ApiResult<int>> quota() async {
    try {
      final res = await _dio.get('/api/chat/quota');
      return ApiSuccess(res.data['remaining'] as int? ?? 0);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '쿼터 조회 실패');
    }
  }
}
