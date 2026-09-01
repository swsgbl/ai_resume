import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/storage_constants.dart';
import '../../core/storage/storage_service.dart';

/// 认证拦截器
///
/// 自动添加Token到请求头，处理Token刷新
class AuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();

  // Token刷新锁，防止并发刷新
  bool _isRefreshing = false;
  final Queue<_RetryRequest> _requestQueue = Queue();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 添加Token到请求头（从安全存储读取）
    final token = await _storage.getSecureString(StorageConstants.keyAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 处理401未授权错误
    if (err.response?.statusCode == ApiErrorCode.unauthorized) {
      // 如果正在刷新Token，将请求加入队列
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _requestQueue.add(_RetryRequest(completer, err.requestOptions));
        // Note: cannot resolve with future directly, skip this request for now
        handler.next(err);
        return;
      }

      // 开始刷新Token
      _isRefreshing = true;
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          // 重试原请求
          final retryResponse = await _retry(err.requestOptions);
          handler.resolve(retryResponse);

          // 处理队列中的请求
          _processQueue(newToken);
        } else {
          // Token刷新失败
          _rejectQueue();
          handler.next(err);
        }
      } catch (e) {
        // Token刷新失败，清除本地数据
        await _storage.clear();
        _rejectQueue();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
      return;
    }

    return handler.next(err);
  }

  /// 刷新Token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken =
          await _storage.getSecureString(StorageConstants.keyRefreshToken);
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.endpoints.refreshToken}',
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['accessToken'] as String?;
        if (accessToken != null) {
          // 保存到安全存储
          await _storage.setSecureString(
            StorageConstants.keyAccessToken,
            accessToken,
          );
          return accessToken;
        }
      }
    } catch (e) {
      // 记录错误但不抛出
      if (ApiConfig.enableErrorLog) {
        print('Token refresh failed: $e');
      }
    }
    return null;
  }

  /// 重试原请求
  Future<Response> _retry(RequestOptions requestOptions) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    return await Dio().request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// 处理队列中的请求
  void _processQueue(String newToken) {
    while (_requestQueue.isNotEmpty) {
      final retryRequest = _requestQueue.removeFirst();
      retryRequest.completer.complete(_retry(retryRequest.requestOptions));
    }
  }

  /// 拒绝队列中的请求
  void _rejectQueue() {
    while (_requestQueue.isNotEmpty) {
      final retryRequest = _requestQueue.removeFirst();
      retryRequest.completer.completeError(
        DioException(
          requestOptions: retryRequest.requestOptions,
          error: 'Token refresh failed',
          type: DioExceptionType.unknown,
        ),
      );
    }
  }
}

/// 重试请求包装类
class _RetryRequest {
  final Completer<Response> completer;
  final RequestOptions requestOptions;

  _RetryRequest(this.completer, this.requestOptions);
}

/// 日志拦截器
///
/// 记录请求和响应信息（仅开发环境）
class CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (ApiConfig.enableRequestLog) {
      print('📤 [API Request] ${options.method} ${options.uri}');
      if (options.data != null && ApiConfig.enableVerboseLog) {
        // 仅在详细模式下打印请求数据（可能包含敏感信息）
        print('   Data: ${options.data}');
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (ApiConfig.enableResponseLog) {
      print('✅ [API Response] ${response.statusCode} ${response.requestOptions.uri}');
    }
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (ApiConfig.enableErrorLog) {
      print('❌ [API Error] ${err.requestOptions.uri}');
      print('   Error: ${err.message}');
    }
    return handler.next(err);
  }
}

/// 错误拦截器
///
/// 统一处理API错误
class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // 处理不同类型的错误
    String errorMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = '网络连接超时，请检查网络设置';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          errorMessage = '登录已过期，请重新登录';
        } else if (statusCode == 403) {
          errorMessage = '没有权限访问';
        } else if (statusCode == 404) {
          errorMessage = '请求的资源不存在';
        } else if (statusCode == 500) {
          errorMessage = '服务器错误，请稍后重试';
        } else {
          errorMessage = '请求失败: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消';
        break;
      case DioExceptionType.connectionError:
        errorMessage = '网络连接失败，请检查网络';
        break;
      default:
        errorMessage = '发生未知错误';
    }

    final error = err.copyWith(
      message: errorMessage,
    );

    return handler.next(error);
  }
}
