import 'package:dio/dio.dart';
import '../../../core/dio_client.dart';
import '../../../core/api_result.dart';

class MemoryRepository {
  final Dio _dio = DioClient.I.dio;

  Future<ApiResult<bool>> hasProfile() async {
    try {
      final res = await _dio.get('/api/memory/profile');
      return ApiSuccess(res.data != null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const ApiSuccess(false);
      return ApiFailure(e.response?.data?['message']?.toString() ?? '프로필 조회 실패');
    }
  }
}

final memoryRepository = MemoryRepository();
