import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 5000),
      receiveTimeout: const Duration(milliseconds: 5000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('accessToken');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(PrettyLogInterceptor());
  }

  return dio;
});

class PrettyLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('*** Request ***');
    debugPrint('Uri: ${options.uri}');
    debugPrint('Method: ${options.method}');
    if (options.headers.isNotEmpty) {
      debugPrint('Headers:');
      _prettyPrintJson(options.headers);
    }
    if (options.queryParameters.isNotEmpty) {
      debugPrint('Query Parameters:');
      _prettyPrintJson(options.queryParameters);
    }
    if (options.data != null) {
      debugPrint('Body:');
      _prettyPrintJson(options.data);
    }
    debugPrint('***************\n');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('*** Response ***');
    debugPrint('Uri: ${response.requestOptions.uri}');
    debugPrint('StatusCode: ${response.statusCode}');
    if (response.headers.map.isNotEmpty) {
      debugPrint('Headers:');
      _prettyPrintJson(response.headers.map);
    }
    if (response.data != null) {
      debugPrint('Body:');
      _prettyPrintJson(response.data);
    }
    debugPrint('****************\n');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('*** Error ***');
    debugPrint('Uri: ${err.requestOptions.uri}');
    debugPrint('Error: ${err.error}');
    debugPrint('Message: ${err.message}');
    if (err.response != null) {
      debugPrint('StatusCode: ${err.response!.statusCode}');
      if (err.response!.headers.map.isNotEmpty) {
        debugPrint('Headers:');
        _prettyPrintJson(err.response!.headers.map);
      }
      if (err.response!.data != null) {
        debugPrint('Error Body:');
        _prettyPrintJson(err.response!.data);
      }
    }
    debugPrint('*************\n');
    super.onError(err, handler);
  }

  void _prettyPrintJson(dynamic data) {
    if (data is Map || data is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        debugPrint(encoder.convert(data));
      } catch (e) {
        debugPrint(data.toString());
      }
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          final decoded = json.decode(trimmed);
          const encoder = JsonEncoder.withIndent('  ');
          debugPrint(encoder.convert(decoded));
        } catch (e) {
          debugPrint(data);
        }
      } else {
        debugPrint(data);
      }
    } else {
      debugPrint(data.toString());
    }
  }
}
