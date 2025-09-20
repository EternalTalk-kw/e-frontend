// lib/features/voice/voice_repository.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart'; // PlatformFile
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class VoiceRepository {
  final _dio = DioClient.I.dio;

  Future<ApiResult<String>> uploadSample(String filePath) async {
    try {
      if (kIsWeb) {
        return const ApiFailure('웹에서는 uploadSampleWeb(PlatformFile)을 사용하세요.');
      }
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(
        '/api/voice/upload-sample',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final voiceId = res.data['voiceId'] as String?;
      return voiceId != null ? ApiSuccess(voiceId) : const ApiFailure('voiceId 없음');
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '샘플 업로드 실패');
    }
  }

  /// ✅ 웹: 바이트 업로드
  Future<ApiResult<String>> uploadSampleWeb(PlatformFile pf) async {
    try {
      final Uint8List? bytes = pf.bytes;
      if (bytes == null) return const ApiFailure('파일 바이트가 없습니다');
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: pf.name),
      });
      final res = await _dio.post(
        '/api/voice/upload-sample',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final voiceId = res.data['voiceId'] as String?;
      return voiceId != null ? ApiSuccess(voiceId) : const ApiFailure('voiceId 없음');
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '샘플 업로드 실패');
    }
  }

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

final voiceRepository = VoiceRepository();
