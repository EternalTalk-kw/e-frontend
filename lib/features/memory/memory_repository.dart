// lib/features/memory/memory_repository.dart
import 'package:dio/dio.dart';
import '../../core/dio_client.dart';
import '../../core/api_result.dart';

class MemoryRepository {
  final Dio _dio = DioClient.I.dio;

  /// 프로필 존재 여부만 확인 (200이면 true, 404면 false)
  Future<ApiResult<bool>> hasProfile() async {
    try {
      final res = await _dio.get('/api/memory/profile');
      // 데이터가 비어 있어도 200이면 존재한다고 판단
      return const ApiSuccess(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const ApiSuccess(false);
      return ApiFailure(e.response?.data?['message']?.toString() ?? '프로필 조회 실패');
    } catch (e) {
      return ApiFailure('프로필 조회 실패: $e');
    }
  }

  /// 실제 프로필 데이터 가져오기
  /// 백엔드가 내려주는 JSON 그대로 Map으로 감쌉니다.
  /// 예: { "displayName": "...", "personalityPrompt": "...", "photoUrl": "..." }
  Future<ApiResult<Map<String, dynamic>>> getProfile() async {
    try {
      final res = await _dio.get('/api/memory/profile');
      final data = res.data is Map<String, dynamic>
          ? (res.data as Map<String, dynamic>)
          : <String, dynamic>{};
      return ApiSuccess(data);
    } on DioException catch (e) {
      // 404면 없는 것이므로 호출 측에서 온보딩으로 분기
      if (e.response?.statusCode == 404) {
        return const ApiFailure('프로필이 없습니다', code: 404);
      }
      return ApiFailure(e.response?.data?['message']?.toString() ?? '프로필 불러오기 실패');
    } catch (e) {
      return ApiFailure('프로필 불러오기 실패: $e');
    }
  }
}

final memoryRepository = MemoryRepository();