import 'package:dio/dio.dart';
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class VoiceRepository {
  final _dio = DioClient.I.dio;

  Future<ApiResult<String>> generateTts(String text) async {
    try {
      final res = await _dio.post('/api/voice/generate', data: {'text': text});
      final url = res.data['url'] as String?;
      if (url == null) return const ApiFailure('URL 없음');
      return ApiSuccess(url);
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '생성 실패');
    }
  }
}
