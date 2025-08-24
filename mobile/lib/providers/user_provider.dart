import 'package:flutter/foundation.dart';
import 'package:tripthread/models/follow_status.dart';
import 'package:tripthread/models/user.dart';
import 'package:tripthread/services/api_service.dart';

class FollowStatus {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isRequestPending;
  final bool isPrivate;
  final String? requestId;
  final String? requestStatus;

  FollowStatus({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isRequestPending = false,
    this.isPrivate = false,
    this.requestId,
    this.requestStatus,
  });

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      isFollowing: json['isFollowing'] ?? false,
      isFollowedBy: json['isFollowedBy'] ?? false,
      isRequestPending: json['isRequestPending'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      requestId: json['requestId'],
      requestStatus: json['requestStatus'],
    );
  }
}

// This class is well-defined and serves as a local model for the API response.
class DetailedFollowStatus {
  final bool isFollowing;
  final bool isFollowedBy;
  final bool isRequestPending;
  final bool isPrivate;
  final String? requestId;
  final String? requestStatus;

  DetailedFollowStatus({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isRequestPending = false,
    this.isPrivate = false,
    this.requestId,
    this.requestStatus,
  });

  factory DetailedFollowStatus.fromJson(Map<String, dynamic> json) {
    return DetailedFollowStatus(
      isFollowing: json['isFollowing'] ?? false,
      isFollowedBy: json['isFollowedBy'] ?? false,
      isRequestPending: json['isRequestPending'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      requestId: json['requestId'],
      requestStatus: json['requestStatus'],
    );
  }
}

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;

  UserProvider({required ApiService apiService}) : _apiService = apiService;

  // --- STATE ---
  final Map<String, User> _userCache = {};
  final Map<String, UserStats> _statsCache = {};
  final Map<String, FollowStatus> _followStatusCache = {};
  final Map<String, DetailedFollowStatus> _detailedFollowStatusCache = {};
  List<dynamic> _pendingFollowRequests = [];

  final List<Map<String, dynamic>> _discoverUsers = [];
  bool _isLoading = false;
  bool _isDiscoverLoading = false;
  bool _isFollowRequestsLoading = false;
  String? _error;
  String? _discoverError;
  int _discoverPage = 1;
  bool _hasMoreUsers = true;

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  bool get isDiscoverLoading => _isDiscoverLoading;
  bool get isFollowRequestsLoading => _isFollowRequestsLoading;
  String? get error => _error;
  String? get discoverError => _discoverError;
  List<Map<String, dynamic>> get discoverUsers => _discoverUsers;
  bool get hasMoreUsers => _hasMoreUsers;
  List<dynamic> get pendingFollowRequests => _pendingFollowRequests;

  User? getUser(String userId) => _userCache[userId];
  UserStats? getUserStats(String userId) => _statsCache[userId];
  DetailedFollowStatus? getDetailedFollowStatus(String userId) =>
      _detailedFollowStatusCache[userId];

  // --- METHODS ---

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Centralized data loading for a profile screen. This is the single entry point
  // for fetching all data needed for a user profile.
  Future<void> loadProfileData(String userId, String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Run all API calls in parallel for better performance.
      await Future.wait([
        fetchUser(userId),
        fetchUserStats(userId),
        fetchDetailedFollowStatus(userId),
        // Only fetch pending requests if the user is viewing their own profile.
        if (userId == currentUserId) loadPendingFollowRequests(),
      ]);
    } catch (e) {
      _error = "Failed to load profile data: ${e.toString()}";
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<User?> fetchUser(String userId) async {
    try {
      final response = await _apiService.getUser(userId);
      if (response.success && response.data != null) {
        _userCache[userId] = response.data!;
        notifyListeners();
        return response.data;
      } else {
        _error = response.error ?? 'Failed to fetch user';
        notifyListeners();
      }
    } catch (e) {
      _error = 'An unexpected error occurred while fetching user.';
      notifyListeners();
      debugPrint('Fetch user error: $e');
    }
    return null;
  }

  Future<UserStats?> fetchUserStats(String userId) async {
    try {
      final response = await _apiService.getUserStats(userId);
      if (response.success && response.data != null) {
        _statsCache[userId] = response.data!;
        notifyListeners();
        return response.data;
      }
    } catch (e) {
      debugPrint('Fetch user stats error: $e');
    }
    return null;
  }

  Future<DetailedFollowStatus?> fetchDetailedFollowStatus(String userId) async {
    try {
      final response = await _apiService.getDetailedFollowStatus(userId);
      if (response.success && response.data != null) {
        final status = DetailedFollowStatus.fromJson(response.data!.toJson());
        _detailedFollowStatusCache[userId] = status;
        notifyListeners();
        return status;
      }
    } catch (e) {
      _error = "Failed to fetch follow status";
      notifyListeners();
      debugPrint('Fetch detailed follow status error: $e');
    }
    return null;
  }

  Future<void> loadPendingFollowRequests() async {
    _isFollowRequestsLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.getPendingFollowRequests();
      if (response.success && response.data != null) {
        _pendingFollowRequests = response.data!;
      } else {
        _error = response.error ?? "Failed to load follow requests";
      }
    } catch (e) {
      _error = "An unexpected error occurred while loading requests.";
      debugPrint('Load pending follow requests error: $e');
    } finally {
      _isFollowRequestsLoading = false;
      notifyListeners();
    }
  }
  
