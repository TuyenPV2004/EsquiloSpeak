import 'dart:io';
import 'package:dio/dio.dart';

bool isTransientDioError(DioException de) {
  final statusCode = de.response?.statusCode;
  return de.type == DioExceptionType.connectionTimeout ||
      de.type == DioExceptionType.sendTimeout ||
      de.type == DioExceptionType.receiveTimeout ||
      de.type == DioExceptionType.connectionError ||
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode >= 500);
}

bool isTransientNetworkException(Object error) {
  if (error is DioException) {
    return isTransientDioError(error);
  }
  return error is SocketException || error is IOException;
}
