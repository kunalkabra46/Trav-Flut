import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tripthread/models/api_response.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/models/follow_status.dart';
import 'package:tripthread/models/trip.dart';
import 'package:tripthread/services/storage_service.dart';
import 'package:tripthread/config/app_config.dart';
import 'package:tripthread/utils/error_handler.dart';

class ApiService {
  late final Dio _dio;
  StorageService? _storageService;
  VoidCallback? _unauthorizedCallback;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: AppConfig.defaultHeaders,
    ));

    _setupInterceptors();
  }

  void setStorageService(StorageService storageService) {
    _storageService = storageService;
  }

  void setUnauthorizedCallback(VoidCallback callback) {
    _unauthorizedCallback = callback;
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
              // Refresh failed, clear tokens and call unauthorized callback
              await _storageService!.clearTokens();
              _unauthorizedCallback?.call();
            }
          } else {
            // No refresh token, call unauthorized callback
            _unauthorizedCallback?.call();
          }
        }
        handler.next(error);
      },
    ));
  }

  // Authentication
  Future<ApiResponse<AuthResponse>> signup({
    required String email,
    required String password,
    required String name,
    String? username,
  }) async {
    try {
      debugPrint('[ApiService] Signup attempt for email: $email');
      final response = await _dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'name': name,
        if (username != null && username.isNotEmpty) 'username': username,
      });

      debugPrint('[ApiService] Signup response status: ${response.statusCode}');

      return ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Signup DioException: ${e.message}');
      return ApiResponse<AuthResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Signup unexpected error: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[ApiService] Login attempt for email: $email');
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('[ApiService] Login response status: ${response.statusCode}');

      return ApiResponse<AuthResponse>.fromJson(
        response.data,
        (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Login DioException: ${e.message}');
      return ApiResponse<AuthResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Login unexpected error: $e');
      return ApiResponse<AuthResponse>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> logout() async {
    try {
      debugPrint('[ApiService] Logout attempt');
      final response = await _dio.post('/auth/logout');
      debugPrint('[ApiService] Logout response status: ${response.statusCode}');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Logout DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Logout unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // User Management
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      debugPrint('[ApiService] Getting current user');
      final response = await _dio.get('/users/me');
      debugPrint('[ApiService] Get current user response: ${response.statusCode}');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get current user DioException: ${e.message}');
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get current user unexpected error: $e');
      return ApiResponse<User>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<User>> getUser(String userId) async {
    try {
      debugPrint('[ApiService] Getting user: $userId');
      final response = await _dio.get('/users/$userId');
      debugPrint('[ApiService] Get user response: ${response.statusCode}');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get user DioException: ${e.message}');
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get user unexpected error: $e');
      return ApiResponse<User>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
  }) async {
    try {
      debugPrint('[ApiService] Updating profile');
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;
      if (isPrivate != null) data['isPrivate'] = isPrivate;

      final response = await _dio.put('/users/me', data: data);
      debugPrint('[ApiService] Update profile response: ${response.statusCode}');

      return ApiResponse<User>.fromJson(
        response.data,
        (json) => User.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Update profile DioException: ${e.message}');
      return ApiResponse<User>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Update profile unexpected error: $e');
      return ApiResponse<User>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<UserStats>> getUserStats(String userId) async {
    try {
      debugPrint('[ApiService] Getting user stats: $userId');
      final response = await _dio.get('/users/$userId/stats');
      debugPrint('[ApiService] Get user stats response: ${response.statusCode}');

      return ApiResponse<UserStats>.fromJson(
        response.data,
        (json) => UserStats.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get user stats DioException: ${e.message}');
      return ApiResponse<UserStats>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get user stats unexpected error: $e');
      return ApiResponse<UserStats>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Follow System - Unified approach
  Future<ApiResponse<void>> followUser(String userId) async {
    try {
      debugPrint('[ApiService] Following user: $userId');
      final response = await _dio.post('/follow/$userId');
      debugPrint('[ApiService] Follow user response: ${response.statusCode}');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
        error: response.data['error'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Follow user DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Follow user unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> unfollowUser(String userId) async {
    try {
      debugPrint('[ApiService] Unfollowing user: $userId');
      final response = await _dio.delete('/follow/$userId');
      debugPrint('[ApiService] Unfollow user response: ${response.statusCode}');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
        error: response.data['error'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Unfollow user DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Unfollow user unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<FollowStatusResponse>> getDetailedFollowStatus(String userId) async {
    try {
      debugPrint('[ApiService] Getting detailed follow status for user: $userId');
      final response = await _dio.get('/follow/$userId');
      debugPrint('[ApiService] Get detailed follow status response: ${response.statusCode}');

      return ApiResponse<FollowStatusResponse>.fromJson(
        response.data,
        (json) => FollowStatusResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get detailed follow status DioException: ${e.message}');
      return ApiResponse<FollowStatusResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get detailed follow status unexpected error: $e');
      return ApiResponse<FollowStatusResponse>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Follow Requests Management
  Future<ApiResponse<List<FollowRequestDto>>> getPendingFollowRequests() async {
    try {
      debugPrint('[ApiService] Getting pending follow requests');
      final response = await _dio.get('/follow/requests');
      debugPrint('[ApiService] Get pending follow requests response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        final List<dynamic> requestsData = response.data['data'];
        final requests = requestsData
            .map((data) => FollowRequestDto.fromJson(data))
            .toList();
        return ApiResponse<List<FollowRequestDto>>(
          success: true,
          data: requests,
        );
      }

      return ApiResponse<List<FollowRequestDto>>(
        success: false,
        error: response.data['error'] ?? 'Failed to get pending follow requests',
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get pending follow requests DioException: ${e.message}');
      return ApiResponse<List<FollowRequestDto>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get pending follow requests unexpected error: $e');
      return ApiResponse<List<FollowRequestDto>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> acceptFollowRequest(String requestId) async {
    try {
      debugPrint('[ApiService] Accepting follow request: $requestId');
      final response = await _dio.put('/follow/requests/$requestId/accept');
      debugPrint('[ApiService] Accept follow request response: ${response.statusCode}');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
        error: response.data['error'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Accept follow request DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Accept follow request unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> rejectFollowRequest(String requestId) async {
    try {
      debugPrint('[ApiService] Rejecting follow request: $requestId');
      final response = await _dio.put('/follow/requests/$requestId/reject');
      debugPrint('[ApiService] Reject follow request response: ${response.statusCode}');

      return ApiResponse<void>(
        success: response.data['success'],
        message: response.data['message'],
        error: response.data['error'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Reject follow request DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Reject follow request unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // User Discovery and Search
  Future<ApiResponse<List<Map<String, dynamic>>>> searchUsers({
    String? search,
    int page = 1,
    int limit = 20,
    bool prioritizeFollowed = false,
  }) async {
    try {
      debugPrint(
          '[ApiService] Searching users: search=$search, page=$page, limit=$limit, prioritizeFollowed=$prioritizeFollowed');
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
        'prioritizeFollowed': prioritizeFollowed.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get('/users', queryParameters: queryParams);
      debugPrint('[ApiService] Search users response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        final paginatedData = response.data['data'];
        if (paginatedData['items'] != null) {
          final List<dynamic> usersData = paginatedData['items'];
          final users = usersData.cast<Map<String, dynamic>>();
          return ApiResponse<List<Map<String, dynamic>>>(
            success: true,
            data: users,
          );
        }
      }

      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: response.data['error'] ?? 'Failed to search users',
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Search users DioException: ${e.message}');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Search users unexpected error: $e');
      return ApiResponse<List<Map<String, dynamic>>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Feed Management
  Future<ApiResponse<Map<String, dynamic>>> getHomeFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('[ApiService] Getting home feed: page=$page, limit=$limit');
      final response = await _dio.get('/feed/home', queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      debugPrint('[ApiService] Get home feed response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: response.data['error'] ?? 'Failed to get home feed',
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get home feed DioException: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get home feed unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getDiscoverTrips({
    int page = 1,
    int limit = 20,
    String? status,
    String? mood,
    bool includePrivate = false,
  }) async {
    try {
      debugPrint(
          '[ApiService] Getting discover trips: page=$page, limit=$limit, status=$status, mood=$mood');
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (mood != null) queryParams['mood'] = mood;
      if (includePrivate) queryParams['includePrivate'] = 'true';

      final response =
          await _dio.get('/discover/trips', queryParameters: queryParams);
      debugPrint(
          '[ApiService] Get discover trips response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: response.data['data'],
        );
      }

      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: response.data['error'] ?? 'Failed to get discover trips',
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get discover trips DioException: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get discover trips unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Trip Participants
  Future<List<TripParticipant>> getTripParticipants(String tripId) async {
    try {
      debugPrint('[ApiService] Getting trip participants for trip: $tripId');
      final response = await _dio.get('/trips/$tripId/participants');
      debugPrint('[ApiService] Get trip participants response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        final List<dynamic> participantsData = response.data['data'];
        return participantsData
            .map((data) => TripParticipant.fromJson(data))
            .toList();
      }

      throw Exception(response.data['error'] ?? 'Failed to get trip participants');
    } on DioException catch (e) {
      debugPrint('[ApiService] Get trip participants DioException: ${e.message}');
      throw Exception(e.response?.data['error'] ?? 'Network error occurred');
    } catch (e) {
      debugPrint('[ApiService] Get trip participants unexpected error: $e');
      rethrow;
    }
  }

  Future<void> removeTripParticipant(String tripId, String userId) async {
    try {
      debugPrint('[ApiService] Removing trip participant: $userId from trip: $tripId');
      final response = await _dio.delete('/trips/$tripId/participants', queryParameters: {
        'userId': userId,
      });
      debugPrint('[ApiService] Remove trip participant response: ${response.statusCode}');

      if (!response.data['success']) {
        throw Exception(response.data['error'] ?? 'Failed to remove participant');
      }
    } on DioException catch (e) {
      debugPrint('[ApiService] Remove trip participant DioException: ${e.message}');
      throw Exception(e.response?.data['error'] ?? 'Network error occurred');
    } catch (e) {
      debugPrint('[ApiService] Remove trip participant unexpected error: $e');
      rethrow;
    }
  }
}