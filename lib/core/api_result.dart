// lib/core/api_result.dart
sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? code;
  const ApiFailure(this.message, {this.code});

  /// 서버 에러 응답이 다양한 키/타입으로 와도 안전하게 변환
  factory ApiFailure.fromJson(Object? data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data as Map);
      final msg = _asString(
        map['message'] ??
            map['error'] ??
            map['detail'] ??
            map['errorMessage'] ??
            map['errors'] ??
            'Unknown error',
      );
      final cd = _asIntOrNull(
        map['code'] ?? map['status'] ?? map['errorCode'],
      );
      return ApiFailure(msg, code: cd);
    }
    return ApiFailure(_asString(data));
  }
}

// ---------- helpers ----------
String _asString(dynamic v) {
  if (v == null) return 'Unknown error';
  if (v is String) return v;
  return v.toString();
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
