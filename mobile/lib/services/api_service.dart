import 'package:dio/dio.dart';
import 'package:tripthread/models/api_response.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  late final Dio _dio;
  StorageService? _storageService;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void setStorageService(StorageService storageService) {
    _storageService = storageService;
  }

  void _setupInterceptors() {
    // Request interceptor to add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_storageService != null) {
          final token = await _storageService!.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle token refresh on 401
        if (error.response?.statusCode == 401 && _storageService != null) {
          final refreshToken = await _storageService!.getRefreshToken();
          if (refreshToken != null) {
            try {
              final response = await _dio.post('/auth/refresh-token', data: {
                'refreshToken': refreshToken,
              });

              if (response.statusCode == 200) {
                final newToken = response.data['data']['accessToken'];
                await _storageService!.saveAccessToken(newToken);

                // Retry original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              }
            } catch (e) {
              // Refresh failed, clear tokens
              await _storageService!.clearTokens();
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // Auth endpoints
  Future<ApiResponse<AuthResponse>> signup({
    required String email,
    required String password,
    required String name,
    String? username,
  }) async {
    try {
      final response = await _dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'name': name,
        if (username != null) 'username': username,
      });

      return ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      return ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<AuthResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<void>> logout(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  // User endpoints
  Future<ApiResponse<User>> getUser(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<User>> updateProfile({
    required String userId,
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final response = await _dio.put('/users/$userId', data: {
        if (name != null) 'name': name,
        if (username != null) 'username': username,
        if (bio != null) 'bio': bio,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<User>> togglePrivacy(String userId) async {
    try {
      final response = await _dio.patch('/users/$userId/privacy');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<UserStats>> getUserStats(String userId) async {
    try {
      final response = await _dio.get('/users/$userId/stats');

      return ApiResponse<UserStats>.fromJson(
        response.data,
        (json) => UserStats.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<UserStats>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  // Follow endpoints
  Future<ApiResponse<void>> followUser(String userId) async {
    try {
      final response = await _dio.post('/follow/$userId');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<void>> unfollowUser(String userId) async {
    try {
      final response = await _dio.delete('/follow/$userId');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<List<User>>> getFollowers(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/users/$userId/followers', queryParameters: {
        'page': page,
        'limit': limit,
      });

      final followers = (response.data['data']['followers'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      return ApiResponse<List<User>>(
        success: response.data['success'],
        data: followers,
      );
    } on DioException catch (e) {
      return ApiResponse<List<User>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<List<User>>> getFollowing(String userId, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/users/$userId/following', queryParameters: {
        'page': page,
        'limit': limit,
      });

      final following = (response.data['data']['following'] as List)
          .map((json) => User.fromJson(json))
          .toList();

      return ApiResponse<List<User>>(
        success: response.data['success'],
        data: following,
      );
    } on DioException catch (e) {
      return ApiResponse<List<User>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }
}