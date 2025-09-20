sealed class ApiResult<T> {
  const ApiResult();
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? code;   // ✅ 선택적으로 상태 코드 보관 가능
  const ApiFailure(this.message, {this.code});

  // ✅ JSON에서 생성할 때 타입을 안전하게 변환
  factory ApiFailure.fromJson(Map<String, dynamic> json) {
    return ApiFailure(
      _asString(json['message']),
      code: _asIntOrNull(json['code']),
    );
  }
}

// ---------- helpers ----------
String _asString(dynamic v) {
  if (v == null) return 'Unknown error';
  if (v is String) return v;
  return v.toString(); // int, bool, map 등도 문자열화
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is String) return int.tryParse(v);
  return null;
}
