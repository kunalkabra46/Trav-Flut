import 'package:dio/dio.dart';
import 'package:tripthread/models/api_response.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/models/trip.dart';
import 'package:tripthread/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // static const String baseUrl = 'http://localhost:3000/api';
  // static const String baseUrl = 'http://10.61.114.100:3000/api';
  static const String baseUrl = 'http://192.168.0.110:3000/api';
  // static const String baseUrl = 'http://192.168.0.111:3000/api';

  late final Dio _dio;
  StorageService? _storageService;
  VoidCallback? _onUnauthorized;

  ApiService() {
    debugPrint('[ApiService] Initializing with baseUrl: $baseUrl');
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
    debugPrint('[ApiService] Setting storage service');
    _storageService = storageService;
  }

  void setUnauthorizedCallback(VoidCallback callback) {
    debugPrint('[ApiService] Setting unauthorized callback');
    _onUnauthorized = callback;
  }

  void _setupInterceptors() {
    debugPrint('[ApiService] Setting up interceptors');

    // Request interceptor to add auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('[ApiService] Request: ${options.method} ${options.path}');
        debugPrint('[ApiService] Request headers: ${options.headers}');
        if (options.data != null) {
          debugPrint('[ApiService] Request data: ${options.data}');
        }

        if (_storageService != null) {
          final token = await _storageService!.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '[ApiService] Added auth token: ${token.substring(0, 10)}...');
          } else {
            debugPrint('[ApiService] No auth token available');
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
            '[ApiService] Response: ${response.statusCode} ${response.requestOptions.path}');
        debugPrint('[ApiService] Response data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint(
            '[ApiService] Error: ${error.type} ${error.response?.statusCode} ${error.requestOptions.path}');
        debugPrint('[ApiService] Error message: ${error.message}');
        if (error.response?.data != null) {
          debugPrint(
              '[ApiService] Error response data: ${error.response?.data}');
        }

        // Handle token refresh on 401
        if (error.response?.statusCode == 401 && _storageService != null) {
          debugPrint('[ApiService] Attempting token refresh...');
          final refreshToken = await _storageService!.getRefreshToken();
          if (refreshToken != null) {
            try {
              debugPrint('[ApiService] Calling refresh token endpoint');
              final response = await _dio.post('/auth/refresh-token', data: {
                'refreshToken': refreshToken,
              });

              if (response.statusCode == 200 &&
                  response.data['success'] == true) {
                final newToken = response.data['data']['accessToken'];
                await _storageService!.saveAccessToken(newToken);
                debugPrint('[ApiService] Token refreshed successfully');

                // Retry original request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                debugPrint(
                    '[ApiService] Retrying original request with new token');
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              } else {
                debugPrint(
                    '[ApiService] Token refresh failed: ${response.data}');
                // Refresh failed, clear tokens and notify
                await _storageService!.clearTokens();
                if (_onUnauthorized != null) {
                  _onUnauthorized!();
                }
              }
            } catch (e) {
              debugPrint('[ApiService] Token refresh error: $e');
              // Refresh failed, clear tokens and notify
              await _storageService!.clearTokens();
              if (_onUnauthorized != null) {
                _onUnauthorized!();
              }
            }
          } else {
            debugPrint('[ApiService] No refresh token available');
            // No refresh token, clear tokens and notify
            await _storageService!.clearTokens();
            if (_onUnauthorized != null) {
              _onUnauthorized!();
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
      debugPrint(
          '[ApiService] Signup called with email: $email, name: $name, username: $username');
      final response = await _dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'name': name,
        if (username != null) 'username': username,
      });

      debugPrint('[ApiService] Signup response: ${response.statusCode}');
      return ApiResponse<AuthResponse>(
        success: response.data['success'],
        data: AuthResponse.fromJson(response.data['data']),
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
      debugPrint('[ApiService] Login called with email: $email');
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      debugPrint('[ApiService] Login response: ${response.statusCode}');
      return ApiResponse<AuthResponse>(
        success: response.data['success'],
        data: AuthResponse.fromJson(response.data['data']),
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
      debugPrint('[ApiService] Logout called');
      final response = await _dio.post('/auth/logout');
      debugPrint('[ApiService] Logout response: ${response.statusCode}');
      return ApiResponse<void>(
        success: response.data['success'],
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

  // User endpoints
  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      debugPrint('[ApiService] Getting current user');
      final response = await _dio.get('/users/me');
      debugPrint(
          '[ApiService] Get current user response: ${response.statusCode}');
      return ApiResponse<User>(
        success: response.data['success'],
        data: User.fromJson(response.data['data']),
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

  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      debugPrint(
          '[ApiService] Updating profile: name=$name, username=$username, bio=$bio, avatarUrl=$avatarUrl');
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (bio != null) data['bio'] = bio;
      if (avatarUrl != null) data['avatarUrl'] = avatarUrl;

      final response = await _dio.put('/users/me', data: data);
      debugPrint(
          '[ApiService] Update profile response: ${response.statusCode}');
      return ApiResponse<User>(
        success: response.data['success'],
        data: User.fromJson(response.data['data']),
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

  Future<ApiResponse<List<Map<String, dynamic>>>> searchUsers({
    String? search,
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    try {
      debugPrint(
          '[ApiService] Searching users: search=$search, page=$page, limit=$limit, refresh=$refresh');
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await _dio.get('/users', queryParameters: queryParams);
      debugPrint('[ApiService] Search users response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        final data = response.data['data'];
        final users = (data['items'] as List<dynamic>)
            .map((user) => Map<String, dynamic>.from(user))
            .toList();
        final hasNext = data['hasNext'] as bool;

        debugPrint(
            '[ApiService] Found ${users.length} users, hasNext: $hasNext');
        return ApiResponse<List<Map<String, dynamic>>>(
          success: true,
          data: users,
        );
      } else {
        debugPrint(
            '[ApiService] Search users failed: ${response.data['error']}');
        return ApiResponse<List<Map<String, dynamic>>>(
          success: false,
          error: response.data['error'] ?? 'Failed to search users',
        );
      }
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

  Future<ApiResponse<void>> followUser(String userId,
      {String? currentUserId}) async {
    try {
      debugPrint('[ApiService] Following user: $userId');
      final response = await _dio.post('/follow/$userId');
      debugPrint('[ApiService] Follow user response: ${response.statusCode}');
      return ApiResponse<void>(
        success: response.data['success'],
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

  Future<ApiResponse<void>> unfollowUser(String userId,
      {String? currentUserId}) async {
    try {
      debugPrint('[ApiService] Unfollowing user: $userId');
      final response = await _dio.delete('/follow/$userId');
      debugPrint('[ApiService] Unfollow user response: ${response.statusCode}');
      return ApiResponse<void>(
        success: response.data['success'],
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

  // Trip endpoints
  Future<ApiResponse<Trip>> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    required List<String> destinations,
    String? mood,
    String? type,
    String? coverMediaUrl,
  }) async {
    try {
      debugPrint(
          '[ApiService] Creating trip: title=$title, destinations=$destinations');
      final data = {
        'title': title,
        if (description != null) 'description': description,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        'destinations': destinations,
        if (mood != null) 'mood': mood,
        if (type != null) 'type': type,
        if (coverMediaUrl != null) 'coverMediaUrl': coverMediaUrl,
      };

      final response = await _dio.post('/trips', data: data);
      debugPrint('[ApiService] Create trip response: ${response.statusCode}');
      return ApiResponse<Trip>(
        success: response.data['success'],
        data: Trip.fromJson(response.data['data']),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Create trip DioException: ${e.message}');
      return ApiResponse<Trip>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<bool>> getFollowStatus(String userId) async {
    try {
      final response = await _dio.get('/follow/$userId');

      return ApiResponse<bool>(
        success: response.data['success'],
        data: (response.data['data'] != null)
            ? (response.data['data']['isFollowing'] ?? false)
            : false,
      );
    } on DioException catch (e) {
      return ApiResponse<bool>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<FollowStatusResponse>> getDetailedFollowStatus(
      String userId) async {
    try {
      final response = await _dio.get('/follow/$userId');

      return ApiResponse<FollowStatusResponse>.fromJson(
        response.data,
        (json) => FollowStatusResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse<FollowStatusResponse>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<List<FollowRequestDto>>> getPendingFollowRequests() async {
    try {
      final response = await _dio.get('/follow/requests');

      final requests = (response.data['data'] as List)
          .map((json) => FollowRequestDto.fromJson(json))
          .toList();

      return ApiResponse<List<FollowRequestDto>>(
        success: response.data['success'],
        data: requests,
      );
    } on DioException catch (e) {
      return ApiResponse<List<FollowRequestDto>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<void>> acceptFollowRequest(String requestId) async {
    try {
      final response = await _dio.post('/follow/requests/$requestId/accept');

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

  Future<ApiResponse<void>> rejectFollowRequest(String requestId) async {
    try {
      final response = await _dio.post('/follow/requests/$requestId/reject');

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

  Future<ApiResponse<List<Trip>>> getUserTrips() async {
    try {
      debugPrint('[ApiService] Getting user trips');
      final response = await _dio.get('/trips');
      debugPrint(
          '[ApiService] Get user trips response: ${response.statusCode}');

      if (response.data['success'] && response.data['data'] != null) {
        final data = response.data['data'];
        final trips = (data['items'] as List<dynamic>)
            .map((trip) => Trip.fromJson(trip))
            .toList();

        debugPrint('[ApiService] Found ${trips.length} user trips');
        return ApiResponse<List<Trip>>(
          success: true,
          data: trips,
        );
      } else {
        debugPrint(
            '[ApiService] Get user trips failed: ${response.data['error']}');
        return ApiResponse<List<Trip>>(
          success: false,
          error: response.data['error'] ?? 'Failed to get user trips',
        );
      }
    } on DioException catch (e) {
      debugPrint('[ApiService] Get user trips DioException: ${e.message}');
      return ApiResponse<List<Trip>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get user trips unexpected error: $e');
      return ApiResponse<List<Trip>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<Trip>> getTrip(String tripId) async {
    try {
      debugPrint('[ApiService] Getting trip: $tripId');
      final response = await _dio.get('/trips/$tripId');
      debugPrint('[ApiService] Get trip response: ${response.statusCode}');
      return ApiResponse<Trip>(
        success: response.data['success'],
        data: Trip.fromJson(response.data['data']),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get trip DioException: ${e.message}');
      return ApiResponse<Trip>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get trip unexpected error: $e');
      return ApiResponse<Trip>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> endTrip(String tripId) async {
    try {
      debugPrint('[ApiService] Ending trip: $tripId');
      final response = await _dio.post('/trips/$tripId/end');
      debugPrint('[ApiService] End trip response: ${response.statusCode}');
      return ApiResponse<void>(
        success: response.data['success'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] End trip DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] End trip unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<void>> publishFinalPost(String tripId) async {
    try {
      debugPrint('[ApiService] Publishing final post for trip: $tripId');
      final response = await _dio.post('/trips/$tripId/publish');
      debugPrint(
          '[ApiService] Publish final post response: ${response.statusCode}');
      return ApiResponse<void>(
        success: response.data['success'],
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Publish final post DioException: ${e.message}');
      return ApiResponse<void>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Publish final post unexpected error: $e');
      return ApiResponse<void>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<ApiResponse<List<TripThreadEntry>>> getTripEntries(
      String tripId) async {
    try {
      debugPrint('[ApiService] Getting trip entries for trip: $tripId');
      final response = await _dio.get('/trips/$tripId/entries');
      debugPrint(
          '[ApiService] Get trip entries response: ${response.statusCode}');

      if (response.data['data'] == null) {
        return ApiResponse<Trip?>(
          success: true,
          data: null,
          message: response.data['message'],
        );
      }

      return ApiResponse<Trip?>.fromJson(
        response.data,
        (json) => json != null ? Trip.fromJson(json as Map<String, dynamic>) : null,
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get trip entries DioException: ${e.message}');
      return ApiResponse<List<TripThreadEntry>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Get trip entries unexpected error: $e');
      return ApiResponse<List<TripThreadEntry>>(
        success: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  // Feed endpoints
  Future<ApiResponse<Map<String, dynamic>>> getHomeFeed({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.post('/trips/$tripId/entries', data: request.toJson());

      return ApiResponse<TripThreadEntry>.fromJson(
        response.data,
        (json) => TripThreadEntry.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      debugPrint('[ApiService] Get home feed DioException: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    }
  }

  Future<ApiResponse<List<TripThreadEntry>>> getThreadEntries(String tripId) async {
    try {
      debugPrint(
          '[ApiService] Getting discover trips: page=$page, limit=$limit, status=$status, mood=$mood');
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (mood != null) queryParams['mood'] = mood;

      final response =
          await _dio.get('/discover/trips', queryParameters: queryParams);

      debugPrint(
          '[ApiService] Get discover trips response: ${response.statusCode}');
      debugPrint('[ApiService] Discover trips response data: ${response.data}');

      return ApiResponse<Map<String, dynamic>>(
        success: response.data['success'],
        data: response.data['data'],
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
  // Add this method for manual refresh
  Future<ApiResponse<Map<String, dynamic>>> refreshAccessToken(
      String refreshToken) async {
    try {
      debugPrint('[ApiService] Refreshing access token');
      final response = await _dio.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        debugPrint('[ApiService] Token refresh successful');
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          data: Map<String, dynamic>.from(response.data['data']),
        );
      } else {
        debugPrint('[ApiService] Token refresh failed: ${response.data}');
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          error: response.data['error'] ?? 'Failed to refresh token',
        );
      }
    } on DioException catch (e) {
      debugPrint('[ApiService] Token refresh DioException: ${e.message}');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: e.response?.data['error'] ?? 'Network error occurred',
      );
    } catch (e) {
      debugPrint('[ApiService] Token refresh unexpected error: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        error: 'Unknown error occurred',
      );
    }
  }
}
