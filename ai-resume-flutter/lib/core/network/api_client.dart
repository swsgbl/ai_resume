import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../core/config/api_config.dart';
import 'api_interceptors.dart';

/// API客户端
///
/// 封装Dio实例，提供HTTP请求能力
class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;

  /// 初始化API客户端
  void initialize({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器
    _dio.interceptors.addAll([
      AuthInterceptor(),
      CustomLogInterceptor(),
      ErrorInterceptor(),
    ]);

    // 开发环境添加日志拦截器
    if (ApiConfig.enableRequestLog || ApiConfig.enableResponseLog) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: ApiConfig.enableRequestLog,
          responseBody: ApiConfig.enableResponseLog,
          error: true,
          compact: true,
        ),
      );
    }
  }

  /// GET请求
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// POST请求
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// PUT请求
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// DELETE请求
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// PATCH请求
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.patch(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
    return response.data as T;
  }

  /// 上传文件
  Future<T> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    Options? options,
  }) async {
    final response = await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      options: options,
    );
    return response.data as T;
  }

  /// 获取Dio实例（用于特殊场景）
  Dio get dio => _dio;
}
