// lib/features/video/video_repository.dart
import 'package:dio/dio.dart';
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class VideoRepository {
  final _dio = DioClient.I.dio;

  Future<ApiResult<String>> uploadPhoto(String filePath) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(
        '/api/video/upload-photo',
        data: form,
        options: Options(contentType: 'multipart/form-data'), // ✅ 멀티파트 명시
      );
      final url = res.data['url'] as String?;
      return url != null ? ApiSuccess(url) : const ApiFailure('사진 URL 없음');
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '업로드 실패');
    }
  }

  Future<ApiResult<String>> generate(String photoUrl, String audioUrl) async {
    try {
      final res = await _dio.post('/api/video/generate', data: {
        'photoUrl': photoUrl,
        'audioUrl': audioUrl,
      });
      final jobId = res.data['jobId'] as String?;
      return jobId != null ? ApiSuccess(jobId) : const ApiFailure('jobId 없음');
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '생성 실패');
    }
  }

  Future<ApiResult<Map<String, dynamic>>> status(String jobId) async {
    try {
      final res = await _dio.get('/api/video/status/$jobId');
      return ApiSuccess(Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '상태 조회 실패');
    }
  }
}