  // --- ACTIONS (Follow, Unfollow, Requests) ---

  Future<bool> sendFollowRequest(String userId) async {
    try {
      final response = await _apiService.sendFollowRequest(userId);
      if (response.success) {
        // After the action succeeds, refresh the state from the server.
        await fetchDetailedFollowStatus(userId);
        return true;
      }
      _error = response.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "Failed to send follow request.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelFollowRequest(String userId) async {
    try {
      final response = await _apiService.cancelFollowRequest(userId);
      if (response.success) {
        // After the action succeeds, refresh the state from the server.
        await fetchDetailedFollowStatus(userId);
        return true;
      }
      _error = response.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = "Failed to cancel follow request.";
      notifyListeners();
      return false;
    }
  }

  Future<bool> unfollowUser(String userId, {String? currentUserId}) async {
    try {
      final response = await _apiService.unfollowUser(userId);
      if (response.success) {
        // Refresh all relevant data from the server for a consistent state.
        await Future.wait([
          fetchDetailedFollowStatus(userId),
          fetchUserStats(userId),
          if (currentUserId != null) fetchUserStats(currentUserId),
        ]);
        return true;
      }
      _error = response.error ?? 'Failed to unfollow user';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during unfollow.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> acceptFollowRequest(String requestId) async {
      try {
        final response = await _apiService.acceptFollowRequest(requestId);
        if (response.success) {
          // Remove the request from the local list and refresh all requests.
          _pendingFollowRequests.removeWhere((req) => req['id'] == requestId);
          await loadPendingFollowRequests(); // Refresh the list from the server
          return true;
        }
        _error = response.error;
        notifyListeners();
        return false;
      } catch (e) {
        _error = 'Failed to accept request';
        notifyListeners();
        return false;
      }
  }

  Future<bool> rejectFollowRequest(String requestId) async {
      try {
        final response = await _apiService.rejectFollowRequest(requestId);
        if (response.success) {
          // Remove the request from the local list and refresh all requests.
          _pendingFollowRequests.removeWhere((req) => req['id'] == requestId);
           await loadPendingFollowRequests(); // Refresh the list from the server
          return true;
        }
        _error = response.error;
        notifyListeners();
        return false;
      } catch (e) {
        _error = 'Failed to reject request';
        notifyListeners();
        return false;
      }
  }

  // --- Other Methods ---

  Future<void> searchUsers({String? search, bool refresh = false}) async {
    // This implementation is fine, no changes needed.
    if (refresh) {
      _discoverPage = 1;
      _discoverUsers.clear();
      _hasMoreUsers = true;
    }
    if (_isDiscoverLoading || !_hasMoreUsers) return;

    _isDiscoverLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.searchUsers(search: search, page: _discoverPage);
      if (response.success && response.data != null) {
        _discoverUsers.addAll(response.data!);
        // Fix: ApiResponse does not have hasNext, so infer from data length
        // Assuming the API returns a page size of 20
        const int pageSize = 20;
        _hasMoreUsers = response.data!.length == pageSize;
        if (_hasMoreUsers) {
          _discoverPage++;
        }
      } else {
        _discoverError = response.error ?? "Failed to search users";
      }
    } catch (e) {
      _discoverError = "An error occurred while searching users";
    } finally {
      _isDiscoverLoading = false;
      notifyListeners();
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
      final response = await _apiService.getFollowStatus(userId);

      if (response.success && response.data != null) {
        final followStatusResponse = response.data!;
        final followStatus = FollowStatus(isFollowing: followStatusResponse.isFollowing);
        _followStatusCache[userId] = followStatus;
        notifyListeners();
        return followStatus.isFollowing;
      } else {
        _followStatusCache[userId] = FollowStatus(isFollowing: false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _followStatusCache[userId] = FollowStatus(isFollowing: false);
      notifyListeners();
      debugPrint('Fetch follow status error: $e');
      return false;
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
    _followStatusCache[userId] = FollowStatus(isFollowing: isFollowing);
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

  void clearFollowStatusCache() {
    _followStatusCache.clear();
    _detailedFollowStatusCache.clear();
    notifyListeners();
  }

  void clearFollowRequestsError() {
    _followRequestsError = null;
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
