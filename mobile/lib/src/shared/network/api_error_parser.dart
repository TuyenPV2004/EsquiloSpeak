class ApiErrorParser {
  /// Extract error code from backend JSON response data.
  /// Priority: error.code (OpenAPI standard), fallback root code for legacy compatibility.
  static String? extractErrorCode(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    // Standard OpenAPI Envelope: { "error": { "code": "..." } }
    final errorObj = responseData['error'];
    if (errorObj is Map<String, dynamic> && errorObj['code'] is String) {
      return errorObj['code'] as String;
    }

    // Fallback legacy root level code: { "code": "..." }
    if (responseData['code'] is String) {
      return responseData['code'] as String;
    }

    return null;
  }

  /// Extract error message from backend JSON response data.
  static String? extractErrorMessage(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final errorObj = responseData['error'];
    if (errorObj is Map<String, dynamic> && errorObj['message'] is String) {
      return errorObj['message'] as String;
    }

    if (responseData['message'] is String) {
      return responseData['message'] as String;
    }

    return null;
  }
}
