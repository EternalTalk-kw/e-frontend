// lib/features/video/video_repository.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart'; // XFile
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class VideoRepository {
  final _dio = DioClient.I.dio;

  /// 모바일/데스크톱: 파일 경로 업로드
  Future<ApiResult<String>> uploadPhoto(String filePath) async {
    try {
      if (kIsWeb) {
        return const ApiFailure(
          '웹에서는 uploadPhoto(String) 대신 uploadPhotoWeb(XFile)을 사용하세요.',
        );
      }
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post(
        '/api/video/upload-photo',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
      final url = res.data['url'] as String?;
      return url != null ? ApiSuccess(url) : const ApiFailure('사진 URL 없음');
    } on DioException catch (e) {
      return ApiFailure(e.response?.data?['message']?.toString() ?? '업로드 실패');
    }
  }

  /// ✅ 웹: XFile → bytes 업로드 (dart:io 사용 안 함)
  Future<ApiResult<String>> uploadPhotoWeb(XFile xfile) async {
    try {
      final Uint8List bytes = await xfile.readAsBytes();
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: xfile.name, // 서버에서 원본 파일명 필요할 수 있음
        ),
      });
      final res = await _dio.post(
        '/api/video/upload-photo',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
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

final videoRepository = VideoRepository();
