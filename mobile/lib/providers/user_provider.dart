import 'package:flutter/foundation.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/models/follow_status.dart';
import 'package:tripthread/models/api_response.dart';
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

  Future<bool> updatePrivacySettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        _error = 'No current user found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _apiService.togglePrivacy(currentUser.id);

      if (response.success && response.data != null) {
        // Update the user in cache
        final updatedUser = response.data!;
        _userCache[updatedUser.id] = updatedUser;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to update privacy settings';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Privacy settings update error: $e');
      return false;
    }
  }

  Future<bool> fetchFollowStatus(String userId) async {
    try {
      final response = await _apiService.getDetailedFollowStatus(userId);

      if (response.success && response.data != null) {
        final followStatus = response.data!;
        _followStatusCache[userId] = followStatus.isFollowing;
        notifyListeners();
        return followStatus.isFollowing;
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
        final defaultResponse = FollowStatusResponse(
          isFollowing: false,
          isFollowedBy: false,
          isRequestPending: false,
          isPrivate: _userCache[userId]?.isPrivate ?? false,
        );
        _detailedFollowStatusCache[userId] = defaultResponse;
        _followStatusCache[userId] = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      final defaultResponse = FollowStatusResponse(
        isFollowing: false,
        isFollowedBy: false,
        isRequestPending: false,
        isPrivate: _userCache[userId]?.isPrivate ?? false,
      );
      _detailedFollowStatusCache[userId] = defaultResponse;
      _followStatusCache[userId] = false;
      notifyListeners();
      debugPrint('Fetch detailed follow status error: $e');
      return null;
    }
  }

  // Fixed version of follow request loading
  Future<void> loadPendingFollowRequests() async {
    try {
      debugPrint('[UserProvider] Starting to load pending follow requests');
      _isFollowRequestsLoading = true;
      _followRequestsError = null;
      notifyListeners();

      final response = await _apiService.getPendingFollowRequests();
      debugPrint('[UserProvider] API response: success=${response.success}, error=${response.error}');

      if (response.success && response.data != null) {
        _pendingFollowRequests = response.data!;
        _followRequestsError = null;
        debugPrint('[UserProvider] Loaded ${_pendingFollowRequests.length} pending follow requests');
      } else {
        _followRequestsError = response.error ?? 'Failed to load follow requests';
        debugPrint('[UserProvider] Failed to load follow requests: $_followRequestsError');
      }
    } catch (e) {
      _followRequestsError = 'An unexpected error occurred';
      debugPrint('[UserProvider] Load pending follow requests error: $e');
    } finally {
      _isFollowRequestsLoading = false;
      notifyListeners();
      debugPrint('[UserProvider] Finished loading follow requests. Count: ${_pendingFollowRequests.length}');
    }
  }

  // Updated accept/reject follow request methods
  Future<bool> acceptFollowRequest(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.respondToFollowRequest(userId, true);

      if (response.success) {
        // Remove request from pending list
        _pendingFollowRequests.removeWhere((req) => req.followerId == userId);
        
        // Update follow status caches
        _followStatusCache[userId] = true;
        _detailedFollowStatusCache[userId] = FollowStatusResponse(
          isFollowing: true,
          isFollowedBy: true,
          isRequestPending: false,
          isPrivate: false,
        );

        // Fetch current user
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          // Refresh stats for both users
          await Future.wait([
            fetchUserStats(userId),
            fetchUserStats(currentUser.id),
          ]);
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

  Future<bool> rejectFollowRequest(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.respondToFollowRequest(userId, false);

      if (response.success) {
        // Remove request from pending list
        _pendingFollowRequests.removeWhere((req) => req.followerId == userId);
        
        // Update follow status caches
        _followStatusCache[userId] = false;
        _detailedFollowStatusCache[userId] = FollowStatusResponse(
          isFollowing: false,
          isFollowedBy: false,
          isRequestPending: false,
          isPrivate: true,
        );

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
        if (refresh) {
          _discoverUsers.clear();
        }

        _discoverUsers.addAll(response.data!);
        _hasMoreUsers = response.data!.any((user) => user['hasNext'] as bool? ?? false);
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
      _error = null;
      notifyListeners();

      // First check if user is private
      final targetUser = await fetchUser(userId);
      if (targetUser == null) {
        _error = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      ApiResponse<void> response;
      if (targetUser.isPrivate) {
        // For private users, send a follow request
        response = await _apiService.sendFollowRequest(userId);
        if (response.success) {
          _detailedFollowStatusCache[userId] = FollowStatusResponse(
            isFollowing: false,
            isFollowedBy: false,
            isRequestPending: true,
            isPrivate: true,
          );
        }
      } else {
        // For public users, follow directly
        response = await _apiService.followUser(userId);
        if (response.success) {
          _followStatusCache[userId] = true;
          _detailedFollowStatusCache[userId] = FollowStatusResponse(
            isFollowing: true,
            isFollowedBy: false,
            isRequestPending: false,
            isPrivate: false,
          );
        }
      }

      if (response.success) {
        // Refresh stats for both users
        if (currentUserId != null) {
          await fetchUserStats(currentUserId);
        }
        await fetchUserStats(userId);
        
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

  // Clear user search state
  void clearUserSearch() {
    _discoverUsers.clear();
    _hasMoreUsers = false;
    _discoverPage = 1;
    _isDiscoverLoading = false;
    notifyListeners();
  }

  // Send follow request for private users
  Future<bool> sendFollowRequest(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.sendFollowRequest(userId);
      
      if (response.success) {
        // Update follow status cache
        _detailedFollowStatusCache[userId] = FollowStatusResponse(
          isFollowing: false,
          isFollowedBy: false,
          isRequestPending: true,
          isPrivate: true,
        );
        
        // Refresh stats for both users
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          await fetchUserStats(currentUser.id);
        }
        await fetchUserStats(userId);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to send follow request';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Send follow request error: $e');
      return false;
    }
  }

  // Cancel follow request
  Future<bool> cancelFollowRequest(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _apiService.cancelFollowRequest(userId);
      
      if (response.success) {
        // Update follow status cache
        _detailedFollowStatusCache[userId] = FollowStatusResponse(
          isFollowing: false,
          isFollowedBy: false,
          isRequestPending: false,
          isPrivate: true,
        );
        
        // Refresh stats for both users
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          await fetchUserStats(currentUser.id);
        }
        await fetchUserStats(userId);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error ?? 'Failed to cancel follow request';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      debugPrint('Cancel follow request error: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(String userId, {String? currentUserId}) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First check if there are any requests pending
      final detailedStatus = await fetchDetailedFollowStatus(userId);
      
      // If there's a pending request, cancel it instead of unfollowing
      final response = detailedStatus?.isRequestPending == true
          ? await _apiService.cancelFollowRequest(userId)
          : await _apiService.unfollowUser(userId);

      if (response.success) {
        // Update follow status caches
        _followStatusCache[userId] = false;
        _detailedFollowStatusCache[userId] = FollowStatusResponse(
          isFollowing: false,
          isFollowedBy: detailedStatus?.isFollowedBy ?? false,
          isRequestPending: false,
          isPrivate: detailedStatus?.isPrivate ?? false,
        );

        // Refresh both users' stats in parallel
        await Future.wait([
          fetchUserStats(userId),
          if (currentUserId != null) fetchUserStats(currentUserId),
        ]);

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
      debugPrint('Unfollow user error: $e');
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

  // Helper method to refresh stats after follow/unfollow actions
  Future<void> refreshUserStats() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        await fetchUserStats(response.data!.id);
      }
    } catch (e) {
      debugPrint('Error refreshing user stats: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        _userCache[response.data!.id] = response.data!;
        notifyListeners();
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Get current user error: $e');
      return null;
    }
  }
}
