import 'package:flutter/foundation.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;

  UserProvider({required ApiService apiService}) : _apiService = apiService;

  final Map<String, User> _userCache = {};
  final Map<String, UserStats> _statsCache = {};
  final Map<String, bool> _followStatusCache = {};
  final Map<String, FollowStatusResponse> _detailedFollowStatusCache = {};
  List<FollowRequestDto> _pendingFollowRequests = [];
  final List<Map<String, dynamic>> _discoverUsers = [];
  bool _isLoading = false;
  bool _isDiscoverLoading = false;
  bool _isFollowRequestsLoading = false;
  String? _error;
  String? _discoverError;
  String? _followRequestsError;
  int _discoverPage = 1;
  bool _hasMoreUsers = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get isDiscoverLoading => _isDiscoverLoading;
  bool get isFollowRequestsLoading => _isFollowRequestsLoading;
  String? get error => _error;
  String? get discoverError => _discoverError;
  String? get followRequestsError => _followRequestsError;
  bool isFollowing(String userId) => _followStatusCache[userId] ?? false;
  FollowStatusResponse? getDetailedFollowStatus(String userId) =>
      _detailedFollowStatusCache[userId];
  List<FollowRequestDto> get pendingFollowRequests => _pendingFollowRequests;
  List<Map<String, dynamic>> get discoverUsers => _discoverUsers;
  bool get hasMoreUsers => _hasMoreUsers;

  User? getUser(String userId) => _userCache[userId];
  UserStats? getUserStats(String userId) => _statsCache[userId];

  Future<User?> fetchUser(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.getUser(userId);

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        _isLoading = false;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to fetch user';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Fetch user error: $e');
      return null;
    }
  }

  Future<UserStats?> fetchUserStats(String userId) async {
    try {
      final response = await _apiService.getUserStats(userId);

      if (response.success && response.data != null) {
        _statsCache[userId] = response.data!;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to fetch user stats';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Fetch user stats error: $e');
      return null;
    }
  }

  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? username,
    String? bio,
    String? avatarUrl,
    bool? isPrivate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.updateProfile(
        userId: userId,
        name: name,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        isPrivate: isPrivate,
      );

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  Future<bool> togglePrivacy(String userId) async {
    try {
      final response = await _apiService.togglePrivacy(userId);

      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to toggle privacy';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      notifyListeners();
      debugPrint('Toggle privacy error: $e');
      return false;
    }
  }

  Future<bool> fetchFollowStatus(String userId) async {
    try {
      final response = await _apiService.getFollowStatus(userId);

      if (response.success) {
        _followStatusCache[userId] = response.data ?? false;
        notifyListeners();
        return response.data ?? false;
      } else {
        _followStatusCache[userId] = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _followStatusCache[userId] = false;
      notifyListeners();
      debugPrint('Fetch follow status error: $e');
      return false;
    }
  }

  Future<FollowStatusResponse?> fetchDetailedFollowStatus(String userId) async {
    try {
      final response = await _apiService.getDetailedFollowStatus(userId);

      if (response.success && response.data != null) {
        _detailedFollowStatusCache[userId] = response.data!;
        _followStatusCache[userId] = response.data!.isFollowing;
        notifyListeners();
        return response.data;
      } else {
        _detailedFollowStatusCache[userId] = const FollowStatusResponse(
          isFollowing: false,
          isRequestPending: false,
        );
        _followStatusCache[userId] = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _detailedFollowStatusCache[userId] = const FollowStatusResponse(
        isFollowing: false,
        isRequestPending: false,
      );
      _followStatusCache[userId] = false;
      notifyListeners();
      debugPrint('Fetch detailed follow status error: $e');
      return null;
    }
  }

  Future<void> loadPendingFollowRequests() async {
    try {
      _isFollowRequestsLoading = true;
      _followRequestsError = null;
      notifyListeners();

      final response = await _apiService.getPendingFollowRequests();

      if (response.success && response.data != null) {
        _pendingFollowRequests = response.data!;
        _followRequestsError = null;
      } else {
        _followRequestsError =
            response.error ?? 'Failed to load follow requests';
      }
    } catch (e) {
      _followRequestsError = 'An unexpected error occurred';
      debugPrint('Load pending follow requests error: $e');
    } finally {
      _isFollowRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> acceptFollowRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.acceptFollowRequest(requestId);

      if (response.success) {
        // Remove the request from pending list
        _pendingFollowRequests.removeWhere((req) => req.id == requestId);

        // Update follow status cache for the requester
        final request = _pendingFollowRequests.firstWhere(
          (req) => req.id == requestId,
          orElse: () => _pendingFollowRequests.first,
        );
        if (_pendingFollowRequests.isNotEmpty) {
          _followStatusCache[request.followerId] = true;
          _detailedFollowStatusCache[request.followerId] =
              const FollowStatusResponse(
            isFollowing: true,
            isRequestPending: false,
          );
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to accept follow request';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Accept follow request error: $e');
      return false;
    }
  }

  Future<bool> rejectFollowRequest(String requestId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.rejectFollowRequest(requestId);

      if (response.success) {
        // Remove the request from pending list
        _pendingFollowRequests.removeWhere((req) => req.id == requestId);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to reject follow request';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Reject follow request error: $e');
      return false;
    }
  }

  Future<void> searchUsers({String? search, bool refresh = false}) async {
    try {
      if (refresh) {
        _discoverPage = 1;
        _discoverUsers.clear();
        _hasMoreUsers = true;
        _discoverError = null;
      }

      if (!_hasMoreUsers) return;

      _isDiscoverLoading = true;
      notifyListeners();

      final response = await _apiService.searchUsers(
        search: search,
        page: _discoverPage,
        limit: 20,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final users = data['items'] as List<dynamic>;
        final hasNext = data['hasNext'] as bool;

        if (refresh) {
          _discoverUsers.clear();
        }

        _discoverUsers.addAll(users.cast<Map<String, dynamic>>());
        _hasMoreUsers = hasNext;
        _discoverPage++;
        _discoverError = null;
      } else {
        _discoverError = response.error ?? 'Failed to fetch users';
      }
    } catch (e) {
      _discoverError = 'An unexpected error occurred';
      debugPrint('Search users error: $e');
    } finally {
      _isDiscoverLoading = false;
      notifyListeners();
    }
  }

  void clearDiscoverError() {
    _discoverError = null;
    notifyListeners();
  }

  void resetDiscover() {
    _discoverUsers.clear();
    _discoverPage = 1;
    _hasMoreUsers = true;
    _discoverError = null;
    notifyListeners();
  }

  void updateFollowStatus(String userId, bool isFollowing) {
    _followStatusCache[userId] = isFollowing;
    notifyListeners();
  }

  Future<bool> followUser(String userId, {String? currentUserId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.followUser(userId);

      if (response.success) {
        // Update follow status cache
        _followStatusCache[userId] = true;

        // Refresh target user's stats
        await fetchUserStats(userId);

        // Refresh current user's stats if provided
        if (currentUserId != null) {
          await fetchUserStats(currentUserId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to follow user';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Follow user error: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId, {String? currentUserId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.unfollowUser(userId);

      if (response.success) {
        // Update follow status cache
        _followStatusCache[userId] = false;

        // Refresh target user's stats
        await fetchUserStats(userId);

        // Refresh current user's stats if provided
        if (currentUserId != null) {
          await fetchUserStats(currentUserId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to unfollow user';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearFollowStatusCache() {
    _followStatusCache.clear();
    _detailedFollowStatusCache.clear();
    notifyListeners();
  }

  void clearFollowRequestsError() {
    _followRequestsError = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCache() {
    _userCache.clear();
    _statsCache.clear();
    _detailedFollowStatusCache.clear();
    _pendingFollowRequests.clear();
    notifyListeners();
  }

  // Method to refresh current user's stats after follow/unfollow actions
  Future<void> refreshCurrentUserStats(String currentUserId) async {
    await fetchUserStats(currentUserId);
  }
}
